extends Node
class_name ShipDatabase

## Полная база данных кораблей Isleborn Online
## Согласно GDD: от плота до флагмана гильдии

var ships: Dictionary = {}

func _ready() -> void:
	_register_all_ships()

func _register_all_ships() -> void:
	# ============================================
	# РАННИЕ КОРАБЛИ
	# ============================================
	
	ships["raft"] = {
		"id": "raft",
		"name": "Плот",
		"class": "RAFT",
		"tier": 1,
		"base_health": 50.0,
		"base_speed": 3.0,
		"cargo_capacity": 2,
		"crew_capacity": 1,
		"weapon_slots": 0,
		"module_slots": 0,
		"cost": {
			"palm_wood": 10
		},
		"required_island_level": 1,
		"description": "Простой плот для начала путешествий"
	}
	
	ships["canoe"] = {
		"id": "canoe",
		"name": "Каноэ",
		"class": "CANOE",
		"tier": 1,
		"base_health": 70.0,
		"base_speed": 4.0,
		"cargo_capacity": 3,
		"crew_capacity": 1,
		"weapon_slots": 0,
		"module_slots": 1,
		"cost": {
			"palm_wood": 15,
			"rope": 2
		},
		"required_island_level": 2,
		"description": "Улучшенная версия плота с вёслами"
	}
	
	ships["fishing_boat"] = {
		"id": "fishing_boat",
		"name": "Рыбацкая лодка",
		"class": "BOAT",
		"tier": 1,
		"base_health": 100.0,
		"base_speed": 4.5,
		"cargo_capacity": 5,
		"crew_capacity": 2,
		"weapon_slots": 0,
		"module_slots": 2,
		"cost": {
			"palm_wood": 25,
			"rope": 5,
			"fabric": 3
		},
		"required_island_level": 3,
		"description": "Лодка для рыбалки и разведки"
	}
	
	# ============================================
	# СРЕДНИЕ КОРАБЛИ
	# ============================================
	
	ships["barge"] = {
		"id": "barge",
		"name": "Баркас",
		"class": "BOAT",
		"tier": 2,
		"base_health": 200.0,
		"base_speed": 5.0,
		"cargo_capacity": 10,
		"crew_capacity": 3,
		"weapon_slots": 1,
		"module_slots": 3,
		"cost": {
			"wood": 50,
			"metal": 10,
			"rope": 10,
			"fabric": 8
		},
		"required_island_level": 5,
		"required_building": "shipyard_l1",
		"description": "Торговое судно с местом для груза"
	}
	
	ships["schooner"] = {
		"id": "schooner",
		"name": "Шхуна",
		"class": "SCHOONER",
		"tier": 2,
		"base_health": 300.0,
		"base_speed": 6.5,
		"cargo_capacity": 8,
		"crew_capacity": 4,
		"weapon_slots": 2,
		"module_slots": 4,
		"cost": {
			"wood": 80,
			"metal": 20,
			"rope": 15,
			"fabric": 12
		},
		"required_island_level": 8,
		"required_building": "shipyard_l2",
		"description": "Быстрое судно для исследования и боя"
	}
	
	ships["patrol_boat"] = {
		"id": "patrol_boat",
		"name": "Патрульный катер",
		"class": "BOAT",
		"tier": 2,
		"base_health": 250.0,
		"base_speed": 7.0,
		"cargo_capacity": 5,
		"crew_capacity": 3,
		"weapon_slots": 3,
		"module_slots": 3,
		"cost": {
			"wood": 60,
			"metal": 30,
			"rope": 10
		},
		"required_island_level": 7,
		"required_building": "shipyard_l2",
		"description": "Быстрое судно для патрулирования"
	}
	
	ships["trade_sloop"] = {
		"id": "trade_sloop",
		"name": "Торговая шаланда",
		"class": "BOAT",
		"tier": 2,
		"base_health": 350.0,
		"base_speed": 5.5,
		"cargo_capacity": 20,
		"crew_capacity": 5,
		"weapon_slots": 1,
		"module_slots": 5,
		"cost": {
			"wood": 100,
			"metal": 15,
			"rope": 20,
			"fabric": 15
		},
		"required_island_level": 6,
		"required_building": "shipyard_l2",
		"description": "Большое торговое судно"
	}
	
	# ============================================
	# ПОЗДНИЕ КОРАБЛИ
	# ============================================
	
	ships["caravel"] = {
		"id": "caravel",
		"name": "Каравелла",
		"class": "CARAVEL",
		"tier": 3,
		"base_health": 600.0,
		"base_speed": 6.0,
		"cargo_capacity": 15,
		"crew_capacity": 8,
		"weapon_slots": 4,
		"module_slots": 6,
		"cost": {
			"wood": 200,
			"metal": 50,
			"rope": 30,
			"fabric": 25,
			"rare_wood": 10
		},
		"required_island_level": 15,
		"required_building": "shipyard_l3",
		"description": "Мощное судно для дальних плаваний"
	}
	
	ships["frigate"] = {
		"id": "frigate",
		"name": "Фрегат",
		"class": "FRIGATE",
		"tier": 3,
		"base_health": 800.0,
		"base_speed": 7.0,
		"cargo_capacity": 12,
		"crew_capacity": 12,
		"weapon_slots": 6,
		"module_slots": 8,
		"cost": {
			"wood": 300,
			"metal": 100,
			"rope": 40,
			"fabric": 30,
			"rare_metal": 20
		},
		"required_island_level": 20,
		"required_building": "shipyard_l4",
		"description": "Боевое судно с мощным вооружением"
	}
	
	ships["galleon"] = {
		"id": "galleon",
		"name": "Галеон",
		"class": "GALLEON",
		"tier": 4,
		"base_health": 1200.0,
		"base_speed": 5.5,
		"cargo_capacity": 30,
		"crew_capacity": 20,
		"weapon_slots": 8,
		"module_slots": 10,
		"cost": {
			"wood": 500,
			"metal": 200,
			"rope": 60,
			"fabric": 50,
			"rare_wood": 50,
			"rare_metal": 50
		},
		"required_island_level": 30,
		"required_building": "shipyard_l5",
		"description": "Огромное торговое и боевое судно"
	}
	
	ships["flagship"] = {
		"id": "flagship",
		"name": "Флагман гильдии",
		"class": "FLAGSHIP",
		"tier": 5,
		"base_health": 2000.0,
		"base_speed": 6.0,
		"cargo_capacity": 25,
		"crew_capacity": 30,
		"weapon_slots": 12,
		"module_slots": 15,
		"cost": {
			"wood": 1000,
			"metal": 500,
			"rope": 100,
			"fabric": 100,
			"rare_wood": 100,
			"rare_metal": 100,
			"epic_materials": 50
		},
		"required_island_level": 40,
		"required_building": "shipyard_l6",
		"required_guild_level": 10,
		"description": "Мощнейший корабль для гильдий",
		"is_guild_only": true
	}
	
	# ============================================
	# УНИКАЛЬНЫЕ КОРАБЛИ
	# ============================================
	
	ships["abyss_runner"] = {
		"id": "abyss_runner",
		"name": "Abyss Runner",
		"class": "MAGICAL",
		"tier": 5,
		"base_health": 1500.0,
		"base_speed": 8.0,
		"cargo_capacity": 10,
		"crew_capacity": 8,
		"weapon_slots": 6,
		"module_slots": 8,
		"cost": {
			"rare_wood": 200,
			"rare_metal": 150,
			"void_crystal": 50,
			"abyss_essence": 30
		},
		"required_island_level": 45,
		"required_building": "magical_shipyard",
		"description": "Магический корабль для плавания в Blackwater",
		"special_abilities": ["blackwater_resistance", "void_portal"]
	}


func get_ship(id: String) -> Dictionary:
	return ships.get(id, {})


func get_ships_by_tier(tier: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for ship_id in ships:
		var ship = ships[ship_id]
		if ship.get("tier", 0) == tier:
			result.append(ship)
	return result


func get_ships_by_class(ship_class: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for ship_id in ships:
		var ship = ships[ship_id]
		if ship.get("class", "") == ship_class:
			result.append(ship)
	return result


func get_ships_for_island_level(island_level: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for ship_id in ships:
		var ship = ships[ship_id]
		var required_level = ship.get("required_island_level", 1)
		if island_level >= required_level:
			result.append(ship)
	return result


func get_cost_formula(ship_id: String) -> float:
	var ship = get_ship(ship_id)
	if ship.is_empty():
		return 0.0
	
	var cost = ship.get("cost", {})
	var total_value = 0.0
	
	# Упрощённая формула стоимости
	for resource_id in cost.keys():
		var amount = cost[resource_id]
		# TODO: Умножить на стоимость ресурса в экономике
		total_value += amount
	
	return total_value
