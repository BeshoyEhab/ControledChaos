# WeaponManager.gd - Centralized weapon system
extends Node

signal weapon_switched(weapon_name: StringName, weapon_data: Dictionary)
signal weapon_fired(weapon_name: StringName, projectile_count: int)

# Singleton instance
static var instance

# Current weapon state
var current_weapon_name: StringName = &"shotgun"
var current_weapon_data: Dictionary
var current_weapon_node: Node2D

# Weapon database - Enhanced with more stats
var WEAPONS: Dictionary = {
	&"gun": {
		"attack_mode": "projectile",
		"weapon": "gun",
		"projectile": "enemy",
		"collision_behavior": "disappear",
		"rotate_with_velocity": true,
		"cooldown": 0.25,
		"damage": 300,
		"speed": 800,
		
		# Enhanced stats
		"projectile_size": 1.0,
		"projectile_lifetime": 3.0,
		"projectile_penetration": 0,
		"projectile_bounce_count": 0,
		"projectile_trail_effect": false,
		"projectile_homing": false,
		"projectile_explosive": false,
		"projectile_explosion_radius": 0.0,
		"projectile_piercing": false,
		"projectile_gravity": 0.0,
		
		# Multi-projectile settings
		"spread_angle": 0.0,
		"burst_count": 1,
		"burst_delay": 0.0,
		"max_range": 0.0,
		"scale": 1.0,
		
		# Visual and audio
		"muzzle_flash": true,
		"recoil_force": 0.0,
		"weapon_sound": "",
		"projectile_sound": "",
		
		# Weapon progression
		"rarity": "common",
		"unlock_level": 1,
		"upgrade_tier": 1
	},
	
	&"shotgun": {
		"attack_mode": "projectile",
		"weapon": "shotgun",
		"projectile": "Bullet",
		"collision_behavior": "penetrate",
		"rotate_with_velocity": false,
		"cooldown": 1.2,
		"damage": 150,
		"speed": 400,
		
		# Enhanced stats
		"projectile_size": 5.0,
		"projectile_lifetime": 2.0,
		"projectile_penetration": 10,
		"projectile_bounce_count": 0,
		"projectile_trail_effect": true,
		"projectile_homing": false,
		"projectile_explosive": false,
		"projectile_explosion_radius": 0.0,
		"projectile_piercing": true,
		"projectile_gravity": 0.0,
		
		# Multi-projectile settings
		"spread_angle": 4.3,
		"burst_count": 8,
		"burst_delay": 0.0,
		"max_range": 50.0,
		"scale": 5.0,
		
		# Visual and audio
		"muzzle_flash": true,
		"recoil_force": 50.0,
		"weapon_sound": "",
		"projectile_sound": "",
		
		# Weapon progression
		"rarity": "uncommon",
		"unlock_level": 1,
		"upgrade_tier": 1
	},
	
	&"rifle": {
		"attack_mode": "projectile",
		"weapon": "rifel",
		"projectile": "Arrow",
		"collision_behavior": "disappear",
		"rotate_with_velocity": true,
		"cooldown": 0.05,
		"damage": 10,
		"speed": 1200,
		
		# Enhanced stats
		"projectile_size": 0.8,
		"projectile_lifetime": 5.0,
		"projectile_penetration": 0,
		"projectile_bounce_count": 0,
		"projectile_trail_effect": false,
		"projectile_homing": false,
		"projectile_explosive": false,
		"projectile_explosion_radius": 0.0,
		"projectile_piercing": false,
		"projectile_gravity": 0.0,
		
		# Multi-projectile settings
		"spread_angle": 0.0,
		"burst_count": 1,
		"burst_delay": 0.08,
		"max_range": 0.0,
		"scale": 1.0,
		
		# Visual and audio
		"muzzle_flash": true,
		"recoil_force": 10.0,
		"weapon_sound": "",
		"projectile_sound": "",
		
		# Weapon progression
		"rarity": "common",
		"unlock_level": 1,
		"upgrade_tier": 1
	},
	
	&"staff": {
		"attack_mode": "projectile",
		"weapon": "staff",
		"projectile": "Magic",
		"collision_behavior": "disappear",
		"rotate_with_velocity": true,
		"cooldown": 0.5,
		"damage": 300,
		"speed": 600,
		
		# Enhanced stats
		"projectile_size": 2.0,
		"projectile_lifetime": 4.0,
		"projectile_penetration": 0,
		"projectile_bounce_count": 1,
		"projectile_trail_effect": true,
		"projectile_homing": true,
		"projectile_explosive": true,
		"projectile_explosion_radius": 30.0,
		"projectile_piercing": false,
		"projectile_gravity": 0.0,
		
		# Multi-projectile settings
		"spread_angle": 0.0,
		"burst_count": 1,
		"burst_delay": 0.0,
		"max_range": 0.0,
		"scale": 2.0,
		
		# Visual and audio
		"muzzle_flash": true,
		"recoil_force": 0.0,
		"weapon_sound": "",
		"projectile_sound": "",
		
		# Weapon progression
		"rarity": "rare",
		"unlock_level": 3,
		"upgrade_tier": 2
	},
	
	# New enhanced weapons
	&"flamethrower": {
		"attack_mode": "projectile",
		"weapon": "flamethrower",
		"projectile": "Fire",
		"collision_behavior": "disappear",
		"rotate_with_velocity": false,
		"cooldown": 0.1,
		"damage": 50,
		"speed": 300,
		
		# Enhanced stats
		"projectile_size": 3.0,
		"projectile_lifetime": 1.5,
		"projectile_penetration": 0,
		"projectile_bounce_count": 0,
		"projectile_trail_effect": true,
		"projectile_homing": false,
		"projectile_explosive": false,
		"projectile_explosion_radius": 0.0,
		"projectile_piercing": false,
		"projectile_gravity": 0.0,
		
		# Multi-projectile settings
		"spread_angle": 2.0,
		"burst_count": 5,
		"burst_delay": 0.05,
		"max_range": 40.0,
		"scale": 3.0,
		
		# Visual and audio
		"muzzle_flash": true,
		"recoil_force": 20.0,
		"weapon_sound": "",
		"projectile_sound": "",
		
		# Weapon progression
		"rarity": "epic",
		"unlock_level": 8,
		"upgrade_tier": 3
	},
	
	&"sniper": {
		"attack_mode": "hitscan",
		"weapon": "sniper",
		"projectile": "Bullet",
		"collision_behavior": "disappear",
		"rotate_with_velocity": true,
		"cooldown": 2.0,
		"damage": 1000,
		"speed": 0,
		
		# Enhanced stats
		"projectile_size": 0.0,
		"projectile_lifetime": 0.0,
		"projectile_penetration": 5,
		"projectile_bounce_count": 0,
		"projectile_trail_effect": true,
		"projectile_homing": false,
		"projectile_explosive": false,
		"projectile_explosion_radius": 0.0,
		"projectile_piercing": true,
		"projectile_gravity": 0.0,
		
		# Multi-projectile settings
		"spread_angle": 0.0,
		"burst_count": 1,
		"burst_delay": 0.0,
		"max_range": 2000.0,
		"scale": 1.0,
		
		# Visual and audio
		"muzzle_flash": true,
		"recoil_force": 100.0,
		"weapon_sound": "",
		"projectile_sound": "",
		
		# Weapon progression
		"rarity": "legendary",
		"unlock_level": 12,
		"upgrade_tier": 4
	}
}

