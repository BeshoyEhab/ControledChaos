# UpgradeDB.gd
extends Node

var UPGRADES = {
	# --- Common Upgrades ---
	"common_speed": {
		"title": "Speed Boots",
		"description": "Increases movement speed by 10%.",
		"rarity": "common",
		"icon_path": "res://icons/speed_boots.png",
		"apply": func(stats): stats.player_speed *= 1.1
	},
	"common_damage": {
		"title": "Power Gloves",
		"description": "Increases damage by 10%.",
		"rarity": "common",
		"icon_path": "res://icons/power_gloves.png",
		"apply": func(stats): stats.player_damage *= 1.1
	},
	"common_health": {
		"title": "Health Potion",
		"description": "Increases maximum health by 20.",
		"rarity": "common",
		"icon_path": "res://icons/health_potion.png",
		"apply": func(stats): stats.player_max_health = stats.get("player_max_health", 100) + 20
	},
	
	# --- Rare Upgrades ---
	"rare_cooldown": {
		"title": "Ancient Watch",
		"description": "Reduces attack cooldown by 15%.",
		"rarity": "rare",
		"icon_path": "res://icons/ancient_watch.png",
		"apply": func(stats): stats.player_cooldown *= 0.85
	},
	"rare_multishot": {
		"title": "Multi-Shot Bow",
		"description": "Adds an extra projectile.",
		"rarity": "rare",
		"icon_path": "res://icons/multishot_bow.png",
		"apply": func(stats): stats.player_projectile_count += 1
	},
	"rare_speed_boost": {
		"title": "Lightning Boots",
		"description": "Increases movement speed by 25%.",
		"rarity": "rare",
		"icon_path": "res://icons/lightning_boots.png",
		"apply": func(stats): stats.player_speed *= 1.25
	},
	
	# --- Epic Upgrades ---
	"epic_vampirism": {
		"title": "Vampiric Curse",
		"description": "Heal for 5% of max health on enemy kill.",
		"rarity": "epic",
		"icon_path": "res://icons/vampiric_curse.png",
		"apply": func(stats): stats.player_lifesteal += 0.05
	},
	"epic_bounce": {
		"title": "Ricochet Rounds",
		"description": "Projectiles have 30% chance to bounce.",
		"rarity": "epic", 
		"icon_path": "res://icons/ricochet.png",
		"apply": func(stats): stats.player_bounce_chance += 0.3
	},
	"epic_damage": {
		"title": "Berserker Rage",
		"description": "Increases damage by 50%.",
		"rarity": "epic",
		"icon_path": "res://icons/berserker.png",
		"apply": func(stats): stats.player_damage *= 1.5
	},
	
	# --- Legendary Upgrades ---
	"legendary_time_slow": {
		"title": "Chronos Blessing",
		"description": "Slows time by 20% permanently.",
		"rarity": "legendary",
		"icon_path": "res://icons/chronos_blessing.png",
		"apply": func(stats): stats.time_scale *= 0.8
	},
	"legendary_multishot": {
		"title": "Arrow Storm",
		"description": "Fire 3 additional projectiles.",
		"rarity": "legendary",
		"icon_path": "res://icons/arrow_storm.png",
		"apply": func(stats): stats.player_projectile_count += 3
	},
	
	# --- Mythic Upgrades ---
	"mythic_godmode": {
		"title": "Divine Protection",
		"description": "Become invulnerable for 3 seconds after taking damage.",
		"rarity": "mythic",
		"icon_path": "res://icons/divine_protection.png",
		"apply": func(stats): stats.invulnerability_duration = 3.0
	}
}

# Simple rarity chances based on level
func get_random_cards(count: int, level: int = 1) -> Array[Dictionary]:
	var drawn_cards: Array[Dictionary] = []
	var available_keys = UPGRADES.keys()
	available_keys.shuffle()
	
	var cards_added = 0
	for key in available_keys:
		if cards_added >= count:
			break
			
		var upgrade = UPGRADES[key]
		var rarity = upgrade.rarity
		var should_include = false
		
		# Simple level-based rarity chances
		match rarity:
			"common":
				should_include = randf() < 0.7  # 70% chance
			"rare":
				var rare_chance = 0.25 + (level * 0.02)  # Starts at 25%, increases with level
				should_include = randf() < rare_chance
			"epic":
				var epic_chance = max(0.05, (level - 5) * 0.02)  # Starts appearing at level 5
				should_include = randf() < epic_chance
			"legendary":
				var legendary_chance = max(0.0, (level - 10) * 0.01)  # Starts appearing at level 10
				should_include = randf() < legendary_chance
			"mythic":
				var mythic_chance = max(0.0, (level - 15) * 0.005)  # Starts appearing at level 15
				should_include = randf() < mythic_chance
		
		if should_include:
			var card_data = upgrade.duplicate(true)
			card_data["key"] = key
			drawn_cards.append(card_data)
			cards_added += 1
	
	# Ensure we always have enough cards by adding common ones if needed
	while drawn_cards.size() < count:
		for key in available_keys:
			if drawn_cards.size() >= count:
				break
			var upgrade = UPGRADES[key]
			if upgrade.rarity == "common":
				var card_data = upgrade.duplicate(true)
				card_data["key"] = key
				# Check if we already have this card
				var already_has = false
				for existing_card in drawn_cards:
					if existing_card.key == key:
						already_has = true
						break
				if not already_has:
					drawn_cards.append(card_data)
	
	# If we still don't have enough, just add random ones
	while drawn_cards.size() < count and drawn_cards.size() < available_keys.size():
		var random_key = available_keys[randi() % available_keys.size()]
		var already_has = false
		for existing_card in drawn_cards:
			if existing_card.key == random_key:
				already_has = true
				break
		if not already_has:
			var card_data = UPGRADES[random_key].duplicate(true)
			card_data["key"] = random_key
			drawn_cards.append(card_data)
	
	return drawn_cards

func get_tripled_cards(count: int, level: int = 1) -> Array[Dictionary]:
	var drawn_cards = get_random_cards(count, level)
	
	# Modify each card for tripled effect
	for card_data in drawn_cards:
		card_data.title = "★ " + card_data.title + " ★"
		card_data.description = "TRIPLED EFFECT: " + card_data.description
	
	return drawn_cards

# Check if upgrade exists
func has_upgrade(key: String) -> bool:
	return UPGRADES.has(key)

# Get upgrade data
func get_upgrade(key: String) -> Dictionary:
	if has_upgrade(key):
		return UPGRADES[key].duplicate(true)
	return {}
