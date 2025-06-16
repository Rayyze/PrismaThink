extends Control

var cursor_visible := true
var blink_timer := 0.0
var document: Node

func _ready():
	set_process(true)
	document = get_node("../RichTextDocument")

func _process(delta):
	blink_timer += delta
	var moved: bool = document.old_cursor_pos != document.cursor_pos
	document.old_cursor_pos = document.cursor_pos
	if blink_timer >= 0.5 or moved:
		blink_timer = 0.0
		cursor_visible = !cursor_visible or moved
		queue_redraw()

func _draw() -> void:
	if cursor_visible:
		draw_line(document.cursor_pos, document.cursor_pos + Vector2(0, document.font_size), Color.WHITE, 1)
