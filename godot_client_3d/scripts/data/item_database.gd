extends Node
class_name ItemDatabase

## Центральный реестр всех предметов Isleborn Online
## Поддерживает: оружие, броню, аксессуары, ресурсы, материалы
## Все экипируемые предметы имеют уровень и редкость

var items: Dictionary = {}

func _ready() -> void:
	_register_all_items()

func _register_all_items() -> void:
	_register_resources()
	_register_weapons()
	_register_armor()
	_register_accessories()
	_register_tools()
	_register_consumables()
	# Регистрируем расширенные предметы
	ExpandedItemDatabase.register_expanded_items(items)

## ============================================
## РЕСУРСЫ (Материалы для крафта)
## ============================================

func _register_resources() -> void:
	# Базовые ресурсы
	items["palm_wood"] = {
		"id": "palm_wood",
		"name": "Пальмовая древесина",
		"type": "resource",
		"rarity": "common",
		"weight": 1.0,
		"max_stack": 99,
		"sell_price": 2,
		"description": "Базовая древесина с пальм"
	}
	
	items["stone"] = {
		"id": "stone",
		"name": "Камень",
		"type": "resource",
		"rarity": "common",
		"weight": 1.5,
		"max_stack": 99,
		"sell_price": 1,
		"description": "Обычный камень"
	}
	
	items["stick"] = {
		"id": "stick",
		"name": "Палка",
		"type": "resource",
		"rarity": "common",
		"weight": 0.5,
		"max_stack": 99,
		"sell_price": 1,
		"description": "Простая палка"
	}
	
	items["rope"] = {
		"id": "rope",
		"name": "Верёвка",
		"type": "resource",
		"rarity": "common",
		"weight": 0.3,
		"max_stack": 50,
		"sell_price": 5,
		"description": "Крепкая верёвка из волокон"
	}
	
	items["fabric"] = {
		"id": "fabric",
		"name": "Ткань",
		"type": "resource",
		"rarity": "common",
		"weight": 0.2,
		"max_stack": 50,
		"sell_price": 10,
		"description": "Ткань для парусов и одежды"
	}
	
	items["metal_ingot"] = {
		"id": "metal_ingot",
		"name": "Металлический слиток",
		"type": "resource",
		"rarity": "uncommon",
		"weight": 2.0,
		"max_stack": 50,
		"sell_price": 50,
		"description": "Обработанный металл"
	}

## ============================================
## ОРУЖИЕ
## ============================================

