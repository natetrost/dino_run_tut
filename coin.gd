extends Node

signal coin_collected(coin_obj)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.body_entered.connect(hit_coin) # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func hit_coin(body):
	if body.name == "Dino":
		coin_collected.emit(self)
