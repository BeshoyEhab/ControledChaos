# character.gd
# Optimized Version
extends CharacterBody2D

# ============================================================================
# 1. التعدادات والثوابت (Enums & Constants)
# ============================================================================

# استخدام enum يجعل الكود أكثر وضوحاً من استخدام أرقام عشوائية (0, 1, 2, 3)
enum Direction { DOWN, UP, RIGHT, LEFT }

# ============================================================================
# 2. المتغيرات المُصدَّرة (Exported Variables)
# ============================================================================

@export_group("Movement")
@export var speed: float = 200.0

@export_group("Weapons")
@export var projectile_scene: PackedScene
# استخدام enum للسلاح الحالي يمنع الأخطاء الإملائية
@export var current_weapon: StringName = &"arrow"

# ============================================================================
# 3. المتغيرات الخاصة (Private Variables)
# ============================================================================

# --- متغيرات الحالة ---
var last_direction: Direction = Direction.DOWN
var is_charging: bool = false
var can_attack: bool = true
var weapon_data: Dictionary = {}

# --- العقد (Node References) ---
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fire_point: Marker2D = $FirePoint
@onready var charge_timer: Timer = $ChargeTimer

# --- قاموس بيانات الأسلحة ---
# تم نقله إلى _ready لضمان عدم تهيئته مع كل نسخة
# ولتسهيل تحميله من ملف خارجي (JSON) في المستقبل
static var WEAPONS: Dictionary = {
	&"arrow": {
		"cooldown": 0.3,
		"light_damage": 15, "light_speed": 900, "light_scale": 1.0,
		"heavy_damage": 50, "heavy_speed": 1200, "heavy_scale": 1.8,
		"charge_time": 1.0
	},
	&"fire_magic": {
		"cooldown": 0.5,
		"light_damage": 20, "light_speed": 700, "light_scale": 1.2,
		"heavy_damage": 65, "heavy_speed": 600, "heavy_scale": 2.5,
		"charge_time": 1.2
	}
}

# ============================================================================
# 4. دوال Godot الأساسية (Built-in Functions)
# ============================================================================

func _ready() -> void:
	add_to_group("player")
	# تحميل بيانات السلاح الحالي عند بدء اللعبة
	set_weapon(current_weapon)

func _process(delta: float) -> void:
	# نقل منطق الإدخال إلى _process لضمان عدم فقدان أي ضغطة
	handle_input()

func _physics_process(delta: float) -> void:
	handle_movement()
	handle_aiming()

# ============================================================================
# 5. دوال اللعبة الرئيسية (Main Gameplay Functions)
# ============================================================================

# --- دوال الإدخال والحركة ---
func handle_input() -> void:
	if not can_attack: return

	if Input.is_action_just_pressed("light_attack"):
		fire("light")
	
	if Input.is_action_just_pressed("heavy_attack"):
		start_charge()

	if Input.is_action_just_released("heavy_attack"):
		release_charge()

func handle_movement() -> void:
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_direction * speed
	move_and_slide()
	update_animation(input_direction)

func handle_aiming() -> void:
	fire_point.look_at(get_global_mouse_position())

# --- دوال نظام الأسلحة ---
func set_weapon(weapon_name: StringName) -> void:
	# التحقق من وجود السلاح قبل التبديل إليه
	if not WEAPONS.has(weapon_name):
		push_warning("Weapon '%s' not found in WEAPONS dictionary." % weapon_name)
		return
	
	current_weapon = weapon_name
	# تخزين بيانات السلاح في متغير لتجنب البحث في القاموس كل مرة
	weapon_data = WEAPONS[current_weapon]

func fire(attack_type: String) -> void:
	if projectile_scene == null or weapon_data.is_empty(): return

	var p = projectile_scene.instantiate() as Area2D
	
	# استخدام متغير weapon_data المخزن بدلاً من البحث في القاموس
	p.damage = weapon_data[attack_type + "_damage"]
	p.speed = weapon_data[attack_type + "_speed"]
	p.scale = Vector2.ONE * weapon_data[attack_type + "_scale"]
	
	p.global_position = fire_point.global_position
	p.rotation = fire_point.global_rotation
	
	get_tree().get_root().add_child(p)
	
	# تطبيق Cooldown (فترة راحة) بعد الهجوم
	can_attack = false
	await get_tree().create_timer(weapon_data.get("cooldown", 0.2)).timeout
	can_attack = true

func start_charge() -> void:
	if weapon_data.is_empty(): return
	
	is_charging = true
	charge_timer.start(weapon_data["charge_time"])

func release_charge() -> void:
	if not is_charging: return
	
	if charge_timer.is_stopped():
		fire("heavy")
	
	is_charging = false
	charge_timer.stop()

# --- دالة الرسوم المتحركة (تم إصلاحها ودمجها) ---
func update_animation(direction: Vector2) -> void:
	if not anim_sprite: return

	if direction != Vector2.ZERO:
		# الأولوية للحركة الأفقية
		if direction.x > 0:
			anim_sprite.flip_h = false
			anim_sprite.play("Walk_Right")
			last_direction = Direction.RIGHT
		elif direction.x < 0:
			anim_sprite.flip_h = true
			anim_sprite.play("Walk_Right") # إعادة استخدام نفس الحركة
			last_direction = Direction.LEFT
		elif direction.y > 0:
			anim_sprite.play("Walk_Down")
			last_direction = Direction.DOWN
		elif direction.y < 0:
			anim_sprite.play("Walk_Up")
			last_direction = Direction.UP
	else:
		# حركة الوقوف بناءً على آخر اتجاه
		match last_direction:
			Direction.DOWN:
				anim_sprite.play("Idle_Down")
			Direction.UP:
				anim_sprite.play("Idle_Up")
			Direction.RIGHT:
				anim_sprite.flip_h = false
				anim_sprite.play("Idle_Right")
			Direction.LEFT:
				anim_sprite.flip_h = true
				anim_sprite.play("Idle_Right") # إعادة استخدام نفس الحركة
