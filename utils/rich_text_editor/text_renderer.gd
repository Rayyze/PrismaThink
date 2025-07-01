extends Control

signal cache_updated

# Self-managed variables
var document: Node
var ts: TextServer
var font_rids: Dictionary
var text_origin: Vector2 = Vector2(10.0, 20.0)
var inter_char: float = 1.0
var glyphs_data_cache: Array = []
var breakpoints_data_cache: Array = []
const STYLE_BOLD = 1 << 0       # 0001
const STYLE_ITALIC = 1 << 1     # 0010
const STYLE_UNDERLINE = 1 << 2  # 0100
const STYLE_STRIKETHROUGH = 1 << 3  # 1000

func _ready():
	ts = TextServerManager.get_primary_interface()
	font_rids = {
		"regular": ts.create_font(),
		"italic": ts.create_font(),
		"bold": ts.create_font(),
		"bold-italic": ts.create_font()}
	var font_data: PackedByteArray = FileAccess.get_file_as_bytes("res://fonts/Inter-Regular.ttf")
	for font_name in font_rids:
		ts.font_set_data(font_rids[font_name], font_data)
	var italic_angle: float = 0.3
	var skew := Transform2D(Vector2(1.0, italic_angle), Vector2(0.0, 1.0), Vector2.ZERO)
	var weight: float = 1.0
	ts.font_set_transform(font_rids["italic"], skew)
	ts.font_set_transform(font_rids["bold-italic"], skew)
	ts.font_set_embolden(font_rids["bold"], weight)
	ts.font_set_embolden(font_rids["bold-italic"], weight)

	document = get_node("../RichTextDocument")

func layout_text():	
	glyphs_data_cache = []
	var pos: Vector2 = text_origin
	var total: int = 0
	breakpoints_data_cache = []
	var available_width: float = size.x
	print(available_width)
	var last_breakpoint: int = -1
	var line_start_x: float = text_origin.x

	for seg in document.segments:
		var text: String = seg["text"]
		var style: Array = seg["style"]

		var color: Color = Color.WHITE
		var underline: bool = false
		var strikethrough: bool = false
		var has_bold: bool = false
		var has_italic: bool = false
		var newline: bool = false

		# Extract styling
		var style_mask = 0
		for s in style:
			match s.get("type", ""):
				"color": color = Color(s["value"])
				"u": style_mask |= STYLE_UNDERLINE
				"s": style_mask |= STYLE_STRIKETHROUGH
				"b": style_mask |= STYLE_BOLD
				"i": style_mask |= STYLE_ITALIC
				"br": newline = true

		# Prepare shaped text
		var st: RID = ts.create_shaped_text(TextServer.DIRECTION_AUTO, TextServer.ORIENTATION_HORIZONTAL)
		var font_rid: RID = get_font_rid_from_style(has_bold, has_italic)
		ts.shaped_text_add_string(st, text, [font_rid], document.font_size)
		ts.shaped_text_shape(st)

		var glyphs := ts.shaped_text_get_glyphs(st)
		var i: int = 0
		for g in glyphs:
			print(text[i], " at ", pos)
			print(color)
			var glyph_pos: Vector2 = pos + g.offset
			glyphs_data_cache.append({"pos": glyph_pos, "index": total, "style_mask": style_mask, "color": color})
			var real_advance: float = g.advance + inter_char
			pos.x += real_advance
			total += 1

		# Newlines
		if newline:
			pos.x = text_origin.x
			pos.y += document.font_size
			last_breakpoint = -1
			line_start_x = pos.x

