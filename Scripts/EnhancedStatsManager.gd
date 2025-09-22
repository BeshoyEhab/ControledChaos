# EnhancedStatsManager.gd - Enhanced stats system with weapon integration
extends Node

# Singleton instance
static var instance

# Signals
signal stat_changed(stat_name: String, old_value: float, new_value: float)
signal weapon_stat_changed(weapon_name: StringName, stat_name: String, new_value: float)
signal stat_upgrade_applied(stat_name: String, upgrade_value: float)

# Enhanced stats categories
var player_stats: Dictionary = {
	# Core stats
	"speed": 1.0,
	"damage": 1.0,
	"cooldown": 1.0,
	"max_health": 100.0,
	"current_health": 100.0,
	
	# Projectile stats
	"projectile_count": 0,
	"projectile_size": 1.0,
	"projectile_speed": 1.0,
	"projectile_lifetime": 1.0,
	"projectile_penetration": 0,
	"projectile_bounce_chance": 0.0,
	"projectile_homing": false,
	"projectile_explosive": false,
	"projectile_explosion_radius": 0.0,
	
	# Special abilities
	"lifesteal": 0.0,
	"crit_chance": 0.0,
	"crit_multiplier": 1.0,
	"dodge_chance": 0.0,
	"damage_reflection": 0.0,
	"speed_boost_on_kill": 0.0,
	"damage_boost_on_kill": 0.0,
	
	# Time manipulation
	"time_scale": 1.0,
	"slow_time_on_hit": 0.0,
	"slow_duration": 0.0,
	
	# Defensive stats
	"armor": 0.0,
	"magic_resistance": 0.0,
	"invulnerability_duration": 0.0,
	"shield_recharge_rate": 0.0,
	"max_shield": 0.0,
	"current_shield": 0.0,
}

var enemy_stats: Dictionary = {
	"health_multiplier": 1.0,
	"speed_multiplier": 1.0,
	"damage_multiplier": 1.0,
	"spawn_rate_multiplier": 1.0,
	"elite_chance": 0.0,
	"boss_chance": 0.0,
}

var weapon_stats: Dictionary = {}
var temporary_effects: Dictionary = {}

# Stat limits and caps
var stat_limits: Dictionary = {
	"speed": Vector2(0.1, 10.0),
	"damage": Vector2(0.1, 20.0),
	"cooldown": Vector2(0.01, 5.0),
	"max_health": Vector2(1.0, 10000.0),
	"projectile_count": Vector2(0, 50),
	"projectile_size": Vector2(0.1, 10.0),
	"projectile_speed": Vector2(0.1, 10.0),
	"projectile_lifetime": Vector2(0.1, 30.0),
	"projectile_penetration": Vector2(0, 100),
	"projectile_bounce_chance": Vector2(0.0, 1.0),
	"lifesteal": Vector2(0.0, 1.0),
	"crit_chance": Vector2(0.0, 1.0),
	"crit_multiplier": Vector2(1.0, 10.0),
	"dodge_chance": Vector2(0.0, 0.9),
	"damage_reflection": Vector2(0.0, 1.0),
	"time_scale": Vector2(0.1, 3.0),
	"armor": Vector2(0.0, 100.0),
	"magic_resistance": Vector2(0.0, 100.0),
	"invulnerability_duration": Vector2(0.0, 10.0),
}

func _ready():
	if instance == null:
		instance = self
		# Connect to existing StatsManager for compatibility
		if StatsManager:
			StatsManager.stats_updated.connect(_on_legacy_stats_updated)
	else:
		queue_free()

# Core stat management
func set_stat(stat_name: String, value: float, apply_limits: bool = true) -> bool:
	if not player_stats.has(stat_name):
		print("Warning: Stat '", stat_name, "' not found")
		return false
	
	var old_value = player_stats[stat_name]
	var new_value = value
	
	# Apply limits if requested
	if apply_limits and stat_limits.has(stat_name):
		var limits = stat_limits[stat_name]
		new_value = clampf(new_value, limits.x, limits.y)
	
	player_stats[stat_name] = new_value
	
	# Emit signal for stat change
	stat_changed.emit(stat_name, old_value, new_value)
	
	# Apply special effects for certain stats
	_apply_special_stat_effects(stat_name, new_value)
	
	return old_value != new_value

