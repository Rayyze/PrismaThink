extends ColorRect

signal parent_resized

var dragging: bool = false;
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		dragging = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging = false
	elif event is InputEventMouseMotion and dragging:
		var parent = get_parent()
		var new_size = parent.size + event.relative
		parent.size = new_size.clamp(Vector2(10, 10), new_size)
		emit_signal("parent_resized")