func _draw():
	print(document.segments)
	glyphs_data_cache = []
	var sel_min = min(document.selection_start_index, document.selection_end_index)
	var sel_max = max(document.selection_start_index, document.selection_end_index)
	var pos: Vector2 = text_origin
	var total: int = 0
	breakpoints_data_cache = []
	var available_width: float = size.x
	print(available_width)
	var last_breakpoint: int = -1
	var line_start_x: float = text_origin.x

	for seg in document.segments:
		var text: String = seg["text"]
		var style: Array = seg["style"]

		var color: Color = Color.WHITE
		var underline: bool = false
		var strikethrough: bool = false
		var has_bold: bool = false
		var has_italic: bool = false
		var newline: bool = false

		# Extract styling
		for s in style:
			match s.get("type", ""):
				"color": color = Color(s["value"])
				"u": underline = true
				"s": strikethrough = true
				"b": has_bold = true
				"i": has_italic = true
				"br": newline = true

		# Prepare shaped text
		var st: RID = ts.create_shaped_text(TextServer.DIRECTION_AUTO, TextServer.ORIENTATION_HORIZONTAL)
		var font_rid: RID = get_font_rid_from_style(has_bold, has_italic)
		ts.shaped_text_add_string(st, text, [font_rid], document.font_size)
		ts.shaped_text_shape(st)

		var glyphs := ts.shaped_text_get_glyphs(st)
		var i: int = 0
		for g in glyphs:
			print(text[i], " at ", pos)
			glyphs_data_cache.append({"pos": pos, "index": total})
			var glyph_pos: Vector2 = pos + g.offset
			var real_advance: float = g.advance + inter_char

			# Handle and cache autowrap positions
			var dx: float = pos.x - line_start_x
			if document.word_separators.has(text[i]):
				last_breakpoint = total + 1
			if dx > available_width:
				print(dx, " for ", text[i])
				if last_breakpoint == -1:
					breakpoints_data_cache.append(total + 1)
				else:
					breakpoints_data_cache.append(last_breakpoint)
				newline = true
			i += 1

			# Selection background
			if sel_min <= total and total < sel_max:
				draw_rect(Rect2(glyph_pos, Vector2(real_advance, -document.font_size)), Color(0.2, 0.5, 1.0, 0.4))

			# Draw the glyph
			ts.font_draw_glyph(font_rid, get_canvas_item(), document.font_size, glyph_pos, g.index, color)

			# Underline and strikethrough
			if underline:
				var uy = pos.y + document.font_size * 0.25
				draw_line(Vector2(glyph_pos.x, uy), Vector2(glyph_pos.x + real_advance, uy), color, 1.0)
			if strikethrough:
				var sy = pos.y - document.font_size * 0.25
				draw_line(Vector2(glyph_pos.x, sy), Vector2(glyph_pos.x + real_advance, sy), color, 1.0)

			pos.x += real_advance
			total += 1

		# Newlines
		if newline:
			pos.x = text_origin.x
			pos.y += document.font_size
			last_breakpoint = -1
			line_start_x = pos.x
	emit_signal("cache_updated")

func get_cursor_index_at_pos(target_pos: Vector2) -> int:
	var best_y_diff := INF
	var best_line_y := 0.0
	for glyph_data in glyphs_data_cache:
		var dy = abs(glyph_data["pos"].y - target_pos.y)
		if dy < best_y_diff:
			best_y_diff = dy
			best_line_y = glyph_data["pos"].y
	var best_x_diff := INF
	var min_index := 0
	for glyph_data in glyphs_data_cache:
		if abs(glyph_data["pos"].y - best_line_y) < 0.5:
			var dx = abs(glyph_data["pos"].x - target_pos.x)
			if dx < best_x_diff:
				best_x_diff = dx
				min_index = glyph_data["index"]
	return min_index

func get_pos_at_index(index: int) -> Vector2:
	for glyph_data in glyphs_data_cache:
		if glyph_data["index"] == index:
			return glyph_data["pos"]
	return Vector2.ZERO

func get_font_rid_from_style(has_bold: bool, has_italic: bool) -> RID:
	if has_italic && has_bold:
		return font_rids["bold-italic"]
	elif has_bold:
		return font_rids["bold"]
	elif has_italic:
		return font_rids["italic"]
	else:
		return font_rids["regular"]

func breakpoints_scan():
	breakpoints_data_cache = []
	var available_width: float = size.x
	var last_breakpoint: int = -1
	var last_y: float = text_origin.y
	var line_start_x: float = text_origin.x
	for glyph_data in glyphs_data_cache:
		var pos = glyph_data["pos"]
		var dx: float = pos.x - line_start_x
		if document.word_separator.has(glyph_data["char"]):
			last_breakpoint = glyph_data["index"] + 1
		if dx > available_width:
			if last_breakpoint == -1:
				breakpoints_data_cache.append(glyph_data["index"] + 1)
			else:
				breakpoints_data_cache.append(last_breakpoint)
			line_start_x = pos.x
			last_breakpoint = -1
		if pos.y != last_y:
			last_breakpoint = -1
			line_start_x = pos.x
			last_y = pos.y