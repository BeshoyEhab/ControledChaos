# EnhancedEnemySpawner.gd - Enhanced enemy spawning system
extends Node2D

# Scene references
@export var enemy_scene: PackedScene

# Spawn parameters
var player: Node2D
var player_initial_position: Vector2
var spawn_radius: float = 400.0

# Spawn timing
var base_spawn_time: float = 2.0
var min_spawn_time: float = 0.5
var current_spawn_time: float
var spawn_time_decrease_rate: float = 0.05

# Enhanced enemy database with more variety
var ENEMY_TYPES: Dictionary = {
	"warrior": {
		"behavior": "chase",
		"texture_path": "res://sprites/characters/skeleton.png",
		"base_health": 100.0,
		"base_speed": 100.0,
		"base_damage": 10.0,
		"xp_reward": 10,
		"rarity": "common",
		"spawn_weight": 40,
		"min_level": 1,
		"projectile_texture": "",
		"special_abilities": [],
		"ai_type": "aggressive"
	},
	"orc": {
		"behavior": "chase",
		"texture_path": "res://sprites/characters/skeleton.png",
		"base_health": 150.0,
		"base_speed": 80.0,
		"base_damage": 15.0,
		"xp_reward": 15,
		"rarity": "common",
		"spawn_weight": 35,
		"min_level": 1,
		"projectile_texture": "",
		"special_abilities": [],
		"ai_type": "berserker"
	},
	"mage": {
		"behavior": "ranged",
		"texture_path": "res://sprites/characters/skeleton.png",
		"base_health": 60.0,
		"base_speed": 70.0,
		"base_damage": 20.0,
		"xp_reward": 20,
		"rarity": "uncommon",
		"spawn_weight": 20,
		"min_level": 3,
		"attack_cooldown": 3.0,
		"preferred_distance": 250.0,
		"projectile_speed": 400.0,
		"projectile_texture": "res://sprites/wepons/All_Fire_Bullet_Pixel_16x16_00.png",
		"special_abilities": ["teleport", "shield"],
		"ai_type": "tactical"
	},
	"tank": {
		"behavior": "tank",
		"texture": load("res://sprites/2D Pixel Dungeon Asset Pack/Character_animation/monsters_idle/skeleton2/v2/skeleton2_v2_2.png"),
		"base_health": 300.0,
		"base_speed": 50.0,
		"base_damage": 25.0,
		"xp_reward": 30,
		"rarity": "uncommon",
		"spawn_weight": 15,
		"min_level": 5,
		"projectile_texture": "",
		"special_abilities": ["charge", "stun"],
		"ai_type": "defensive"
	},
	"assassin": {
		"behavior": "fast",
		"texture": load("res://sprites/2D Pixel Dungeon Asset Pack/Character_animation/monsters_idle/skull/v1/skull_v1_3.png"),
		"base_health": 80.0,
		"base_speed": 150.0,
		"base_damage": 18.0,
		"xp_reward": 25,
		"rarity": "uncommon",
		"spawn_weight": 12,
		"min_level": 4,
		"projectile_texture": "",
		"special_abilities": ["stealth", "backstab"],
		"ai_type": "hit_and_run"
	},
	"necromancer": {
		"behavior": "ranged",
		"texture": load("res://sprites/2D Pixel Dungeon Asset Pack/Character_animation/monsters_idle/priest1/v2/priest1_v2_3.png"),
		"base_health": 120.0,
		"base_speed": 60.0,
		"base_damage": 30.0,
		"xp_reward": 40,
		"rarity": "rare",
		"spawn_weight": 8,
		"min_level": 8,
		"attack_cooldown": 2.5,
		"preferred_distance": 300.0,
		"projectile_speed": 350.0,
		"projectile_texture": "res://sprites/wepons/All_Fire_Bullet_Pixel_16x16_00.png",
		"special_abilities": ["summon", "curse", "life_drain"],
		"ai_type": "support"
	},
	"demon": {
		"behavior": "chase",
		"texture": load("res://sprites/2D Pixel Dungeon Asset Pack/Character_animation/monsters_idle/vampire/v1/vampire_v1_3.png"),
		"base_health": 200.0,
		"base_speed": 120.0,
		"base_damage": 35.0,
		"xp_reward": 50,
		"rarity": "rare",
		"spawn_weight": 5,
		"min_level": 10,
		"projectile_texture": "",
		"special_abilities": ["fire_aura", "fear", "regeneration"],
		"ai_type": "aggressive"
	},
	"boss_skeleton": {
		"behavior": "boss",
		"texture": load("res://sprites/2D Pixel Dungeon Asset Pack/Character_animation/monsters_idle/skeleton1/v1/skeleton_v1_3.png"),
		"base_health": 1000.0,
		"base_speed": 80.0,
		"base_damage": 50.0,
		"xp_reward": 200,
		"rarity": "boss",
		"spawn_weight": 1,
		"min_level": 15,
		"attack_cooldown": 1.5,
		"preferred_distance": 200.0,
		"projectile_speed": 500.0,
		"projectile_texture": "res://sprites/wepons/All_Fire_Bullet_Pixel_16x16_00.png",
		"special_abilities": ["multi_attack", "spawn_minions", "rage", "invulnerability"],
		"ai_type": "boss",
		"size_scale": 1.5,
		"color_modulate": Color(1.2, 0.8, 0.8, 1.0)
	}
}

