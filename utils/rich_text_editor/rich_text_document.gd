extends Node

var old_cursor_pos: Vector2
var cursor_pos: Vector2
var font: Resource
var font_size: int = 16
var cursor_index: int
var selection_start_index: int
var selection_end_index: int
var segments: Array = [
	{"text": "Welcome to your note.", "style": []},
	{"text": "bold", "style": [{"type": "i"}]},
	{"text": "t", "style": []}
]
const word_separators: Array = [" ", ".", ",", ";", ":", "/", "-", "_", "(", ")", "[", "]", "{", "}", "|", "\\", "<", ">", "=", "+"]
var max_width: float = 200

func _ready() -> void:
	font = FontVariation.new()
	font.base_font = load("res://fonts/Inter-Regular.ttf")
	font.variation_embolden = 1.2
	#font = load("res://fonts/default_font.tres")

