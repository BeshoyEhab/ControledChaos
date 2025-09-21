extends Area2D

@export var required_key_id: String = "dimension_key" # المفتاح المطلوب لفتح هذه البوابة
@export var target_player_position: Vector2 = Vector2(155,-1255) # الموقع الجديد للاعب عند الانتقال

# لا نحتاج لـ signal gate_activated بعد الآن إذا كانت البوابة تنقل اللاعب مباشرة
# لا نحتاج لـ sprite, closed_texture, open_texture إذا كانت البوابة مجرد شكل ثابت

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		var player_script = body.get_script()
		if player_script and body.has_method("can_unlock_gate"):
			# إذا كان هناك مفتاح مطلوب لهذه البوابة
			if required_key_id != "":
				if body.can_unlock_gate(required_key_id):
					print("Player has key, moving player directly!")
					body.global_position = target_player_position # تغيير موقع اللاعب مباشرة
					# يمكنك إضافة تأثيرات بصرية أو صوتية هنا للانتقال
				else:
					print("Gate is locked! Requires key: ", required_key_id)
			else:
				# إذا لم يكن هناك مفتاح مطلوب، قم بالانتقال مباشرة
				print("No key required, moving player directly!")
				body.global_position = target_player_position # تغيير موقع اللاعب مباشرة
