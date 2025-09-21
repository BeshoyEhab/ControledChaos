# Card.gd (CardUI script)
extends PanelContainer

signal card_selected(card_data)
signal card_hovered(card_data)
signal card_unhovered()

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var rarity_label: Label = $VBoxContainer/RarityLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var select_button: Button = $VBoxContainer/SelectButton
@onready var card_icon: TextureRect = $VBoxContainer/CardIcon
@onready var rarity_border: NinePatchRect = $RarityBorder

var card_data: Dictionary
var is_hovered: bool = false
var is_selected: bool = false
var original_scale: Vector2
var tween: Tween

# Rarity colors (like Hades)
var rarity_colors = {
	"common": Color.WHITE,
	"rare": Color.CYAN,
	"epic": Color.MAGENTA,
	"legendary": Color.GOLD,
	"mythic": Color.RED
}

func _ready():
	original_scale = scale
	
	# Connect button signals
	if select_button:
		select_button.pressed.connect(_on_select_pressed)
		select_button.mouse_entered.connect(_on_card_hover_start)
		select_button.mouse_exited.connect(_on_card_hover_end)
	
	# Make the entire card hoverable
	mouse_entered.connect(_on_card_hover_start)
	mouse_exited.connect(_on_card_hover_end)
	
	# Set initial button text
	if select_button:
		select_button.text = "SELECT"
	
	# Setup card styling
	_setup_card_appearance()

func _setup_card_appearance():
	# Add hover and selection styling
	modulate = Color.WHITE
	
	# Make button more game-like
	if select_button:
		select_button.flat = false
		select_button.add_theme_color_override("font_color", Color.WHITE)
		select_button.add_theme_color_override("font_color_hover", Color.YELLOW)

func set_data(new_card_data: Dictionary):
	card_data = new_card_data
	
	# Safely set text with null checks
	if title_label and card_data.has("title"):
		title_label.text = card_data.title
		
	if rarity_label and card_data.has("rarity"):
		rarity_label.text = "★ " + card_data.rarity.to_upper()
		_set_rarity_color(card_data.rarity.to_lower())
		
	if description_label and card_data.has("description"):
		description_label.text = card_data.description
	
	# Set card icon if available
	if card_icon and card_data.has("icon_path"):
		var icon_path = card_data.icon_path
		var texture = load(icon_path) if icon_path != "" else null
		if texture != null:
			card_icon.texture = texture
		else:
			# Create fallback icon
			_create_fallback_card_icon()
	elif card_icon:
		_create_fallback_card_icon()
	
	# Update visual style based on rarity
	_update_card_styling()

func _set_rarity_color(rarity: String):
	var color = rarity_colors.get(rarity, Color.WHITE)
	
	if rarity_label:
		rarity_label.add_theme_color_override("font_color", color)
	
	if rarity_border:
		rarity_border.modulate = color

func _update_card_styling():
	if not card_data.has("rarity"):
		return
		
	var rarity = card_data.rarity.to_lower()
	var border_color = rarity_colors.get(rarity, Color.WHITE)
	
	# Add subtle glow effect based on rarity
	if rarity == "legendary" or rarity == "mythic":
		_add_glow_effect(border_color)

func _add_glow_effect(color: Color):
	# Create a subtle glow animation
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_loops()
	tween.tween_method(_set_glow_intensity, 0.8, 1.2, 1.0)
	tween.tween_method(_set_glow_intensity, 1.2, 0.8, 1.0)

func _set_glow_intensity(intensity: float):
	if rarity_border:
		rarity_border.modulate.a = intensity

func _on_card_hover_start():
	if is_selected:
		return
		
	is_hovered = true
	card_hovered.emit(card_data)
	
	# Scale up animation (like Hades)
	if tween:
		tween.kill()
	tween = create_tween()
	tween.parallel().tween_property(self, "scale", original_scale * 1.05, 0.1)
	tween.parallel().tween_property(self, "modulate", Color(1.1, 1.1, 1.1, 1.0), 0.1)
	
	# Button highlight
	if select_button:
		select_button.grab_focus()

func _on_card_hover_end():
	if is_selected:
		return
		
	is_hovered = false
	card_unhovered.emit()
	
	# Scale back animation
	if tween:
		tween.kill()
	tween = create_tween()
	tween.parallel().tween_property(self, "scale", original_scale, 0.1)
	tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.1)

func _on_select_pressed():
	print("Card select button pressed!")
	print("Card data: ", card_data)
	print("Is selected: ", is_selected)
	
	if is_selected:
		print("Card already selected, ignoring")
		return
		
	print("Calling _select_card()")
	_select_card()

func _select_card():
	is_selected = true
	card_selected.emit(card_data)
	
	# Selection animation (bigger scale, different color)
	if tween:
		tween.kill()
	tween = create_tween()
	tween.parallel().tween_property(self, "scale", original_scale * 1.1, 0.2)
	tween.parallel().tween_property(self, "modulate", Color(1.3, 1.3, 0.8, 1.0), 0.2)
	
	# Update button text
	if select_button:
		select_button.text = "SELECTED"
		select_button.disabled = true

# Handle input for keyboard navigation (like Hades)
func _gui_input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ENTER, KEY_SPACE:
				if is_hovered and not is_selected:
					_select_card()

# Reset card state (useful for reusing cards)
func reset_card():
	is_selected = false
	is_hovered = false
	
	if tween:
		tween.kill()
	
	scale = original_scale
	modulate = Color.WHITE
	
	if select_button:
		select_button.text = "SELECT"
		select_button.disabled = false

# Disable/enable card
func set_card_enabled(enabled: bool):
	if select_button:
		select_button.disabled = not enabled
	
	modulate = Color.WHITE if enabled else Color(0.5, 0.5, 0.5, 0.7)

# --- Helper function for safe icon loading ---
func _create_fallback_card_icon():
	"""Create a simple colored square if card icon fails to load."""
	if not card_icon:
		return
		
	var rarity = card_data.get("rarity", "common").to_lower()
	var icon_color = rarity_colors.get(rarity, Color.WHITE)
	
	# Create a simple colored texture
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(icon_color)
	var fallback_texture = ImageTexture.create_from_image(image)
	card_icon.texture = fallback_texture
	
	print("Created fallback card icon for rarity: ", rarity)
