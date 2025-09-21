extends Node2D

# Drag your Enemy.tscn scene here in the Inspector
@export var enemy_scene: PackedScene

var player: Node2D
var player_initial_position: Vector2
var spawn_radius: float = 400.0

# --- Spawn Timer Variables ---
var base_spawn_time: float = 2.0 # Initial time between spawns
var min_spawn_time: float = 0.5 # Fastest spawn time
var current_spawn_time: float # Current time between spawns
var spawn_time_decrease_rate: float = 0.05 # How much spawn time decreases per regular interval

# --- Enemy Database ---
# Now using AssetPaths for textures
var ENEMY_TYPES = {
	"warrior": {
		"behavior": "chase", "texture": load("res://sprites/2D Pixel Dungeon Asset Pack/Character_animation/monsters_idle/skeleton1/v2/skeleton_v2_2.png"),
		"base_health": 100.0, "base_speed": 100.0, "base_damage": 10.0, "xp_reward": 10
	},
	"orc": {
		"behavior": "chase", "texture": load("res://sprites/2D Pixel Dungeon Asset Pack/Character_animation/monsters_idle/skull/v2/skull_v2_3.png"),
		"base_health": 150.0, "base_speed": 80.0, "base_damage": 15.0, "xp_reward": 15
	},
	"mage": {
		"behavior": "ranged", "texture": load("res://sprites/2D Pixel Dungeon Asset Pack/Character_animation/monsters_idle/vampire/v2/vampire_v2_3.png"),
		"base_health": 60.0, "base_speed": 70.0, "base_damage": 20.0, "xp_reward": 20,
		"attack_cooldown": 3.0, "preferred_distance": 250.0
	}
}

func _ready():
	player = get_tree().get_first_node_in_group("player")

	# Initialize spawn time
	current_spawn_time = base_spawn_time
	$Timer.wait_time = current_spawn_time
	$Timer.timeout.connect(spawn_enemy)
	
	# Connect to StatsManager difficulty signal
	StatsManager.difficulty_increased.connect(_on_difficulty_increased)

func _process(delta: float):
	# Decrease spawn time gradually
	if not get_tree().paused:
		current_spawn_time = max(min_spawn_time, current_spawn_time - spawn_time_decrease_rate * delta)
		$Timer.wait_time = current_spawn_time

func _on_difficulty_increased():
	# When difficulty jumps, reset spawn time to a higher value
	base_spawn_time += 0.5 # Increase base spawn time slightly for next cycle
	print("Spawn timer reset to: ", current_spawn_time)

func spawn_enemy():
	if get_tree().paused or not is_instance_valid(player):
		return

	# Choose a random direction first
	var angle = randf() * TAU  # TAU is 2*PI in Godot
	var distance = randf_range(spawn_radius/2, spawn_radius)  # Min distance 100, max spawn_radius

	# Convert to cartesian coordinates
	var offset = Vector2(cos(angle), sin(angle)) * distance
	var spawn_position = player.global_position + offset
	var random_enemy_key = ENEMY_TYPES.keys().pick_random()
	var enemy_data = ENEMY_TYPES[random_enemy_key]
	
	var new_enemy = enemy_scene.instantiate()
	new_enemy.enemy_data = enemy_data
	new_enemy.global_position = spawn_position
	
	get_parent().add_child(new_enemy)