# Elite enemy modifications
var ELITE_MODIFIERS: Dictionary = {
	"armored": {
		"health_multiplier": 2.0,
		"speed_multiplier": 0.8,
		"damage_multiplier": 1.2,
		"xp_multiplier": 2.0,
		"color_modulate": Color(0.7, 0.7, 1.0, 1.0),
		"special_abilities": ["damage_reduction"],
		"title": "Armored"
	},
	"swift": {
		"health_multiplier": 0.7,
		"speed_multiplier": 1.8,
		"damage_multiplier": 1.1,
		"xp_multiplier": 1.5,
		"color_modulate": Color(1.0, 1.0, 0.7, 1.0),
		"special_abilities": ["dash_attack"],
		"title": "Swift"
	},
	"berserker": {
		"health_multiplier": 1.5,
		"speed_multiplier": 1.3,
		"damage_multiplier": 1.8,
		"xp_multiplier": 2.5,
		"color_modulate": Color(1.2, 0.5, 0.5, 1.0),
		"special_abilities": ["rage", "frenzy"],
		"title": "Berserker"
	},
	"arcane": {
		"health_multiplier": 1.2,
		"speed_multiplier": 1.0,
		"damage_multiplier": 1.5,
		"xp_multiplier": 2.0,
		"color_modulate": Color(1.0, 0.7, 1.0, 1.0),
		"special_abilities": ["magic_immunity", "spell_reflect"],
		"title": "Arcane"
	}
}

var current_level: int = 1
var total_enemies_spawned: int = 0
var enemies_alive: int = 0

func _ready():
	player = get_tree().get_first_node_in_group("player")
	current_spawn_time = base_spawn_time
	$Timer.wait_time = current_spawn_time
	$Timer.timeout.connect(spawn_enemy)
	
	# Connect to stats manager for level updates
	if StatsManager:
		StatsManager.player_leveled_up.connect(_on_player_leveled_up)
		StatsManager.difficulty_increased.connect(_on_difficulty_increased)

func _process(delta: float):
	if not get_tree().paused:
		current_spawn_time = max(min_spawn_time, current_spawn_time - spawn_time_decrease_rate * delta)
		$Timer.wait_time = current_spawn_time

func _on_player_leveled_up(level: int, options: Array):
	current_level = level

func _on_difficulty_increased():
	base_spawn_time += 0.5
	print("Spawn timer reset to: ", current_spawn_time)

func spawn_enemy():
	if get_tree().paused or not is_instance_valid(player):
		return

	# Choose enemy type based on level and weights
	var enemy_type = choose_enemy_type()
	var enemy_data = ENEMY_TYPES[enemy_type].duplicate(true)
	
	# Apply elite modifier chance
	if should_spawn_elite():
		apply_elite_modifier(enemy_data)
	
	# Choose spawn position
	var spawn_position = choose_spawn_position()
	
	# Create enemy
	var new_enemy = enemy_scene.instantiate()
	if not new_enemy:
		print("Warning: Failed to instantiate enemy scene")
		return
	
	# Apply enemy data
	new_enemy.enemy_data = enemy_data
	new_enemy.global_position = spawn_position
	
	# Connect to enemy death signal
	if new_enemy.has_signal("enemy_died"):
		new_enemy.enemy_died.connect(_on_enemy_died)
	
	get_parent().add_child(new_enemy)
	total_enemies_spawned += 1
	enemies_alive += 1
	
	print("Spawned ", enemy_data.get("title", enemy_type), " at ", spawn_position)

