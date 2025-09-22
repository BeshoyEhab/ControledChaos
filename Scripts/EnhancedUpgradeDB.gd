# EnhancedUpgradeDB.gd - Enhanced upgrade system with weapon integration
extends Node

# Enhanced upgrade database with more comprehensive upgrades
var UPGRADES: Dictionary = {
	# === COMMON UPGRADES ===
	"common_speed": {
		"title": "Speed Boots",
		"description": "Increases movement speed by 15%.",
		"rarity": "common",
		"icon_path": "res://icons/speed_boots.png",
		"type": "stat",
		"stat": "speed",
		"value": 0.15,
		"operation": "multiply"
	},
	"common_damage": {
		"title": "Power Gloves",
		"description": "Increases damage by 15%.",
		"rarity": "common",
		"icon_path": "res://icons/power_gloves.png",
		"type": "stat",
		"stat": "damage",
		"value": 0.15,
		"operation": "multiply"
	},
	"common_health": {
		"title": "Health Potion",
		"description": "Increases maximum health by 25.",
		"rarity": "common",
		"icon_path": "res://icons/health_potion.png",
		"type": "stat",
		"stat": "max_health",
		"value": 25.0,
		"operation": "add"
	},
	"common_projectile_size": {
		"title": "Bigger Bullets",
		"description": "Increases projectile size by 20%.",
		"rarity": "common",
		"icon_path": "res://icons/big_bullets.png",
		"type": "stat",
		"stat": "projectile_size",
		"value": 0.2,
		"operation": "multiply"
	},
	"common_projectile_speed": {
		"title": "Faster Bullets",
		"description": "Increases projectile speed by 20%.",
		"rarity": "common",
		"icon_path": "res://icons/fast_bullets.png",
		"type": "stat",
		"stat": "projectile_speed",
		"value": 0.2,
		"operation": "multiply"
	},
	
	# === UNCOMMON UPGRADES ===
	"uncommon_cooldown": {
		"title": "Ancient Watch",
		"description": "Reduces attack cooldown by 20%.",
		"rarity": "uncommon",
		"icon_path": "res://icons/ancient_watch.png",
		"type": "stat",
		"stat": "cooldown",
		"value": 0.2,
		"operation": "multiply"
	},
	"uncommon_multishot": {
		"title": "Multi-Shot Bow",
		"description": "Adds an extra projectile.",
		"rarity": "uncommon",
		"icon_path": "res://icons/multishot_bow.png",
		"type": "stat",
		"stat": "projectile_count",
		"value": 1.0,
		"operation": "add"
	},
	"uncommon_armor": {
		"title": "Steel Plates",
		"description": "Increases armor by 10.",
		"rarity": "uncommon",
		"icon_path": "res://icons/steel_plates.png",
		"type": "stat",
		"stat": "armor",
		"value": 10.0,
		"operation": "add"
	},
	"uncommon_projectile_lifetime": {
		"title": "Persistent Bullets",
		"description": "Increases projectile lifetime by 50%.",
		"rarity": "uncommon",
		"icon_path": "res://icons/persistent_bullets.png",
		"type": "stat",
		"stat": "projectile_lifetime",
		"value": 0.5,
		"operation": "multiply"
	},
	
	# === RARE UPGRADES ===
	"rare_vampirism": {
		"title": "Vampiric Curse",
		"description": "Heal for 8% of max health on enemy kill.",
		"rarity": "rare",
		"icon_path": "res://icons/vampiric_curse.png",
		"type": "stat",
		"stat": "lifesteal",
		"value": 0.08,
		"operation": "add"
	},
	"rare_bounce": {
		"title": "Ricochet Rounds",
		"description": "Projectiles have 40% chance to bounce.",
		"rarity": "rare",
		"icon_path": "res://icons/ricochet.png",
		"type": "stat",
		"stat": "projectile_bounce_chance",
		"value": 0.4,
		"operation": "add"
	},
	"rare_crit": {
		"title": "Lucky Strike",
		"description": "15% critical hit chance with 2x damage.",
		"rarity": "rare",
		"icon_path": "res://icons/lucky_strike.png",
		"type": "stat",
		"stat": "crit_chance",
		"value": 0.15,
		"operation": "add"
	},
	"rare_penetration": {
		"title": "Piercing Shots",
		"description": "Projectiles can pierce through 2 enemies.",
		"rarity": "rare",
		"icon_path": "res://icons/piercing_shots.png",
		"type": "stat",
		"stat": "projectile_penetration",
		"value": 2.0,
		"operation": "add"
	},
	"rare_dodge": {
		"title": "Shadow Step",
		"description": "15% chance to dodge incoming damage.",
		"rarity": "rare",
		"icon_path": "res://icons/shadow_step.png",
		"type": "stat",
		"stat": "dodge_chance",
		"value": 0.15,
		"operation": "add"
	},
	
	# === EPIC UPGRADES ===
	"epic_time_slow": {
		"title": "Chronos Blessing",
		"description": "Slows time by 25% permanently.",
		"rarity": "epic",
		"icon_path": "res://icons/chronos_blessing.png",
		"type": "stat",
		"stat": "time_scale",
		"value": 0.75,
		"operation": "multiply"
	},
	"epic_multishot": {
		"title": "Arrow Storm",
		"description": "Fire 3 additional projectiles.",
		"rarity": "epic",
		"icon_path": "res://icons/arrow_storm.png",
		"type": "stat",
		"stat": "projectile_count",
		"value": 3.0,
		"operation": "add"
	},
	"epic_explosive": {
		"title": "Explosive Rounds",
		"description": "Projectiles explode on impact with 30 radius.",
		"rarity": "epic",
		"icon_path": "res://icons/explosive_rounds.png",
		"type": "stat",
		"stat": "projectile_explosive",
		"value": 1.0,
		"operation": "set"
	},
	"epic_explosion_radius": {
		"title": "Big Bang",
		"description": "Increases explosion radius by 50%.",
		"rarity": "epic",
		"icon_path": "res://icons/big_bang.png",
		"type": "stat",
		"stat": "projectile_explosion_radius",
		"value": 30.0,
		"operation": "add"
	},
	"epic_homing": {
		"title": "Seeking Missiles",
		"description": "Projectiles home in on enemies.",
		"rarity": "epic",
		"icon_path": "res://icons/seeking_missiles.png",
		"type": "stat",
		"stat": "projectile_homing",
		"value": 1.0,
		"operation": "set"
	},
	
	# === LEGENDARY UPGRADES ===
	"legendary_godmode": {
		"title": "Divine Protection",
		"description": "Become invulnerable for 4 seconds after taking damage.",
		"rarity": "legendary",
		"icon_path": "res://icons/divine_protection.png",
		"type": "stat",
		"stat": "invulnerability_duration",
		"value": 4.0,
		"operation": "set"
	},
	"legendary_time_stop": {
		"title": "Time Dilation",
		"description": "Slows time by 60% for 5 seconds when hit.",
		"rarity": "legendary",
		"icon_path": "res://icons/time_dilation.png",
		"type": "temporary",
		"effect_name": "time_dilation",
		"stat_modifications": {"time_scale": 0.4},
		"duration": 5.0
	},
	"legendary_berserker": {
		"title": "Berserker Rage",
		"description": "Gain 50% damage and speed for 10 seconds after killing an enemy.",
		"rarity": "legendary",
		"icon_path": "res://icons/berserker_rage.png",
		"type": "kill_effect",
		"stat_modifications": {"damage": 1.5, "speed": 1.5},
		"duration": 10.0
	},
	"legendary_phoenix": {
		"title": "Phoenix Rebirth",
		"description": "Revive with full health when you die (once per game).",
		"rarity": "legendary",
		"icon_path": "res://icons/phoenix_rebirth.png",
		"type": "special",
		"effect": "revive_on_death"
	},
	
	# === MYTHIC UPGRADES ===
	"mythic_omnipotence": {
		"title": "Omnipotence",
		"description": "All stats increased by 100% for 15 seconds.",
		"rarity": "mythic",
		"icon_path": "res://icons/omnipotence.png",
		"type": "temporary",
		"effect_name": "omnipotence",
		"stat_modifications": {
			"damage": 2.0,
			"speed": 2.0,
			"projectile_count": 5.0,
			"projectile_size": 2.0,
			"projectile_speed": 2.0
		},
		"duration": 15.0
	},
	"mythic_chaos": {
		"title": "Chaos Control",
		"description": "Randomly switches between all weapons every 3 seconds.",
		"rarity": "mythic",
		"icon_path": "res://icons/chaos_control.png",
		"type": "special",
		"effect": "random_weapon_switch",
		"duration": 30.0
	},
	"mythic_immortality": {
		"title": "Immortality",
		"description": "Cannot die for 10 seconds.",
		"rarity": "mythic",
		"icon_path": "res://icons/immortality.png",
		"type": "temporary",
		"effect_name": "immortality",
		"stat_modifications": {"invulnerability_duration": 10.0},
		"duration": 10.0
	}
}

