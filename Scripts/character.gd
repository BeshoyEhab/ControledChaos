# character.gd - Enhanced with new stats system
extends CharacterBody2D

enum Direction { DOWN, UP, RIGHT, LEFT }
var last_direction = Direction.DOWN

# --- Base Stats ---
const BASE_SPEED = 200.0
const BASE_DAMAGE = 25.0
const BASE_COOLDOWN = 0.5
const BASE_MAX_HEALTH = 100.0

var current_speed: float
var current_damage: float
var current_cooldown: float
var max_health: float
var current_health: float

# --- New enhanced stats ---
var current_projectile_count: int
var current_lifesteal: float
var current_bounce_chance: float
var current_projectile_speed: float
var invulnerability_duration: float = 0.0
var is_invulnerable: bool = false
var invulnerable_timer: float = 0.0

# --- Attack State ---
var is_charging: bool = false
var is_fully_charged: bool = false
var can_attack: bool = true
var current_weapon_node: Node2D

# --- Node References ---
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var weapon_holder: Node2D = $WeaponHolder
@onready var melee_area: Area2D = $WeaponHolder/MeleeArea
@onready var hitscan_ray: RayCast2D = $WeaponHolder/HitscanRay

# --- Visual feedback for invulnerability ---
var invuln_blink_timer: float = 0.0
const INVULN_BLINK_SPEED: float = 0.1

# --- Exported Variables ---
@export_group("Weapons")
@export var projectile_scene: PackedScene
@export var weapon_scene: PackedScene
@export var weapon_orbit_radius: float = 60.0
@export var current_weapon_name: StringName = &"shotgun"

# --- Weapon Database (same as before) ---
var WEAPONS: Dictionary = {
	&"sword": {
		"attack_mode": "melee", "texture_path": AssetPaths.WEAPON_SWORD_ICON,
		"cooldown": 0.5, "damage": 250,
		"player_attack_cooldown": 1.0,
		"player_projectile_count": 0,
		"player_projectile_speed": 1.0,
		"player_bounce_chance": 0.0,
		"player_damage": 1.0,
	},
	&"pistol": {
		"attack_mode": "projectile", "texture_path": AssetPaths.WEAPON_PISTOL_ICON,
		"projectile_texture_path": AssetPaths.PROJECTILE_BULLET, "collision_behavior": "disappear",
		"rotate_with_velocity": true, "cooldown": 0.3, "damage": 300, "speed": 800,
		"player_attack_cooldown": 1.0,
		"player_projectile_count": 0,
		"player_projectile_speed": 1.0,
		"player_bounce_chance": 0.0,
		"player_damage": 1.0,
	},
	&"shotgun": {
		"attack_mode": "projectile", "texture_path": AssetPaths.WEAPON_SHOTGUN_ICON,
		"projectile_texture_path": AssetPaths.PROJECTILE_PELLET, "collision_behavior": "penetrate",
		"rotate_with_velocity": false, "cooldown": 1.0, "damage": 150, "speed": 400,
		"spread_angle": 4.3, "burst_count": 8, "burst_delay": 0.0, "max_range": 50,
		"scale": 5.0, "max_penetrations": 10,
		"player_attack_cooldown": 1.0,
		"player_projectile_count": 0,
		"player_projectile_speed": 1.0,
		"player_bounce_chance": 0.0,
		"player_damage": 1.0,
	},
	&"machine_gun": {
		"attack_mode": "projectile", "texture_path": AssetPaths.WEAPON_MACHINE_GUN_ICON,
		"projectile_texture_path": AssetPaths.PROJECTILE_BULLET, "collision_behavior": "disappear",
		"rotate_with_velocity": true, "cooldown": 0.05, "damage": 50, "speed": 1200,
		"burst_count": 1, "burst_delay": 0.08,
		"player_attack_cooldown": 1.0,
		"player_projectile_count": 0,
		"player_projectile_speed": 1.0,
		"player_bounce_chance": 0.0,
		"player_damage": 1.0,
	},
	&"fire_magic": {
		"attack_mode": "projectile", "texture_path": AssetPaths.WEAPON_FIRE_MAGIC_ICON,
		"projectile_texture_path": AssetPaths.PROJECTILE_FIREBALL, "collision_behavior": "disappear",
		"rotate_with_velocity": true, "cooldown": 0.5, "damage": 300, "speed": 600,
		"player_attack_cooldown": 1.0,
		"player_projectile_count": 0,
		"player_projectile_speed": 1.0,
		"player_bounce_chance": 0.0,
		"player_damage": 1.0,
	},
}

