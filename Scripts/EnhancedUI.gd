# EnhancedUI.gd - Enhanced UI system for displaying weapon and stats information
extends CanvasLayer

# UI Node references
@onready var weapon_info: Control = $WeaponInfo
@onready var weapon_name: Label = $WeaponInfo/VBoxContainer/WeaponName
@onready var damage_label: Label = $WeaponInfo/VBoxContainer/WeaponStats/DamageLabel
@onready var speed_label: Label = $WeaponInfo/VBoxContainer/WeaponStats/SpeedLabel
@onready var cooldown_label: Label = $WeaponInfo/VBoxContainer/WeaponStats/CooldownLabel
@onready var projectile_count_label: Label = $WeaponInfo/VBoxContainer/ProjectileInfo/ProjectileCountLabel
@onready var projectile_size_label: Label = $WeaponInfo/VBoxContainer/ProjectileInfo/ProjectileSizeLabel
@onready var projectile_speed_label: Label = $WeaponInfo/VBoxContainer/ProjectileInfo/ProjectileSpeedLabel

@onready var speed_stat: Label = $StatsInfo/VBoxContainer/StatsContainer/SpeedStat/Value
@onready var damage_stat: Label = $StatsInfo/VBoxContainer/StatsContainer/DamageStat/Value
@onready var projectile_count_stat: Label = $StatsInfo/VBoxContainer/StatsContainer/ProjectileCountStat/Value
@onready var lifesteal_stat: Label = $StatsInfo/VBoxContainer/StatsContainer/LifestealStat/Value
@onready var crit_chance_stat: Label = $StatsInfo/VBoxContainer/StatsContainer/CritChanceStat/Value

@onready var alive_label: Label = $EnemyInfo/VBoxContainer/AliveLabel
@onready var spawned_label: Label = $EnemyInfo/VBoxContainer/SpawnedLabel
@onready var level_label: Label = $EnemyInfo/VBoxContainer/LevelLabel

var update_timer: float = 0.0
var update_interval: float = 0.1  # Update UI every 100ms

func _ready():
	# Connect to weapon manager signals
	var weapon_manager = preload("res://Scripts/WeaponManager.gd").instance
	if weapon_manager:
		weapon_manager.weapon_switched.connect(_on_weapon_switched)
		weapon_manager.weapon_fired.connect(_on_weapon_fired)
	
	# Connect to enhanced stats manager signals
	var enhanced_stats_manager = preload("res://Scripts/EnhancedStatsManager.gd").instance
	if enhanced_stats_manager:
		enhanced_stats_manager.stat_changed.connect(_on_stat_changed)
	
	# Initial update
	update_weapon_info()
	update_stats_info()
	update_enemy_info()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_T:
				toggle_all_ui()
			KEY_W:
				toggle_weapon_info()
			KEY_S:
				toggle_stats_info()
			KEY_E:
				toggle_enemy_info()

func _process(delta: float):
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		update_weapon_info()
		update_stats_info()
		update_enemy_info()

func _on_weapon_switched(_weapon_name: StringName, _weapon_data: Dictionary):
	update_weapon_info()

func _on_weapon_fired(_weapon_name: StringName, _projectile_count: int):
	# Could add weapon firing effects here
	pass

func _on_stat_changed(_stat_name: String, _old_value: float, _new_value: float):
	update_stats_info()

func update_weapon_info():
	var weapon_manager = preload("res://Scripts/WeaponManager.gd").instance
	if not weapon_manager:
		return
	
	var weapon_data = weapon_manager.get_current_weapon()
	if weapon_data.is_empty():
		return
	
	# Update weapon name
	var display_name = weapon_manager.get_weapon_display_name(weapon_data.get("weapon", "unknown"))
	weapon_name.text = display_name
	
	# Update weapon stats
	damage_label.text = "Damage: " + str(weapon_data.get("damage", 0))
	speed_label.text = "Speed: " + str(weapon_data.get("speed", 0))
	cooldown_label.text = "Cooldown: " + str(weapon_data.get("cooldown", 0)) + "s"
	
	# Update projectile info
	var projectile_count = 1 + weapon_data.get("projectile_count", 0)
	projectile_count_label.text = "Projectiles: " + str(projectile_count)
	projectile_size_label.text = "Size: " + str(weapon_data.get("projectile_size", 1.0)) + "x"
	projectile_speed_label.text = "Speed: " + str(weapon_data.get("projectile_speed", 1.0)) + "x"

func update_stats_info():
	var enhanced_stats_manager = preload("res://Scripts/EnhancedStatsManager.gd").instance
	if not enhanced_stats_manager:
		return
	
	# Update player stats display
	speed_stat.text = str(enhanced_stats_manager.get_stat("speed", 1.0)) + "x"
	damage_stat.text = str(enhanced_stats_manager.get_stat("damage", 1.0)) + "x"
	projectile_count_stat.text = str(int(enhanced_stats_manager.get_stat("projectile_count", 0)))
	lifesteal_stat.text = str(int(enhanced_stats_manager.get_stat("lifesteal", 0.0) * 100)) + "%"
	crit_chance_stat.text = str(int(enhanced_stats_manager.get_stat("crit_chance", 0.0) * 100)) + "%"

func update_enemy_info():
	# Update enemy spawner info
	var spawner = get_tree().get_first_node_in_group("enemy_spawner")
	if spawner and spawner.has_method("get_spawn_stats"):
		var stats = spawner.get_spawn_stats()
		alive_label.text = "Alive: " + str(stats.get("currently_alive", 0))
		spawned_label.text = "Spawned: " + str(stats.get("total_spawned", 0))
		level_label.text = "Level: " + str(stats.get("current_level", 1))

# Utility functions
func toggle_weapon_info():
	weapon_info.visible = !weapon_info.visible

func toggle_stats_info():
	$StatsInfo.visible = !$StatsInfo.visible

func toggle_enemy_info():
	$EnemyInfo.visible = !$EnemyInfo.visible

func show_all_ui():
	weapon_info.visible = true
	$StatsInfo.visible = true
	$EnemyInfo.visible = true

func hide_all_ui():
	weapon_info.visible = false
	$StatsInfo.visible = false
	$EnemyInfo.visible = false

func toggle_all_ui():
	if weapon_info.visible or $StatsInfo.visible or $EnemyInfo.visible:
		hide_all_ui()
	else:
		show_all_ui()
