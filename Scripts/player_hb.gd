extends Control

@onready var hp_bar: TextureProgressBar
@onready var hp_label: Label

var max_hp: float = 100.0:
	set(value):
		max_hp = value
		update_display()

var current_hp: float = 100.0:
	set(value):
		current_hp = clamp(value, 0, max_hp)
		update_display()

func _ready():
	# Setup UI positioning for top-left
	setup_ui()
	update_display()

func setup_ui():
	# Set anchors and margins for top-left positioning
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	position = Vector2(20, 20)  # Padding from screen edge
	size = Vector2(200, 40)
	
	# Create HP bar if not exists
	if not hp_bar:
		hp_bar = TextureProgressBar.new()
		add_child(hp_bar)
		hp_bar.name = "HPBar"
	
	# Setup HP bar
	hp_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hp_bar.offset_top = 5
	hp_bar.offset_bottom = -15
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	
	# Create HP label if not exists
	if not hp_label:
		hp_label = Label.new()
		add_child(hp_label)
		hp_label.name = "HPLabel"
	
	# Setup HP label
	hp_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hp_label.offset_top = -15
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 12)
	hp_label.add_theme_color_override("font_color", Color.WHITE)
	hp_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	hp_label.add_theme_constant_override("shadow_offset_x", 1)
	hp_label.add_theme_constant_override("shadow_offset_y", 1)
	
	# Create default textures for HP bar
	create_default_textures()

func create_default_textures():
	# Create simple colored backgrounds
	var under_texture = ImageTexture.new()
	var progress_texture = ImageTexture.new()
	
	# Background (dark red with border)
	var under_img = Image.create(200, 20, false, Image.FORMAT_RGB8)
	under_img.fill(Color(0.2, 0.1, 0.1))
	# Add border
	for x in range(200):
		under_img.set_pixel(x, 0, Color.BLACK)
		under_img.set_pixel(x, 19, Color.BLACK)
	for y in range(20):
		under_img.set_pixel(0, y, Color.BLACK)
		under_img.set_pixel(199, y, Color.BLACK)
	under_texture.set_image(under_img)
	
	# Fill (gradient green to red based on health)
	var progress_img = Image.create(200, 20, false, Image.FORMAT_RGB8)
	progress_img.fill(Color.GREEN)
	progress_texture.set_image(progress_img)
	
	hp_bar.texture_under = under_texture
	hp_bar.texture_progress = progress_texture

func update_display():
	if not hp_bar or not hp_label:
		return
		
	# Update bar values
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	
	# Update label text
	hp_label.text = "%d / %d HP" % [current_hp, max_hp]
	
	# Change color based on HP percentage
	var hp_percentage = current_hp / max_hp
	
	if hp_percentage > 0.6:
		hp_bar.modulate = Color.WHITE  # Green
	elif hp_percentage > 0.3:
		hp_bar.modulate = Color.YELLOW
	else:
		hp_bar.modulate = Color(1.0, 0.3, 0.3)  # Red

func take_damage(damage: float):
	current_hp = current_hp - damage

func heal(amount: float):
	current_hp = current_hp + amount

func set_hp_values(current: float, maximum: float):
	max_hp = maximum
	current_hp = current
