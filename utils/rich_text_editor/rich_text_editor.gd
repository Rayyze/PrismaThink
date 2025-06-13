extends Control

var text_renderer: Node
var cursor_renderer: Node

func _ready():
	text_renderer = find_child("TextRenderer")
	cursor_renderer = find_child("CursorRenderer")
	set_process_input(true)
	set_focus_mode(FOCUS_ALL)
	grab_focus()

func _process(_delta: float) -> void:
	cursor_renderer.line_height = text_renderer.font_size
	cursor_renderer.cursor_pos = text_renderer.cursor_pos

func _input(event):
	# TODO refactor variable (except segments)
	var is_selected: bool = text_renderer.selection_start_index != -1 and text_renderer.selection_end_index != -1
	if event is InputEventKey and event.pressed:
		# Movements
		if event.keycode == KEY_RIGHT:
			var previous_index = text_renderer.cursor_index
			text_renderer.cursor_index = min(_total_length(), text_renderer.cursor_index + 1)
			if event.shift_pressed:
				text_renderer.selection_end_index = text_renderer.cursor_index
				if text_renderer.selection_start_index == -1:
					text_renderer.selection_start_index = previous_index
			else:
				text_renderer.selection_start_index = -1
				text_renderer.selection_end_index = -1
		elif event.keycode == KEY_LEFT:
			var previous_index = text_renderer.cursor_index
			text_renderer.cursor_index = max(0, text_renderer.cursor_index - 1)
			if event.shift_pressed:
				text_renderer.selection_end_index = text_renderer.cursor_index
				if text_renderer.selection_start_index == -1:
					text_renderer.selection_start_index = previous_index
			else:
				text_renderer.selection_start_index = -1
				text_renderer.selection_end_index = -1
			
		# Deletions
		elif is_selected and (event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE):
			_delete_selection(text_renderer.selection_start_index, text_renderer.selection_end_index)
			text_renderer.cursor_index = min(text_renderer.selection_start_index, text_renderer.selection_end_index)
			text_renderer.selection_start_index = -1
			text_renderer.selection_end_index = -1
		elif event.keycode == KEY_BACKSPACE:
			if event.ctrl_pressed:
				_delete_word(-1)
			else:
				_delete_character(-1)
		elif event.keycode == KEY_DELETE:
			if event.ctrl_pressed:
				_delete_word(1)
			else:
				_delete_character(1)
				
		# Insertions
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_insert_text_with_style(" ", [ {"type": "br"}])
			text_renderer.cursor_index += 1
		elif event.unicode > 31:
			_insert_character(char(event.unicode))
		update()
	
	# Selection mouse support
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var new_index: int = _get_cursor_index_at_pos(event.position)
		if event.shift_pressed:
			if text_renderer.selection_start_index == -1:
				text_renderer.selection_start_index = text_renderer.cursor_index
			text_renderer.selection_end_index = new_index
		else:
			text_renderer.selection_start_index = -1
			text_renderer.selection_end_index = -1
		text_renderer.cursor_index = _get_cursor_index_at_pos(event.position)
		update()

func _get_cursor_index_at_pos(pos: Vector2) -> int:
	var x: float = 10
	var y: float = 10
	var total: int = 0

	for seg in text_renderer.segments:
		var text: String = seg["text"]
		var style: Array = seg["style"]
		var f: Font = text_renderer.get_font_from_style(style)
		for s in style:
			if s.get("type", "") == "br":
				x = 10
				y += f.get_ascent()
		for i in text.length():
			var char_code: int = text.unicode_at(i)
			var char_width: float = f.get_char_size(char_code, text_renderer.font_size).x
			if abs(pos.y - y) < f.get_ascent():
				if pos.x < x + char_width / 2:
					return total
			x += char_width
			total += 1
	return total

func _insert_character(c):
	var total: int = 0
	for seg in text_renderer.segments:
		var text: String = seg["text"]
		if text_renderer.cursor_index <= total + text.length():
			var local_index = text_renderer.cursor_index - total
			seg["text"] = text.substr(0, local_index) + c + text.substr(local_index)
			text_renderer.cursor_index += 1
			break
		total += text.length()
	
func _insert_text_with_style(new_text: String, new_style: Array) -> void:
	var new_segments: Array = []
	var total: int = 0
	var inserted: bool = false
	for seg in text_renderer.segments:
		var text: String = seg["text"]
		if not inserted and text_renderer.cursor_index <= total + text.length():
			var local_index = text_renderer.cursor_index - total
			new_segments.append({"text": text.substr(0, local_index), "style": seg["style"].duplicate()})
			new_segments.append({"text": new_text, "style": new_style})
			new_segments.append({"text": text.substr(local_index), "style": seg["style"].duplicate()})
			inserted = true
		else:
			new_segments.append(seg)
		total += text.length()
	if not inserted:
		new_segments.append({"text": new_text, "style": new_style})
	text_renderer.segments = new_segments

