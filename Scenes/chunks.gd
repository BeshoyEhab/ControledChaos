extends Node2D

# @export var current_world_name: String = "LowerWorld" # لم نعد نحتاج لتتبع العالم الحالي هنا

func _ready():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player_node_local = players[0] as CharacterBody2D
		
		# توصيل إشارات المفاتيح إلى اللاعب
		for key in $LowerWorld.get_children():
			if key is Area2D and key.get_script() == load("res://Scenes/gate_key.gd"): # تأكد من المسار الصحيح
				key.key_collected.connect(player_node_local._on_key_collected)

		# لا نحتاج لتوصيل إشارات البوابات هنا بعد الآن
		# for gate in get_tree().get_nodes_in_group("gates"):
		#     gate.gate_activated.connect(_on_gate_activated)
			
		# توصيل إشارة موت اللاعب
		player_node_local.player_died.connect(_on_player_died)
	else:
		print("Error: Player not found in \'player\' group!")

# لا نحتاج لهذه الدوال بعد الآن
# func _on_gate_activated(target_world: String, spawn_position: Vector2):
#     switch_world(target_world, spawn_position)

# func switch_world(new_world_name: String, spawn_position: Vector2):
#     # ... (المنطق القديم للانتقال بين العوالم)

func _on_player_died():
	print("Player died! Returning to Start Menu...")
	get_tree().change_scene_to_file("res://StartMenu.tscn")
