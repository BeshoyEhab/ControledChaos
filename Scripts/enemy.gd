# enemy.gd - Enhanced with new stats system
extends CharacterBody2D

# --- Variables ---
var enemy_data: Dictionary
var base_speed: float
var base_health: float
var base_damage: float
var current_speed: float
var current_health: float
var current_damage: float
var player: Node2D = null

# --- Nodes ---
@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_timer: Timer = $AttackTimer

# --- Behavior Variables ---
var behavior_mode: String
var preferred_distance: float = 100.0

# --- Visual feedback for damage ---
var damage_flash_timer: float = 0.0
var original_modulate: Color

func _ready():
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	original_modulate = sprite.modulate
	
	# Store base stats from enemy_data
	base_speed = enemy_data.get("base_speed", 50.0)
	base_health = enemy_data.get("base_health", 100.0)
	base_damage = enemy_data.get("base_damage", 10.0)
	preferred_distance = enemy_data.get("preferred_distance", 100.0)
	
	# --- Apply initial settings and texture fallback ---
	setup_sprite_texture()
	
	behavior_mode = enemy_data.get("behavior", "chase")
	
	# Connect timer signal if enemy is ranged
	if behavior_mode == "ranged":
		attack_timer.wait_time = enemy_data.get("attack_cooldown", 2.0)
		attack_timer.timeout.connect(perform_ranged_attack)
		attack_timer.start()
		attack_timer.one_shot = false
	else:
		attack_timer.one_shot = true

	# Connect and update stats
	StatsManager.stats_updated.connect(update_stats_from_manager)
	update_stats_from_manager()

func setup_sprite_texture():
	# Safe texture loading with fallback
	if enemy_data.has("texture") and enemy_data.texture != null:
		var texture_resource = enemy_data.texture
		if texture_resource is Texture2D:
			sprite.texture = texture_resource
			return
	
	# If we get here, create a fallback visual
	_create_enemy_fallback_visual()

func _create_enemy_fallback_visual():
	"""Create a simple colored rectangle for enemy visual."""
	var image = Image.create(16, 16, false, Image.FORMAT_RGB8)
	
	# Different colors based on behavior/type
	var color = Color.RED  # Default
	match behavior_mode:
		"ranged":
			color = Color.PURPLE
		"chase":
			color = Color.RED
		"tank":
			color = Color.DARK_RED
		"fast":
			color = Color.ORANGE
		_:
			color = Color.DARK_RED
	
	image.fill(color)
	var fallback_texture = ImageTexture.create_from_image(image)
	sprite.texture = fallback_texture
	print("Created fallback enemy visual with color: ", color)

func _physics_process(delta: float):
	handle_visual_effects(delta)
	
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		return

	# Choose behavior based on behavior_mode
	match behavior_mode:
		"chase":
			handle_chase_behavior()
		"ranged":
			handle_ranged_behavior()
		"tank":
			handle_tank_behavior()
		"fast":
			handle_fast_behavior()

	move_and_slide()

# --- Enhanced Stats Update ---
func update_stats_from_manager():
	# Apply StatsManager multipliers to base stats
	current_speed = StatsManager.get_final_value(base_speed, StatsManager.stats.enemy_speed)
	current_health = StatsManager.get_final_value(base_health, StatsManager.stats.enemy_health)
	current_damage = StatsManager.get_final_value(base_damage, StatsManager.stats.enemy_damage)
	
	# Only set health on first update or if health is at max
	if current_health == base_health or not has_meta("health_initialized"):
		current_health = StatsManager.get_final_value(base_health, StatsManager.stats.enemy_health)
		set_meta("health_initialized", true)

# --- Enhanced Behavior Functions ---
func handle_chase_behavior():
	"""Aggressive behavior: chase the player directly."""
	var direction = (player.global_position - global_position)
	var distance = direction.length()
	
	# Attack when close
	if distance <= 25 and attack_timer.is_stopped():
		attack_player()
	
	velocity = direction.normalized() * current_speed
	sprite.rotation = direction.angle()

