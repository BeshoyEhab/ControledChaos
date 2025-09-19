# character.gd
extends CharacterBody2D

enum Direction { DOWN, UP, RIGHT, LEFT }
var last_direction = Direction.DOWN

# --- Base Stats ---
const BASE_SPEED = 300.0
const BASE_MAX_HEALTH = 100.0

# --- Current Stats ---
var current_speed: float
var max_health: float
var current_health: float

# --- Attack State ---
var is_charging: bool = false
var is_fully_charged: bool = false
var can_attack: bool = true
var current_weapon_node: Node2D

# --- Node References ---
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var charge_timer: Timer = $ChargeTimer
@onready var weapon_holder: Node2D = $WeaponHolder
@onready var melee_area: Area2D = $WeaponHolder/MeleeArea
@onready var hitscan_ray: RayCast2D = $WeaponHolder/HitscanRay

# --- Exported Variables ---
@export_group("Weapons")
@export var projectile_scene: PackedScene
@export var weapon_scene: PackedScene
@export var weapon_orbit_radius: float = 60.0
@export var current_weapon_name: StringName = &"sword"

# --- Weapon Database ---
var WEAPONS: Dictionary = {
	&"sword": {
		"attack_mode": "melee", "texture_path": "res://path/to/sword_icon.png",
		"cooldown": 0.5, "light_damage": 25, "heavy_damage": 60, "charge_time": 0.8
	},
	&"shotgun": {
		"attack_mode": "projectile", "texture_path": "res://path/to/shotgun_icon.png",
		"projectile_texture_path": "res://path/to/pellet.png", "collision_behavior": "disappear",
		"rotate_with_velocity": false, "cooldown": 1.0, "light_damage": 8, "light_speed": 1000,
		"spread_angle": 15,
	},
	&"machine_gun": {
		"attack_mode": "projectile", "texture_path": "res://path/to/mg_icon.png",
		"projectile_texture_path": "res://path/to/bullet.png", "collision_behavior": "disappear",
		"rotate_with_velocity": true, "cooldown": 0.8, "light_damage": 12, "light_speed": 1200,
		"burst_count": 3, "burst_delay": 0.08,
	},
}

func _ready():
	add_to_group("player")
	charge_timer.timeout.connect(_on_charge_timer_timeout)
	StatsManager.stats_updated.connect(update_stats_from_manager)
	update_stats_from_manager()
	current_health = max_health
	switch_weapon(current_weapon_name)

func _process(delta: float):
	handle_input()
	handle_weapon_rotation()

func _physics_process(delta: float):
	handle_movement()

# --- Stats and Health ---
func update_stats_from_manager():
	current_speed = BASE_SPEED * StatsManager.get_stat("player_speed")
	var old_max_health = max_health
	max_health = BASE_MAX_HEALTH * StatsManager.get_stat("player_max_health")
	if old_max_health > 0:
		current_health = max_health * (current_health / old_max_health)
	else:
		current_health = max_health
	StatsManager.player_health_updated.emit(current_health, max_health)

func take_damage(amount: float):
	current_health -= amount
	StatsManager.player_health_updated.emit(current_health, max_health)
	if current_health <= 0:
		get_tree().reload_current_scene()

func heal(amount: float):
	current_health = min(current_health + amount, max_health)
	StatsManager.player_health_updated.emit(current_health, max_health)

func on_enemy_killed():
	var lifesteal_percent = StatsManager.get_raw_stat("player_lifesteal")
	if lifesteal_percent > 0:
		heal(max_health * lifesteal_percent)

# --- Input, Movement, Weapon Rotation ---
func handle_input():
	if not can_attack: return
	if Input.is_action_just_pressed("light_attack"): order_attack("light")
	if Input.is_action_just_pressed("heavy_attack"): start_charge()
	if Input.is_action_just_released("heavy_attack"): release_charge()
	if Input.is_action_just_pressed("switch_weapon"): switch_weapon(WEAPONS.keys().pick_random())

func handle_movement():
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_direction * current_speed
	move_and_slide()
	update_animation(input_direction) # Add your animation logic here

func handle_weapon_rotation():
	if not is_instance_valid(current_weapon_node): return
	var mouse_direction = get_global_mouse_position() - global_position
	weapon_holder.rotation = mouse_direction.angle()
	var angle_deg = rad_to_deg(weapon_holder.rotation)
	current_weapon_node.scale.y = -1 if angle_deg > 90 or angle_deg < -90 else 1

# --- Weapon & Attack Logic ---
func switch_weapon(weapon_name: StringName):
	if not WEAPONS.has(weapon_name): return
	if is_instance_valid(current_weapon_node): current_weapon_node.queue_free()
	current_weapon_node = weapon_scene.instantiate()
	var weapon_data = WEAPONS[weapon_name]
	current_weapon_node.owner_character = self
	current_weapon_node.weapon_data = weapon_data
	var weapon_texture = load(weapon_data["texture_path"])
	current_weapon_node.set_appearance(weapon_texture)
	current_weapon_node.position.x = weapon_orbit_radius
	weapon_holder.add_child(current_weapon_node)
	current_weapon_name = weapon_name

