extends Node

var cursor_pos: Vector2
var font_size: int = 16
var cursor_index: int
var selection_start_index: int
var selection_end_index: int
var segments: Array = [
	{"text": "Welcome to your note.", "style": []},
	{"text": "italic", "style": [{"type": "i"}]},
	{"text": "bold", "style": [{"type": "b"}]}
]
const word_separators: Array = [" ", ".", ",", ";", ":", "/", "-", "_", "(", ")", "[", "]", "{", "}", "|", "\\", "<", ">", "=", "+"]
var edit_mode: bool = true