func _delete_character(direction: int) -> String:
	var total: int = 0
	var removed: String = ""
	for seg in text_renderer.segments:
		var text: String = seg["text"]
		if text_renderer.cursor_index <= total + text.length():
			var local_index: int = text_renderer.cursor_index - total
			if local_index > 0 and direction < 0:
				removed = seg["text"][local_index - 1]
				seg["text"] = text.substr(0, local_index - 1) + text.substr(local_index)
				text_renderer.cursor_index -= 1
				break
			elif local_index < text.length() and direction > 0:
				removed = seg["text"][local_index]
				seg["text"] = text.substr(0, local_index) + text.substr(local_index + 1)
				break
		total += text.length()
	return removed

func _delete_word(direction: int) -> String:
	var removed_char := ""
	var removed_word := ""
	while true:
		removed_char = _delete_character(direction)
		if removed_char == "" or removed_char == " " or removed_char == "\n":
			break
		if direction < 0:
			removed_word = removed_char + removed_word
		else:
			removed_word += removed_char
	return removed_word

func _delete_selection(from: int, to: int) -> String:
	var result: String = ""
	if from > to:
		var tmp: int = from
		from = to
		to = tmp
	var total: int = 0
	for seg in text_renderer.segments:
		var text: String = seg["text"]
		var text_len: int = text.length()
		if total >= to:
			break
		if total + text_len < from:
			total += text_len
			continue
		var local_from: int = max(from - total, 0)
		var local_to: int = min(to - total, text_len)
		var local_len: int = local_to - local_from
		result += text.substr(local_from, local_len)
		text = text.substr(0, local_from) + text.substr(local_from + local_len)
		seg["text"] = text
	return result

func _total_length():
	var total := 0
	for seg in text_renderer.segments:
		total += seg["text"].length()
	return total

func apply_style(from: int, to: int, new_style: Array) -> void:
	var new_segments: Array = []
	var cursor: int = 0
	for seg in text_renderer.segments:
		var text: String = seg["text"]
		var style: Array = seg["style"].duplicate()
		var seg_start: int = cursor
		var seg_end: int = cursor + text.length()
		
		# CASE 1: Segment is completely before or after range
		if seg_end <= from or seg_start >= to:
			new_segments.append(seg)
		# CASE 2: Segment is partially or fully inside the range
		else:
			var local_from: int = max(from, seg_start) - seg_start
			var local_to: int = min(to, seg_end) - seg_start
			
			# Left part (before selection)
			if local_from > 0:
				new_segments.append({"text": text.substr(0, local_from), "style": style.duplicate()})
			
			# Middle part (apply style)
			var mid_text: String = text.substr(local_from, local_to - local_from)
			var mid_style: Array = style.duplicate()
			for tag in new_style:
				if not mid_style.has(tag):
					style = add_tag_to_style(style, tag)
				else:
					mid_style.erase(tag)
			new_segments.append({"text": mid_text, "style": mid_style})
			
			# Right part (after selection)
			if local_to < text.length():
				new_segments.append({"text": text.substr(local_to), "style": style.duplicate()})
			
		cursor += text.length()
	text_renderer.segments = merge_adjacent_segments(clean_empty_segments(new_segments))

func add_tag_to_style(old_style: Array, new_tag: Dictionary) -> Array:
	var style = old_style.duplicate()
	var replaced = false
	for tag in style:
		if tag["type"] == new_tag["type"]:
			tag = new_tag
			replaced = true
			break
	if not replaced:
		style.append(new_tag)
	return style

func merge_adjacent_segments(input: Array) -> Array:
	print(input)
	print("merged into:")
	if input.is_empty():
		return []
	var result := [input[0]]
	for i in range(1, input.size()):
		var last = result[-1]
		var current = input[i]
		if styles_equal(last["style"], current["style"]) and current["style"] != [{"type": "br"}]:
			last["text"] += current["text"]
			result[-1] = last
		else:
			result.append(current)
	print(result)
	return result

func clean_empty_segments(input: Array) -> Array:
	var new_segments: Array = []
	for seg in input:
		if seg["text"] != "":
			new_segments.append(seg.duplicate(true))
	return new_segments

func styles_equal(style_a: Array, style_b: Array):
	for s in style_a:
		if not style_b.has(s):
			return false
	return true

func update():
	text_renderer.segments = merge_adjacent_segments(clean_empty_segments(text_renderer.segments))
	text_renderer.queue_redraw()
