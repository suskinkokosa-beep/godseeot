extends Node
class_name ExpandedItemDatabase

## Расширенная база данных предметов с уровнями и редкостью
## Дополняет основную ItemDatabase

static func register_expanded_items(item_db: Dictionary) -> void:
	_register_weapons_by_level(item_db)
	_register_armor_by_level(item_db)
	_register_accessories_by_level(item_db)

## Оружие по уровням (1-50)
static func _register_weapons_by_level(items: Dictionary) -> void:
	# ========== УРОВЕНЬ 1-10 ==========
	
	# Обычное
	items["stone_knife"].merge({
		"level": 1,
		"required_level": 1
	})
	
	items["wooden_sword"].merge({
		"level": 3,
		"required_level": 3
	})
	
	# Редкое (небольшой бонус +10%)
	items["sea_bone_dagger"] = {
		"id": "sea_bone_dagger",
		"name": "Кинжал из кости моря",
		"type": "weapon",
		"equipment_slot": "main_hand",
		"rarity": "rare",
		"level": 5,
		"required_level": 5,
		"weight": 0.8,
		"max_stack": 1,
		"sell_price": 150,
		"description": "Острый кинжал из кости морского монстра",
		"stats": {
			"damage": 25.0,
			"attack_speed": 1.3,
			"agility": 3.0
		},
		"enhancement_level": 0
	}
	
	# Легендарное (большой бонус +25%)
	items["coral_blade"] = {
		"id": "coral_blade",
		"name": "Коралловый клинок",
		"type": "weapon",
		"equipment_slot": "main_hand",
		"rarity": "legendary",
		"level": 8,
		"required_level": 8,
		"weight": 1.2,
		"max_stack": 1,
		"sell_price": 500,
		"description": "Легендарный меч из живого коралла",
		"stats": {
			"damage": 40.0,
			"attack_speed": 1.1,
			"strength": 5.0,
			"vitality": 3.0
		},
		"enhancement_level": 0
	}
	
	# ========== УРОВЕНЬ 11-25 ==========
	
	items["iron_sword"].merge({
		"level": 12,
		"required_level": 12
	})
	
	# Редкое
	items["steel_cutlass"] = {
		"id": "steel_cutlass",
		"name": "Стальная абордажная сабля",
		"type": "weapon",
		"equipment_slot": "main_hand",
		"rarity": "rare",
		"level": 15,
		"required_level": 15,
		"weight": 2.5,
		"max_stack": 1,
		"sell_price": 800,
		"description": "Испытанная в боях сабля",
		"stats": {
			"damage": 55.0,
			"attack_speed": 1.0,
			"strength": 5.0,
			"agility": 2.0
		},
		"enhancement_level": 0
	}
	
	# Легендарное
	items["tidecaller"] = {
		"id": "tidecaller",
		"name": "Призыватель приливов",
		"type": "weapon",
		"equipment_slot": "main_hand",
		"rarity": "legendary",
		"level": 20,
		"required_level": 20,
		"weight": 3.0,
		"max_stack": 1,
		"sell_price": 2500,
		"description": "Меч, впитавший силу океана",
		"stats": {
			"damage": 80.0,
			"attack_speed": 1.2,
			"strength": 10.0,
			"intelligence": 8.0,
			"special_effect": "water_damage"
		},
		"enhancement_level": 0
	}
	
	# Мифическое (особый бонус +50%)
	items["abyss_rend"] = {
		"id": "abyss_rend",
		"name": "Раздиратель бездны",
		"type": "weapon",
		"equipment_slot": "main_hand",
		"rarity": "mythic",
		"level": 25,
		"required_level": 25,
		"weight": 4.0,
		"max_stack": 1,
		"sell_price": 10000,
		"description": "Мифический клинок из самой глубины океана",
		"stats": {
			"damage": 120.0,
			"attack_speed": 1.0,
			"strength": 15.0,
			"intelligence": 10.0,
			"luck": 10.0,
			"special_effect": "void_damage",
			"lifesteal": 0.1
		},
		"enhancement_level": 0
	}
	
	# ========== УРОВЕНЬ 26-50 ==========
	
	# Легендарное
	items["leviathan_fang"] = {
		"id": "leviathan_fang",
		"name": "Клык левиафана",
		"type": "weapon",
		"equipment_slot": "main_hand",
		"rarity": "legendary",
		"level": 35,
		"required_level": 35,
		"weight": 5.0,
		"max_stack": 1,
		"sell_price": 8000,
		"description": "Оружие из клыка древнего левиафана",
		"stats": {
			"damage": 150.0,
			"attack_speed": 0.9,
			"strength": 20.0,
			"vitality": 15.0,
			"special_effect": "fear_aura"
		},
		"enhancement_level": 0
	}
	
	# Мифическое
	items["ocean_heart"] = {
		"id": "ocean_heart",
		"name": "Сердце океана",
		"type": "weapon",
		"equipment_slot": "main_hand",
		"rarity": "mythic",
		"level": 45,
		"required_level": 45,
		"weight": 3.5,
		"max_stack": 1,
		"sell_price": 25000,
		"description": "Оружие, содержащее саму суть океана",
		"stats": {
			"damage": 200.0,
			"attack_speed": 1.3,
			"strength": 25.0,
			"intelligence": 20.0,
			"vitality": 20.0,
			"luck": 15.0,
			"special_effect": "ocean_mastery",
			"mana_restore": 5.0
		},
		"enhancement_level": 0
	}

