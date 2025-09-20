extends Node

# --- Signals (The game's event system) ---
signal stats_updated
signal player_leveled_up(level, options)
signal show_merge_screen(owned_upgrades)
signal player_health_updated(current_health, max_health)
signal player_xp_updated(current_xp, max_xp, level)
signal difficulty_increased # New signal for the spawner

# --- Stats Dictionary (The single source of truth for multipliers) ---
var stats = {
	# Player Stats
	"player_speed": 1.0,
	"player_damage": 1.0,
	"player_cooldown": 1.0,
	"player_projectile_count": 0, # Start with 0, base is 1 in character
	"player_lifesteal": 0.0,
	"player_bounce_chance": 0.0,
	
	# Enemy Stats
	"enemy_health": 1.0,
	"enemy_speed": 1.0,
	"enemy_damage": 1.0,
}
var owned_upgrades = []

# --- Game Balance Constants ---
const PLAYER_STAT_LIMITS = Vector2(0.5, 4.0) # Min/Max multipliers
const ENEMY_STAT_LIMITS = Vector2(1.0, 5.0) # Adjusted range for enemies

# --- XP and Leveling ---
var current_xp: int = 0
var xp_to_next_level: int = 10
var current_level: int = 1

func _ready():
	# Setup a timer for random stat glitches
	var glitch_timer = Timer.new()
	glitch_timer.name = "GlitchTimer"
	add_child(glitch_timer)
	glitch_timer.wait_time = 20.0
	glitch_timer.autostart = true
	glitch_timer.timeout.connect(apply_random_glitch)

	# Setup a timer to increase game difficulty over time
	var difficulty_timer = Timer.new()
	difficulty_timer.name = "DifficultyTimer"
	add_child(difficulty_timer)
	difficulty_timer.wait_time = 45.0 # Every 45 seconds, enemies get stronger
	difficulty_timer.autostart = true
	difficulty_timer.timeout.connect(increase_difficulty)

func add_xp(amount: int):
	current_xp += amount
	player_xp_updated.emit(current_xp, xp_to_next_level, current_level)
	while current_xp >= xp_to_next_level:
		level_up()

func level_up():
	current_level += 1
	current_xp -= xp_to_next_level
	xp_to_next_level = int(xp_to_next_level * 1.5)
	player_xp_updated.emit(current_xp, xp_to_next_level)
	
	if current_level % 10 == 0:
		show_merge_screen.emit(owned_upgrades)
		return
	
	var card_options = UpgradeDB.get_random_cards(3)
	player_leveled_up.emit(current_level, card_options)
	player_xp_updated.emit(current_xp, xp_to_next_level, current_level)

func apply_upgrade(card_key: String):
	if not UpgradeDB.UPGRADES.has(card_key): return
	var upgrade_data = UpgradeDB.UPGRADES[card_key]
	upgrade_data.apply.call(stats)
	owned_upgrades.append(card_key)
	stats_updated.emit()

func increase_difficulty():
	# Big jump in enemy stats
	stats.enemy_health = min(stats.enemy_health * 1.5, ENEMY_STAT_LIMITS.y)
	stats.enemy_speed = min(stats.enemy_speed * 1.2, ENEMY_STAT_LIMITS.y)
	stats.enemy_damage = min(stats.enemy_damage * 1.5, ENEMY_STAT_LIMITS.y)
	stats_updated.emit()
	difficulty_increased.emit() # Emit the signal here
	print("Difficulty Increased!")

func apply_random_glitch():
	var is_good_glitch = randf() > 0.5
	var stat_name = stats.keys().pick_random()
	var amount = randf_range(1.1, 1.5)
	
	if is_good_glitch:
		stats[stat_name] *= amount
	else:
		stats[stat_name] /= amount
	
	# Clamp player stats
	if "player" in stat_name:
		stats[stat_name] = clampf(stats[stat_name], PLAYER_STAT_LIMITS.x, PLAYER_STAT_LIMITS.y)
	# Clamp enemy stats
	elif "enemy" in stat_name:
		stats[stat_name] = clampf(stats[stat_name], ENEMY_STAT_LIMITS.x, ENEMY_STAT_LIMITS.y)
	
	stats_updated.emit()
	print("Glitch! Stat '%s' changed." % stat_name)

# Helper function to get the raw stat value (e.g., for projectile count)
func get_raw_stat(stat_name: String) -> float:
	return stats.get(stat_name, 0.0)

# Helper function to apply stat multipliers
func get_final_value(base_value: float, stat_multiplier: float, is_bad_when_high: bool = false) -> float:
	# If is_bad_when_high is true (e.g., cooldown), a higher multiplier means a lower final value
	# If the multiplier is 1.0, it means no change.
	# If the multiplier is 0.5, it means half the value (good for cooldown).
	# If the multiplier is 2.0, it means double the value (bad for cooldown).
	if is_bad_when_high:
		# Ensure we don't divide by zero or a very small number
		return base_value / max(0.01, stat_multiplier)
	else:
		return base_value * stat_multiplier
