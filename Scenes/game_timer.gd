extends Control

@onready var timer_bar = $TimerBar
@onready var time_label = $TimeLabel
@onready var timer_node = $Timer
@onready var effect_timer = $EffectTimer

var max_time: float = 300.0  # 5 minutes default
var current_time: float = 0.0
var is_running: bool = false
var is_counting_down: bool = false  # true for countdown, false for count up

# Visual effect properties
var original_modulate: Color = Color.WHITE
var glitch_intensity: float = 0.0
var color_shift_amount: float = 0.0

func _ready():
	setup_ui()
	setup_timers()
	update_display()

func setup_ui():
	# Position in bottom-left corner
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	position = Vector2(20, -50)  # 20px from left, 50px from bottom
	size = Vector2(250, 40)
	
	# Create timer bar
	if not timer_bar:
		timer_bar = TextureProgressBar.new()
		add_child(timer_bar)
		timer_bar.name = "TimerBar"
	
	timer_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	timer_bar.offset_top = 5
	timer_bar.offset_bottom = -15
	timer_bar.max_value = max_time
	timer_bar.value = current_time
	timer_bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	
	# Create time label
	if not time_label:
		time_label = Label.new()
		add_child(time_label)
		time_label.name = "TimeLabel"
	
	time_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	time_label.offset_top = -15
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 12)
	time_label.add_theme_color_override("font_color", Color.WHITE)
	time_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	time_label.add_theme_constant_override("shadow_offset_x", 1)
	time_label.add_theme_constant_override("shadow_offset_y", 1)
	
	create_default_textures()

func setup_timers():
	# Main timer for counting
	if not timer_node:
		timer_node = Timer.new()
		add_child(timer_node)
		timer_node.name = "Timer"
	
	timer_node.wait_time = 1.0  # Update every second
	timer_node.timeout.connect(_on_timer_timeout)
	
	# Effect timer for visual effects every 20 seconds
	if not effect_timer:
		effect_timer = Timer.new()
		add_child(effect_timer)
		effect_timer.name = "EffectTimer"
	
	effect_timer.wait_time = 20.0
	effect_timer.timeout.connect(_on_effect_timer_timeout)

func create_default_textures():
	var under_texture = ImageTexture.new()
	var progress_texture = ImageTexture.new()
	
	# Background (dark gray with border)
	var under_img = Image.create(250, 20, false, Image.FORMAT_RGB8)
	under_img.fill(Color(0.2, 0.2, 0.2))
	# Add border
	for x in range(250):
		under_img.set_pixel(x, 0, Color.BLACK)
		under_img.set_pixel(x, 19, Color.BLACK)
	for y in range(20):
		under_img.set_pixel(0, y, Color.BLACK)
		under_img.set_pixel(249, y, Color.BLACK)
	under_texture.set_image(under_img)
	
	# Fill (orange/amber for time)
	var progress_img = Image.create(250, 20, false, Image.FORMAT_RGB8)
	progress_img.fill(Color.ORANGE)
	progress_texture.set_image(progress_img)
	
	timer_bar.texture_under = under_texture
	timer_bar.texture_progress = progress_texture

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
	# Trigger visual effect every 20 seconds
	create_tween_effect()

func create_tween_effect():
	# Choose random effect
	var effect_type = randi() % 3
	
	match effect_type:
		0:
			glitch_effect()
		1:
			color_pulse_effect()
		2:
			shake_effect()

func glitch_effect():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Glitch the bar
	tween.tween_method(apply_glitch, 0.0, 1.0, 0.1)
	tween.tween_method(apply_glitch, 1.0, 0.0, 0.1).set_delay(0.1)
	tween.tween_method(apply_glitch, 0.0, 0.5, 0.05).set_delay(0.2)
	tween.tween_method(apply_glitch, 0.5, 0.0, 0.05).set_delay(0.25)
	
	# Flash the text
	tween.tween_property(time_label, "modulate", Color.RED, 0.05)
	tween.tween_property(time_label, "modulate", Color.CYAN, 0.05).set_delay(0.05)
	tween.tween_property(time_label, "modulate", Color.WHITE, 0.2).set_delay(0.1)

func color_pulse_effect():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Pulse through colors
	var colors = [Color.RED, Color.GREEN, Color.BLUE, Color.MAGENTA, Color.YELLOW]
	var pulse_duration = 0.15
	
	for i in range(colors.size()):
		tween.tween_property(timer_bar, "modulate", colors[i], pulse_duration).set_delay(i * pulse_duration)
	
	tween.tween_property(timer_bar, "modulate", Color.WHITE, 0.3).set_delay(colors.size() * pulse_duration)

func shake_effect():
	var original_pos = position
	var tween = create_tween()
	
	# Shake positions
	var shake_positions = [
		original_pos + Vector2(3, 0),
		original_pos + Vector2(-3, 1),
		original_pos + Vector2(2, -2),
		original_pos + Vector2(-1, 2),
		original_pos
	]
	
	for i in range(shake_positions.size()):
		tween.tween_property(self, "position", shake_positions[i], 0.05)

func apply_glitch(intensity: float):
	# Create glitch effect by modulating color channels randomly
	var r = randf_range(1.0 - intensity, 1.0 + intensity)
	var g = randf_range(1.0 - intensity, 1.0 + intensity)
	var b = randf_range(1.0 - intensity, 1.0 + intensity)
	timer_bar.modulate = Color(r, g, b, 1.0)

func update_display():
	if not timer_bar or not time_label:
		return
	
	# Update bar
	if is_counting_down:
		timer_bar.value = current_time
	else:
		timer_bar.value = current_time
	
	timer_bar.max_value = max_time
	
	# Format time display
	var minutes = int(current_time) / 60
	var seconds = int(current_time) % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]
	
	# Change color based on time remaining (for countdown)
	if is_counting_down:
		var time_percentage = current_time / max_time
		if time_percentage < 0.1:
			timer_bar.modulate = Color.RED
		elif time_percentage < 0.3:
			timer_bar.modulate = Color.YELLOW
		else:
			timer_bar.modulate = Color.WHITE
	else:
		timer_bar.modulate = Color.WHITE

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
	update_display()

func set_max_time(time_seconds: float):
	max_time = time_seconds
	if is_counting_down:
		current_time = max_time
	update_display()

func set_current_time(time_seconds: float):
	current_time = clamp(time_seconds, 0, max_time)
	update_display()
