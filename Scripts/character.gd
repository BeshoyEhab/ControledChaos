# هذا السكربت مخصص لعقدة من نوع CharacterBody2D
extends CharacterBody2D

# سرعة حركة اللاعب بالبكسل في الثانية.
@export var speed: float = 150.0

# متغير لتخزين آخر اتجاه كان اللاعب يواجهه.
# 0: Down, 1: Up, 2: Right, 3: Left
var last_direction: int = 0

# هذه الدالة تُستدعى في كل إطار فيزيائي (الأفضل للحركة)
func _physics_process(delta: float) -> void:
	# 1. الحصول على مدخلات اللاعب
	var input_direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# 2. حساب السرعة
	velocity = input_direction * speed

	# 3. تحريك الشخصية
	move_and_slide()
	
	# 4. تحديث الرسوم المتحركة
	update_animation(input_direction)


# دالة اختيارية لتغيير الرسوم المتحركة بناءً على اتجاه الحركة
func update_animation(direction: Vector2) -> void:
	# نتأكد أولاً من وجود عقدة AnimatedSprite2D
	if not has_node("AnimatedSprite2D"):
		return

	var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

	# إذا كانت الشخصية تتحرك
	if direction != Vector2.ZERO:
		# هذا المنطق الجديد يعطي الأولوية للحركة الأفقية
		# ويمنع تداخل الحركات العمودية والأفقية في نفس الإطار
		if direction.x > 0:
			anim_sprite.flip_h = false
			anim_sprite.play("Walk_Right")
			last_direction = 2 # Right
		elif direction.x < 0:
			anim_sprite.flip_h = true
			anim_sprite.play("Walk_Right") # نستخدم نفس الحركة مع قلبها
			last_direction = 3 # Left
		elif direction.y > 0:
			anim_sprite.play("Walk_Down")
			last_direction = 0 # Down
		elif direction.y < 0:
			anim_sprite.play("Walk_Up")
			last_direction = 1 # Up
	else:
		# إذا كانت الشخصية لا تتحرك، شغل حركة الوقوف المناسبة
		# تم إصلاح المشكلة هنا: نقارن أرقاماً بأرقام (بدون علامات اقتباس)
		match last_direction:
			0: # Down
				anim_sprite.play("Idle_Down")
			1: # Up
				anim_sprite.play("Idle_Up")
			2: # Right
				anim_sprite.flip_h = false
				anim_sprite.play("Idle_Right")
			3: # Left
				anim_sprite.flip_h = true
				anim_sprite.play("Idle_Right") # نستخدم نفس الحركة مع قلبها