func handle_ranged_behavior():
	"""Ranged behavior: maintain distance and shoot."""
	var direction_to_player = (player.global_position - global_position)
	var distance = direction_to_player.length()
	
	var move_direction = Vector2.ZERO
	
	# Maintain preferred distance
	if distance < preferred_distance - 30:
		move_direction = -direction_to_player.normalized()  # Move away
	elif distance > preferred_distance + 50:
		move_direction = direction_to_player.normalized()   # Move closer
	else:
		# Strafe around player at preferred distance
		var perpendicular = Vector2(-direction_to_player.y, direction_to_player.x).normalized()
		move_direction = perpendicular * (1 if randf() > 0.5 else -1)
	
	velocity = move_direction * current_speed * 0.7  # Slower movement for ranged
	sprite.rotation = direction_to_player.angle()

func handle_tank_behavior():
	"""Tank behavior: slow but high health, charges at player."""
	var direction = (player.global_position - global_position)
	var distance = direction.length()
	
	# Charge attack when medium distance
	if distance <= 50 and attack_timer.is_stopped():
		attack_player()
		# Brief charge boost
		velocity = direction.normalized() * current_speed * 2.0
	else:
		velocity = direction.normalized() * current_speed * 0.6  # Normally slower
	
	sprite.rotation = direction.angle()

func handle_fast_behavior():
	"""Fast behavior: quick hit-and-run attacks."""
	var direction = (player.global_position - global_position)
	var distance = direction.length()
	
	# Quick dash attacks
	if distance <= 30 and attack_timer.is_stopped():
		attack_player()
		# Quick retreat after attack
		velocity = -direction.normalized() * current_speed * 1.5
	elif distance > 80:
		# Dash toward player when far
		velocity = direction.normalized() * current_speed * 1.3
	else:
		# Circle around player at medium distance
		var perpendicular = Vector2(-direction.y, direction.x).normalized()
		velocity = perpendicular * current_speed
	
	sprite.rotation = direction.angle()

# --- Enhanced Attack Functions ---
func attack_player():
	"""Direct melee attack on player."""
	attack_timer.start()
	
	# Check if player has invulnerability
	if player.has_method("take_damage"):
		player.take_damage(current_damage)
		print("Enemy dealt ", current_damage, " damage to player")

func perform_ranged_attack():
	"""Create and fire a projectile."""
	if get_tree().paused or not is_instance_valid(player): 
		return

	# Safe projectile scene loading
	var projectile_scene = load("res://Scenes/Projectile.tscn")
	if not projectile_scene:
		print("Warning: Enemy projectile scene not found at res://Scenes/Projectile.tscn")
		return
		
	var p = projectile_scene.instantiate() as CharacterBody2D
	if not p:
		print("Warning: Failed to instantiate enemy projectile")
		return
	
	# Setup projectile properties
	p.damage = current_damage
	
	# Make projectile hostile to player
	p.add_to_group("enemy_projectiles")
	p.set_collision_layer_value(7, true)   # Enemy projectile layer
	p.set_collision_layer_value(6, false)  # Remove player projectile layer
	p.set_collision_mask_value(1, true)    # Hit player only
	p.set_collision_mask_value(2, false)   # Don't hit enemies
	p.set_collision_mask_value(3, true)    # Hit walls/obstacles
	
	# Calculate direction and velocity
	var direction = (player.global_position - global_position).normalized()
	var projectile_speed = enemy_data.get("projectile_speed", 400.0)
	
	# Apply some predictive aiming for moving targets
	if player.velocity.length() > 0:
		var time_to_target = global_position.distance_to(player.global_position) / projectile_speed
		var predicted_pos = player.global_position + player.velocity * time_to_target
		direction = (predicted_pos - global_position).normalized()
	
	p.initial_velocity = direction * projectile_speed
	p.global_position = global_position
	
	# Safe texture loading for enemy projectiles
	_setup_enemy_projectile_visual(p)
	
	get_parent().add_child(p)
	print("Enemy fired projectile with damage: ", current_damage)

