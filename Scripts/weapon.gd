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

func set_appearance(texture_path: String):
	if sprite:
		var loaded_texture = load(texture_path) if texture_path else null
		if loaded_texture:
			sprite.texture = loaded_texture
			if sprite.has_node("ColorRectFallback"): # Remove fallback if texture is loaded
				sprite.get_node("ColorRectFallback").queue_free()
		else:
			# Fallback to a ColorRect if texture is missing
			sprite.texture = null # Clear any existing texture
			if not sprite.has_node("ColorRectFallback"):
				var color_rect = ColorRect.new()
				color_rect.name = "ColorRectFallback"
				color_rect.color = Color("red") # Default fallback color for weapons
				color_rect.size = Vector2(32, 32) # Default size, adjust as needed
				color_rect.pivot_offset = color_rect.size / 2 # Center pivot
				sprite.add_child(color_rect)