func _ready():
	add_to_group("player")
	StatsManager.stats_updated.connect(update_stats_from_manager)
	update_stats_from_manager()
	current_health = max_health
	
	# Debug: Print exported scene assignments
	print("=== Character Scene Setup ===")
	print("projectile_scene: ", projectile_scene)
	print("weapon_scene: ", weapon_scene)
	if projectile_scene:
		print("projectile_scene path: ", projectile_scene.resource_path)
	if weapon_scene:
		print("weapon_scene path: ", weapon_scene.resource_path)
	print("=============================")
	
	switch_weapon(current_weapon_name)

func _process(delta: float):
	handle_input()
	handle_weapon_rotation()
	handle_invulnerability(delta)

func _physics_process(delta: float):
	handle_movement()

# --- Enhanced Stats Update ---
func update_stats_from_manager():
	current_speed = StatsManager.get_final_value(BASE_SPEED, StatsManager.stats.player_speed)
	current_damage = StatsManager.get_final_value(BASE_DAMAGE, StatsManager.stats.player_damage)
	current_cooldown = StatsManager.get_final_value(BASE_COOLDOWN, StatsManager.stats.player_cooldown, true)
	
	# NEW: Get additional stats from StatsManager
	current_projectile_count = int(StatsManager.get_raw_stat("player_projectile_count"))
	current_lifesteal = StatsManager.get_raw_stat("player_lifesteal")
	current_bounce_chance = StatsManager.get_raw_stat("player_bounce_chance")
	current_projectile_speed = StatsManager.get_raw_stat("player_projectile_speed")
	
	# Handle max health upgrades
	var old_max_health = max_health
	var base_max_health = StatsManager.get_raw_stat("player_max_health")
	if base_max_health > 0:
		max_health = base_max_health
	else:
		max_health = BASE_MAX_HEALTH
	
	# Scale current health proportionally if max health changed
	if old_max_health > 0 and old_max_health != max_health:
		var health_ratio = current_health / old_max_health
		current_health = max_health * health_ratio
	elif old_max_health == 0:
		current_health = max_health
	
	# Handle invulnerability duration upgrade
	if StatsManager.stats.has("invulnerability_duration"):
		invulnerability_duration = StatsManager.get_raw_stat("invulnerability_duration")
	
	# Apply time scale if it exists
	if StatsManager.stats.has("time_scale"):
		var time_scale = StatsManager.get_raw_stat("time_scale")
		Engine.time_scale = time_scale
	
	StatsManager.player_health_updated.emit(current_health, max_health)

# --- Enhanced Damage System with Invulnerability ---
func take_damage(amount: float):
	if is_invulnerable:
		return  # No damage while invulnerable
	
	current_health -= amount
	StatsManager.player_health_updated.emit(current_health, max_health)
	
	# Trigger invulnerability if we have the upgrade
	if invulnerability_duration > 0:
		start_invulnerability()
	
	if current_health <= 0:
		die()

func start_invulnerability():
	is_invulnerable = true
	invulnerable_timer = invulnerability_duration
	print("Player is now invulnerable for ", invulnerability_duration, " seconds")

func handle_invulnerability(delta: float):
	if not is_invulnerable:
		return
	
	# Count down invulnerability timer
	invulnerable_timer -= delta
	if invulnerable_timer <= 0:
		is_invulnerable = false
		anim_sprite.modulate.a = 1.0  # Reset transparency
		print("Invulnerability ended")
		return
	
	# Visual feedback: blink effect
	invuln_blink_timer += delta
	if invuln_blink_timer >= INVULN_BLINK_SPEED:
		invuln_blink_timer = 0.0
		anim_sprite.modulate.a = 0.5 if anim_sprite.modulate.a == 1.0 else 1.0

