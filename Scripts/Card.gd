# CardUI.gd
extends PanelContainer

@onready var title_label = $VBoxContainer/TitleLabel
@onready var rarity_label = $VBoxContainer/RarityLabel
@onready var description_label = $VBoxContainer/DescriptionLabel
@onready var select_button = $VBoxContainer/SelectButton

func _ready():
	select_button.text = "Select" # Set button text to English

func set_data(card_data: Dictionary):
	title_label.text = card_data.title
	rarity_label.text = "Rarity: " + card_data.rarity # Changed to English
	description_label.text = card_data.description
