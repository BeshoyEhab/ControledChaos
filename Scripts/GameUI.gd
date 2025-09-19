extends CanvasLayer

@onready var health_bar = $HealthBar
@onready var xp_bar = $XPBar
@onready var game_timer_label = $GameTimerLabel # Assuming you add a Label node named GameTimerLabel

var game_time: float = 0.0

func _ready():
	StatsManager.player_health_updated.connect(_on_health_updated)
	StatsManager.player_xp_updated.connect(_on_xp_updated)
	# Ensure bars are visible from the start
	health_bar.visible = true
	xp_bar.visible = true
	game_timer_label.visible = true

func _process(delta: float):
	if not get_tree().paused:
		game_time += delta
		update_game_timer_display()

func update_game_timer_display():
	var minutes = floor(game_time / 60)
	var seconds = fmod(game_time, 60)
	game_timer_label.text = "%02d:%02d" % [minutes, seconds]

func _on_health_updated(current_health, max_health):
	health_bar.max_value = max_health
	health_bar.value = current_health

func _on_xp_updated(current_xp, max_xp):
	xp_bar.max_value = max_xp
	xp_bar.value = current_xp