func _register_weapons() -> void:
	# Оружие ближнего боя - уровень 1
	items["stone_knife"] = {
		"id": "stone_knife",
		"name": "Каменный нож",
		"type": "weapon",
		"equipment_slot": "main_hand",
		"rarity": "common",
		"level": 1,
		"required_level": 1,
		"weight": 0.5,
		"max_stack": 1,
		"sell_price": 10,
		"description": "Простой нож из камня",
		"stats": {
			"damage": 10.0,
			"attack_speed": 1.2
		},
		"enhancement_level": 0
	}
	
	# Уровень 3
	items["spear"] = {
		"id": "spear",
		"name": "Копьё",
		"type": "weapon",
		"equipment_slot": "main_hand",
		"rarity": "common",
		"level": 3,
		"required_level": 3,
		"weight": 1.5,
		"max_stack": 1,
		"sell_price": 25,
		"description": "Простое копьё для охоты",
		"stats": {
			"damage": 15.0,
			"attack_speed": 1.0,
			"range": 2.0
		},
		"enhancement_level": 0
	}
	
	items["wooden_sword"] = {
		"id": "wooden_sword",
		"name": "Деревянный меч",
		"type": "weapon",
		"equipment_slot": "main_hand",
		"rarity": "common",
		"level": 3,
		"required_level": 3,
		"weight": 1.0,
		"max_stack": 1,
		"sell_price": 30,
		"description": "Примитивный деревянный меч",
		"stats": {
			"damage": 12.0,
			"attack_speed": 1.1
		},
		"enhancement_level": 0
	}
	
	# Уровень 12
	items["iron_sword"] = {
		"id": "iron_sword",
		"name": "Железный меч",
		"type": "weapon",
		"equipment_slot": "main_hand",
		"rarity": "common",
		"level": 12,
		"required_level": 12,
		"weight": 2.0,
		"max_stack": 1,
		"sell_price": 150,
		"description": "Качественный железный меч",
		"stats": {
			"damage": 30.0,
			"attack_speed": 1.0
		},
		"enhancement_level": 0
	}
	
	# Оружие дальнего боя
	items["wooden_bow"] = {
		"id": "wooden_bow",
		"name": "Деревянный лук",
		"type": "weapon",
		"equipment_slot": "main_hand",
		"rarity": "common",
		"level": 5,
		"required_level": 5,
		"weight": 1.0,
		"max_stack": 1,
		"sell_price": 40,
		"description": "Простой лук из дерева",
		"stats": {
			"damage": 18.0,
			"attack_speed": 0.8,
			"range": 15.0
		},
		"enhancement_level": 0
	}
	
	items["crossbow"] = {
		"id": "crossbow",
		"name": "Арбалет",
		"type": "weapon",
		"equipment_slot": "main_hand",
		"rarity": "common",
		"level": 15,
		"required_level": 15,
		"weight": 2.5,
		"max_stack": 1,
		"sell_price": 200,
		"description": "Мощный арбалет",
		"stats": {
			"damage": 45.0,
			"attack_speed": 0.5,
			"range": 20.0
		},
		"enhancement_level": 0
	}
	
	# Щиты
	items["wooden_shield"] = {
		"id": "wooden_shield",
		"name": "Деревянный щит",
		"type": "shield",
		"equipment_slot": "offhand",
		"rarity": "common",
		"level": 5,
		"required_level": 5,
		"weight": 3.0,
		"max_stack": 1,
		"sell_price": 50,
		"description": "Простой деревянный щит",
		"stats": {
			"defense": 10.0,
			"block_chance": 0.15
		},
		"enhancement_level": 0
	}

## ============================================
## БРОНЯ
## ============================================

func _register_armor() -> void:
	# Шлемы - уровень 1
	items["cloth_helmet"] = {
		"id": "cloth_helmet",
		"name": "Тканевый капюшон",
		"type": "armor",
		"equipment_slot": "helmet",
		"rarity": "common",
		"level": 1,
		"required_level": 1,
		"weight": 0.5,
		"max_stack": 1,
		"sell_price": 30,
		"description": "Лёгкий тканевый капюшон",
		"stats": {
			"defense": 5.0,
			"vitality": 2.0
		},
		"enhancement_level": 0
	}
	
	# Уровень 5
	items["leather_helmet"] = {
		"id": "leather_helmet",
		"name": "Кожаный шлем",
		"type": "armor",
		"equipment_slot": "helmet",
		"rarity": "common",
		"level": 5,
		"required_level": 5,
		"weight": 1.0,
		"max_stack": 1,
		"sell_price": 80,
		"description": "Крепкий кожаный шлем",
		"stats": {
			"defense": 12.0,
			"vitality": 5.0
		},
		"enhancement_level": 0
	}
	
	# Нагрудники - уровень 1
	items["cloth_chest"] = {
		"id": "cloth_chest",
		"name": "Тканевая рубаха",
		"type": "armor",
		"equipment_slot": "chest",
		"rarity": "common",
		"level": 1,
		"required_level": 1,
		"weight": 1.0,
		"max_stack": 1,
		"sell_price": 50,
		"description": "Лёгкая тканевая одежда",
		"stats": {
			"defense": 8.0,
			"vitality": 3.0
		},
		"enhancement_level": 0
	}
	
	# Уровень 5
	items["leather_chest"] = {
		"id": "leather_chest",
		"name": "Кожаный доспех",
		"type": "armor",
		"equipment_slot": "chest",
		"rarity": "common",
		"level": 5,
		"required_level": 5,
		"weight": 2.5,
		"max_stack": 1,
		"sell_price": 150,
		"description": "Крепкий кожаный доспех",
		"stats": {
			"defense": 20.0,
			"vitality": 8.0,
			"agility": -2.0
		},
		"enhancement_level": 0
	}
	
	# Поножи - уровень 1
	items["cloth_legs"] = {
		"id": "cloth_legs",
		"name": "Тканевые штаны",
		"type": "armor",
		"equipment_slot": "legs",
		"rarity": "common",
		"level": 1,
		"required_level": 1,
		"weight": 0.8,
		"max_stack": 1,
		"sell_price": 40,
		"description": "Лёгкие штаны",
		"stats": {
			"defense": 6.0,
			"vitality": 2.0
		},
		"enhancement_level": 0
	}
	
	# Сапоги - уровень 1
	items["cloth_boots"] = {
		"id": "cloth_boots",
		"name": "Тканевые сапоги",
		"type": "armor",
		"equipment_slot": "boots",
		"rarity": "common",
		"level": 1,
		"required_level": 1,
		"weight": 0.5,
		"max_stack": 1,
		"sell_price": 30,
		"description": "Мягкие сапоги",
		"stats": {
			"defense": 4.0,
			"agility": 1.0
		},
		"enhancement_level": 0
	}
	
	# Перчатки - уровень 1
	items["cloth_gloves"] = {
		"id": "cloth_gloves",
		"name": "Тканевые перчатки",
		"type": "armor",
		"equipment_slot": "gloves",
		"rarity": "common",
		"level": 1,
		"required_level": 1,
		"weight": 0.3,
		"max_stack": 1,
		"sell_price": 25,
		"description": "Лёгкие перчатки",
		"stats": {
			"defense": 3.0,
			"focus": 2.0
		},
		"enhancement_level": 0
	}

