extends Node

var old_cursor_pos: Vector2
var cursor_pos: Vector2
var font_size: int
var cursor_index: int
var selection_start_index: int
var selection_end_index: int
var segments: Array = [
	{"text": "Welcome to your note.", "style": []},
	{"text": "bold", "style": [{"type": "i"}]}
]