extends Node

#preload obstacles
var stump_scene = preload("res://scenes/stump.tscn")
var rock_scene = preload("res://scenes/rock.tscn")
var barrel_scene = preload("res://scenes/barrel.tscn")
var bird_scene = preload("res://scenes/bird.tscn")
var ledge48_scene = preload("res://scenes/ledge48.tscn")
var ledge96_scene = preload("res://scenes/ledge96.tscn")
var coin_scene = preload("res://scenes//coin.tscn")
var obstacle_types := [stump_scene, rock_scene, barrel_scene]
var ledge_types := [ledge48_scene, ledge96_scene]
var obstacles : Array
var ledges : Array
var coins : Array
var bird_heights := [200, 390]
var ledge_heights := [260, 300]

#game variables
const DINO_START_POS := Vector2i(150, 485)
const CAM_START_POS := Vector2i(576, 324)
var difficulty
const MAX_DIFFICULTY : int = 2
var score : int
const SCORE_MODIFIER : int = 10
var high_score : int
var speed : float
var slow_modifier : float
var slow_remaining : float
var slow_last_delta : float
const SLOW_MOD_START = 0.2
const SLOW_MOD_TIME = 0.6
const SLOW_COOLDOWN = 2.0
const START_SPEED : float = 10.0
const MAX_SPEED : int = 25
const SPEED_MODIFIER : int = 5000
const COIN_BONUS : int = 10
var screen_size : Vector2i
var ground_height : int
var game_running : bool
var last_obs
var last_ledge

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_window().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	$GameOver.get_node("Button").pressed.connect(new_game)
	new_game()

func new_game():
	#reset variables
	slow_modifier = 1.0
	slow_last_delta = SLOW_COOLDOWN
	score = 0
	show_score()
	game_running = false
	$Dino.game_active = false
	get_tree().paused = false
	difficulty = 0
	
	#delete all obstacles
	for obs in obstacles:
		obs.queue_free()
	obstacles.clear()

	#delete all ledges
	for ledge in ledges:
		ledge.queue_free()
	ledges.clear()
	
	#delete all coins
	for coin in coins:
		coin.queue_free()
	coins.clear()
	
	#reset the nodes
	$Dino.position = DINO_START_POS
	$Dino.velocity = Vector2i(0, 0)
	$Camera2D.position = CAM_START_POS
	$Ground.position = Vector2i(0, 0)
	
	#reset hud and game over screen
	$HUD.get_node("StartLabel").show()
	$GameOver.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if game_running:
		if Input.is_action_pressed("ui_left") and slow_last_delta > SLOW_COOLDOWN:
			Input.action_release("ui_left")
			var dino_sprite = $Dino.get_node("AnimatedSprite2D")	
			if dino_sprite.animation == "run":
				slow_modifier = SLOW_MOD_START
				slow_remaining = SLOW_MOD_TIME
				slow_last_delta = 0.0
				$HUD.get_node("SlowButton").disabled = true
		else:
			var slow_button = $HUD.get_node("SlowButton")
			slow_last_delta += delta
			if (slow_last_delta > SLOW_COOLDOWN):
				slow_button.disabled = false
				slow_button.text = "SLOW"
			else:
				slow_button.text = "%.2f" % (SLOW_COOLDOWN - slow_last_delta)
				
			
		#speed up and adjust difficulty
		speed = START_SPEED + score / SPEED_MODIFIER
		if speed > MAX_SPEED:
			speed = MAX_SPEED
		adjust_difficulty()
		
		#generate obstacles
		generate_obs()
		
		#generate ledges
		generate_ledge()
		
		#move dino and camera
		$Dino.position.x += (speed * slow_modifier)
		$Camera2D.position.x += (speed * slow_modifier)
		
		#update slow modifier
		if (slow_modifier < 1.0):
			slow_remaining -= delta
			var dino_sprite = $Dino.get_node("AnimatedSprite2D")
			if (slow_remaining < 0.0) or dino_sprite.animation != "run":
				slow_modifier = 1.0

		#update score
		score += speed
		show_score()
		
		#update ground position
		if $Camera2D.position.x - $Ground.position.x > screen_size.x * 1.5:
			$Ground.position.x += screen_size.x
			
		#remove obstacles that have gone off screen
		for obs in obstacles:
			if obs.position.x < ($Camera2D.position.x - screen_size.x):
				remove_obs(obs)
				
		#remove ledge that have gone offscreen
		for ledge in ledges:
			if ledge.position.x < ($Camera2D.position.x - screen_size.x):
				ledge.queue_free()
				ledges.erase(ledge)

		#remove coins that have gone offscreen
		for coin in coins:
			if coin.position.x < ($Camera2D.position.x - screen_size.x):
				coin.queue_free()
				coins.erase(coin)
			
	else:
		if Input.is_action_pressed("ui_accept"):
			game_running = true
			Input.action_release("ui_accept")
			$Dino.game_active = true

			$HUD.get_node("StartLabel").hide()

