# projectile.gd
extends Area2D

# هذه المتغيرات سيتم تحديدها من قبل اللاعب عند الإطلاق
var damage: float = 10.0
var speed: float = 800.0
var lifetime: float = 0.1 # مدة بقاء القذيفة بالثواني

func _ready() -> void:
	# ربط الإشارات برمجياً
	body_entered.connect(_on_body_entered)
	$Timer.timeout.connect(_on_timeout)
	# بدء مؤقت التدمير الذاتي
	$Timer.start(lifetime)

func _physics_process(delta: float) -> void:
	# تحريك القذيفة إلى الأمام بناءً على اتجاهها
	position += transform.x * speed * delta

func _on_body_entered(body: Node) -> void:
	# تجاهل الاصطدام باللاعب نفسه
	if body.is_in_group("player"):
		return
		
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
	
	# تدمير القذيفة عند الاصطدام بأي شيء (عدا اللاعب)
	queue_free()

func _on_timeout() -> void:
	queue_free() # تدمير القذيفة عند انتهاء عمرها
	print("time_out")
