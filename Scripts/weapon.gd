# weapon.gd - Updated for proper shotgun handling
extends Node2D
var weapon_data: Dictionary
var owner_character: CharacterBody2D
var weapon: String

var shotgun: Sprite2D
var rifel: Sprite2D
var gun: Sprite2D
var staff: Sprite2D

var anim_shotgun: AnimatedSprite2D
var anim_rifel: AnimatedSprite2D
var anim_gun: AnimatedSprite2D
var anim_staff: AnimatedSprite2D

func _ready():
	# Get weapon nodes safely
	shotgun = get_node_or_null("shotgun")
	rifel = get_node_or_null("rifel")
	gun = get_node_or_null("gun")
	staff = get_node_or_null("staff")
	
	if shotgun:
		anim_shotgun = get_node_or_null("shotgun/anim_shotgun")
	if rifel:
		anim_rifel = get_node_or_null("rifel/anim_rifel")
	if gun:
		anim_gun = get_node_or_null("gun/anim_gun")
	if staff:
		anim_staff = get_node_or_null("staff/anim_staff")

var current_sprite: Sprite2D
var current_anim: AnimatedSprite2D

func order_attack():
	print("Weapon order_attack() called")
	if not is_instance_valid(owner_character) or weapon_data.is_empty(): 
		print("ERROR: Invalid owner or empty weapon data")
		return
	
	# Weapon attacks are now handled by WeaponManager
	# This function is kept for compatibility but delegates to the character
	owner_character.order_attack()

func play_attack_animation():
	"""Play weapon attack animation"""
	if current_anim and is_instance_valid(current_anim):
		current_anim.visible = true
		current_anim.play(weapon)
		await current_anim.animation_finished
		current_anim.visible = false
	

func set_appearance():
	# Hide all sprites first
	shotgun.visible = false
	rifel.visible = false
	gun.visible = false
	staff.visible = false
	
	# Assign and show the correct sprite and animation
	match weapon:
		"shotgun":
			current_sprite = shotgun
			current_anim = anim_shotgun
		"rifel":
			current_sprite = rifel
			current_anim = anim_rifel
		"gun":
			current_sprite = gun 
			current_anim = anim_gun
		"staff":
			current_sprite = staff
			current_anim = anim_staff
		# ADD THIS DEFAULT CASE
		_:
			print("ERROR: Unrecognized weapon name '", weapon, "'. No sprite to show.")
			current_sprite = null # Explicitly set to null
			current_anim = null
	
	# This check now prevents the crash
	if is_instance_valid(current_sprite):
		current_sprite.visible = true
		print("Set appearance for weapon: ", weapon, ", sprite visible: ", current_sprite.visible)
	else:
		print("Could not set appearance, current_sprite is not valid.")
