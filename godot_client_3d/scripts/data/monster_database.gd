extends Node
class_name MonsterDatabase

## Полная база данных монстров Isleborn Online
## Согласно GDD: T1-T5, мировые боссы, более 70 видов

var monsters: Dictionary = {}

func _ready() -> void:
	_register_all_monsters()

func _register_all_monsters() -> void:
	# ============================================
	# T1 - МАЛЫЕ (Начальная зона)
	# ============================================
	
	monsters["reef_eel"] = {
		"id": "reef_eel",
		"name": "Рифовый угорь",
		"tier": 1,
		"health": 20.0,
		"damage": 3.0,
		"speed": 3.0,
		"attack_range": 1.5,
		"biomes": ["tropical_shallow"],
		"loot_table": {
			"common": [{"item_id": "eel_meat", "chance": 0.8}],
			"uncommon": [{"item_id": "eel_scale", "chance": 0.2}]
		}
	}
	
	monsters["coral_worm"] = {
		"id": "coral_worm",
		"name": "Коралловый червь",
		"tier": 1,
		"health": 15.0,
		"damage": 2.0,
		"speed": 2.5,
		"attack_range": 1.2,
		"biomes": ["tropical_shallow"],
		"loot_table": {
			"common": [{"item_id": "coral_chunk", "chance": 0.7}]
		}
	}
	
	monsters["small_crab"] = {
		"id": "small_crab",
		"name": "Мелкий краб",
		"tier": 1,
		"health": 18.0,
		"damage": 2.5,
		"speed": 2.0,
		"attack_range": 1.0,
		"biomes": ["tropical_shallow"],
		"loot_table": {
			"common": [{"item_id": "crab_meat", "chance": 0.9}, {"item_id": "crab_shell", "chance": 0.5}]
		}
	}
	
	monsters["claw_raccoon"] = {
		"id": "claw_raccoon",
		"name": "Ловчий рак-щипач",
		"tier": 1,
		"health": 25.0,
		"damage": 4.0,
		"speed": 3.5,
		"attack_range": 1.3,
		"biomes": ["tropical_shallow"],
		"loot_table": {
			"common": [{"item_id": "crab_claw", "chance": 0.6}]
		}
	}
	
	monsters["sawfish_small"] = {
		"id": "sawfish_small",
		"name": "Рыба-пила малая",
		"tier": 1,
		"health": 22.0,
		"damage": 3.5,
		"speed": 4.0,
		"attack_range": 2.0,
		"biomes": ["tropical_shallow"],
		"loot_table": {
			"common": [{"item_id": "saw_tooth", "chance": 0.4}]
		}
	}
	
	monsters["sharkling"] = {
		"id": "sharkling",
		"name": "Акульчик-отступник",
		"tier": 1,
		"health": 30.0,
		"damage": 5.0,
		"speed": 5.0,
		"attack_range": 1.8,
		"biomes": ["tropical_shallow"],
		"loot_table": {
			"common": [{"item_id": "shark_meat", "chance": 0.8}, {"item_id": "shark_tooth", "chance": 0.3}]
		}
	}
	
	monsters["poison_urchin"] = {
		"id": "poison_urchin",
		"name": "Ядовитый морской ёж",
		"tier": 1,
		"health": 12.0,
		"damage": 2.0,
		"speed": 1.0,
		"attack_range": 0.8,
		"biomes": ["tropical_shallow"],
		"abilities": ["poison_spike"],
		"loot_table": {
			"common": [{"item_id": "urchin_spike", "chance": 0.7}, {"item_id": "poison_gland", "chance": 0.3}]
		}
	}
	
	monsters["slippery_bass"] = {
		"id": "slippery_bass",
		"name": "Скользкий окунь-телепорт",
		"tier": 1,
		"health": 16.0,
		"damage": 2.5,
		"speed": 4.5,
		"attack_range": 1.5,
		"biomes": ["tropical_shallow"],
		"abilities": ["teleport_escape"],
		"loot_table": {
			"common": [{"item_id": "bass_meat", "chance": 0.9}]
		}
	}
	
	monsters["sand_jellyfish"] = {
		"id": "sand_jellyfish",
		"name": "Песчаная медуза",
		"tier": 1,
		"health": 14.0,
		"damage": 1.5,
		"speed": 2.5,
		"attack_range": 1.5,
		"biomes": ["tropical_shallow"],
		"abilities": ["sting"],
		"loot_table": {
			"common": [{"item_id": "jellyfish_tentacle", "chance": 0.6}]
		}
	}
	
	monsters["noise_squid"] = {
		"id": "noise_squid",
		"name": "Шумовой кальмарёнок",
		"tier": 1,
		"health": 20.0,
		"damage": 3.0,
		"speed": 3.5,
		"attack_range": 1.8,
		"biomes": ["tropical_shallow"],
		"abilities": ["ink_cloud"],
		"loot_table": {
			"common": [{"item_id": "squid_ink", "chance": 0.5}]
		}
	}
	
	# ============================================
	# T2 - СРЕДНИЕ
	# ============================================
	
	monsters["young_sea_serpent"] = {
		"id": "young_sea_serpent",
		"name": "Молодой морской змей",
		"tier": 2,
		"health": 80.0,
		"damage": 10.0,
		"speed": 4.0,
		"attack_range": 2.5,
		"biomes": ["deep_blue"],
		"loot_table": {
			"common": [{"item_id": "serpent_scale", "chance": 0.9}],
			"uncommon": [{"item_id": "serpent_fang", "chance": 0.4}],
			"rare": [{"item_id": "serpent_essence", "chance": 0.1}]
		}
	}
	
	monsters["electric_ray"] = {
		"id": "electric_ray",
		"name": "Электрический скат",
		"tier": 2,
		"health": 60.0,
		"damage": 8.0,
		"speed": 5.0,
		"attack_range": 3.0,
		"biomes": ["deep_blue"],
		"abilities": ["electric_shock"],
		"loot_table": {
			"common": [{"item_id": "ray_meat", "chance": 0.8}],
			"uncommon": [{"item_id": "electric_organ", "chance": 0.5}]
		}
	}
	
	monsters["crab_brute"] = {
		"id": "crab_brute",
		"name": "Краб-громила",
		"tier": 2,
		"health": 100.0,
		"damage": 12.0,
		"speed": 2.5,
		"attack_range": 2.0,
		"biomes": ["deep_blue"],
		"abilities": ["crush"],
		"loot_table": {
			"common": [{"item_id": "brute_shell", "chance": 0.7}],
			"uncommon": [{"item_id": "heavy_claw", "chance": 0.4}]
		}
	}
	
	monsters["drift_jellyfish"] = {
		"id": "drift_jellyfish",
		"name": "Дрейфующая медуза",
		"tier": 2,
		"health": 50.0,
		"damage": 6.0,
		"speed": 3.0,
		"attack_range": 2.5,
		"biomes": ["deep_blue"],
		"abilities": ["poison_cloud"],
		"loot_table": {
			"common": [{"item_id": "jellyfish_core", "chance": 0.6}]
		}
	}
	
	monsters["acid_moray"] = {
		"id": "acid_moray",
		"name": "Кислотная мурена",
		"tier": 2,
		"health": 70.0,
		"damage": 9.0,
		"speed": 4.5,
		"attack_range": 2.0,
		"biomes": ["deep_blue"],
		"abilities": ["acid_spit"],
		"loot_table": {
			"common": [{"item_id": "moray_tooth", "chance": 0.7}],
			"uncommon": [{"item_id": "acid_gland", "chance": 0.3}]
		}
	}
	
	monsters["sea_wolf"] = {
		"id": "sea_wolf",
		"name": "Морской волк",
		"tier": 2,
		"health": 90.0,
		"damage": 11.0,
		"speed": 6.0,
		"attack_range": 2.5,
		"biomes": ["deep_blue"],
		"abilities": ["pack_hunt"],
		"loot_table": {
			"common": [{"item_id": "wolf_fang", "chance": 0.8}],
			"uncommon": [{"item_id": "wolf_pelt", "chance": 0.4}]
		}
	}
	
	# ============================================
	# T3 - ОПАСНЫЕ
	# ============================================
	
	monsters["giant_shark"] = {
		"id": "giant_shark",
		"name": "Гигантская акула",
		"tier": 3,
		"health": 200.0,
		"damage": 25.0,
		"speed": 7.0,
		"attack_range": 3.5,
		"biomes": ["deep_blue", "mist_sea"],
		"abilities": ["ram", "frenzy"],
		"loot_table": {
			"common": [{"item_id": "shark_fin", "chance": 1.0}],
			"uncommon": [{"item_id": "shark_heart", "chance": 0.6}],
			"rare": [{"item_id": "shark_essence", "chance": 0.2}]
		}
	}
	
	monsters["relic_crab"] = {
		"id": "relic_crab",
		"name": "Реликтовый краб",
		"tier": 3,
		"health": 250.0,
		"damage": 20.0,
		"speed": 3.0,
		"attack_range": 3.0,
		"biomes": ["deep_blue"],
		"abilities": ["armor_break", "earthquake"],
		"loot_table": {
			"uncommon": [{"item_id": "relic_shell", "chance": 0.8}],
			"rare": [{"item_id": "ancient_claw", "chance": 0.4}],
			"epic": [{"item_id": "relic_core", "chance": 0.1}]
		}
	}
	
	monsters["squid_thrower"] = {
		"id": "squid_thrower",
		"name": "Кальмар-метатель",
		"tier": 3,
		"health": 180.0,
		"damage": 22.0,
		"speed": 5.0,
		"attack_range": 4.0,
		"biomes": ["deep_blue", "mist_sea"],
		"abilities": ["tentacle_grab", "ink_bomb"],
		"loot_table": {
			"common": [{"item_id": "squid_tentacle", "chance": 0.9}],
			"rare": [{"item_id": "squid_eye", "chance": 0.3}]
		}
	}
	
	monsters["ancient_moray"] = {
		"id": "ancient_moray",
		"name": "Древняя мурена",
		"tier": 3,
		"health": 220.0,
		"damage": 28.0,
		"speed": 6.0,
		"attack_range": 3.5,
		"biomes": ["deep_blue"],
		"abilities": ["poison_breath", "burrow"],
		"loot_table": {
			"uncommon": [{"item_id": "ancient_tooth", "chance": 0.7}],
			"rare": [{"item_id": "venom_sac", "chance": 0.4}]
		}
	}
	
	# ============================================
	# T4 - ЭЛИТНЫЕ
	# ============================================
	
	monsters["serpent_mastodon"] = {
		"id": "serpent_mastodon",
		"name": "Морской змей-мастодонт",
		"tier": 4,
		"health": 500.0,
		"damage": 50.0,
		"speed": 5.0,
		"attack_range": 5.0,
		"biomes": ["deep_blue", "mist_sea"],
		"abilities": ["water_cyclone", "tail_slam", "roar"],
		"loot_table": {
			"uncommon": [{"item_id": "mastodon_scale", "chance": 1.0}],
			"rare": [{"item_id": "serpent_heart", "chance": 0.6}],
			"epic": [{"item_id": "mastodon_essence", "chance": 0.3}],
			"legendary": [{"item_id": "serpent_crown", "chance": 0.05}]
		}
	}
	
	monsters["storm_crab"] = {
		"id": "storm_crab",
		"name": "Штормовой краб",
		"tier": 4,
		"health": 600.0,
		"damage": 45.0,
		"speed": 4.0,
		"attack_range": 4.5,
		"biomes": ["mist_sea"],
		"abilities": ["lightning_claw", "storm_aura", "thunder_stomp"],
		"loot_table": {
			"rare": [{"item_id": "storm_shell", "chance": 0.8}],
			"epic": [{"item_id": "lightning_core", "chance": 0.4}]
		}
	}
	
	monsters["astral_jellyfish"] = {
		"id": "astral_jellyfish",
		"name": "Астральная медуза",
		"tier": 4,
		"health": 400.0,
		"damage": 40.0,
		"speed": 6.0,
		"attack_range": 5.0,
		"biomes": ["mist_sea"],
		"abilities": ["phase_shift", "mind_control", "astral_blast"],
		"loot_table": {
			"rare": [{"item_id": "astral_tentacle", "chance": 0.9}],
			"epic": [{"item_id": "astral_core", "chance": 0.5}]
		}
	}
	
	# ============================================
	# T5 - БОССЫ
	# ============================================
	
	monsters["kraken"] = {
		"id": "kraken",
		"name": "Кракен",
		"tier": 5,
		"health": 5000.0,
		"damage": 100.0,
		"speed": 4.0,
		"attack_range": 10.0,
		"biomes": ["deep_blue", "blackwater"],
		"is_boss": true,
		"abilities": ["tentacle_swarm", "ink_vortex", "depth_pull", "kraken_roar"],
		"phases": 3,
		"loot_table": {
			"epic": [{"item_id": "kraken_tentacle", "chance": 1.0}],
			"legendary": [{"item_id": "kraken_heart", "chance": 0.8}, {"item_id": "kraken_eye", "chance": 0.5}],
			"unique": [{"item_id": "kraken_crown", "chance": 0.1}]
		}
	}
	
	monsters["leviathan"] = {
		"id": "leviathan",
		"name": "Левиафан",
		"tier": 5,
		"health": 8000.0,
		"damage": 120.0,
		"speed": 5.0,
		"attack_range": 12.0,
		"biomes": ["blackwater"],
		"is_boss": true,
		"abilities": ["whirlpool", "tidal_wave", "depth_breath", "ancient_roar"],
		"phases": 4,
		"loot_table": {
			"legendary": [{"item_id": "leviathan_scale", "chance": 1.0}, {"item_id": "leviathan_heart", "chance": 0.9}],
			"unique": [{"item_id": "leviathan_crown", "chance": 0.15}]
		}
	}
	
	monsters["storm_serpent"] = {
		"id": "storm_serpent",
		"name": "Штормовой Змей",
		"tier": 5,
		"health": 6000.0,
		"damage": 110.0,
		"speed": 7.0,
		"attack_range": 15.0,
		"biomes": ["mist_sea"],
		"is_boss": true,
		"abilities": ["lightning_strike", "storm_breath", "wind_tornado", "storm_eye"],
		"phases": 4,
		"loot_table": {
			"legendary": [{"item_id": "storm_scale", "chance": 1.0}, {"item_id": "storm_heart", "chance": 0.85}],
			"unique": [{"item_id": "storm_crown", "chance": 0.12}]
		}
	}
	
	monsters["abyss_lady"] = {
		"id": "abyss_lady",
		"name": "Владычица Бездны",
		"tier": 5,
		"health": 10000.0,
		"damage": 150.0,
		"speed": 6.0,
		"attack_range": 20.0,
		"biomes": ["blackwater"],
		"is_boss": true,
		"abilities": ["void_blast", "tentacle_realm", "abyss_portal", "mind_shatter", "final_void"],
		"phases": 5,
		"loot_table": {
			"legendary": [{"item_id": "abyss_essence", "chance": 1.0}, {"item_id": "void_core", "chance": 0.95}],
			"unique": [{"item_id": "abyss_crown", "chance": 0.2}]
		}
	}


func get_monster(id: String) -> Dictionary:
	return monsters.get(id, {})


func get_monsters_by_tier(tier: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for monster_id in monsters:
		var monster = monsters[monster_id]
		if monster.get("tier", 0) == tier:
			result.append(monster)
	return result


func get_monsters_by_biome(biome_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for monster_id in monsters:
		var monster = monsters[monster_id]
		var biomes = monster.get("biomes", [])
		if biome_id in biomes:
			result.append(monster)
	return result


func get_boss_monsters() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for monster_id in monsters:
		var monster = monsters[monster_id]
		if monster.get("is_boss", false):
			result.append(monster)
	return result
