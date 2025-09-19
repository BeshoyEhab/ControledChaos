# LevelUpUI.gd
extends Control

@onready var header_label = $CenterContainer/VBoxContainer/HeaderLabel
@onready var card_container = $CenterContainer/VBoxContainer/CardContainer
@export var card_scene: PackedScene

func _ready():
	hide()
	StatsManager.player_leveled_up.connect(show_upgrade_options)
	# Connect the merge signal if you implement the merge screen
	# StatsManager.show_merge_screen.connect(show_merge_options)

func show_upgrade_options(_level: int, options: Array[Dictionary]):
	get_tree().paused = true
	header_label.text = "Choose a New Upgrade!" # Changed to English
	
	# Clear old cards
	for child in card_container.get_children():
		child.queue_free()

	# Create new cards
	for card_data in options:
		var card_instance = card_scene.instantiate()
		# Assumes your CardUI.gd script has a set_data function
		card_instance.set_data(card_data) 
		
		# Connect the button's pressed signal
		card_instance.get_node("VBoxContainer/SelectButton").pressed.connect(
			func(): _on_card_selected(card_data["key"])
		)
		card_container.add_child(card_instance)
	
	show()

func _on_card_selected(card_key: String):
	StatsManager.apply_upgrade(card_key)
	hide()
	get_tree().paused = false

# You can add the show_merge_options function here later
# func show_merge_options(owned_upgrades: Array):
#     get_tree().paused = true
#     header_label.text = "Merge Items!"
#     # ... logic to show owned items for merging ...
#     show()
