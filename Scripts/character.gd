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

var collected_keys: Array[String] = []

signal player_died

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
@export var weapon_orbit_radius: float = 10.0
@export var current_weapon_name: StringName = &"shotgun"

# --- Weapon System ---
var weapon_manager

func _ready():
	add_to_group("player")
	StatsManager.stats_updated.connect(update_stats_from_manager)
	update_stats_from_manager()
	current_health = max_health
	
	# Initialize weapon manager
	weapon_manager = preload("res://Scripts/WeaponManager.gd").instance
	if not weapon_manager:
		var weapon_manager_class = preload("res://Scripts/WeaponManager.gd")
		weapon_manager = weapon_manager_class.new()
		get_tree().root.add_child(weapon_manager)
	
	# Connect weapon manager signals
	weapon_manager.weapon_switched.connect(_on_weapon_switched)
	
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

func _physics_process(_delta: float):
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
		player_died.emit()
		queue_free()
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

# --- Weapon & Attack Logic ---
func switch_weapon(weapon_name: StringName):
	print("switch_weapon() called with: ", weapon_name)
	
	if not weapon_manager:
		print("ERROR: Weapon manager not initialized")
		return
	
	# Use weapon manager to switch weapon
	if weapon_manager.switch_weapon(weapon_name):
		current_weapon_name = weapon_name
		_update_weapon_visual()
	else:
		print("Failed to switch weapon: ", weapon_name)

func _on_weapon_switched(weapon_name: StringName, _weapon_data: Dictionary):
	print("Weapon switched signal received: ", weapon_name)
	current_weapon_name = weapon_name
	_update_weapon_visual()

func _update_weapon_visual():
	# Remove old weapon node
	if is_instance_valid(current_weapon_node): 
		print("Removing old weapon node")
		current_weapon_node.queue_free()
	
	# Safety check for weapon_scene
	if not weapon_scene:
		print("ERROR: weapon_scene is null! Please assign a weapon scene in the inspector.")
		# Create a simple fallback weapon node for testing
		current_weapon_node = Node2D.new()
		current_weapon_node.name = "FallbackWeapon"
		var fallback_weapon_data = weapon_manager.get_current_weapon()
		
		# Use set_meta() to store weapon data on a basic Node2D
		current_weapon_node.set_meta("weapon_data", fallback_weapon_data)
		current_weapon_node.set_meta("owner_character", self)
		
		weapon_holder.add_child(current_weapon_node)
		current_weapon_node.weapon = current_weapon_name
		current_weapon_node.set_appearance()
		print("Created fallback weapon node")
		return
	
	print("Instantiating weapon scene")
	current_weapon_node = weapon_scene.instantiate()
	if not current_weapon_node:
		print("ERROR: Failed to instantiate weapon scene")
		return
		
	var weapon_data = weapon_manager.get_current_weapon()
	current_weapon_node.owner_character = self
	current_weapon_node.weapon_data = weapon_data
	
	current_weapon_node.position.x = weapon_orbit_radius
	weapon_holder.add_child(current_weapon_node)
	current_weapon_node.weapon = current_weapon_name
	current_weapon_node.set_appearance()
	print("Successfully switched to weapon: ", current_weapon_name)
	print("Weapon data assigned: ", weapon_data)

func order_attack():
	print("order_attack() called")
	
	if not weapon_manager:
		print("ERROR: Weapon manager not initialized!")
		return
	
	# Use weapon manager to fire weapon
	var _projectiles = weapon_manager.fire_weapon(self, projectile_scene, weapon_holder)
	
	# Play weapon animation if weapon node exists
	if is_instance_valid(current_weapon_node) and current_weapon_node.has_method("play_attack_animation"):
		current_weapon_node.play_attack_animation()
	
	# Apply cooldown from stats
	var weapon_data = weapon_manager.get_current_weapon()
	var final_cooldown = weapon_data.get("cooldown", 0.2) * (current_cooldown / BASE_COOLDOWN)
	print("Setting can_attack to false, waiting for cooldown: ", final_cooldown)
	
	can_attack = false
	await get_tree().create_timer(final_cooldown).timeout
	can_attack = true
	print("Attack cooldown finished, can_attack = true")

# Weapon attack functions are now handled by WeaponManager

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



func add_key(key_id: String): # <--- هذه هي الدالة التي يجب أن تكون موجودة
	if not collected_keys.has(key_id):
		collected_keys.append(key_id)
		print("Player collected key: ", key_id)

func has_key(key_id: String) -> bool:
	return collected_keys.has(key_id)

func can_unlock_gate(required_key_id: String) -> bool:
	return has_key(required_key_id)

func _on_key_collected(key_id_value: String):
	add_key(key_id_value)
	add_key(key_id_value)
	print("Player now has keys: ", collected_keys)
