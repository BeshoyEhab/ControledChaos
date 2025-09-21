# LevelUpUI.gd
extends Control

@onready var header_label = $CenterContainer/VBoxContainer/HeaderLabel
@onready var card_container = $CenterContainer/VBoxContainer/CardContainer
@onready var level_info_label = $CenterContainer/VBoxContainer/LevelInfoLabel
@onready var background_overlay = $BackgroundOverlay
@onready var center_container = $CenterContainer

@export var card_scene: PackedScene

var current_cards: Array[Node] = []
var current_level: int = 1
var selection_made: bool = false

func _ready():
	hide()
	StatsManager.player_leveled_up.connect(show_upgrade_options)
	
	# Setup the scene properly
	_setup_ui_layout()
	
	# Setup background overlay
	if background_overlay:
		background_overlay.color = Color(0, 0, 0, 0.7)
		background_overlay.anchors_preset = Control.PRESET_FULL_RECT
	
	# Setup center container
	if center_container:
		center_container.anchors_preset = Control.PRESET_FULL_RECT
	
	# Setup initial styling
	if header_label:
		header_label.add_theme_font_size_override("font_size", 32)
		header_label.add_theme_color_override("font_color", Color.GOLD)
		header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _setup_ui_layout():
	# Ensure all nodes are properly sized
	print("=== UI LAYOUT DEBUG ===")
	
	if background_overlay:
		background_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		background_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Allow clicks to pass through
		print("Background overlay setup: ", background_overlay.size)
	
	if center_container:
		center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		print("Center container setup: ", center_container.size)
	
	if card_container:
		# Make sure card container can expand
		card_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		print("Card container exists: ", card_container != null)
		print("Card container visible: ", card_container.visible)
		print("Card container position: ", card_container.position)
		print("Card container size: ", card_container.size)
	else:
		print("ERROR: card_container is null!")
	
	print("========================")

func show_upgrade_options(level: int, options: Array[Dictionary]):
	current_level = level
	selection_made = false
	
	print("=== LEVEL UP DEBUG ===")
	print("Level: ", level)
	print("Options count: ", options.size())
	print("Options: ", options)
	
	# Pause the game
	get_tree().paused = true
	
	# Update header with level info
	if header_label:
		header_label.text = "LEVEL UP!"
	if level_info_label:
		level_info_label.text = "Level " + str(level) + " - Choose Your Power!"
		level_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Clear old cards
	_clear_cards()
	
	# Show the UI first
	show()
	print("LevelUpUI is now visible")
	
	# Create cards immediately without complex animation for debugging
	_create_cards_simple(options)

func _clear_cards():
	for card in current_cards:
		if is_instance_valid(card):
			card.queue_free()
	current_cards.clear()
	
	for child in card_container.get_children():
		child.queue_free()

func _create_cards_with_animation(options: Array[Dictionary]):
	for i in range(options.size()):
		var card_data = options[i]
		
		# Create card instance
		if not card_scene:
			push_error("Card scene not set in LevelUpUI!")
			continue
			
		var card_instance = card_scene.instantiate()
		card_container.add_child(card_instance)
		current_cards.append(card_instance)
		
		# Wait for the card to be ready
		if not card_instance.is_node_ready():
			await card_instance.ready
		
		# Set card data
		card_instance.set_data(card_data)
		
		# Connect signals from the enhanced CardUI
		if card_instance.has_signal("card_selected"):
			card_instance.card_selected.connect(_on_card_selected)
		if card_instance.has_signal("card_hovered"):
			card_instance.card_hovered.connect(_on_card_hovered)
		if card_instance.has_signal("card_unhovered"):
			card_instance.card_unhovered.connect(_on_card_unhovered)
		
		# Initial animation setup
		card_instance.modulate.a = 0.0
		card_instance.scale = Vector2.ZERO
		
		# Simple delayed animation using Timer instead of complex tweens
		var delay = i * 0.1
		_animate_card_entrance(card_instance, delay)

