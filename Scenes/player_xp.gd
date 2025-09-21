extends Control

@onready var xp_bar: TextureProgressBar
@onready var xp_label: Label
@onready var level_label: Label

var current_xp: float = 0.0:
	set(value):
		current_xp = clamp(value, 0, xp_to_next_level)
		check_level_up()
		update_display()

var xp_to_next_level: float = 100.0:
	set(value):
		xp_to_next_level = value
		update_display()

var current_level: int = 1:
	set(value):
		current_level = value
		calculate_xp_needed()
		update_display()

# XP scaling formula: base_xp * (level^1.5)
var base_xp_per_level: float = 100.0

func _ready():
	setup_ui()
	calculate_xp_needed()
	update_display()

func setup_ui():
	# Set anchors for top-left, positioned under HP bar
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	position = Vector2(20, 70)  # Under HP bar (HP bar is at y=20, height=40)
	size = Vector2(200, 35)
	
	# Create XP bar if not exists
	if not xp_bar:
		xp_bar = TextureProgressBar.new()
		add_child(xp_bar)
		xp_bar.name = "XPBar"
	
	# Setup XP bar
	xp_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	xp_bar.offset_top = 15
	xp_bar.offset_bottom = -10
	xp_bar.max_value = xp_to_next_level
	xp_bar.value = current_xp
	xp_bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	
	# Create level label if not exists
	if not level_label:
		level_label = Label.new()
		add_child(level_label)
		level_label.name = "LevelLabel"
	
	# Setup level label (top-left)
	level_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	level_label.size = Vector2(60, 15)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	level_label.add_theme_font_size_override("font_size", 11)
	level_label.add_theme_color_override("font_color", Color.CYAN)
	level_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	level_label.add_theme_constant_override("shadow_offset_x", 1)
	level_label.add_theme_constant_override("shadow_offset_y", 1)
	
	# Create XP label if not exists
	if not xp_label:
		xp_label = Label.new()
		add_child(xp_label)
		xp_label.name = "XPLabel"
	
	# Setup XP label (bottom)
	xp_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	xp_label.offset_top = -10
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_label.add_theme_font_size_override("font_size", 10)
	xp_label.add_theme_color_override("font_color", Color.YELLOW)
	xp_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	xp_label.add_theme_constant_override("shadow_offset_x", 1)
	xp_label.add_theme_constant_override("shadow_offset_y", 1)
	
	create_default_textures()

func create_default_textures():
	# Create XP bar textures (blue theme)
	var under_texture = ImageTexture.new()
	var progress_texture = ImageTexture.new()
	
	# Background (dark blue with border)
	var under_img = Image.create(200, 15, false, Image.FORMAT_RGB8)
	under_img.fill(Color(0.1, 0.1, 0.3))
	# Add border
	for x in range(200):
		under_img.set_pixel(x, 0, Color.BLACK)
		under_img.set_pixel(x, 14, Color.BLACK)
	for y in range(15):
		under_img.set_pixel(0, y, Color.BLACK)
		under_img.set_pixel(199, y, Color.BLACK)
	under_texture.set_image(under_img)
	
	# Fill (bright blue/cyan)
	var progress_img = Image.create(200, 15, false, Image.FORMAT_RGB8)
	progress_img.fill(Color.CYAN)
	progress_texture.set_image(progress_img)
	
	xp_bar.texture_under = under_texture
	xp_bar.texture_progress = progress_texture

func update_display():
	if not xp_bar or not xp_label or not level_label:
		return
		
	# Update bar values
	xp_bar.max_value = xp_to_next_level
	xp_bar.value = current_xp
	
	# Update labels
	level_label.text = "Level %d" % current_level
	xp_label.text = "%d / %d XP" % [current_xp, xp_to_next_level]
	
	# Visual feedback when close to level up
	var xp_percentage = current_xp / xp_to_next_level
	if xp_percentage > 0.8:
		xp_bar.modulate = Color(1.2, 1.2, 1.0)  # Bright when close to level up
	else:
		xp_bar.modulate = Color.WHITE

func calculate_xp_needed():
	xp_to_next_level = base_xp_per_level * pow(current_level, 1.5)

func check_level_up():
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		current_level += 1
		# Could emit signal here for level up effects
		print("Level up! Now level ", current_level)

func gain_xp(amount: float):
	current_xp = current_xp + amount

func set_level(level: int):
	current_level = level
	current_xp = 0.0  # Reset XP when setting level manually