# Weapon upgrade system
var weapon_upgrades: Dictionary = {}
var unlocked_weapons: Array[StringName] = [&"gun", &"shotgun", &"rifle", &"staff"]

func _ready():
	if instance == null:
		instance = self
		set_process_unhandled_input(true)
	else:
		queue_free()

func _unhandled_input(event):
	# Debug weapon switching with number keys
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				switch_weapon(&"gun")
			KEY_2:
				switch_weapon(&"shotgun")
			KEY_3:
				switch_weapon(&"rifle")
			KEY_4:
				switch_weapon(&"staff")
			KEY_5:
				switch_weapon(&"flamethrower")
			KEY_6:
				switch_weapon(&"sniper")

# Weapon management functions
func switch_weapon(weapon_name: StringName) -> bool:
	if not WEAPONS.has(weapon_name):
		print("Warning: Weapon '", weapon_name, "' not found")
		return false
	
	if weapon_name not in unlocked_weapons:
		print("Weapon '", weapon_name, "' is locked")
		return false
	
	current_weapon_name = weapon_name
	current_weapon_data = WEAPONS[weapon_name].duplicate(true)
	
	# Apply any upgrades
	_apply_weapon_upgrades()
	
	weapon_switched.emit(weapon_name, current_weapon_data)
	print("Switched to weapon: ", weapon_name)
	return true

