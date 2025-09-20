extends CharacterBody2D

# --- Variables ---
var enemy_data: Dictionary
var current_speed: float
var current_health: float
var damage: float
var player: Node2D = null

# --- Nodes ---
@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_timer: Timer = $AttackTimer

# --- Behavior Variables ---
var behavior_mode: String

func _ready():
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	
	# --- Apply initial settings and texture fallback ---
	if enemy_data.has("texture") and enemy_data.texture:
		sprite.texture = enemy_data.texture
	else:
		# Fallback to a ColorRect if texture is missing
		sprite.texture = null # Clear any existing texture
		if not sprite.has_node("ColorRectFallback"):
			var color_rect = ColorRect.new()
			color_rect.name = "ColorRectFallback"
			color_rect.color = Color("red") # Default fallback color for enemies
			color_rect.size = Vector2(16, 16) # Default size, adjust as needed
			color_rect.pivot_offset = color_rect.size / 2 # Center pivot
			sprite.add_child(color_rect)

	behavior_mode = enemy_data.get("behavior", "chase") # Get behavior
	
	# Connect timer signal if enemy is ranged
	if behavior_mode == "ranged":
		attack_timer.wait_time = enemy_data.attack_cooldown
		attack_timer.timeout.connect(perform_ranged_attack)
		attack_timer.start()
		attack_timer.one_shot = false
	else:
		attack_timer.one_shot = true

	# Connect and update stats
	StatsManager.stats_updated.connect(update_stats_from_manager)
	update_stats_from_manager()
	current_health = StatsManager.get_final_value(enemy_data.base_health, StatsManager.stats.enemy_health)

func _physics_process(delta: float):
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		return

	# --- Choose behavior based on behavior_mode ---
	match behavior_mode:
		"chase":
			handle_chase_behavior()
		"ranged":
			handle_ranged_behavior()

	move_and_slide()

# --- Behavior Functions ---
func handle_chase_behavior():
	"""Simple behavior: chase the player directly."""
	var direction = (player.global_position - global_position)
	if direction.length() <= 15 and attack_timer.is_stopped():
		attack_timer.start()
		player.take_damage(damage)
	velocity = direction.normalized() * current_speed
	# Rotate sprite to face player (optional)
	sprite.rotation = direction.angle()

func handle_ranged_behavior():
	"""Complex behavior: maintain distance and shoot."""
	var direction_to_player = (player.global_position - global_position)
	var distance = direction_to_player.length()
	var preferred_distance = enemy_data.preferred_distance

	var move_direction = Vector2.ZERO

	# If player is too close, move away
	if distance < preferred_distance - 20:
		move_direction = -direction_to_player.normalized()
	# If player is too far, move closer
	elif distance > preferred_distance + 20:
		move_direction = direction_to_player.normalized()
	# If at ideal distance, stop moving (or strafe)
	else:
		move_direction = Vector2.ZERO # Stop to focus on attacking

	velocity = move_direction * current_speed
	# Rotate sprite to always face player
	sprite.rotation = direction_to_player.angle()

# --- Attack and Damage Functions ---
func perform_ranged_attack():
	"""Create and fire a projectile."""
	# Don't fire if game is paused or player is invalid
	if get_tree().paused or not is_instance_valid(player): return

	print("Mage is firing!")
	# Assume you have a projectile scene ready (can use the same as player's projectile)
	# Make sure you have an exported projectile_scene variable in the enemy script
	# or load it directly here
	var projectile_scene = load("res://Scenes/Projectile.tscn") # Replace with correct path
	var p = projectile_scene.instantiate() as CharacterBody2D
	
	# Setup projectile properties
	p.damage = damage # Damage calculated from StatsManager
	
	# Make projectile not hit other enemies
	p.add_to_group("enemy_projectiles") # We will need to modify projectile collision logic
	
	var direction = to_local(player.global_position).normalized()
	p.initial_velocity = direction * 500 # Projectile speed
	p.global_position = global_position
	
	# You can also change projectile appearance here
	# p.get_node("Sprite2D").texture = load("res://path/to/fireball.png")
	
	get_parent().add_child(p)

func take_damage(amount: float):
	current_health -= amount
	if current_health <= 0: die()

func die():
	StatsManager.add_xp(enemy_data.xp_reward)
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node and player_node.has_method("on_enemy_killed"):
		player_node.on_enemy_killed()
	queue_free()

func update_stats_from_manager():
	current_speed = StatsManager.get_final_value(enemy_data.base_speed, StatsManager.stats.enemy_speed)
	damage = StatsManager.get_final_value(enemy_data.base_damage, StatsManager.stats.enemy_damage)