func _animate_card_entrance(card_instance: Node, delay: float):
	# Wait for the delay
	if delay > 0:
		await get_tree().create_timer(delay).timeout
	
	# Simple tween animation
	var tween = create_tween()
	tween.parallel().tween_property(card_instance, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(card_instance, "scale", Vector2.ONE, 0.3)

# Simple card creation without animation for debugging
func _create_cards_simple(options: Array[Dictionary]):
	print("Creating cards simple method...")
	
	for i in range(options.size()):
		var card_data = options[i]
		print("Creating card ", i + 1, ": ", card_data.get("title", "Unknown"))
		
		# Create card instance
		if not card_scene:
			push_error("Card scene not set in LevelUpUI!")
			print("ERROR: card_scene is null!")
			continue
		
		print("Card scene found: ", card_scene.resource_path)
		var card_instance = card_scene.instantiate()
		if not card_instance:
			print("ERROR: Failed to instantiate card")
			continue
		
		print("Card instantiated successfully")
		card_container.add_child(card_instance)
		current_cards.append(card_instance)
		
		# Wait for the card to be ready
		if not card_instance.is_node_ready():
			print("Waiting for card to be ready...")
			await card_instance.ready
		
		print("Setting card data...")
		card_instance.set_data(card_data)
		
		# Connect signals from the enhanced CardUI
		if card_instance.has_signal("card_selected"):
			card_instance.card_selected.connect(_on_card_selected)
			print("Connected card_selected signal")
		else:
			print("WARNING: card_selected signal not found")
			
		if card_instance.has_signal("card_hovered"):
			card_instance.card_hovered.connect(_on_card_hovered)
		if card_instance.has_signal("card_unhovered"):
			card_instance.card_unhovered.connect(_on_card_unhovered)
		
		# Make sure card is visible
		card_instance.modulate.a = 1.0
		card_instance.scale = Vector2.ONE
		card_instance.visible = true
		
		print("Card ", i + 1, " created and configured")
	
	print("All cards created. Total cards in container: ", card_container.get_child_count())
	print("Current cards array size: ", current_cards.size())
	
	# Debug: Print container and card info
	print("Card container visible: ", card_container.visible)
	print("Card container position: ", card_container.position)
	print("Card container size: ", card_container.size)
	
	for child in card_container.get_children():
		print("Card child: ", child.name, " visible: ", child.visible, " position: ", child.position)

func _on_card_selected(card_data: Dictionary):
	print("=== _on_card_selected called ===")
	print("Selection made: ", selection_made)
	print("Card data received: ", card_data)
	
	if selection_made:
		print("Selection already made, ignoring")
		return
	
	selection_made = true
	print("Card selected: ", card_data.get("title", "Unknown"))
	
	# Disable all other cards
	for card in current_cards:
		if is_instance_valid(card) and card.card_data != card_data:
			card.set_card_enabled(false)
			# Fade out unselected cards
			var tween = create_tween()
			tween.tween_property(card, "modulate", Color(0.5, 0.5, 0.5, 0.3), 0.3)
	
	# Apply the upgrade IMMEDIATELY
	if card_data.has("key"):
		print("Applying upgrade with key: ", card_data.key)
		StatsManager.apply_upgrade(card_data.key)
		print("Upgrade applied successfully")
	else:
		print("ERROR: Card data has no 'key' field!")
		print("Available fields: ", card_data.keys())
	
	# Close UI immediately for testing
	print("Closing upgrade UI...")
	_close_upgrade_ui_immediate()

func _close_upgrade_ui_immediate():
	"""Close UI immediately without animation for debugging"""
	hide()
	get_tree().paused = false
	print("Level up UI closed immediately, game unpaused")

func _on_card_hovered(card_data: Dictionary):
	# Update header with card info
	if header_label:
		header_label.text = card_data.get("title", "Unknown Card")
	if level_info_label:
		level_info_label.text = card_data.get("description", "No description available")

func _on_card_unhovered():
	# Reset header
	if header_label:
		header_label.text = "LEVEL UP!"
	if level_info_label:
		level_info_label.text = "Level " + str(current_level) + " - Choose Your Power!"

func _close_upgrade_ui():
	# Animate out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		hide()
		modulate.a = 1.0
		get_tree().paused = false
		print("Level up UI closed, game unpaused")
	)

# Input handling for keyboard navigation
func _input(event):
	if not visible or selection_made:
		return
		
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				if current_cards.size() >= 1 and current_cards[0].has_method("_select_card"):
					current_cards[0]._select_card()
			KEY_2:
				if current_cards.size() >= 2 and current_cards[1].has_method("_select_card"):
					current_cards[1]._select_card()
			KEY_3:
				if current_cards.size() >= 3 and current_cards[2].has_method("_select_card"):
					current_cards[2]._select_card()
			KEY_ESCAPE:
				# Emergency close (you might not want this in a real game)
				if OS.is_debug_build():
					_close_upgrade_ui()

# Get current selection state
func is_selection_active() -> bool:
	return visible and not selection_made

# Force close (for emergency situations)
func force_close():
	_clear_cards()
	hide()
	get_tree().paused = false
	selection_made = false
