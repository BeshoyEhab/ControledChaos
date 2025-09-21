# weapon.gd - Updated for proper shotgun handling
extends Node2D
var weapon_data: Dictionary
var owner_character: CharacterBody2D
var weapon: String

@onready var shotgun: Sprite2D = $shotgun
@onready var rifel: Sprite2D = $rifel
@onready var gun: Sprite2D = $gun
@onready var staff: Sprite2D = $staff

@onready var anim_shotgun: AnimatedSprite2D = $shotgun/anim_shotgun
@onready var anim_rifel: AnimatedSprite2D = $rifel/anim_rifel
@onready var anim_gun: AnimatedSprite2D = $gun/anim_gun
@onready var anim_staff: AnimatedSprite2D = $staff/anim_staff

var current_sprite: Sprite2D
var current_anim: AnimatedSprite2D

func order_attack():
	print("Weapon order_attack() called")
	if not is_instance_valid(owner_character) or weapon_data.is_empty(): 
		print("ERROR: Invalid owner or empty weapon data")
		return
		
	var attack_mode = weapon_data.get("attack_mode", "projectile")
	print("Weapon attack mode: ", attack_mode)
	print("Weapon data: ", weapon_data)
	
	match attack_mode:
		"projectile", "lobbed":
			# Let the character handle all projectile logic including bursts and spreads
			owner_character.execute_projectile_attack(weapon_data)
		"melee":
			owner_character.execute_melee_attack(weapon_data)
		"hitscan":
			owner_character.execute_hitscan_attack(weapon_data)
	
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
