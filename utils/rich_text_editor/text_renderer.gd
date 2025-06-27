extends Control

# Self-managed variables
var document: Node
var ts: TextServer
var font_rids: Dictionary

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
	var skew := Transform2D(0.0, Vector2(1.0, 1.0), 0.3, Vector2.ZERO)
	ts.font_set_transform(font_rids["italic"], skew)
	ts.font_set_transform(font_rids["bold-italic"], skew)
	ts.font_set_embolden(font_rids["bold"], 0.2)
	ts.font_set_embolden(font_rids["bold-italic"], 0.2)

	document = get_node("../RichTextDocument")

func _draw():
	var x := 10.0
	var y := 10.0
	var total := 0

	for seg in document.segments:
		var text: String = seg["text"]
		var style: Array = seg["style"]

		var color := Color.WHITE
		var underline := false
		var strikethrough := false
		var has_bold := false
		var has_italic := false

		# Extract styling
		for s in style:
			match s.get("type", ""):
				"color": color = Color(s["value"])
				"u": underline = true
				"s": strikethrough = true
				"b": has_bold = true
				"i": has_italic = true

		var font: Font = document.font

		# Prepare shaped text
		var st := ts.create_shaped_text(TextServer.DIRECTION_AUTO, TextServer.ORIENTATION_HORIZONTAL)
		var font_rid: RID = get_font_rid_from_style(has_bold, has_italic)
		ts.shaped_text_add_string(st, text, [font_rid], document.font_size)
		ts.shaped_text_shape(st)

		var glyphs := ts.shaped_text_get_glyphs(st)
		print(glyphs)
		for g in glyphs:
			var pos: Vector2 = Vector2(x, y) + g.offset

			# Selection background
			if document.selection_start_index <= total and total < document.selection_end_index:
				draw_rect(Rect2(pos, Vector2(g.advance, font.get_height())), Color(0.2, 0.5, 1.0, 0.4))

			# Draw the glyph
			ts.font_draw_glyph(font_rid, get_canvas_item(), document.font_size, pos, g.index, color)

			# Underline and strikethrough
			if underline:
				var uy = y + document.font_size * 1.25
				draw_line(Vector2(pos.x, uy), Vector2(pos.x + g.advance, uy), color, 1.0)
			if strikethrough:
				var sy = y + document.font_size * 0.75
				draw_line(Vector2(pos.x, sy), Vector2(pos.x + g.advance, sy), color, 1.0)

			x += g.advance
			total += 1

		# Newlines
		for s in style:
			if s.get("type", "") == "br":
				x = 10
				y += document.font_size


func get_font_rid_from_style(has_bold: bool, has_italic: bool) -> RID:
	if has_italic && has_bold:
		return font_rids["bold-italic"]
	elif has_bold:
		return font_rids["bold"]
	elif has_italic:
		return font_rids["italic"]
	else:
		return font_rids["regular"]