func _setup_enemy_projectile_visual(projectile: Node):
	"""Safely set up enemy projectile visual with fallback."""
	var texture_set = false
	
	# Try to set custom enemy projectile texture
	if enemy_data.has("projectile_texture"):
		var texture_path = enemy_data.projectile_texture
		var texture_resource = load(texture_path) if texture_path != "" else null
		
		if texture_resource != null and projectile.has_method("set_texture"):
			projectile.set_texture(texture_path)
			texture_set = true
		elif texture_resource != null and projectile.has_node("Sprite2D"):
			projectile.get_node("Sprite2D").texture = texture_resource
			texture_set = true
	
	# Fallback: create a simple red projectile visual
	if not texture_set and projectile.has_node("Sprite2D"):
		var sprite = projectile.get_node("Sprite2D")
		var image = Image.create(6, 6, false, Image.FORMAT_RGB8)
		image.fill(Color.RED)  # Red enemy projectiles
		var fallback_texture = ImageTexture.create_from_image(image)
		sprite.texture = fallback_texture
		print("Created fallback enemy projectile visual")

# --- Enhanced Damage and Death ---
func take_damage(amount: float):
	current_health -= amount
	
	# Visual feedback for taking damage
	sprite.modulate = Color.WHITE
	damage_flash_timer = 0.1
	
	print("Enemy took ", amount, " damage. Health: ", current_health)
	
	if current_health <= 0: 
		die()

func handle_visual_effects(delta: float):
	# Handle damage flash effect
	if damage_flash_timer > 0:
		damage_flash_timer -= delta
		if damage_flash_timer <= 0:
			sprite.modulate = original_modulate

func die():
	# Give XP based on enemy type and current difficulty
	var base_xp = enemy_data.get("xp_reward", 10)
	var difficulty_multiplier = StatsManager.stats.enemy_health  # Use enemy health as difficulty indicator
	var final_xp = int(base_xp * difficulty_multiplier)
	
	StatsManager.add_xp(final_xp)
	print("Enemy died, gave ", final_xp, " XP")
	
	# Trigger player's on_enemy_killed for lifesteal, etc.
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node and player_node.has_method("on_enemy_killed"):
		player_node.on_enemy_killed()
	
	# TODO: Add death effects, loot drops, etc.
	spawn_death_effect()
	
	queue_free()

func spawn_death_effect():
	# Safe death effect loading
	var death_particles = load("res://effects/DeathEffect.tscn")
	if death_particles:
		var effect = death_particles.instantiate()
		if effect:
			effect.global_position = global_position
			get_parent().add_child(effect)
	else:
		# Simple fallback death effect - brief color flash
		var flash_timer = Timer.new()
		flash_timer.wait_time = 0.1
		flash_timer.one_shot = true
		flash_timer.timeout.connect(func(): flash_timer.queue_free())
		get_parent().add_child(flash_timer)
		flash_timer.start()
		
		# Create a simple death particle effect
		for i in range(5):
			var particle = ColorRect.new()
			particle.color = Color.WHITE
			particle.size = Vector2(2, 2)
			particle.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
			get_parent().add_child(particle)
			
			# Animate particle
			var tween = create_tween()
			tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
			tween.parallel().tween_property(particle, "position", particle.position + Vector2(randf_range(-20, 20), randf_range(-20, 20)), 0.5)
			tween.tween_callback(particle.queue_free)

# --- Helper Functions ---
func get_distance_to_player() -> float:
	if is_instance_valid(player):
		return global_position.distance_to(player.global_position)
	return 0.0

func is_player_visible() -> bool:
	if not is_instance_valid(player):
		return false
	
	# Simple line-of-sight check using RayCast2D
	# You could add a RayCast2D node for more sophisticated visibility
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	query.exclude = [self]  # Don't hit self
	var result = space_state.intersect_ray(query)
	
	# If ray hits player directly, they're visible
	return result and result.collider == player
