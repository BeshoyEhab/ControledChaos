extends Node2D

# @export var current_world_name: String = "LowerWorld" # لم نعد نحتاج لتتبع العالم الحالي هنا

func _ready():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player_node_local = players[0] as CharacterBody2D
		
		# توصيل إشارات المفاتيح إلى اللاعب
		for key in $LowerWorld.get_children():
			if key is Area2D and key.get_script() == load("res://Scripts/gate_key.gd"): # تأكد من المسار الصحيح
				key.key_collected.connect(player_node_local._on_key_collected)
				
		player_node_local.player_died.connect(_on_player_died)
	else:
		print("Error: Player not found in \'player\' group!")


func _on_player_died():
	print("Player died! Returning to Start Menu...")
	get_tree().change_scene_to_file("res://Scenes/startmenue.tscn")
