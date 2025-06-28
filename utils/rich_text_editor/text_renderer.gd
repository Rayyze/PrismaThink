extends Control

# Self-managed variables
var document: Node
var ts: TextServer
var font_rids: Dictionary
var text_origin: Vector2 = Vector2(10.0, 20.0)
var inter_char: float = 1.0
var glyphs_data_cache: Array = []

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

func _draw():
	glyphs_data_cache = []
	var sel_min = min(document.selection_start_index, document.selection_end_index)
	var sel_max = max(document.selection_start_index, document.selection_end_index)
	var pos: Vector2 = text_origin
	var total: int = 0

	for seg in document.segments:
		var text: String = seg["text"]
		var style: Array = seg["style"]

		var color: Color = Color.WHITE
		var underline: bool = false
		var strikethrough: bool = false
		var has_bold: bool = false
		var has_italic: bool = false

		# Extract styling
		for s in style:
			match s.get("type", ""):
				"color": color = Color(s["value"])
				"u": underline = true
				"s": strikethrough = true
				"b": has_bold = true
				"i": has_italic = true

		# Prepare shaped text
		var st: RID = ts.create_shaped_text(TextServer.DIRECTION_AUTO, TextServer.ORIENTATION_HORIZONTAL)
		var font_rid: RID = get_font_rid_from_style(has_bold, has_italic)
		ts.shaped_text_add_string(st, text, [font_rid], document.font_size)
		ts.shaped_text_shape(st)

		var glyphs := ts.shaped_text_get_glyphs(st)
		for g in glyphs:
			glyphs_data_cache.append({"pos": pos, "index": total})
			var glyph_pos: Vector2 = pos + g.offset

			# Selection background
			if sel_min <= total and total < sel_max:
				draw_rect(Rect2(glyph_pos, Vector2(g.advance + inter_char, -document.font_size)), Color(0.2, 0.5, 1.0, 0.4))

			# Draw the glyph
			ts.font_draw_glyph(font_rid, get_canvas_item(), document.font_size, glyph_pos, g.index, color)

			# Underline and strikethrough
			if underline:
				var uy = pos.y + document.font_size * 1.25
				draw_line(Vector2(glyph_pos.x, uy), Vector2(glyph_pos.x + g.advance, uy), color, 1.0)
			if strikethrough:
				var sy = pos.y + document.font_size * 0.75
				draw_line(Vector2(glyph_pos.x, sy), Vector2(glyph_pos.x + g.advance, sy), color, 1.0)

			pos.x += g.advance + inter_char
			total += 1

		# Newlines
		for s in style:
			if s.get("type", "") == "br":
				pos.x = 10
				pos.y += document.font_size

func get_cursor_index_at_pos(target_pos: Vector2) -> int:
	var min_y: float = INF
	var min_x: float = INF
	var min_index: int = 0
	for glyph_data in glyphs_data_cache:
		if min_y > abs(glyph_data["pos"].y - target_pos.y):
			min_y = glyph_data["pos"].y
	for glyph_data in glyphs_data_cache:
		if min_y == glyph_data["pos"].y:
			if min_x > abs(glyph_data["pos"].x - target_pos.x):
				min_x = glyph_data["pos"].x
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

func eucl_dist_sq(a: Vector2, b: Vector2) -> float:
	return pow(a.x - b.x, 2) + pow(a.y - b.y, 2)