# Weapon-specific upgrades
var WEAPON_UPGRADES: Dictionary = {
	"shotgun_spread": {
		"title": "Wide Spread",
		"description": "Increases shotgun spread by 50%.",
		"rarity": "uncommon",
		"weapon": "shotgun",
		"stat": "spread_angle",
		"value": 2.15,
		"operation": "add"
	},
	"shotgun_pellets": {
		"title": "More Pellets",
		"description": "Adds 2 more pellets to shotgun.",
		"rarity": "rare",
		"weapon": "shotgun",
		"stat": "burst_count",
		"value": 2.0,
		"operation": "add"
	},
	"rifle_burst": {
		"title": "Burst Fire",
		"description": "Rifle fires 3 rounds in quick succession.",
		"rarity": "rare",
		"weapon": "rifle",
		"stat": "burst_count",
		"value": 3.0,
		"operation": "set"
	},
	"staff_homing": {
		"title": "Guided Missiles",
		"description": "Staff projectiles home in on enemies.",
		"rarity": "epic",
		"weapon": "staff",
		"stat": "projectile_homing",
		"value": 1.0,
		"operation": "set"
	},
	"gun_rapid_fire": {
		"title": "Rapid Fire",
		"description": "Reduces gun cooldown by 50%.",
		"rarity": "uncommon",
		"weapon": "gun",
		"stat": "cooldown",
		"value": 0.5,
		"operation": "multiply"
	}
}