func get_stat(stat_name: String, default_value: float = 0.0) -> float:
	return player_stats.get(stat_name, default_value)

func modify_stat(stat_name: String, modifier: float, operation: String = "add") -> bool:
	if not player_stats.has(stat_name):
		return false
	
	var current_value = player_stats[stat_name]
	var new_value: float
	
	match operation:
		"add":
			new_value = current_value + modifier
		"multiply":
			new_value = current_value * modifier
		"set":
			new_value = modifier
		_:
			print("Warning: Unknown operation '", operation, "'")
			return false
	
	return set_stat(stat_name, new_value)

# Weapon stat management
func set_weapon_stat(weapon_name: StringName, stat_name: String, value: float) -> bool:
	if not weapon_stats.has(weapon_name):
		weapon_stats[weapon_name] = {}
	
	weapon_stats[weapon_name][stat_name] = value
	weapon_stat_changed.emit(weapon_name, stat_name, value)
	
	# Update WeaponManager if it exists
	var weapon_manager = preload("res://Scripts/WeaponManager.gd").instance
	if weapon_manager:
		weapon_manager.upgrade_weapon(weapon_name, stat_name, value)
	
	return true

func get_weapon_stat(weapon_name: StringName, stat_name: String, default_value: float = 0.0) -> float:
	if weapon_stats.has(weapon_name) and weapon_stats[weapon_name].has(stat_name):
		return weapon_stats[weapon_name][stat_name]
	return default_value

# Temporary effects system
func apply_temporary_effect(effect_name: String, stat_modifications: Dictionary, duration: float):
	var effect = {
		"stat_modifications": stat_modifications,
		"duration": duration,
		"time_remaining": duration,
		"original_values": {}
	}
	
	# Store original values
	for stat_name in stat_modifications:
		if player_stats.has(stat_name):
			effect.original_values[stat_name] = player_stats[stat_name]
	
	temporary_effects[effect_name] = effect
	print("Applied temporary effect: ", effect_name, " for ", duration, " seconds")

func remove_temporary_effect(effect_name: String):
	if temporary_effects.has(effect_name):
		var effect = temporary_effects[effect_name]
		
		# Restore original values
		for stat_name in effect.original_values:
			set_stat(stat_name, effect.original_values[stat_name])
		
		temporary_effects.erase(effect_name)
		print("Removed temporary effect: ", effect_name)

func _process(delta: float):
	# Update temporary effects
	var effects_to_remove: Array[String] = []
	
	for effect_name in temporary_effects:
		var effect = temporary_effects[effect_name]
		effect.time_remaining -= delta
		
		if effect.time_remaining <= 0:
			effects_to_remove.append(effect_name)
	
	# Remove expired effects
	for effect_name in effects_to_remove:
		remove_temporary_effect(effect_name)

# Special stat effects
func _apply_special_stat_effects(stat_name: String, value: float):
	match stat_name:
		"time_scale":
			Engine.time_scale = value
		"max_health":
			# Adjust current health proportionally if max health changes
			var health_ratio = player_stats.current_health / player_stats.max_health
			player_stats.current_health = value * health_ratio
		"current_shield":
			# Clamp shield to max shield
			if value > player_stats.max_shield:
				player_stats.current_shield = player_stats.max_shield

# Enhanced upgrade system
func apply_upgrade(upgrade_data: Dictionary) -> bool:
	var upgrade_type = upgrade_data.get("type", "stat")
	var stat_name = upgrade_data.get("stat", "")
	var value = upgrade_data.get("value", 0.0)
	var operation = upgrade_data.get("operation", "add")
	var duration = upgrade_data.get("duration", 0.0)
	
	if upgrade_type == "stat" and stat_name != "":
		if duration > 0:
			# Temporary stat boost
			var stat_modifications = {stat_name: value}
			apply_temporary_effect(upgrade_data.get("effect_name", "temp_upgrade"), stat_modifications, duration)
		else:
			# Permanent stat boost
			var success = modify_stat(stat_name, value, operation)
			if success:
				stat_upgrade_applied.emit(stat_name, value)
			return success
	
	elif upgrade_type == "weapon":
		var weapon_name = upgrade_data.get("weapon", "")
		if weapon_name != "" and stat_name != "":
			return set_weapon_stat(weapon_name, stat_name, value)
	
	return false

