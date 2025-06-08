extends Control

var segments: Array = [
	{"text": "Welcome to your note.", "style": []},
	{"text": "bold", "style": [{"type": "i"}]}
]
var custom_theme: Resource = preload("res://themes/default_theme.tres")
var font_regular: Resource
var font_bold: Resource
var font_italic: Resource
var font_bold_italic: Resource
var line_height: int = 16
var font_size: int
var cursor_pos: Vector2
var cursor_index: int

func _ready():
	var default_theme: Resource = load("res://themes/default_theme.tres")
	print(default_theme.get_font_type_list())
	print(default_theme.get_font_list("rich_text_editor"))
	font_regular = default_theme.get_font("regular_font", "rich_text_editor")
	font_bold = default_theme.get_font("bold_font", "rich_text_editor")
	font_italic = default_theme.get_font("italic_font", "rich_text_editor")
	font_bold_italic = default_theme.get_font("bold_italic_font", "rich_text_editor")
	font_size = ThemeDB.fallback_font_size

func _draw():
	var x := 10
	var y := 10
	var total := 0
	var has_bold: bool = false
	var has_italic: bool = false
	var f: Resource = font_regular
	var col: Color = Color.WHITE

	for seg in segments:
		var text: String = seg["text"]
		var style: Array = seg["style"]
		
		for s in style:
			match s.get("type", ""):
				"b": has_bold = true
				"i": has_italic = true
				"color": col = Color(s["value"])
		if has_bold and has_italic:
			f = font_bold_italic
		elif has_bold:
			f = font_bold
		elif has_italic:
			f = font_italic

		f.draw_string(get_canvas_item(), Vector2(x, y + line_height), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)

		if cursor_index >= total and cursor_index <= total + text.length():
			cursor_pos = Vector2(x + f.get_string_size(text.substr(0, cursor_index - total)).x, y)

		x += f.get_string_size(text).x
		total += text.length()
