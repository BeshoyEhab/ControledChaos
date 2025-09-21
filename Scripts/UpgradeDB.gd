# UpgradeDB.gd
extends Node

var UPGRADES = {
	# --- Common Upgrades ---
	"common_speed": {
		"title": "Speed Boots", "description": "Increases movement speed.", "rarity": "Common",
		"apply": func(stats): stats.player_speed *= 1.1
	},
	"common_damage": {
		"title": "Power Gloves", "description": "Increases damage.", "rarity": "Common",
		"apply": func(stats): stats.player_damage *= 1.1
	},

	# --- Rare Upgrades ---
	"rare_cooldown": {
		"title": "Ancient Watch", "description": "Reduces attack cooldown (faster attacks).", "rarity": "Rare",
		"apply": func(stats): stats.player_cooldown *= 1.15 # Multiplier is good because it's used in division
	},
	"rare_multishot": {
		"title": "Multi-Shot Bow", "description": "Adds an extra projectile to spread attacks.", "rarity": "Rare",
		"apply": func(stats): stats.player_projectile_count += 1
	},

	# --- Epic Upgrades ---
	"epic_vampirism": {
		"title": "Vampiric Curse", "description": "Heal for a small amount on enemy kill.", "rarity": "Epic",
		"apply": func(stats): stats.player_lifesteal += 0.05
	},
}

# --- Helper function to get random cards ---
func get_random_cards(count: int) -> Array:
	var drawn_cards = []
	var card_pool = []
	for key in UPGRADES:
		var rarity = UPGRADES[key].rarity
		if rarity == "Common": card_pool.append(key)
		if rarity == "Rare" and randf() < 0.4: card_pool.append(key)
		if rarity == "Epic" and randf() < 0.15: card_pool.append(key)
	
	card_pool.shuffle()

	for i in range(min(count, card_pool.size())):
		var card_key = card_pool[i]
		var card_data = UPGRADES[card_key].duplicate()
		card_data["key"] = card_key
		drawn_cards.append(card_data)
		
	return drawn_cards