# Compatibility with legacy StatsManager
func _on_legacy_stats_updated():
	# Sync with legacy stats for compatibility
	if StatsManager.stats.has("player_speed"):
		set_stat("speed", StatsManager.stats.player_speed, false)
	if StatsManager.stats.has("player_damage"):
		set_stat("damage", StatsManager.stats.player_damage, false)
	if StatsManager.stats.has("player_cooldown"):
		set_stat("cooldown", StatsManager.stats.player_cooldown, false)
	if StatsManager.stats.has("player_max_health"):
		set_stat("max_health", StatsManager.stats.player_max_health, false)
	if StatsManager.stats.has("player_projectile_count"):
		set_stat("projectile_count", StatsManager.stats.player_projectile_count, false)
	if StatsManager.stats.has("player_projectile_speed"):
		set_stat("projectile_speed", StatsManager.stats.player_projectile_speed, false)
	if StatsManager.stats.has("player_bounce_chance"):
		set_stat("projectile_bounce_chance", StatsManager.stats.player_bounce_chance, false)
	if StatsManager.stats.has("player_lifesteal"):
		set_stat("lifesteal", StatsManager.stats.player_lifesteal, false)

# Utility functions
func get_all_stats() -> Dictionary:
	return player_stats.duplicate(true)

func get_weapon_stats(weapon_name: StringName) -> Dictionary:
	return weapon_stats.get(weapon_name, {}).duplicate(true)

func reset_all_stats():
	for stat_name in player_stats:
		var default_value = 0.0
		match stat_name:
			"speed", "damage", "projectile_speed", "time_scale":
				default_value = 1.0
			"max_health", "current_health":
				default_value = 100.0
			"cooldown":
				default_value = 1.0
		set_stat(stat_name, default_value)

func get_stat_display_name(stat_name: String) -> String:
	var display_names = {
		"speed": "Movement Speed",
		"damage": "Attack Damage",
		"cooldown": "Attack Cooldown",
		"max_health": "Maximum Health",
		"projectile_count": "Projectile Count",
		"projectile_size": "Projectile Size",
		"projectile_speed": "Projectile Speed",
		"projectile_lifetime": "Projectile Lifetime",
		"projectile_penetration": "Projectile Penetration",
		"projectile_bounce_chance": "Bounce Chance",
		"lifesteal": "Lifesteal",
		"crit_chance": "Critical Hit Chance",
		"crit_multiplier": "Critical Hit Damage",
		"dodge_chance": "Dodge Chance",
		"armor": "Armor",
		"magic_resistance": "Magic Resistance",
		"time_scale": "Time Scale"
	}
	return display_names.get(stat_name, stat_name.replace("_", " ").capitalize())

func get_stat_description(stat_name: String) -> String:
	var descriptions = {
		"speed": "How fast you move",
		"damage": "Base damage dealt by attacks",
		"cooldown": "Time between attacks (lower is better)",
		"max_health": "Maximum amount of health you can have",
		"projectile_count": "Additional projectiles fired per attack",
		"projectile_size": "Size multiplier for projectiles",
		"projectile_speed": "Speed multiplier for projectiles",
		"projectile_lifetime": "How long projectiles last",
		"projectile_penetration": "How many enemies projectiles can pierce",
		"projectile_bounce_chance": "Chance for projectiles to bounce off walls",
		"lifesteal": "Percentage of damage dealt that heals you",
		"crit_chance": "Chance for critical hits",
		"crit_multiplier": "Damage multiplier for critical hits",
		"dodge_chance": "Chance to avoid incoming damage",
		"armor": "Reduces physical damage taken",
		"magic_resistance": "Reduces magical damage taken",
		"time_scale": "Global time speed (lower = slower time)"
	}
	return descriptions.get(stat_name, "No description available")