func generate_ledge():
	if ledges.is_empty() or last_ledge.position.x < score + randi_range(300,600):
		var ledge_type = ledge_types[randi() % ledge_types.size()]
		var ledge = ledge_type.instantiate()
		var ledge_x : int = screen_size.x + score + 100
		var ledge_y = ledge_heights[randi() % ledge_heights.size()]
		var ledge_w = ledge.get_node("Sprite2D").texture.get_width()
		ledge.position = Vector2i(ledge_x, ledge_y)
		add_child(ledge)
		ledges.append(ledge)
		last_ledge = ledge
		
		#spawn coin
		var new_coin = coin_scene.instantiate();
		var coin_w = new_coin.get_node("Sprite2D").texture.get_width()
		var coin_h = new_coin.get_node("Sprite2D").texture.get_height()
		new_coin.position = Vector2i(ledge_x + (ledge_w / 2) - coin_w, ledge_y - 48 - coin_h)
		new_coin.coin_collected.connect(hit_coin)
		add_child(new_coin)
		coins.append(new_coin)

func generate_obs():
	#generate ground obstacles
	if obstacles.is_empty() or last_obs.position.x < score + randi_range(300, 500):
		var obs_type = obstacle_types[randi() % obstacle_types.size()]
		var obs
		var max_obs = difficulty + 1
		for i in range(randi() % max_obs + 1):
			obs = obs_type.instantiate()
			var obs_height = obs.get_node("Sprite2D").texture.get_height()
			var obs_scale = obs.get_node("Sprite2D").scale
			var obs_x : int = screen_size.x + score + 100 + (i * 100)
			var obs_y : int = screen_size.y - ground_height - (obs_height * obs_scale.y / 2) + 5
			last_obs = obs
			add_obs(obs, obs_x, obs_y)
		#additionally random chance to spawn a bird
		if difficulty == MAX_DIFFICULTY:
			if (randi() % 2) == 0:
				#generate bird obstacles
				obs = bird_scene.instantiate()
				var obs_x : int = screen_size.x + score + 100
				var obs_y : int = bird_heights[randi() % bird_heights.size()]
				add_obs(obs, obs_x, obs_y)

func add_obs(obs, x, y):
	obs.position = Vector2i(x, y)
	obs.body_entered.connect(hit_obs)
	add_child(obs)
	obstacles.append(obs)

func remove_obs(obs):
	obs.queue_free()
	obstacles.erase(obs)

func hit_coin(coin_hit):
	for coin in coins:
		if coin == coin_hit:
			coin.queue_free()
			coins.erase(coin)
	score += COIN_BONUS	
	
func hit_obs(body):
	if body.name == "Dino":
		game_over()

func show_score():
	$HUD.get_node("ScoreLabel").text = "SCORE: " + str(score / SCORE_MODIFIER)

func check_high_score():
	if score > high_score:
		high_score = score
		$HUD.get_node("HighScoreLabel").text = "HIGH SCORE: " + str(high_score / SCORE_MODIFIER)

func adjust_difficulty():
	difficulty = score / SPEED_MODIFIER
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY

func game_over():
	check_high_score()
	get_tree().paused = true
	game_running = false
	$GameOver.show()
