extends Node2D

@onready var display_container = $DisplayContainer
var metadata: Dictionary
var id: String

func set_display(node: Node) -> void:
	display_container.add_child(node)
	
func to_json() -> Dictionary:
	return {
		"id": id,
		"metadata": metadata,
		"type": display_container.get_child(0).name
	}