func order_attack(attack_type: String):
	if not is_instance_valid(current_weapon_node): return
	var weapon_data = current_weapon_node.weapon_data
	if not weapon_data.has(attack_type + "_damage"): return
	current_weapon_node.order_attack(attack_type)
	var cooldown_multiplier = StatsManager.get_stat("player_attack_cooldown")
	var final_cooldown = weapon_data.get("cooldown", 0.2) * cooldown_multiplier
	can_attack = false
	await get_tree().create_timer(final_cooldown).timeout
	can_attack = true

func execute_projectile_attack(data: Dictionary, type: String):
	if projectile_scene == null: return
	var base_damage = data[type + "_damage"]
	var speed = data[type + "_speed"]
	var scale = data.get(type + "_scale", 1.0)
	var burst_count = data.get("burst_count", 1)
	var burst_delay = data.get("burst_delay", 0)
	var projectile_count = StatsManager.get_raw_stat("player_projectile_count")
	var spread_angle_deg = data.get("spread_angle", 0)

	for i in range(burst_count):
		var total_spread_angle = spread_angle_deg * (projectile_count - 1)
		var start_angle = weapon_holder.rotation - deg_to_rad(total_spread_angle / 2.0)
		var angle_step = deg_to_rad(spread_angle_deg) if projectile_count > 1 else 0
		for j in range(projectile_count):
			var p = projectile_scene.instantiate() as CharacterBody2D
			var damage_multiplier = StatsManager.get_stat("player_" + type + "_damage")
			p.damage = base_damage * damage_multiplier
			p.gravity = data.get("gravity", 0)
			p.rotate_with_velocity = data.get("rotate_with_velocity", true)
			p.collision_behavior = data.get("collision_behavior", "disappear")
			if data.has("projectile_texture_path"):
				p.set_texture(load(data["projectile_texture_path"]))
			var current_angle = start_angle + (angle_step * j)
			var speed_multiplier = StatsManager.get_stat("player_projectile_speed")
			p.initial_velocity = Vector2.RIGHT.rotated(current_angle) * speed * speed_multiplier
			p.scale = Vector2.ONE * scale
			p.global_position = weapon_holder.global_position
			get_tree().get_root().add_child(p)
		if burst_delay > 0:
			await get_tree().create_timer(burst_delay).timeout

func execute_melee_attack(data: Dictionary, type: String):
	var damage_multiplier = StatsManager.get_stat("player_" + type + "_damage")
	var damage = data[type + "_damage"] * damage_multiplier
	melee_area.monitoring = true
	for body in melee_area.get_overlapping_bodies():
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(damage)
	await get_tree().create_timer(0.1).timeout
	melee_area.monitoring = false

func execute_hitscan_attack(data: Dictionary, type: String):
	hitscan_ray.force_raycast_update()
	if hitscan_ray.is_colliding():
		var collider = hitscan_ray.get_collider()
		if collider.is_in_group("enemies") and collider.has_method("take_damage"):
			var damage_multiplier = StatsManager.get_stat("player_" + type + "_damage")
			var damage = data[type + "_damage"] * damage_multiplier
			collider.take_damage(damage)

# --- Charging Logic ---
func start_charge():
	if not is_instance_valid(current_weapon_node): return
	var weapon_data = current_weapon_node.weapon_data
	if not weapon_data.has("heavy_damage"): return
	is_charging = true
	is_fully_charged = false
	charge_timer.start(weapon_data["charge_time"])

func release_charge():
	if not is_charging: return
	if is_fully_charged: order_attack("heavy")
	is_charging = false
	is_fully_charged = false
	charge_timer.stop()

func _on_charge_timer_timeout():
	if is_charging: is_fully_charged = true

# character.gd (add this function anywhere in the script)

func update_animation(direction: Vector2) -> void:
	# Make sure the AnimatedSprite2D node exists
	if not anim_sprite: return

	# --- Handle Walking Animation ---
	if direction != Vector2.ZERO:
		# Prioritize horizontal movement for animation
		if direction.x > 0:
			anim_sprite.flip_h = false
			anim_sprite.play("Walk_Right")
			last_direction = Direction.RIGHT
		elif direction.x < 0:
			anim_sprite.flip_h = true
			anim_sprite.play("Walk_Right") # Use the same animation, just flipped
			last_direction = Direction.LEFT
		elif direction.y > 0:
			anim_sprite.play("Walk_Down")
			last_direction = Direction.DOWN
		elif direction.y < 0:
			anim_sprite.play("Walk_Up")
			last_direction = Direction.UP
	
	# --- Handle Idle Animation ---
	else:
		match last_direction:
			Direction.DOWN:
				anim_sprite.play("Idle_Down")
			Direction.UP:
				anim_sprite.play("Idle_Up")
			Direction.RIGHT:
				anim_sprite.flip_h = false
				anim_sprite.play("Idle_Right")
			Direction.LEFT:
				anim_sprite.flip_h = true
				anim_sprite.play("Idle_Right") # Use the same animation, just flipped
