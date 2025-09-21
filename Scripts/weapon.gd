# weapon.gd - Updated for proper shotgun handling
extends Node2D
var weapon_data: Dictionary
var owner_character: CharacterBody2D
@onready var sprite: Sprite2D = $Sprite2D

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

func set_appearance(texture_path: String):
	print("Setting weapon appearance: ", texture_path)
	if sprite:
		if texture_path != "":
			var loaded_texture = load(texture_path)
			if loaded_texture:
				sprite.texture = loaded_texture
				print("Weapon texture loaded successfully")
				# Remove fallback if texture is loaded
				if sprite.has_node("ColorRectFallback"):
					sprite.get_node("ColorRectFallback").queue_free()
			else:
				print("Warning: Could not load weapon texture: ", texture_path)
				_create_fallback_visual()
		else:
			print("No texture path provided, creating fallback")
			_create_fallback_visual()
	else:
		print("ERROR: No sprite node found in weapon")

func _create_fallback_visual():
	"""Create a simple colored rectangle if texture fails to load."""
	if not sprite:
		return
		
	# Clear any existing texture
	sprite.texture = null
	
	# Remove existing fallback if any
	if sprite.has_node("ColorRectFallback"):
		sprite.get_node("ColorRectFallback").queue_free()
	
	# Create new fallback visual
	var color_rect = ColorRect.new()
	color_rect.name = "ColorRectFallback"
	color_rect.color = Color.GRAY  # Gray for weapons
	color_rect.size = Vector2(20, 6)  # Weapon-like shape
	color_rect.pivot_offset = Vector2(0, color_rect.size.y / 2)  # Pivot at left center
	sprite.add_child(color_rect)
	print("Created fallback weapon visual")
