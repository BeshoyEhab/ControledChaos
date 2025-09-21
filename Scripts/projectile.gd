# projectile.gd - Enhanced projectile script
extends CharacterBody2D

var damage: float = 10.0
var initial_velocity: Vector2 = Vector2.ZERO
var gravity: float = 0.0
var rotate_with_velocity: bool = true
var collision_behavior: String = "disappear"
var bounces_left: int = 1
var max_lifetime: float = 5.0  # Auto-destroy after 5 seconds
var max_range: float = 0.0  # 0 means no range limit
var travel_distance: float = 0.0  # Track how far projectile has traveled
var start_position: Vector2
var max_penetrations: int = 0  # How many enemies can this projectile hit
var enemies_hit: int = 0  # Counter for enemies hit
var hit_enemies: Array = []  # Track which enemies we've already hit
var type: String

@onready var anim_player: AnimatedSprite2D = %forPlayer
@onready var anim_enemy: AnimatedSprite2D = %forEnemy
@onready var timer: Timer = $Timer
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready():
	print("Projectile created - Damage: ", damage, " Velocity: ", initial_velocity, " Max penetrations: ", max_penetrations)
	velocity = initial_velocity
	start_position = global_position
	
	# Setup auto-destruction timer
	if timer:
		timer.wait_time = max_lifetime
		timer.timeout.connect(queue_free)
		timer.start()
	else:
		print("Warning: Timer node not found in projectile scene")
		# Create a fallback timer
		var fallback_timer = Timer.new()
		fallback_timer.wait_time = max_lifetime
		fallback_timer.one_shot = true
		fallback_timer.timeout.connect(queue_free)
		add_child(fallback_timer)
		fallback_timer.start()

	if is_in_group("player_projectiles"):
		anim_player.visible = true
		anim_player.global_position = global_position
		anim_player.rotation = rotation
		anim_player.play(type)
	elif is_in_group("enemy_projectiles"):
		anim_enemy.visible = true
		anim_enemy.global_position = global_position
		anim_enemy.rotation = rotation
		anim_enemy.play(type)

func _physics_process(delta: float):
	# Apply gravity
	velocity.y += gravity * delta
	
	# Rotate with velocity if enabled
	rotation = velocity.angle()
	
	# Track travel distance for range-limited projectiles
	var old_position = global_position
	
	# Move without collision detection first
	var motion = velocity * delta
	
	# Use test_move to check for collisions without stopping
	var collision_found = false
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + motion)
	query.exclude = [self]
	query.collision_mask = collision_mask
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider
		collision_found = true
		print("Ray detected collision with: ", collider.name if collider else "unknown")
		
		# Handle the collision but don't stop movement for penetrating projectiles
		_handle_penetration_collision(collider)
	
	# Always move regardless of collision (for penetration)
	global_position += motion
	
	# Update travel distance
	travel_distance += motion.length()
	if is_in_group("player_projectiles"):
		anim_player.global_position = global_position
	elif is_in_group("enemy_projectiles"):
		anim_enemy.global_position = global_position
	
	# Check if projectile has exceeded max range
	if max_range > 0 and travel_distance >= max_range:
		print("Projectile exceeded max range (", max_range, "), destroying")
		queue_free()
		return

func _handle_penetration_collision(collider):
	"""Handle collision without stopping projectile movement"""
	
	# Simple collision logic: Only hit what we're supposed to hit
	if is_in_group("player_projectiles"):
		# Player projectiles should only damage enemies
		if not collider.is_in_group("enemies"):
			if collider.is_in_group("player"):
				print("Player projectile ignoring player (friendly fire prevention)")
			else:
				print("Player projectile hit obstacle: ", collider.name, " - stopping")
				queue_free()  # Stop for walls/obstacles
			return
	elif is_in_group("enemy_projectiles"):
		# Enemy projectiles should only damage player
		if not collider.is_in_group("player"):
			if collider.is_in_group("enemies"):
				print("Enemy projectile ignoring enemy (friendly fire prevention)")
			else:
				print("Enemy projectile hit obstacle: ", collider.name, " - stopping")
				queue_free()  # Stop for walls/obstacles
			return
	
	# If we reach here, it's a valid target
	if collider.has_method("take_damage"):
		# Check if we've already hit this target (for penetrating projectiles)
		if collider in hit_enemies:
			print("Already hit this target, ignoring")
			return
		
		print("Dealing ", damage, " damage to ", collider.name)
		collider.take_damage(damage)
		
		# Track this target as hit
		hit_enemies.append(collider)
		enemies_hit += 1
		print("Targets hit: ", enemies_hit, " / ", max_penetrations)
		
		# Handle collision behavior
		match collision_behavior:
			"disappear": 
				print("Projectile disappearing after hit")
				queue_free()
			"penetrate":
				print("Projectile penetrating through target")
				# Check if we've hit maximum targets
				if max_penetrations > 0 and enemies_hit >= max_penetrations:
					print("Max penetrations reached (", max_penetrations, "), projectile disappearing")
					queue_free()
				else:
					print("Continuing through target (", enemies_hit, " / ", max_penetrations, " hits)")
			_:
				print("Projectile disappearing after hit (default behavior)")
				queue_free()
	else:
		# Hit something that can't take damage
		print("Hit non-damageable object: ", collider.name, " - stopping projectile")
		queue_free()

