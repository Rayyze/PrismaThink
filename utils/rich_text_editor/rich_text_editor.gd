extends Control

var text_renderer: Node
var document: Node

func _ready():
	text_renderer = find_child("TextRenderer")
	document = find_child("RichTextDocument")
	set_process_input(true)
	set_focus_mode(FOCUS_ALL)
	grab_focus()

func _input(event):
	# TODO refactor variable (except segments)
	var is_selected: bool = document.selection_start_index != -1 and document.selection_end_index != -1
	if event is InputEventKey and event.pressed:
		# Movements
		if event.keycode == KEY_RIGHT:
			var previous_index = document.cursor_index
			document.cursor_index = min(_total_length(), document.cursor_index + 1)
			if event.shift_pressed:
				document.selection_end_index = document.cursor_index
				if document.selection_start_index == -1:
					document.selection_start_index = previous_index
			else:
				document.selection_start_index = -1
				document.selection_end_index = -1
		elif event.keycode == KEY_LEFT:
			var previous_index = document.cursor_index
			document.cursor_index = max(0, document.cursor_index - 1)
			if event.shift_pressed:
				document.selection_end_index = document.cursor_index
				if document.selection_start_index == -1:
					document.selection_start_index = previous_index
			else:
				document.selection_start_index = -1
				document.selection_end_index = -1
		elif event.keycode == KEY_UP:
			document.cursor_index = get_cursor_index_vertical(-1)
		elif event.keycode == KEY_DOWN:
			document.cursor_index = get_cursor_index_vertical(1)

		# Deletions
		elif is_selected and (event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE):
			_delete_selection(document.selection_start_index, document.selection_end_index)
			document.cursor_index = min(document.selection_start_index, document.selection_end_index)
			document.selection_start_index = -1
			document.selection_end_index = -1
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
			document.cursor_index += 1
		elif event.unicode > 31:
			_insert_text_with_style(char(event.unicode), [])
			document.cursor_index += 1
		update()
	
	# Selection mouse support
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var new_index: int = _get_cursor_index_at_pos(event.position)
		if event.shift_pressed:
			if document.selection_start_index == -1:
				document.selection_start_index = document.cursor_index
			document.selection_end_index = new_index
		else:
			document.selection_start_index = -1
			document.selection_end_index = -1
		document.cursor_index = _get_cursor_index_at_pos(event.position)
		print(event.position)
		update()

func _get_cursor_index_at_pos(pos: Vector2) -> int:
	var x: float = 10
	var y: float = 10
	var total: int = 0

	for seg in document.segments:
		var text: String = seg["text"]
		var style: Array = seg["style"]
		var f: Font = text_renderer.get_font_from_style(style)
		for s in style:
			if s.get("type", "") == "br":
				x = 10
				y += document.font_size
		for i in text.length():
			var char_code: int = text.unicode_at(i)
			var char_width: float = f.get_char_size(char_code, document.font_size).x
			if abs(pos.y - y) < document.font_size:
				if pos.x < x + char_width / 2:
					return total
			x += char_width
			total += 1
	return total

func _get_pos_at_index(index: int) -> Vector2:
	var pos: Vector2 = Vector2(10.0, 10.0)
	var total: int = 0
	var found: bool = false
	for seg in document.segments:
		var text: String = seg["text"]
		var style: Array = seg["style"]
		var f: Font = text_renderer.get_font_from_style(style)
		for s in style:
			if s.get("type", "") == "br":
				pos.x = 10
				pos.y += document.font_size
		for i in text.length():
			if total == index:
				found = true
				break
			var char_code: int = text.unicode_at(i)
			pos.x += f.get_char_size(char_code, document.font_size).x
			total += 1
		if found:
			break
	return pos

func get_cursor_index_vertical(direction: int) -> int:
	var pos: Vector2 = _get_pos_at_index(document.cursor_index)
	print(pos)
	pos.y += direction * document.font_size
	print(pos)
	return _get_cursor_index_at_pos(pos)

	
func _insert_text_with_style(new_text: String, new_style: Array) -> void:
	var new_segments: Array = []
	var total: int = 0
	var inserted: bool = false
	for seg in document.segments:
		var text: String = seg["text"]
		if not inserted and document.cursor_index <= total + text.length():
			var local_index = document.cursor_index - total
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

func _delete_selection(from: int, to: int) -> String:
	var result: String = ""
	if from > to:
		var tmp: int = from
		from = to
		to = tmp
	var total: int = 0
	for seg in document.segments:
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

func styles_equal(style_a: Array, style_b: Array):
	for s in style_a:
		if not style_b.has(s):
			return false
	return true

func update():
	document.segments = merge_adjacent_segments(clean_empty_segments(document.segments))
	text_renderer.queue_redraw()
