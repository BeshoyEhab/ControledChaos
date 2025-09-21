extends Control

@onready var start_button = $StartButton

func _ready():
	start_button.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	# تحميل مشهد اللعبة الرئيسي (Chunk.tscn) عند الضغط على زر البدء
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")



func _on_button_2_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.