func set_texture(texture_path: String):
	if texture_path != "":
		var loaded_texture = load(texture_path)
		if loaded_texture:
			print("Loaded projectile texture: ", texture_path)
		else:
			print("Warning: Could not load projectile texture: ", texture_path)
			_create_fallback_visual()
	else:
		_create_fallback_visual()

func _create_fallback_visual():
	"""Create a simple colored rectangle if texture fails to load."""
	# Create new fallback visual
	var color_rect = ColorRect.new()
	color_rect.name = "ColorRectFallback"
	
	# Different colors based on projectile group
	if is_in_group("player_projectiles"):
		color_rect.color = Color.YELLOW
	elif is_in_group("enemy_projectiles"):
		color_rect.color = Color.RED
	else:
		color_rect.color = Color.BLUE
	
	color_rect.size = Vector2(8, 8)
	color_rect.pivot_offset = color_rect.size / 2
	print("Created fallback projectile visual")

func handle_collision(collision: KinematicCollision2D):
	var collider = collision.get_collider()
	print("Projectile collision with: ", collider.name if collider else "unknown")
	
	# --- Logic to prevent friendly fire ---
	# If projectile is from player, ignore collision with player
	if is_in_group("player_projectiles") and collider.is_in_group("player"):
		print("Ignoring collision with player (friendly fire prevention)")
		return
		
	# If projectile is from enemy, ignore collision with other enemies
	if is_in_group("enemy_projectiles") and collider.is_in_group("enemies"):
		print("Ignoring collision with enemy (friendly fire prevention)")
		return
	
	# --- Damage Logic ---
	# If projectile hits something that can take damage
	if collider.has_method("take_damage"):
		# Check if we've already hit this enemy (for penetrating projectiles)
		if collider in hit_enemies:
			print("Already hit this enemy, ignoring")
			return
		
		print("Dealing ", damage, " damage to ", collider.name)
		collider.take_damage(damage)
		
		# Track this enemy as hit
		hit_enemies.append(collider)
		enemies_hit += 1
		print("Enemies hit: ", enemies_hit, " / ", max_penetrations)
		
		# Handle collision behavior after dealing damage
		match collision_behavior:
			"disappear": 
				print("Projectile disappearing after hit")
				queue_free()
			"penetrate":
				print("Projectile penetrating through enemy")
				# Check if we've hit maximum enemies
				if max_penetrations > 0 and enemies_hit >= max_penetrations:
					print("Max penetrations reached (", max_penetrations, "), projectile disappearing")
					queue_free()
				else:
					print("Continuing through enemy (", enemies_hit, " / ", max_penetrations, " hits)")
			"bounce":
				if bounces_left > 0:
					print("Projectile bouncing, bounces left: ", bounces_left - 1)
					velocity = velocity.bounce(collision.get_normal())
					bounces_left -= 1
				else:
					print("No bounces left, projectile disappearing")
					queue_free()
			_:
				print("Unknown collision behavior, projectile disappearing")
				queue_free()
	else:
		# Hit something that can't take damage (wall, obstacle, etc.)
		print("Hit obstacle: ", collider.name)
		match collision_behavior:
			"disappear": 
				print("Projectile hit wall, disappearing")
				queue_free()
			"bounce":
				if bounces_left > 0:
					velocity = velocity.bounce(collision.get_normal())
					bounces_left -= 1
					print("Bounced off obstacle")
				else: 
					queue_free()
			_: 
				queue_free()

# Optional: Add visual effects for impact
func _on_impact():
	# You can add particle effects, sound effects, etc. here
	pass
