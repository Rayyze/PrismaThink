extends Control

var text_renderer: Node
var document: Node
var is_dragging: bool = false

func _ready():
	text_renderer = find_child("TextRenderer")
	document = find_child("RichTextDocument")
	set_process_input(true)
	set_focus_mode(FOCUS_ALL)
	grab_focus()

func _input(event):
	var is_selected: bool = document.selection_start_index != -1 and document.selection_end_index != -1
	var previous_cursor: int = document.cursor_index
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				document.cursor_index = get_cursor_index_horizontal(-1, event.ctrl_pressed)
			KEY_RIGHT:
				document.cursor_index = get_cursor_index_horizontal(1, event.ctrl_pressed)
			KEY_UP:
				document.cursor_index = get_cursor_index_vertical(-1)
			KEY_DOWN:
				document.cursor_index = get_cursor_index_vertical(1)
			KEY_DELETE, KEY_BACKSPACE:
				if is_selected:
					_delete_selection(document.selection_start_index, document.selection_end_index)
					document.cursor_index = min(document.selection_start_index, document.selection_end_index)
				elif event.keycode == KEY_DELETE:
					var to = get_cursor_index_horizontal(1, event.ctrl_pressed)
					_delete_selection(document.cursor_index, to)
				else:
					var to = get_cursor_index_horizontal(-1, event.ctrl_pressed)
					_delete_selection(document.cursor_index, to)
					document.cursor_index = max(0, document.cursor_index - 1)
			KEY_ENTER, KEY_KP_ENTER:
				_insert_text_with_style(" ", [{"type": "br"}], document.cursor_index)
				document.cursor_index += 1
			_:
				if event.ctrl_pressed and is_selected:
					match event.keycode:
						KEY_B:
							_apply_style(document.selection_start_index, document.selection_end_index, [{"type": "b"}])
						KEY_I:
							_apply_style(document.selection_start_index, document.selection_end_index, [{"type": "i"}])
						KEY_U:
							_apply_style(document.selection_start_index, document.selection_end_index, [{"type": "u"}])
						KEY_K:
							_apply_style(document.selection_start_index, document.selection_end_index, [{"type": "s"}])
				elif event.unicode > 31:
					_insert_text_with_style(char(event.unicode), [], document.cursor_index)
					document.cursor_index += 1
		if event.shift_pressed:
			if not is_selected:
				document.selection_start_index = previous_cursor
			document.selection_end_index = document.cursor_index
		elif event.keycode not in [KEY_CTRL, KEY_SHIFT, KEY_ALT, KEY_CAPSLOCK, KEY_META]:
			document.selection_end_index = -1
			document.selection_start_index = -1
		update()

	# Mouse press
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				var new_index = _get_cursor_index_at_pos(event.position)
				if Input.is_key_pressed(KEY_SHIFT):
					if document.selection_start_index == -1:
						document.selection_start_index = document.cursor_index
					document.selection_end_index = new_index
				else:
					document.selection_start_index = new_index
					document.selection_end_index = new_index
				document.cursor_index = new_index
				update()
			else:
				is_dragging = false

	# Mouse drag
	elif event is InputEventMouseMotion and is_dragging:
		var new_index = _get_cursor_index_at_pos(event.position)
		document.selection_end_index = new_index
		document.cursor_index = new_index
		update()

func _get_cursor_index_at_pos(target_pos: Vector2) -> int:
	var pos: Vector2 = Vector2(10.0, 10.0 + document.font_size* 0.5)
	var dist: Array = []
	var indices: Array = []
	var total: int = 0
	var same_line_dist: Array = []
	var same_line_indices: Array = []

	for seg in document.segments:
		var text: String = seg["text"]
		var style: Array = seg["style"]
		var f: Font = text_renderer.get_font_from_style(style)
		for i in text.length():
			var d := eucl_dist_sq(pos, target_pos)
			if abs(pos.y - target_pos.y) < document.font_size * 0.5:
				same_line_dist.append(d)
				same_line_indices.append(total)
			var char_code: int = text.unicode_at(i)
			var char_width: float = f.get_char_size(char_code, document.font_size).x
			pos.x += char_width
			total += 1
			dist.append(d)
			indices.append(total)
		for s in style:
			if s.get("type", "") == "br":
				pos.x = 10
				pos.y += document.font_size
	print(dist)
	if not same_line_indices.is_empty():
		print(same_line_indices[same_line_dist.find(same_line_dist.min())])
		return same_line_indices[same_line_dist.find(same_line_dist.min())]
	elif indices.size() > 0:
		print( indices[dist.find(dist.min())])
		return indices[dist.find(dist.min())]
	else:
		return 0

func _get_pos_at_index(index: int) -> Vector2:
	var pos: Vector2 = Vector2(10.0, 10.0 + document.font_size/2)
	var total: int = 0
	var found: bool = false
	for seg in document.segments:
		var text: String = seg["text"]
		var style: Array = seg["style"]
		var f: Font = text_renderer.get_font_from_style(style)
		for i in text.length():
			if total == index:
				found = true
				break

			var char_code: int = text.unicode_at(i)
			pos.x += f.get_char_size(char_code, document.font_size).x
			total += 1
		if found:
			break
		for s in style:
			if s.get("type", "") == "br":
				pos.x = 10
				pos.y += document.font_size
	return pos

