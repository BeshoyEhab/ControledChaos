# Key.gd
extends Area2D

@export var key_id: String = "dimension_key" # معرف فريد لهذا المفتاح

signal key_collected(key_id_value) # إشارة تصدر عند جمع المفتاح

@onready var animated_sprite = $AnimatedSprite2D # مرجع لـ AnimatedSprite2D

func _ready():
	body_entered.connect(_on_body_entered)
	if animated_sprite:
		animated_sprite.play("default") # تشغيل الرسم المتحرك الافتراضي للمفتاح

func _on_body_entered(body: Node2D):
	# التحقق مما إذا كان الجسم الذي دخل المنطقة هو اللاعب
	if body.is_in_group("player"):
		key_collected.emit(key_id) # إصدار الإشارة مع معرف المفتاح
		queue_free() # إزالة المفتاح من المشهد
