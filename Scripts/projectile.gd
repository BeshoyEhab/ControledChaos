extends CharacterBody2D

var damage: float = 10.0
var initial_velocity: Vector2 = Vector2.ZERO
var gravity: float = 0.0
var rotate_with_velocity: bool = true
var collision_behavior: String = "disappear"
var bounces_left: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var timer: Timer = $Timer

func _ready():
	velocity = initial_velocity
	timer.timeout.connect(queue_free)
	timer.start()

func _physics_process(delta: float):
	velocity.y += gravity * delta
	if rotate_with_velocity and velocity.length() > 0:
		rotation = velocity.angle()
	var collision = move_and_collide(velocity * delta)
	if collision:
		handle_collision(collision)

func set_texture(texture_path: String):
	if sprite:
		var loaded_texture = load(texture_path) if texture_path else null
		if loaded_texture:
			sprite.texture = loaded_texture
			if sprite.has_node("ColorRectFallback"): # Remove fallback if texture is loaded
				sprite.get_node("ColorRectFallback").queue_free()
		else:
			# Fallback to a ColorRect if texture is missing
			sprite.texture = null # Clear any existing texture
			if not sprite.has_node("ColorRectFallback"):
				var color_rect = ColorRect.new()
				color_rect.name = "ColorRectFallback"
				color_rect.color = Color("blue") # Default fallback color for projectiles
				color_rect.size = Vector2(16, 16) # Default size, adjust as needed
				color_rect.pivot_offset = color_rect.size / 2 # Center pivot
				sprite.add_child(color_rect)

func handle_collision(collision: KinematicCollision2D):
	var collider = collision.get_collider()

	# --- Logic to prevent friendly fire ---
	# If projectile is from player, ignore collision with player
	if is_in_group("player_projectiles") and collider.is_in_group("player"):
		return
	# If projectile is from enemy, ignore collision with other enemies
	if is_in_group("enemy_projectiles") and collider.is_in_group("enemies"):
		return
	
	# --- Damage Logic ---
	# If projectile hits something that can take damage
	if collider.has_method("take_damage"):
		collider.take_damage(damage)
		queue_free() # Delete projectile after hit
		return
	match collision_behavior:
		"disappear": queue_free()
		"bounce":
			if bounces_left > 0:
				velocity = velocity.bounce(collision.get_normal())
				bounces_left -= 1
			else: queue_free()
		_: queue_free()