# Upgrade generation system
func get_random_cards(count: int, level: int = 1, exclude_owned: Array[String] = []) -> Array[Dictionary]:
	var drawn_cards: Array[Dictionary] = []
	var available_upgrades = UPGRADES.keys()
	
	# Remove owned upgrades from available pool
	for owned_upgrade in exclude_owned:
		available_upgrades.erase(owned_upgrade)
	
	available_upgrades.shuffle()
	
	var cards_added = 0
	for key in available_upgrades:
		if cards_added >= count:
			break
			
		var upgrade = UPGRADES[key]
		var rarity = upgrade.rarity
		var should_include = false
		
		# Level-based rarity chances
		match rarity:
			"common":
				should_include = randf() < 0.8  # 80% chance
			"uncommon":
				var chance = 0.3 + (level * 0.02)  # 30% base, increases with level
				should_include = randf() < chance
			"rare":
				var chance = max(0.1, (level - 3) * 0.03)  # Starts at level 3
				should_include = randf() < chance
			"epic":
				var chance = max(0.02, (level - 8) * 0.02)  # Starts at level 8
				should_include = randf() < chance
			"legendary":
				var chance = max(0.005, (level - 15) * 0.01)  # Starts at level 15
				should_include = randf() < chance
			"mythic":
				var chance = max(0.001, (level - 25) * 0.005)  # Starts at level 25
				should_include = randf() < chance
		
		if should_include:
			var card_data = upgrade.duplicate(true)
			card_data["key"] = key
			drawn_cards.append(card_data)
			cards_added += 1
	
	# Ensure we have enough cards by adding common ones if needed
	while drawn_cards.size() < count:
		for key in available_upgrades:
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
	
	return drawn_cards

# Weapon upgrade generation
func get_weapon_upgrades(weapon_name: StringName, count: int = 2) -> Array[Dictionary]:
	var weapon_upgrades_list: Array[Dictionary] = []
	
	for key in WEAPON_UPGRADES:
		var upgrade = WEAPON_UPGRADES[key]
		if upgrade.get("weapon", "") == weapon_name:
			var card_data = upgrade.duplicate(true)
			card_data["key"] = key
			weapon_upgrades_list.append(card_data)
	
	weapon_upgrades_list.shuffle()
	return weapon_upgrades_list.slice(0, count)

# Upgrade application
func apply_upgrade(upgrade_key: String) -> bool:
	if not UPGRADES.has(upgrade_key):
		print("Warning: Upgrade '", upgrade_key, "' not found")
		return false
	
	var upgrade_data = UPGRADES[upgrade_key]
	
	# Apply upgrade through EnhancedStatsManager
	var enhanced_stats_manager = preload("res://Scripts/EnhancedStatsManager.gd").instance
	if enhanced_stats_manager:
		return enhanced_stats_manager.apply_upgrade(upgrade_data)
	
	# Fallback to legacy system
	if StatsManager:
		StatsManager.apply_upgrade(upgrade_key)
		return true
	
	return false

# Utility functions
func get_upgrade_info(upgrade_key: String) -> Dictionary:
	return UPGRADES.get(upgrade_key, {})

func has_upgrade(upgrade_key: String) -> bool:
	return UPGRADES.has(upgrade_key)

func get_upgrades_by_rarity(rarity: String) -> Array[String]:
	var upgrades: Array[String] = []
	for key in UPGRADES:
		if UPGRADES[key].rarity == rarity:
			upgrades.append(key)
	return upgrades

func get_upgrade_rarity_chance(rarity: String, level: int) -> float:
	match rarity:
		"common":
			return 0.8
		"uncommon":
			return 0.3 + (level * 0.02)
		"rare":
			return max(0.1, (level - 3) * 0.03)
		"epic":
			return max(0.02, (level - 8) * 0.02)
		"legendary":
			return max(0.005, (level - 15) * 0.01)
		"mythic":
			return max(0.001, (level - 25) * 0.005)
		_:
			return 0.0
