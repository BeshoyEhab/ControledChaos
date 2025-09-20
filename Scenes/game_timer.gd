extends Control

@onready var time_label = $TimeLabel
@onready var timer_node = $Timer
@onready var effect_timer = $EffectTimer

var max_time: float = 300.0  # 5 minutes default
var current_time: float = 0.0
var is_running: bool = false
var is_counting_down: bool = false  # true for countdown, false for count up

# Visual effect properties
var original_font_size: int = 16
var original_color: Color = Color.WHITE

func _ready():
	setup_ui()
	setup_timers()
	update_display()

func setup_ui():
	# Use proper viewport-relative anchoring for true center positioning
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	offset_left = -75  # Half of width (150/2)
	offset_right = 75   # Half of width (150/2) 
	offset_top = 25     # Distance from top
	offset_bottom = 55  # Top + height (25 + 30)
	
	# Create time label - centered using anchors instead of position
	if not time_label:
		time_label = Label.new()
		add_child(time_label)
		time_label.name = "TimeLabel"
	
	time_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", original_font_size)
	time_label.add_theme_color_override("font_color", original_color)
	time_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	time_label.add_theme_constant_override("shadow_offset_x", 2)
	time_label.add_theme_constant_override("shadow_offset_y", 2)

func setup_timers():
	# Main timer for counting
	if not timer_node:
		timer_node = Timer.new()
		add_child(timer_node)
		timer_node.name = "Timer"
	
	timer_node.wait_time = 1.0  # Update every second
	timer_node.timeout.connect(_on_timer_timeout)
	
	# Effect timer for visual effects every 45 seconds
	if not effect_timer:
		effect_timer = Timer.new()
		add_child(effect_timer)
		effect_timer.name = "EffectTimer"
	
	effect_timer.wait_time = 45.0  # Changed to 45 seconds
	effect_timer.timeout.connect(_on_effect_timer_timeout)

func _on_timer_timeout():
	if is_counting_down:
		current_time -= 1.0
		if current_time <= 0:
			current_time = 0
			stop_timer()
			# Timer finished - could emit signal here
			print("Timer finished!")
	else:
		current_time += 1.0
		if current_time >= max_time:
			current_time = max_time
	
	update_display()

func _on_effect_timer_timeout():
	# Trigger visual effect every 45 seconds
	create_text_effect()

func create_text_effect():
	# Choose random effect type
	var effect_type = randi() % 4
	
	match effect_type:
		0:
			color_cycle_effect()
		1:
			pulse_size_effect()
		2:
			rainbow_flash_effect()
		3:
			dramatic_grow_effect()

func color_cycle_effect():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Cycle through different colors smoothly
	var colors = [Color.RED, Color.ORANGE, Color.YELLOW, Color.GREEN, Color.CYAN, Color.BLUE, Color.MAGENTA]
	var cycle_duration = 0.3
	
	for i in range(colors.size()):
		tween.tween_method(set_text_color, colors[i], colors[(i + 1) % colors.size()], cycle_duration).set_delay(i * cycle_duration)
	
	# Return to original color
	tween.tween_method(set_text_color, colors[-1], original_color, 0.5).set_delay(colors.size() * cycle_duration)

func pulse_size_effect():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Pulse the size dramatically
	var sizes = [original_font_size, 24, 32, 28, 20, original_font_size]
	var pulse_duration = 0.2
	
	for i in range(sizes.size()):
		tween.tween_method(set_text_size, sizes[i], sizes[i], pulse_duration).set_delay(i * pulse_duration)

func rainbow_flash_effect():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Rapid rainbow flashing
	var rainbow_colors = [Color.RED, Color.ORANGE, Color.YELLOW, Color.GREEN, Color.CYAN, Color.BLUE, Color.MAGENTA, Color.PINK]
	
	for i in range(rainbow_colors.size() * 2):  # Double cycle for more flash
		var color = rainbow_colors[i % rainbow_colors.size()]
		tween.tween_method(set_text_color, color, color, 0.05).set_delay(i * 0.05)
	
	# Return to original
	tween.tween_method(set_text_color, original_color, original_color, 0.2).set_delay(rainbow_colors.size() * 2 * 0.05)

func dramatic_grow_effect():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Dramatic grow and shrink with color change
	tween.tween_method(set_text_size, original_font_size, 40, 0.5)
	tween.tween_method(set_text_color, original_color, Color.GOLD, 0.5)
	
	# Hold for drama
	tween.tween_method(set_text_size, 40, 40, 0.3).set_delay(0.5)
	tween.tween_method(set_text_color, Color.GOLD, Color.GOLD, 0.3).set_delay(0.5)
	
	# Return to normal
	tween.tween_method(set_text_size, 40, original_font_size, 0.4).set_delay(0.8)
	tween.tween_method(set_text_color, Color.GOLD, original_color, 0.4).set_delay(0.8)

func set_text_color(color: Color):
	if time_label:
		time_label.add_theme_color_override("font_color", color)

func set_text_size(size: int):
	if time_label:
		time_label.add_theme_font_size_override("font_size", size)

func update_display():
	if not time_label:
		return
	
	# Format time display with better formatting
	var minutes = int(current_time) / 60
	var seconds = int(current_time) % 60
	var hours = minutes / 60
	
	# Show hours if over 60 minutes, otherwise just minutes:seconds
	if hours > 0:
		minutes = minutes % 60
		time_label.text = "%d:%02d:%02d" % [hours, minutes, seconds]
	else:
		time_label.text = "%02d:%02d" % [minutes, seconds]
	
	# Enhanced color feedback for countdown mode (when not in effect)
	if is_counting_down and not effect_timer.is_stopped():
		var time_percentage = current_time / max_time
		if time_percentage < 0.05:  # Last 5% - critical
			original_color = Color.RED
		elif time_percentage < 0.1:  # Last 10% - urgent
			original_color = Color(1.0, 0.3, 0.0)  # Red-orange
		elif time_percentage < 0.3:  # Last 30% - warning
			original_color = Color.YELLOW
		else:
			original_color = Color.WHITE
		
		set_text_color(original_color)

# Timer control functions
func start_timer(countdown: bool = false):
	is_counting_down = countdown
	if countdown and current_time <= 0:
		current_time = max_time
	is_running = true
	timer_node.start()
	effect_timer.start()

func stop_timer():
	is_running = false
	timer_node.stop()
	effect_timer.stop()

func pause_timer():
	if is_running:
		timer_node.paused = true
		effect_timer.paused = true

func resume_timer():
	if is_running:
		timer_node.paused = false
		effect_timer.paused = false

func reset_timer():
	stop_timer()
	current_time = 0.0 if not is_counting_down else max_time
	# Reset visual properties
	set_text_color(Color.WHITE)
	set_text_size(original_font_size)
	original_color = Color.WHITE
	update_display()

func set_max_time(time_seconds: float):
	max_time = time_seconds
	if is_counting_down:
		current_time = max_time
	update_display()

func set_current_time(time_seconds: float):
	current_time = clamp(time_seconds, 0, max_time)
	update_display()
