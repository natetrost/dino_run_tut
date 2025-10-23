extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_node("JumpButton").pressed.connect(jump_button)
	get_node("DuckButton").pressed.connect(duck_button)
	get_node("SlowButton").pressed.connect(slow_button)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func jump_button():
	Input.action_press("ui_accept")

func duck_button():
	Input.action_press("ui_down")

func slow_button():
	Input.action_press("ui_left")
