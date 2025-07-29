extends Control

@onready var rich_text_editor = load("res://utils/rich_text_editor/rich_text_editor.tscn").instantiate()

func _ready():
	add_child(rich_text_editor)
	size = Vector2(600.0, 400.0)
	rich_text_editor.size = size

func _on_resize_control_parent_resized() -> void:
	rich_text_editor.size = size