func heal(amount: float):
	current_health = min(current_health + amount, max_health)
	StatsManager.player_health_updated.emit(current_health, max_health)

# --- Enhanced Enemy Kill Handler ---
func on_enemy_killed():
	if current_lifesteal > 0:
		var heal_amount = max_health * current_lifesteal
		heal(heal_amount)
		print("Healed for ", heal_amount, " HP from lifesteal")

func die():
	print("Player died!")
	get_tree().reload_current_scene()

# --- Input, Movement, Weapon Rotation (same as before) ---
func handle_input():
	# Debug: Print attack input
	if Input.is_action_pressed("attack"):
		print("Attack input detected! can_attack: ", can_attack)
	
	if not can_attack: 
		if Input.is_action_pressed("attack"):
			print("Cannot attack - can_attack is false")
		return
		
	if Input.is_action_pressed("attack"): 
		print("Calling order_attack()")
		order_attack()
		
	if Input.is_action_just_pressed("switch_weapon"): 
		switch_weapon(WEAPONS.keys().pick_random())

func handle_movement():
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_direction * current_speed
	move_and_slide()
	update_animation(input_direction)

func handle_weapon_rotation():
	if not is_instance_valid(current_weapon_node): return
	var mouse_direction = get_global_mouse_position() - global_position
	weapon_holder.rotation = mouse_direction.angle()
	var angle_deg = rad_to_deg(weapon_holder.rotation)
	current_weapon_node.scale.y = -1 if angle_deg > 90 or angle_deg < -90 else 1

# --- Weapon & Attack Logic (same switching logic) ---
func switch_weapon(weapon_name: StringName):
	print("switch_weapon() called with: ", weapon_name)
	
	if not WEAPONS.has(weapon_name): 
		print("Warning: Weapon '", weapon_name, "' not found in WEAPONS database")
		return
		
	if is_instance_valid(current_weapon_node): 
		print("Removing old weapon node")
		current_weapon_node.queue_free()
	
	# Safety check for weapon_scene
	if not weapon_scene:
		print("ERROR: weapon_scene is null! Please assign a weapon scene in the inspector.")
		# Create a simple fallback weapon node for testing
		current_weapon_node = Node2D.new()
		current_weapon_node.name = "FallbackWeapon"
		var weapon_data = WEAPONS[weapon_name]
		
		# Use set_meta() to store weapon data on a basic Node2D
		current_weapon_node.set_meta("weapon_data", weapon_data)
		current_weapon_node.set_meta("owner_character", self)
		
		weapon_holder.add_child(current_weapon_node)
		current_weapon_name = weapon_name
		print("Created fallback weapon node")
		return
	
	print("Instantiating weapon scene")
	current_weapon_node = weapon_scene.instantiate()
	if not current_weapon_node:
		print("ERROR: Failed to instantiate weapon scene")
		return
		
	var weapon_data = WEAPONS[weapon_name]
	current_weapon_node.owner_character = self
	current_weapon_node.weapon_data = weapon_data
	
	# Safe weapon texture loading - use the weapon's set_appearance method if available
	if current_weapon_node.has_method("set_appearance"):
		current_weapon_node.set_appearance(weapon_data.get("texture_path", ""))
	else:
		_create_fallback_weapon_visual(current_weapon_node, weapon_data.get("texture_path", ""))
	
	current_weapon_node.position.x = weapon_orbit_radius
	weapon_holder.add_child(current_weapon_node)
	current_weapon_name = weapon_name
	print("Successfully switched to weapon: ", weapon_name)
	print("Weapon data assigned: ", weapon_data)

