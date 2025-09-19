# weapon.gd
extends Node2D

var weapon_data: Dictionary
var owner_character: CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D

func order_attack(attack_type: String):
	if not is_instance_valid(owner_character) or weapon_data.is_empty(): return
	var attack_mode = weapon_data.get("attack_mode", "projectile")
	match attack_mode:
		"projectile", "lobbed":
			owner_character.execute_projectile_attack(weapon_data, attack_type)
		"melee":
			owner_character.execute_melee_attack(weapon_data, attack_type)
		"hitscan":
			owner_character.execute_hitscan_attack(weapon_data, attack_type)

func set_appearance(texture: Texture2D):
	sprite.texture = texture