## Броня по уровням
static func _register_armor_by_level(items: Dictionary) -> void:
	# ========== ШЛЕМЫ ==========
	
	items["cloth_helmet"].merge({
		"level": 1,
		"required_level": 1
	})
	
	items["leather_helmet"].merge({
		"level": 5,
		"required_level": 5
	})
	
	# Редкое
	items["coral_helmet"] = {
		"id": "coral_helmet",
		"name": "Коралловый шлем",
		"type": "armor",
		"equipment_slot": "helmet",
		"rarity": "rare",
		"level": 10,
		"required_level": 10,
		"weight": 1.5,
		"max_stack": 1,
		"sell_price": 400,
		"description": "Прочный шлем из коралла",
		"stats": {
			"defense": 25.0,
			"vitality": 8.0,
			"intelligence": 3.0
		},
		"enhancement_level": 0
	}
	
	# Легендарное
	items["tidal_crown"] = {
		"id": "tidal_crown",
		"name": "Корона приливов",
		"type": "armor",
		"equipment_slot": "helmet",
		"rarity": "legendary",
		"level": 20,
		"required_level": 20,
		"weight": 2.0,
		"max_stack": 1,
		"sell_price": 3000,
		"description": "Легендарная корона морского короля",
		"stats": {
			"defense": 40.0,
			"vitality": 15.0,
			"intelligence": 12.0,
			"mana_regen": 2.0
		},
		"enhancement_level": 0
	}
	
	# Мифическое
	items["void_mask"] = {
		"id": "void_mask",
		"name": "Маска бездны",
		"type": "armor",
		"equipment_slot": "helmet",
		"rarity": "mythic",
		"level": 40,
		"required_level": 40,
		"weight": 1.8,
		"max_stack": 1,
		"sell_price": 15000,
		"description": "Маска, открывающая видение бездны",
		"stats": {
			"defense": 60.0,
			"vitality": 25.0,
			"intelligence": 20.0,
			"perception": 15.0,
			"special_effect": "true_sight"
		},
		"enhancement_level": 0
	}
	
	# ========== НАГРУДНИКИ ==========
	
	items["cloth_chest"].merge({
		"level": 1,
		"required_level": 1
	})
	
	items["leather_chest"].merge({
		"level": 5,
		"required_level": 5
	})
	
	# Редкое
	items["sea_scale_armor"] = {
		"id": "sea_scale_armor",
		"name": "Чешуйчатый доспех",
		"type": "armor",
		"equipment_slot": "chest",
		"rarity": "rare",
		"level": 12,
		"required_level": 12,
		"weight": 4.0,
		"max_stack": 1,
		"sell_price": 600,
		"description": "Доспех из чешуи морского дракона",
		"stats": {
			"defense": 35.0,
			"vitality": 12.0,
			"agility": -1.0
		},
		"enhancement_level": 0
	}
	
	# Легендарное
	items["kraken_plate"] = {
		"id": "kraken_plate",
		"name": "Латы кракена",
		"type": "armor",
		"equipment_slot": "chest",
		"rarity": "legendary",
		"level": 25,
		"required_level": 25,
		"weight": 6.0,
		"max_stack": 1,
		"sell_price": 5000,
		"description": "Мощные латы из панциря кракена",
		"stats": {
			"defense": 60.0,
			"vitality": 25.0,
			"strength": 10.0,
			"special_effect": "damage_reflection"
		},
		"enhancement_level": 0
	}
	
	# Мифическое
	items["abyss_guardian"] = {
		"id": "abyss_guardian",
		"name": "Страж бездны",
		"type": "armor",
		"equipment_slot": "chest",
		"rarity": "mythic",
		"level": 45,
		"required_level": 45,
		"weight": 7.0,
		"max_stack": 1,
		"sell_price": 20000,
		"description": "Доспех, сотканный из самой тьмы океана",
		"stats": {
			"defense": 90.0,
			"vitality": 40.0,
			"strength": 20.0,
			"intelligence": 15.0,
			"special_effect": "damage_immunity_chance"
		},
		"enhancement_level": 0
	}

## Аксессуары по уровням
static func _register_accessories_by_level(items: Dictionary) -> void:
	items["copper_ring"].merge({
		"level": 1,
		"required_level": 1
	})
	
	# Редкое
	items["coral_ring"] = {
		"id": "coral_ring",
		"name": "Коралловое кольцо",
		"type": "accessory",
		"rarity": "rare",
		"level": 8,
		"required_level": 8,
		"weight": 0.1,
		"max_stack": 1,
		"sell_price": 300,
		"description": "Кольцо из живого коралла",
		"stats": {
			"luck": 8.0,
			"perception": 5.0,
			"focus": 3.0
		},
		"enhancement_level": 0
	}
	
	# Легендарное
	items["tidecaller_ring"] = {
		"id": "tidecaller_ring",
		"name": "Кольцо призывателя приливов",
		"type": "accessory",
		"rarity": "legendary",
		"level": 20,
		"required_level": 20,
		"weight": 0.1,
		"max_stack": 1,
		"sell_price": 2000,
		"description": "Кольцо, усиливающее связь с океаном",
		"stats": {
			"luck": 15.0,
			"intelligence": 10.0,
			"mana_regen": 3.0,
			"special_effect": "water_resistance"
		},
		"enhancement_level": 0
	}
	
	# Мифическое
	items["ocean_soul"] = {
		"id": "ocean_soul",
		"name": "Душа океана",
		"type": "accessory",
		"rarity": "mythic",
		"level": 50,
		"required_level": 50,
		"weight": 0.2,
		"max_stack": 1,
		"sell_price": 30000,
		"description": "Амулет, содержащий душу самого океана",
		"stats": {
			"luck": 25.0,
			"vitality": 30.0,
			"intelligence": 25.0,
			"all_stats": 10.0,
			"special_effect": "ocean_control"
		},
		"enhancement_level": 0
	}