func order_attack():
	print("order_attack() called")
	
	if not is_instance_valid(current_weapon_node): 
		print("ERROR: current_weapon_node is not valid!")
		return
	
	# Check if weapon has the order_attack method (proper weapon script)
	if current_weapon_node.has_method("order_attack"):
		print("Using weapon's order_attack method")
		current_weapon_node.order_attack()
	else:
		print("Weapon doesn't have order_attack method, using fallback")
		# Fallback for basic Node2D weapons
		var weapon_data = null
		if current_weapon_node.has_meta("weapon_data"):
			weapon_data = current_weapon_node.get_meta("weapon_data")
		
		if not weapon_data:
			print("ERROR: weapon_data is null!")
			return
			
		if not weapon_data.has("damage"): 
			print("ERROR: weapon_data has no damage property!")
			return
		
		print("Fallback weapon data: ", weapon_data)
		print("Attack mode: ", weapon_data.get("attack_mode", "unknown"))
		
		# Handle burst fire for projectile weapons
		if weapon_data.attack_mode == "projectile" or weapon_data.attack_mode == "lobbed":
			print("Executing projectile attack")
			var burst_count = weapon_data.get("burst_count", 1)
			var burst_delay = weapon_data.get("burst_delay", 0.0)
			for i in range(burst_count):
				execute_projectile_attack(weapon_data)
				if burst_delay > 0 and i < burst_count - 1:
					await get_tree().create_timer(burst_delay).timeout
		else:
			print("Executing other attack type: ", weapon_data.attack_mode)
			match weapon_data.attack_mode:
				"melee": execute_melee_attack(weapon_data)
				"hitscan": execute_hitscan_attack(weapon_data)
	
	# Apply cooldown from stats
	var weapon_data = _get_current_weapon_data()
	var final_cooldown = weapon_data.get("cooldown", 0.2) * (current_cooldown / BASE_COOLDOWN)
	print("Setting can_attack to false, waiting for cooldown: ", final_cooldown)
	
	can_attack = false
	await get_tree().create_timer(final_cooldown).timeout
	can_attack = true
	print("Attack cooldown finished, can_attack = true")

# Helper function to get weapon data from current weapon
func _get_current_weapon_data() -> Dictionary:
	if not is_instance_valid(current_weapon_node):
		return {}
	
	# Check if it's a proper weapon with weapon_data property
	if current_weapon_node.has_method("get") and "weapon_data" in current_weapon_node:
		return current_weapon_node.weapon_data
	# Check if it's a fallback weapon with meta data
	elif current_weapon_node.has_meta("weapon_data"):
		return current_weapon_node.get_meta("weapon_data")
	
	return {}

# --- Enhanced Projectile Attack ---
func execute_projectile_attack(data: Dictionary):
	if projectile_scene == null: 
		print("ERROR: projectile_scene is null! Please assign a projectile scene in the inspector.")
		return
		
	var base_damage = data["damage"]
	var base_speed = data["speed"]
	var scale = data.get("scale", 1.0)
	var spread_angle_deg = data.get("spread_angle", 0)

	# Use enhanced stats
	var final_damage = base_damage * (current_damage / BASE_DAMAGE)
	var final_speed = base_speed * current_projectile_speed
	var total_projectiles = 1 + current_projectile_count

	var total_spread_angle = spread_angle_deg * (total_projectiles - 1)
	var start_angle = weapon_holder.rotation - deg_to_rad(total_spread_angle / 2.0)
	var angle_step = deg_to_rad(spread_angle_deg) if total_projectiles > 1 else 0
	
	for j in range(total_projectiles):
		var p = projectile_scene.instantiate() as CharacterBody2D
		if not p:
			print("ERROR: Failed to instantiate projectile")
			continue
		
		p.damage = final_damage
		p.gravity = data.get("gravity", 0)
		p.rotate_with_velocity = data.get("rotate_with_velocity", true)
		p.collision_behavior = data.get("collision_behavior", "disappear")
		
		# Apply bounce chance
		if randf() < current_bounce_chance:
			p.collision_behavior = "bounce"
			p.bounces_left = 1
		
		# Safe texture loading with fallback
		if data.has("projectile_texture_path"):
			if p.has_method("set_texture"):
				var texture_resource = load(data["projectile_texture_path"])
				if texture_resource != null:
					p.set_texture(data["projectile_texture_path"])
				else:
					print("Warning: Could not load projectile texture: ", data["projectile_texture_path"])
					_create_fallback_projectile_visual(p)
			else:
				_create_fallback_projectile_visual(p)
		else:
			_create_fallback_projectile_visual(p)
		
		var current_angle = start_angle + (angle_step * j)
		
		p.initial_velocity = Vector2.RIGHT.rotated(current_angle) * final_speed
		p.scale = Vector2.ONE * scale
		p.global_position = weapon_holder.global_position
		
		# Add to player_projectiles group for friendly fire prevention
		p.add_to_group("player_projectiles")
		p.set_collision_layer_value(6, true)
		p.set_collision_layer_value(5, false)
		p.set_collision_mask_value(2, true)
		p.set_collision_mask_value(1, false)
		get_tree().get_root().add_child(p)

