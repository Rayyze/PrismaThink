extends Node2D

signal glyph_cache_updated

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

func _draw() -> void:
	layout_text()
	draw_glyphs()

func layout_text():	
	glyphs_data_cache.clear()
	var pos: Vector2 = text_origin
	var total: int = 0
	breakpoints_data_cache.clear()

	for seg in document.segments:
		var text: String = seg["text"]
		var style: Array = seg["style"]
		var color: Color = Color.WHITE
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
		var font_rid: RID = get_font_rid_from_style(style_mask & STYLE_BOLD, style_mask & STYLE_ITALIC)
		ts.shaped_text_add_string(st, text, [font_rid], document.font_size)
		ts.shaped_text_shape(st)

		var glyphs := ts.shaped_text_get_glyphs(st)
		var i = 0
		for g in glyphs:
			var glyph_pos: Vector2 = pos + g.offset
			var real_advance: float = g.advance + inter_char
			glyphs_data_cache.append({
				"pos": glyph_pos,
				"advance": real_advance,
				"index": total,
				"style_mask": style_mask,
				"color": color,
				"char_index": g.index,
				"char": text[i]
			})
			pos.x += real_advance
			total += 1
			i += 1

		# Newlines
		if newline:
			pos.x = text_origin.x
			pos.y += document.font_size
		ts.free_rid(st)
	add_linebreaks()
	emit_signal("glyph_cache_updated")

func add_linebreaks():
	var available_width: float = get_parent().size.x
	var line_x: float = text_origin.x
	var line_y: float = text_origin.y
	var last_breakpoint_index: int = -1
	var i: int = 0
	var new_cache: Array = []
	var index_shift: int = 0

	while i < glyphs_data_cache.size():
		var g = glyphs_data_cache[i]
		var advance = g["advance"]
		
		# Explicit line breaks
		if g.has("line_break") and g["line_break"]:
			line_x = text_origin.x
			line_y += document.font_size

		# Word separator
		if document.word_separators.has(g["char"]):
			last_breakpoint_index = i

		# Overflow wrap
		if (line_x - text_origin.x + advance) > available_width:
			new_cache.append({
				"pos": Vector2(line_x, line_y),
				"index": i + index_shift,
				"advance": 0,
				"char": "",
				"style_mask": 0,
				"color": Color.WHITE,
				"char_index": 1777,
			})
			index_shift += 1
			if last_breakpoint_index == -1:
				line_x = text_origin.x
				line_y += document.font_size
			else:
				var wrap_line_y = line_y + document.font_size
				var wrap_x: float = text_origin.x
				for j in range(last_breakpoint_index + 1, i):
					var g2 = new_cache[j + index_shift]
					var a2 = g2["advance"]
					g2["pos"] = Vector2(wrap_x, wrap_line_y)
					wrap_x += a2
				line_y = wrap_line_y
				line_x = wrap_x
			last_breakpoint_index = -1
		g["pos"] = Vector2(line_x, line_y)
		g["index"] += index_shift
		new_cache.append(g)
		line_x += advance
		i += 1
	glyphs_data_cache = new_cache

func draw_glyphs():
	var sel_min = min(document.selection_start_index, document.selection_end_index)
	var sel_max = max(document.selection_start_index, document.selection_end_index)
	var pos: Vector2 = text_origin
	var total: int = 0

	for glyph_data in glyphs_data_cache:
		var font_rid: RID = get_font_rid_from_style(glyph_data["style_mask"] & STYLE_BOLD, glyph_data["style_mask"] & STYLE_ITALIC)

		# Selection background
		if document.edit_mode and sel_min <= total and total < sel_max:
			draw_rect(Rect2(glyph_data["pos"], Vector2(glyph_data["advance"], -document.font_size)), Color(0.2, 0.5, 1.0, 0.4))

		# Draw the glyph
		ts.font_draw_glyph(font_rid, get_canvas_item(), document.font_size, glyph_data["pos"], glyph_data["char_index"], glyph_data["color"])

		# Underline and strikethrough
		if glyph_data["style_mask"] & STYLE_UNDERLINE:
			var uy = pos.y + document.font_size * 0.25
			draw_line(Vector2(glyph_data["pos"].x, uy), Vector2(glyph_data["pos"].x + glyph_data["advance"], uy), glyph_data["color"], 1.0)
		if glyph_data["style_mask"] & STYLE_STRIKETHROUGH:
			var sy = pos.y - document.font_size * 0.25
			draw_line(Vector2(glyph_data["pos"].x, sy), Vector2(glyph_data["pos"].x + glyph_data["advance"], sy), glyph_data["color"], 1.0)
		total += 1

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


func get_total_glyphs() -> int:
	return glyphs_data_cache.size()
