extends Control

# Self-managed variables
var document: Node
var custom_theme: Resource = preload("res://themes/default_theme.tres")
var font_regular: Resource
var font_bold: Resource
var font_italic: Resource
var font_bold_italic: Resource

func _ready():
	var default_theme: Resource = load("res://themes/default_theme.tres")
	document = get_node("../RichTextDocument")
	font_regular = default_theme.get_font("regular_font", "rich_text_editor")
	font_bold = default_theme.get_font("bold_font", "rich_text_editor")
	font_italic = default_theme.get_font("italic_font", "rich_text_editor")
	font_bold_italic = default_theme.get_font("bold_italic_font", "rich_text_editor")
	document.font_size = ThemeDB.fallback_font_size

func _draw():
	var x: float = 10
	var y: float = 10
	var total: int = 0
	var col: Color
	var is_selected: bool = document.selection_start_index != -1 and document.selection_end_index != -1
	var sel_from: int = min(document.selection_start_index, document.selection_end_index)
	var sel_to: int = max(document.selection_start_index, document.selection_end_index)

	for seg in document.segments:
		var text: String = seg["text"]
		var style: Array = seg["style"]

		var f: Font = get_font_from_style(style)
		var new_line: bool = false
		col = Color.WHITE

		for s in style:
			if s.get("type", "") == "color":
				col = Color(s["value"])
			if s.get("type", "") == "br":
				new_line = true

		for i in text.length():
			var char_string: String = text[i]
			var char_code: int = text.unicode_at(i)
			var char_width = f.get_char_size(char_code, document.font_size).x

			# Draw selection background
			if is_selected and (total >= sel_from and total < sel_to):
				draw_rect(Rect2(Vector2(x, y), Vector2(char_width, f.get_height())), Color(0.2, 0.5, 1.0, 0.4))

			# Draw character
			f.draw_string(get_canvas_item(), Vector2(x, y + document.font_size), char_string, HORIZONTAL_ALIGNMENT_LEFT, -1, document.font_size, col)

			# Update cursor position
			if document.cursor_index == total:
				document.cursor_pos = Vector2(x, y)

			x += char_width
			total += 1
			if new_line:
				y += document.font_size
				x = 10

	# Final cursor check (in case it's at the end of the last segment)
	if document.cursor_index == total:
		document.cursor_pos = Vector2(x, y)

func get_font_from_style(style: Array):
	var has_bold: bool = false
	var has_italic: bool = false
	for s in style:
		match s.get("type", ""):
			"b": has_bold = true
			"i": has_italic = true
	if has_bold and has_italic:
		return font_bold_italic
	elif has_bold:
		return font_bold
	elif has_italic:
		return font_italic
	else:
		return font_regular