func choose_enemy_type() -> String:
	var available_enemies = []
	var total_weight = 0
	
	# Filter enemies by level requirement and build weight list
	for enemy_key in ENEMY_TYPES:
		var enemy_data = ENEMY_TYPES[enemy_key]
		if enemy_data.get("min_level", 1) <= current_level:
			var weight = enemy_data.get("spawn_weight", 1)
			# Reduce weight for rare enemies
			var rarity = enemy_data.get("rarity", "common")
			match rarity:
				"uncommon":
					weight = int(weight * 0.7)
				"rare":
					weight = int(weight * 0.4)
				"boss":
					weight = int(weight * 0.1)
			
			available_enemies.append({"key": enemy_key, "weight": weight})
			total_weight += weight
	
	if available_enemies.is_empty():
		return "warrior"  # Fallback
	
	# Weighted random selection
	var random_value = randi() % total_weight
	var current_weight = 0
	
	for enemy_info in available_enemies:
		current_weight += enemy_info.weight
		if random_value < current_weight:
			return enemy_info.key
	
	return available_enemies[0].key

func should_spawn_elite() -> bool:
	var elite_chance = 0.05 + (current_level * 0.01)  # 5% base + 1% per level
	return randf() < elite_chance

func apply_elite_modifier(enemy_data: Dictionary):
	var modifier_key = ELITE_MODIFIERS.keys()[randi() % ELITE_MODIFIERS.size()]
	var modifier = ELITE_MODIFIERS[modifier_key]
	
	# Apply stat modifications
	enemy_data.base_health *= modifier.get("health_multiplier", 1.0)
	enemy_data.base_speed *= modifier.get("speed_multiplier", 1.0)
	enemy_data.base_damage *= modifier.get("damage_multiplier", 1.0)
	enemy_data.xp_reward = int(enemy_data.xp_reward * modifier.get("xp_multiplier", 1.0))
	
	# Apply visual modifications
	if modifier.has("color_modulate"):
		enemy_data.color_modulate = modifier.color_modulate
	
	# Add special abilities
	if modifier.has("special_abilities"):
		for ability in modifier.special_abilities:
			if not enemy_data.special_abilities.has(ability):
				enemy_data.special_abilities.append(ability)
	
	# Set elite title
	enemy_data.elite_title = modifier.get("title", "Elite")
	enemy_data.is_elite = true
	
	print("Applied elite modifier: ", modifier_key)

func choose_spawn_position() -> Vector2:
	# Choose random direction and distance
	var angle = randf() * TAU
	var distance = randf_range(spawn_radius/2, spawn_radius)
	
	# Convert to cartesian coordinates
	var offset = Vector2(cos(angle), sin(angle)) * distance
	return player.global_position + offset

func _on_enemy_died():
	enemies_alive -= 1

# Utility functions
func get_spawn_stats() -> Dictionary:
	return {
		"total_spawned": total_enemies_spawned,
		"currently_alive": enemies_alive,
		"current_level": current_level,
		"spawn_time": current_spawn_time
	}

func set_spawn_parameters(new_spawn_time: float = -1, new_radius: float = -1):
	if new_spawn_time > 0:
		base_spawn_time = new_spawn_time
		current_spawn_time = new_spawn_time
		$Timer.wait_time = current_spawn_time
	
	if new_radius > 0:
		spawn_radius = new_radius

func pause_spawning():
	$Timer.paused = true

func resume_spawning():
	$Timer.paused = false

func force_spawn_boss():
	if ENEMY_TYPES.has("boss_skeleton"):
		var boss_data = ENEMY_TYPES["boss_skeleton"].duplicate(true)
		var spawn_position = choose_spawn_position()
		
		var new_enemy = enemy_scene.instantiate()
		if new_enemy:
			new_enemy.enemy_data = boss_data
			new_enemy.global_position = spawn_position
			
			if new_enemy.has_signal("enemy_died"):
				new_enemy.enemy_died.connect(_on_enemy_died)
			
			get_parent().add_child(new_enemy)
			enemies_alive += 1
			print("Force spawned boss at ", spawn_position)
