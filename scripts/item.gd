extends Node2D

@onready var display_component = $DisplayComponent
var metadata: Dictionary
var id: String

func set_display(node: Node) -> void:
	display_component.add_child(node)
	
func to_json() -> Dictionary:
	return {
		"id": id,
		"metadata": metadata,
		"type": display_component.get_child(0).name
	}
