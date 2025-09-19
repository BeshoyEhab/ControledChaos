# UpgradeDB.gd (Global Autoload Script)
extends Node

var UPGRADES = {
	# --- Common Upgrades ---
	"common_speed": {
		"title": "حذاء السرعة", "description": "زيادة سرعة الحركة بنسبة 10%.", "rarity": "common",
		"apply": func(stats): stats.player_speed += 0.1
	},
	"common_health": {
		"title": "درع بسيط", "description": "زيادة الصحة القصوى بنسبة 15%.", "rarity": "common",
		"apply": func(stats): stats.player_max_health += 0.15
	},
	"common_light_damage": {
		"title": "قفازات القوة", "description": "زيادة ضرر الهجوم الخفيف بنسبة 10%.", "rarity": "common",
		"apply": func(stats): stats.player_light_damage += 0.1
	},
	# --- Rare Upgrades ---
	"rare_cooldown": {
		"title": "ساعة أثرية", "description": "تقليل فترة الانتظار للهجوم بنسبة 15%.", "rarity": "rare",
		"apply": func(stats): stats.player_attack_cooldown -= 0.15
	},
	"rare_multishot": {
		"title": "قوس متعدد السهام", "description": "إضافة قذيفة إضافية لهجمات الانتشار.", "rarity": "rare",
		"apply": func(stats): stats.player_projectile_count += 1
	},
	"rare_bounce": {
		"title": "طلاء مطاطي", "description": "منح المقذوفات فرصة 25% للارتداد.", "rarity": "rare",
		"apply": func(stats): stats.player_bounce_chance += 0.25
	},
	# --- Epic Upgrades ---
	"epic_berserk": {
		"title": "غضب المحارب", "description": "زيادة الضرر بنسبة 50%، لكن تقليل الصحة بنسبة 25%.", "rarity": "epic",
		"apply": func(stats): stats.player_light_damage += 0.5; stats.player_heavy_damage += 0.5; stats.player_max_health -= 0.25
	},
	"epic_vampirism": {
		"title": "لعنة مصاص الدماء", "description": "استعادة 5% من الصحة عند قتل عدو.", "rarity": "epic",
		"apply": func(stats): stats.player_lifesteal += 0.05
	},
}

const MERGE_RECIPES = {
	"common_light_damage,common_speed": "merged_blitz_attack",
}

const MERGED_UPGRADES = {
	"merged_blitz_attack": {
		"title": "هجوم خاطف (مدموج)", "description": "كل 1% زيادة في السرعة تمنح 0.5% زيادة في الضرر.", "rarity": "merged",
		"is_passive_effect": true
	}
}

func get_random_cards(count: int) -> Array[Dictionary]:
	var drawn_cards = []
	var card_pool = []
	for key in UPGRADES:
		var rarity = UPGRADES[key].rarity
		if rarity == "common": card_pool.append(key)
		if rarity == "rare" and randf() < 0.4: card_pool.append(key)
		if rarity == "epic" and randf() < 0.15: card_pool.append(key)
	card_pool.shuffle()
	for i in range(min(count, card_pool.size())):
		var card_key = card_pool[i]
		var card_data = UPGRADES[card_key].duplicate()
		card_data["key"] = card_key
		drawn_cards.append(card_data)
	return drawn_cards