func get_cursor_index_vertical(direction: int) -> int:
	var pos: Vector2 = _get_pos_at_index(document.cursor_index)
	pos.y += direction * document.font_size
	return _get_cursor_index_at_pos(pos)

func get_cursor_index_horizontal(direction: int, ctrl_pressed: bool) -> int:
	if ctrl_pressed:
		return _find_next_word_index(direction)
	else:
		if direction < 0:
			return max(0, document.cursor_index - 1)
		else:
			return min(_total_length(), document.cursor_index + 1)

func _apply_style(from: int, to: int, style: Array) -> void:
	var deleted_segments: Array = _delete_selection(from, to)
	print(deleted_segments)
	var index: int = min(from, to)
	for seg in deleted_segments:
		var new_style: Array = seg["style"]
		var text: String = seg["text"]
		var text_len: int = text.length()
		for s in style:
			if new_style.has(s):
				new_style.erase(s)
			else:
				new_style.append(s)
		_insert_text_with_style(text, new_style, index)
		index += text_len
		print(seg)

func _insert_text_with_style(new_text: String, new_style: Array, index: int) -> void:
	var new_segments: Array = []
	var total: int = 0
	var inserted: bool = false
	for seg in document.segments:
		var text: String = seg["text"]
		if not inserted and index <= total + text.length():
			var local_index = index - total
			new_segments.append({"text": text.substr(0, local_index), "style": seg["style"].duplicate()})
			new_segments.append({"text": new_text, "style": new_style})
			new_segments.append({"text": text.substr(local_index), "style": seg["style"].duplicate()})
			inserted = true
		else:
			new_segments.append(seg)
		total += text.length()
	if not inserted:
		new_segments.append({"text": new_text, "style": new_style})
	document.segments = new_segments

func _delete_character(direction: int) -> String:
	var total: int = 0
	var removed: String = ""
	for seg in document.segments:
		var text: String = seg["text"]
		if document.cursor_index <= total + text.length():
			var local_index: int = document.cursor_index - total
			if local_index > 0 and direction < 0:
				removed = seg["text"][local_index - 1]
				seg["text"] = text.substr(0, local_index - 1) + text.substr(local_index)
				document.cursor_index -= 1
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

func _find_next_word_index(direction: int) -> int:
	var before: int = 0
	var after: int = 0
	var total: int = 0
	var found: bool = false
	for seg in document.segments:
		var text: String = seg["text"]
		for c in text:
			if document.word_separators.has(c):
				if total < document.cursor_index:
					before = total
				elif total > document.cursor_index:
					after = total
					found = true
					break
			total += 1
		if found:
			break
	if direction < 0:
		return before
	else:
		return after

func _delete_selection(from: int, to: int) -> Array:
	from = clamp(from, 0, _total_length())
	to = clamp(to, 0, _total_length())
	var deleted_segments: Array = []
	if from > to:
		var tmp: int = from
		from = to
		to = tmp
	var total: int = 0
	for seg in document.segments:
		var text: String = seg["text"]
		var style: Array = seg["style"].duplicate()
		var text_len: int = text.length()
		if total >= to:
			break
		if total + text_len < from:
			total += text_len
			continue
		var local_from: int = max(from - total, 0)
		var local_to: int = min(to - total, text_len)
		var local_len: int = local_to - local_from
		deleted_segments.append({"text": text.substr(local_from, local_len), "style": style})
		text = text.substr(0, local_from) + text.substr(local_from + local_len)
		seg["text"] = text
		total += text_len
	return deleted_segments

func _total_length():
	var total: int = 0
	for seg in document.segments:
		total += seg["text"].length()
	return total

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
	return result

func clean_empty_segments(input: Array) -> Array:
	var new_segments: Array = []
	for seg in input:
		if seg["text"] != "":
			new_segments.append(seg.duplicate(true))
	return new_segments

func add_trailing_break() -> void:
	if document.segments.is_empty() or document.segments[-1] != {"text": " ", "style": [{"type": "br"}]}:
		document.segments.append({"text": " ", "style": [{"type": "br"}]})

func styles_equal(style_a: Array, style_b: Array):
	if style_a.size() != style_b.size():
		return false
	for s in style_a:
		if not style_b.has(s):
			return false
	return true

func update():
	add_trailing_break()
	document.segments = merge_adjacent_segments(clean_empty_segments(document.segments))
	document.cursor_pos = _get_pos_at_index(document.cursor_index) - Vector2(0.0, document.font_size/2)
	text_renderer.queue_redraw()

func eucl_dist_sq(a: Vector2, b: Vector2) -> float:
	return pow(a.x - b.x, 2) + pow(a.y - b.y, 2)