func get_current_weapon() -> Dictionary:
	return current_weapon_data.duplicate(true)

func get_weapon_data(weapon_name: StringName) -> Dictionary:
	if WEAPONS.has(weapon_name):
		return WEAPONS[weapon_name].duplicate(true)
	return {}

func get_available_weapons() -> Array[StringName]:
	return unlocked_weapons

func unlock_weapon(weapon_name: StringName) -> bool:
	if WEAPONS.has(weapon_name) and weapon_name not in unlocked_weapons:
		unlocked_weapons.append(weapon_name)
		print("Unlocked weapon: ", weapon_name)
		return true
	return false

# Weapon upgrade system
func upgrade_weapon(weapon_name: StringName, upgrade_type: String, value: float) -> bool:
	if not WEAPONS.has(weapon_name):
		return false
	
	if not weapon_upgrades.has(weapon_name):
		weapon_upgrades[weapon_name] = {}
	
	if not weapon_upgrades[weapon_name].has(upgrade_type):
		weapon_upgrades[weapon_name][upgrade_type] = 0.0
	
	weapon_upgrades[weapon_name][upgrade_type] += value
	
	# If this is the current weapon, update it
	if weapon_name == current_weapon_name:
		_apply_weapon_upgrades()
	
	print("Upgraded ", weapon_name, " ", upgrade_type, " by ", value)
	return true

func _apply_weapon_upgrades():
	if not weapon_upgrades.has(current_weapon_name):
		return
	
	var upgrades = weapon_upgrades[current_weapon_name]
	
	# Apply each upgrade to the current weapon data
	for upgrade_type in upgrades:
		var upgrade_value = upgrades[upgrade_type]
		if current_weapon_data.has(upgrade_type):
			if upgrade_type in ["damage", "speed", "projectile_size", "projectile_lifetime", "projectile_penetration", "projectile_bounce_count", "projectile_explosion_radius"]:
				current_weapon_data[upgrade_type] += upgrade_value
			elif upgrade_type in ["cooldown"]:
				current_weapon_data[upgrade_type] = max(0.01, current_weapon_data[upgrade_type] - upgrade_value)

# Weapon firing system
func fire_weapon(weapon_owner: Node2D, projectile_scene: PackedScene, weapon_holder: Node2D) -> Array[Node2D]:
	if current_weapon_data.is_empty():
		return []
	
	var projectiles: Array[Node2D] = []
	var weapon_data = get_current_weapon()
	
	match weapon_data.attack_mode:
		"projectile", "lobbed":
			projectiles = await _fire_projectile_weapon(weapon_owner, projectile_scene, weapon_holder, weapon_data)
		"hitscan":
			_fire_hitscan_weapon(weapon_owner, weapon_data)
		"melee":
			_fire_melee_weapon(weapon_owner, weapon_data)
	
	weapon_fired.emit(current_weapon_name, projectiles.size())
	return projectiles

func _fire_projectile_weapon(weapon_owner: Node2D, projectile_scene: PackedScene, weapon_holder: Node2D, weapon_data: Dictionary) -> Array[Node2D]:
	var projectiles: Array[Node2D] = []
	var burst_count = weapon_data.get("burst_count", 1)
	var burst_delay = weapon_data.get("burst_delay", 0.0)
	var spread_angle = weapon_data.get("spread_angle", 0.0)
	
	for i in range(burst_count):
		var projectile_count = 1 + StatsManager.get_raw_stat("player_projectile_count")
		var total_spread_angle = spread_angle * (projectile_count - 1)
		var start_angle = weapon_holder.rotation - deg_to_rad(total_spread_angle / 2.0)
		var angle_step = deg_to_rad(spread_angle) if projectile_count > 1 else 0.0
		
		for j in range(projectile_count):
			var p = _create_projectile(weapon_owner, projectile_scene, weapon_holder, weapon_data, start_angle + (angle_step * j))
			if p:
				projectiles.append(p)
		
		if burst_delay > 0 and i < burst_count - 1:
			await get_tree().create_timer(burst_delay).timeout
	
	return projectiles

