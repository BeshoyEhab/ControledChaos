# projectile.gd
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

func set_texture(projectile_texture: Texture2D):
	if sprite: sprite.texture = projectile_texture

func handle_collision(collision: KinematicCollision2D):
	var collider = collision.get_collider()
	if collider.is_in_group("player"): return
	if collider.is_in_group("enemies"):
		if collider.has_method("take_damage"): collider.take_damage(damage)
		queue_free()
		return
	match collision_behavior:
		"disappear": queue_free()
		"bounce":
			if bounces_left > 0:
				velocity = velocity.bounce(collision.get_normal())
				bounces_left -= 1
			else: queue_free()
		_: queue_free()
