# StatsManager.gd (Global Autoload Script)
extends Node

# --- الإشارات (Signals) ---
signal stats_updated
signal player_leveled_up(level, options)
signal show_merge_screen(owned_upgrades)
signal player_health_updated(current_health, max_health)

# ============================================================================
# 1. قاموس الإحصائيات الرئيسي
# ============================================================================
var stats = {
	# --- إحصائيات اللاعب ---
	"player_max_health": 1.0,
	"player_speed": 1.0,
	"player_attack_cooldown": 1.0,
	"player_light_damage": 1.0,
	"player_heavy_damage": 1.0,
	"player_projectile_count": 1,
	"player_projectile_speed": 1.0,
	"player_bounce_chance": 0.0,
	"player_bounce_count": 1,
	"player_lifesteal": 0.0,

	# --- إحصائيات الأعداء ---
	"enemy_max_health": 1.0,
	"enemy_speed": 1.0,
	"enemy_damage": 1.0,
}
var owned_upgrades = []

const PLAYER_STAT_LIMITS = Vector2(0.2, 3.0)
const ENEMY_STAT_LIMITS = Vector2(0.1, 1.5)

# ============================================================================
# 2. نظام الخبرة والمستويات
# ============================================================================
var current_xp: int = 0
var xp_to_next_level: int = 10
var current_level: int = 1

func _ready():
	var timer = Timer.new()
	timer.name = "GlitchTimer"
	timer.wait_time = 20.0
	timer.autostart = true
	timer.timeout.connect(apply_random_glitch)
	add_child(timer)

func add_xp(amount: int):
	current_xp += amount
	if current_xp >= xp_to_next_level:
		level_up()

func level_up():
	current_level += 1
	current_xp = 0
	var xp_multiplier = randf_range(1.3, 1.6)
	xp_to_next_level = int(xp_to_next_level * xp_multiplier)
	
	if current_level % 10 == 0 or (current_level > 5 and randf() < 0.1):
		show_merge_screen.emit(owned_upgrades)
		return

	var card_options = UpgradeDB.get_random_cards(3)
	player_leveled_up.emit(current_level, card_options)

func apply_upgrade(card_key: String):
	if not UpgradeDB.UPGRADES.has(card_key): return
	
	var upgrade_data = UpgradeDB.UPGRADES[card_key]
	upgrade_data.apply.call(stats)
	owned_upgrades.append(card_key)
	
	clamp_all_stats()
	stats_updated.emit()
	print("Applied upgrade: ", upgrade_data.title)

# ============================================================================
# 3. نظام "الجليتش" العشوائي
# ============================================================================
func apply_random_glitch():
	print("--- GLITCH OCCURRED! ---")
	var glitch_type = randi_range(0, 1)
	var modifiable_stats = []
	for key in stats.keys():
		if "count" not in key and "chance" not in key and "lifesteal" not in key:
			modifiable_stats.append(key)

	if modifiable_stats.size() < 2: return

	var stat1_name = modifiable_stats.pick_random()
	modifiable_stats.erase(stat1_name)
	var stat2_name = modifiable_stats.pick_random()

	match glitch_type:
		0: # نظام التبديل
			var temp = stats[stat1_name]
			stats[stat1_name] = stats[stat2_name]
			stats[stat2_name] = temp
		1: # نظام الزيادة والنقصان
			var amount = randf_range(0.1, 0.3)
			stats[stat1_name] -= amount
			stats[stat2_name] += amount

	clamp_all_stats()
	stats_updated.emit()

func clamp_all_stats():
	for key in stats.keys():
		if "count" in key or "chance" in key or "lifesteal" in key: continue
		var limits = PLAYER_STAT_LIMITS if "player" in key else ENEMY_STAT_LIMITS
		stats[key] = clampf(stats[key], limits.x, limits.y)

# ============================================================================
# 4. دوال مساعدة
# ============================================================================
func get_stat(stat_name: String):
	return stats.get(stat_name, 1.0)

func get_raw_stat(stat_name: String):
	return stats.get(stat_name, 0)
