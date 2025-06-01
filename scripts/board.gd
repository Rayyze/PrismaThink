extends Node2D

@onready var background_material: ShaderMaterial = $CanvasLayer/Background.material

var pan_offset := Vector2.ZERO
var zoom := 1.0

func _process(delta):
	update_shader_parameters()

func update_shader_parameters():
	print("offset: ")
	print(pan_offset)
	print("zomm: ")
	print(zoom)
	var shader_offset = -pan_offset * zoom
	background_material.set_shader_parameter("offset", shader_offset)
	background_material.set_shader_parameter("zoom", zoom)
	
func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		pan_offset += event.relative
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom *= 1.01
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom /= 1.01