# --- Enhanced Melee Attack ---
func execute_melee_attack(data: Dictionary):
	var final_damage = data["damage"] * (current_damage / BASE_DAMAGE)
	melee_area.monitoring = true
	for body in melee_area.get_overlapping_bodies():
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(final_damage)
	await get_tree().create_timer(0.1).timeout
	melee_area.monitoring = false

# --- Enhanced Hitscan Attack ---
func execute_hitscan_attack(data: Dictionary):
	hitscan_ray.force_raycast_update()
	if hitscan_ray.is_colliding():
		var collider = hitscan_ray.get_collider()
		if collider.is_in_group("enemies") and collider.has_method("take_damage"):
			var final_damage = data["damage"] * (current_damage / BASE_DAMAGE)
			collider.take_damage(final_damage)

func _on_charge_timer_timeout():
	if is_charging: is_fully_charged = true

func update_animation(direction: Vector2) -> void:
	if not anim_sprite: return

	if direction != Vector2.ZERO:
		if direction.x > 0:
			anim_sprite.flip_h = false
			anim_sprite.play("Walk_Right")
			last_direction = Direction.RIGHT
		elif direction.x < 0:
			anim_sprite.flip_h = true
			anim_sprite.play("Walk_Right")
			last_direction = Direction.LEFT
		elif direction.y > 0:
			anim_sprite.play("Walk_Down")
			last_direction = Direction.DOWN
		elif direction.y < 0:
			anim_sprite.play("Walk_Up")
			last_direction = Direction.UP
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
				anim_sprite.play("Idle_Right")

# --- Helper function for safe texture loading ---
func _create_fallback_projectile_visual(projectile: Node):
	"""Create a simple colored rectangle if projectile texture fails to load."""
	if not projectile.has_node("Sprite2D"):
		return
		
	var sprite = projectile.get_node("Sprite2D")
	
	# Create a simple colored texture as fallback
	var image = Image.create(8, 8, false, Image.FORMAT_RGB8)
	image.fill(Color.YELLOW)  # Yellow projectiles for player
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	print("Created fallback projectile visual")

func _create_fallback_weapon_visual(weapon_node: Node, texture_path: String):
	"""Create a simple weapon visual if texture fails to load."""
	if not weapon_node or not weapon_node.has_method("set_appearance"):
		return
	
	# Try to load the texture safely
	var texture_resource = load(texture_path) if texture_path != "" else null
	
	if texture_resource != null:
		weapon_node.set_appearance(texture_path)
	else:
		print("Warning: Could not load weapon texture: ", texture_path)
		# Create a simple fallback weapon visual
		if weapon_node.has_node("Sprite2D"):
			var sprite = weapon_node.get_node("Sprite2D")
			var image = Image.create(16, 4, false, Image.FORMAT_RGB8)
			image.fill(Color.GRAY)  # Gray rectangle for weapon
			var fallback_texture = ImageTexture.create_from_image(image)
			sprite.texture = fallback_texture
