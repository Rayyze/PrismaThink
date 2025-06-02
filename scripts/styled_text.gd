extends Resource
class_name StyledText

var segments: Array = []

func _init() -> void:
	segments = []

func add_segment(text: String, style: Array = []) -> void:
	segments.append({"text": text, "style": style})

func insert_at(index: int, text: String, style: Array) -> void:
	segments.insert(index, { "text": text, "style": style })

func apply_style(from: int, to: int, new_style: Array) -> void:
	var new_segments: Array = []
	var cursor: int = 0
	
	for seg in segments:
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
	segments = merge_adjacent_segments(new_segments)

func add_tag_to_style(old_style: Array, new_tag: Dictionary) -> Array:
	var style = old_style.duplicate()
	var replaced = false
	for tag in style:
		if tag["name"] == new_tag["name"]:
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
		if last["style"] == current["style"]:
			last["text"] += current["text"]
			result[-1] = last
		else:
			result.append(current)
	return result

func styles_equal(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for tag in a:
		if not b.has(tag):
			return false
	return true

func to_bbcode() -> String:
	var result = ""
	for seg in segments:
		result += segment_to_bbcode(seg)
	return result

func segment_to_bbcode(segment: Dictionary) -> String:
	var opening = ""
	var closing = ""

	for tag in segment["style"]:
		if tag.has("value"):
			opening += "[%s=%s]" % [tag["name"], tag["value"]]
		else:
			opening += "[%s]" % tag["name"]

		if not tag["name"] in ["br", "hr"]:
			closing = "[/%s]" % tag["name"] + closing

	return opening + segment["text"] + closing
