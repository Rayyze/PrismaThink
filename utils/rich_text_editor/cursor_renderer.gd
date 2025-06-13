extends Control

# to be synced variable
var old_cursor_pos: Vector2
var cursor_pos: Vector2
var line_height: int
# self managed variables
var cursor_visible := true
var blink_timer := 0.0

func _ready():
	set_process(true)

func _process(delta):
	blink_timer += delta
	var moved: bool = old_cursor_pos != cursor_pos
	old_cursor_pos = cursor_pos
	if blink_timer >= 0.5 or moved:
		blink_timer = 0.0
		cursor_visible = !cursor_visible or moved
		queue_redraw()

func _draw() -> void:
	if cursor_visible:
		draw_line(cursor_pos, cursor_pos + Vector2(0, line_height), Color.WHITE, 1)