## ============================================
## АКСЕССУАРЫ
## ============================================

func _register_accessories() -> void:
	items["copper_ring"] = {
		"id": "copper_ring",
		"name": "Медное кольцо",
		"type": "accessory",
		"rarity": "common",
		"level": 1,
		"required_level": 1,
		"weight": 0.1,
		"max_stack": 1,
		"sell_price": 100,
		"description": "Простое медное кольцо",
		"stats": {
			"luck": 3.0,
			"perception": 2.0
		},
		"enhancement_level": 0
	}
	
	items["leather_amulet"] = {
		"id": "leather_amulet",
		"name": "Кожаный амулет",
		"type": "accessory",
		"rarity": "common",
		"level": 1,
		"required_level": 1,
		"weight": 0.2,
		"max_stack": 1,
		"sell_price": 120,
		"description": "Амулет из кожи",
		"stats": {
			"vitality": 5.0,
			"focus": 3.0
		},
		"enhancement_level": 0
	}

## ============================================
## ИНСТРУМЕНТЫ
## ============================================

func _register_tools() -> void:
	items["fishing_rod"] = {
		"id": "fishing_rod",
		"name": "Удочка",
		"type": "tool",
		"rarity": "common",
		"weight": 1.0,
		"max_stack": 1,
		"sell_price": 50,
		"description": "Простая удочка для рыбалки"
	}
	
	items["pickaxe"] = {
		"id": "pickaxe",
		"name": "Кирка",
		"type": "tool",
		"rarity": "common",
		"weight": 2.0,
		"max_stack": 1,
		"sell_price": 60,
		"description": "Инструмент для добычи камня"
	}

## ============================================
## РАСХОДНИКИ
## ============================================

func _register_consumables() -> void:
	items["healing_herb"] = {
		"id": "healing_herb",
		"name": "Целебная трава",
		"type": "consumable",
		"rarity": "common",
		"weight": 0.1,
		"max_stack": 20,
		"sell_price": 5,
		"description": "Восстанавливает 20 HP",
		"effect": {
			"type": "heal",
			"amount": 20.0
		}
	}

func get_item(id: String) -> Dictionary:
	return items.get(id, {})

func get_items_by_type(item_type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in items.keys():
		var item = items[item_id]
		if item.get("type", "") == item_type:
			result.append(item)
	return result

func get_items_by_rarity(rarity: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in items.keys():
		var item = items[item_id]
		if item.get("rarity", "") == rarity:
			result.append(item)
	return result

func get_items_by_level(min_level: int, max_level: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in items.keys():
		var item = items[item_id]
		var level = item.get("level", 0)
		if level >= min_level and level <= max_level:
			result.append(item)
	return result