func _create_projectile(weapon_owner: Node2D, projectile_scene: PackedScene, weapon_holder: Node2D, weapon_data: Dictionary, angle: float) -> Node2D:
	if not projectile_scene:
		return null
	
	var p = projectile_scene.instantiate() as CharacterBody2D
	if not p:
		return null
	
	# Apply weapon stats to projectile
	var base_damage = weapon_data["damage"]
	var base_speed = weapon_data["speed"]
	var final_damage = base_damage * (StatsManager.get_final_value(1.0, StatsManager.stats.player_damage))
	var final_speed = base_speed * StatsManager.get_raw_stat("player_projectile_speed")
	
	p.damage = final_damage
	p.initial_velocity = Vector2.RIGHT.rotated(angle) * final_speed
	p.gravity = weapon_data.get("projectile_gravity", 0.0)
	p.rotate_with_velocity = weapon_data.get("rotate_with_velocity", true)
	p.collision_behavior = weapon_data.get("collision_behavior", "disappear")
	p.max_lifetime = weapon_data.get("projectile_lifetime", 5.0)
	p.max_range = weapon_data.get("max_range", 0.0)
	p.max_penetrations = weapon_data.get("projectile_penetration", 0)
	p.bounces_left = weapon_data.get("projectile_bounce_count", 0)
	
	# Apply bounce chance from stats
	if randf() < StatsManager.get_raw_stat("player_bounce_chance"):
		p.collision_behavior = "bounce"
		p.bounces_left = 1
	
	# Set projectile scale based on weapon projectile size
	var projectile_scale = weapon_data.get("projectile_size", 1.0) * weapon_data.get("scale", 1.0)
	
	# Use the new scaling method if available
	if p.has_method("set_projectile_scale"):
		p.set_projectile_scale(projectile_scale)
	else:
		# Fallback to manual scaling
		p.scale = Vector2.ONE * projectile_scale
		
		# Set collision shape scale
		if p.has_node("CollisionShape2D"):
			var collision_shape = p.get_node("CollisionShape2D")
			if collision_shape.shape is CircleShape2D:
				var circle_shape = collision_shape.shape as CircleShape2D
				circle_shape.radius = circle_shape.radius * projectile_scale
			elif collision_shape.shape is RectangleShape2D:
				var rect_shape = collision_shape.shape as RectangleShape2D
				rect_shape.size = rect_shape.size * projectile_scale
	
	p.global_position = weapon_holder.global_position
	p.rotation = angle
	p.type = weapon_data.get("projectile", "enemy")
	
	# Set projectile group and collision layers
	p.add_to_group("player_projectiles")
	p.set_collision_layer_value(6, true)
	p.set_collision_layer_value(5, false)
	p.set_collision_mask_value(2, true)
	p.set_collision_mask_value(1, false)
	
	# Set projectile texture if specified
	if weapon_data.has("projectile_texture_path") and p.has_method("set_texture"):
		p.set_texture(weapon_data["projectile_texture_path"])
	
	get_tree().get_root().add_child(p)
	return p

func _fire_hitscan_weapon(_weapon_owner: Node2D, _weapon_data: Dictionary):
	# Implement hitscan logic here
	pass

func _fire_melee_weapon(_weapon_owner: Node2D, _weapon_data: Dictionary):
	# Implement melee logic here
	pass

# Utility functions
func get_weapon_rarity(weapon_name: StringName) -> String:
	if WEAPONS.has(weapon_name):
		return WEAPONS[weapon_name].get("rarity", "common")
	return "common"

func get_weapon_unlock_level(weapon_name: StringName) -> int:
	if WEAPONS.has(weapon_name):
		return WEAPONS[weapon_name].get("unlock_level", 1)
	return 1

func is_weapon_unlocked(weapon_name: StringName) -> bool:
	return weapon_name in unlocked_weapons

func get_weapon_display_name(weapon_name: StringName) -> String:
	var display_names = {
		&"gun": "Pistol",
		&"shotgun": "Shotgun",
		&"rifle": "Assault Rifle",
		&"staff": "Magic Staff",
		&"flamethrower": "Flamethrower",
		&"sniper": "Sniper Rifle"
	}
	return display_names.get(weapon_name, weapon_name.capitalize())
