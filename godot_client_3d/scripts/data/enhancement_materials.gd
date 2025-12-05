extends Node
class_name EnhancementMaterials

## База данных материалов для заточки
## Материалы выпадают с монстров с небольшим шансом

static var materials: Dictionary = {}

func _ready() -> void:
	if materials.is_empty():
		_register_materials()

static func _register_materials() -> void:
	if not materials.is_empty():
		return
	
	# Базовые материалы (для заточки +0 до +3)
	materials["whetstone_basic"] = {
		"id": "whetstone_basic",
		"name": "Обычный точильный камень",
		"description": "Базовый материал для заточки",
		"enhancement_range": [0, 3],
		"drop_chance_base": 0.15,  # 15% базовый шанс
		"monster_tier_min": 1,
		"monster_tier_max": 3
	}
	
	# Улучшенные материалы (для заточки +3 до +8)
	materials["whetstone_improved"] = {
		"id": "whetstone_improved",
		"name": "Улучшенный точильный камень",
		"description": "Материал для заточки среднего уровня",
		"enhancement_range": [3, 8],
		"drop_chance_base": 0.08,  # 8% базовый шанс
		"monster_tier_min": 2,
		"monster_tier_max": 4
	}
	
	# Редкие материалы (для заточки +8 до +10)
	materials["whetstone_rare"] = {
		"id": "whetstone_rare",
		"name": "Редкий точильный камень",
		"description": "Драгоценный материал для заточки",
		"enhancement_range": [8, 10],
		"drop_chance_base": 0.05,  # 5% базовый шанс
		"monster_tier_min": 3,
		"monster_tier_max": 5
	}
	
	# Легендарные материалы (для заточки +10 до +12)
	materials["whetstone_legendary"] = {
		"id": "whetstone_legendary",
		"name": "Легендарный точильный камень",
		"description": "Исключительно редкий материал для максимальной заточки",
		"enhancement_range": [10, 12],
		"drop_chance_base": 0.02,  # 2% базовый шанс
		"monster_tier_min": 4,
		"monster_tier_max": 5
	}
	
	# Защитные материалы (снижают риск поломки)
	materials["protection_charm"] = {
		"id": "protection_charm",
		"name": "Оберег защиты",
		"description": "Снижает риск поломки при заточке",
		"protection_level": 1,  # Снижает риск на 1 уровень
		"drop_chance_base": 0.03,  # 3% базовый шанс
		"monster_tier_min": 2,
		"monster_tier_max": 5
	}
	
	materials["protection_charm_greater"] = {
		"id": "protection_charm_greater",
		"name": "Большой оберег защиты",
		"description": "Сильно снижает риск поломки при заточке",
		"protection_level": 2,  # Снижает риск на 2 уровня
		"drop_chance_base": 0.01,  # 1% базовый шанс
		"monster_tier_min": 4,
		"monster_tier_max": 5
	}

## Получить материал по ID
static func get_material(material_id: String) -> Dictionary:
	if materials.is_empty():
		_register_materials()
	return materials.get(material_id, {})

## Получить материалы для уровня заточки
static func get_materials_for_level(level: int) -> Array[Dictionary]:
	if materials.is_empty():
		_register_materials()
	
	var result: Array[Dictionary] = []
	
	for material_id in materials.keys():
		var material = materials[material_id]
		var range_min = material.get("enhancement_range", [0, 0])[0]
		var range_max = material.get("enhancement_range", [0, 0])[1]
		
		if level >= range_min and level < range_max:
			result.append(material)
	
	return result

## Вычислить шанс дропа материала с монстра
static func calculate_drop_chance(material_id: String, monster_tier: int, player_luck: float = 0.0) -> float:
	if materials.is_empty():
		_register_materials()
	
	var mat_data = materials.get(material_id, {})
	
	if mat_data.is_empty():
		return 0.0
	
	var base_chance = mat_data.get("drop_chance_base", 0.0)
	var tier_min = mat_data.get("monster_tier_min", 1)
	var tier_max = mat_data.get("monster_tier_max", 5)
	
	# Проверяем, что монстр подходящего тира
	if monster_tier < tier_min or monster_tier > tier_max:
		return 0.0
	
	# Бонус за тир монстра: +0.5% за каждый тир выше минимального
	var tier_bonus = (monster_tier - tier_min) * 0.005
	
	# Бонус за удачу: +0.1% за единицу удачи
	var luck_bonus = player_luck * 0.001
	
	var final_chance = base_chance + tier_bonus + luck_bonus
	
	# Ограничиваем максимумом 50%
	return min(final_chance, 0.5)

## Генерировать дроп материалов с монстра
static func generate_material_drop(monster_tier: int, player_luck: float = 0.0) -> Array[String]:
	if materials.is_empty():
		_register_materials()
	
	var dropped_materials: Array[String] = []
	
	for material_id in materials.keys():
		var mat_data = materials[material_id]
		var tier_min = mat_data.get("monster_tier_min", 1)
		var tier_max = mat_data.get("monster_tier_max", 5)
		
		if monster_tier >= tier_min and monster_tier <= tier_max:
			var drop_chance = calculate_drop_chance(material_id, monster_tier, player_luck)
			if randf() < drop_chance:
				dropped_materials.append(material_id)
	
	return dropped_materials
