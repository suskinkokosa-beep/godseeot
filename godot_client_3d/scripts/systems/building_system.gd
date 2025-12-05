extends Node
class_name BuildingSystem

## Система строительства с модулями для Isleborn Online
## Согласно GDD: постройки с модулями, которые можно улучшать

enum BuildingType {
	BASIC,           # Костёр, сушилка
	PRODUCTION,      # Кузница, плотницкая, верфь
	DEFENSIVE,       # Башни, стены
	MAGICAL,         # Магические постройки (L25+)
	DECORATIVE,      # Статуи, фонтаны
	STORAGE,         # Склады
	HOUSING,         # Жильё для NPC
	FARMING          # Фермы
}

enum BuildingModuleType {
	# Базовые модули
	BASE_FOUNDATION,      # Фундамент
	BASE_WALLS,           # Стены
	
	# Производственные модули
	PROD_FURNACE,         # Печь (кузница)
	PROD_WORKBENCH,       # Верстак
	PROD_FORGE,           # Горн
	PROD_ANVIL,           # Наковальня
	PROD_DOCK,            # Причал (верфь)
	PROD_DRYING_RACK,     # Сушилка
	
	# Защитные модули
	DEF_TOWER,            # Башня
	DEF_WALL,             # Стена
	DEF_CATAPULT,         # Катапульта
	DEF_BALLISTA,         # Баллиста
	DEF_TOTEM,            # Тотемы
	
	# Магические модули
	MAG_RUNIC_TOTEM,      # Рунический тотем
	MAG_CRYSTAL_WELL,     # Кристальный колодец
	MAG_ENCHANTING_TABLE, # Стол зачарования
	MAG_OBSERVATORY,      # Обсерватория
	
	# Декоративные модули
	DEC_STATUE,           # Статуя
	DEC_FOUNTAIN,         # Фонтан
	DEC_FLAG,             # Флаг
	DEC_LAMP,             # Фонарь
}

class BuildingModule:
	var module_id: String
	var module_type: BuildingModuleType
	var name: String
	var level: int = 1
	var max_level: int = 3
	var health: float = 100.0
	var max_health: float = 100.0
	var effects: Dictionary = {}  # Бонусы, которые даёт модуль
	var cost_to_upgrade: Dictionary = {}
	
	func _init(_id: String, _type: BuildingModuleType, _name: String):
		module_id = _id
		module_type = _type
		name = _name

class BuildingData:
	var building_id: String
	var building_type: BuildingType
	var name: String
	var position: Vector3
	var rotation: float = 0.0
	var level: int = 1
	var max_level: int = 5
	var health: float = 100.0
	var max_health: float = 100.0
	var modules: Dictionary = {}  # module_id -> BuildingModule
	var module_slots: int = 3  # Количество слотов модулей
	var required_island_level: int = 1
	var effects: Dictionary = {}  # Эффекты всего здания
	var is_built: bool = false
	var build_progress: float = 0.0
	var build_time: float = 60.0  # Секунды
	
	func _init(_id: String, _type: BuildingType, _name: String, _pos: Vector3):
		building_id = _id
		building_type = _type
		name = _name
		position = _pos

var buildings: Dictionary = {}  # building_id -> BuildingData
var building_templates: Dictionary = {}

signal building_constructed(building_id: String)
signal building_destroyed(building_id: String)
signal module_added(building_id: String, module_id: String)
signal module_upgraded(building_id: String, module_id: String, new_level: int)

func _ready() -> void:
	_initialize_building_templates()

func _initialize_building_templates() -> void:
	# Базовые постройки
	building_templates["campfire"] = {
		"id": "campfire",
		"name": "Костёр",
		"type": BuildingType.BASIC,
		"required_island_level": 1,
		"base_health": 50.0,
		"build_time": 5.0,
		"module_slots": 0,
		"effects": {"cooking": true, "light": true}
	}
	
	building_templates["workshop_l1"] = {
		"id": "workshop_l1",
		"name": "Мастерская (Уровень 1)",
		"type": BuildingType.PRODUCTION,
		"required_island_level": 3,
		"base_health": 200.0,
		"build_time": 120.0,
		"module_slots": 3,
		"effects": {"crafting": true}
	}
	
	building_templates["shipyard_l1"] = {
		"id": "shipyard_l1",
		"name": "Верфь (Уровень 1)",
		"type": BuildingType.PRODUCTION,
		"required_island_level": 5,
		"base_health": 300.0,
		"build_time": 180.0,
		"module_slots": 4,
		"effects": {"ship_crafting": true}
	}
	
	building_templates["forge_l1"] = {
		"id": "forge_l1",
		"name": "Кузница (Уровень 1)",
		"type": BuildingType.PRODUCTION,
		"required_island_level": 6,
		"base_health": 250.0,
		"build_time": 150.0,
		"module_slots": 4,
		"effects": {"metal_crafting": true}
	}
	
	building_templates["tower_bow_l1"] = {
		"id": "tower_bow_l1",
		"name": "Башня с луками",
		"type": BuildingType.DEFENSIVE,
		"required_island_level": 10,
		"base_health": 400.0,
		"build_time": 200.0,
		"module_slots": 2,
		"effects": {"defense": true, "range": 50.0}
	}
	
	building_templates["runic_totem_water"] = {
		"id": "runic_totem_water",
		"name": "Рунический тотем воды",
		"type": BuildingType.MAGICAL,
		"required_island_level": 25,
		"base_health": 500.0,
		"build_time": 300.0,
		"module_slots": 3,
		"effects": {"water_resistance": 0.2, "monster_damage_reduction": 0.15}
	}

## Создать постройку
func create_building(template_id: String, position: Vector3, island_level: int) -> BuildingData:
	var template = building_templates.get(template_id)
	if not template:
		push_error("Building template not found: %s" % template_id)
		return null
	
	if island_level < template.get("required_island_level", 1):
		push_error("Island level too low for building %s" % template_id)
		return null
	
	var building = BuildingData.new(
		"building_%d" % Time.get_ticks_msec(),
		template.get("type", BuildingType.BASIC),
		template.get("name", "Unknown"),
		position
	)
	
	building.required_island_level = template.get("required_island_level", 1)
	building.max_health = template.get("base_health", 100.0)
	building.health = building.max_health
	building.build_time = template.get("build_time", 60.0)
	building.module_slots = template.get("module_slots", 0)
	building.max_level = template.get("max_level", 5)
	
	# Копируем эффекты из шаблона
	for key in template.get("effects", {}).keys():
		building.effects[key] = template.get("effects", {})[key]
	
	buildings[building.building_id] = building
	return building

## Начать строительство
func start_building(building_id: String) -> bool:
	var building = buildings.get(building_id)
	if not building:
		return false
	
	if building.is_built:
		return false
	
	building.build_progress = 0.0
	return true

## Обновить прогресс строительства
func update_building_progress(building_id: String, delta: float) -> void:
	var building = buildings.get(building_id)
	if not building or building.is_built:
		return
	
	building.build_progress += delta / building.build_time
	if building.build_progress >= 1.0:
		building.build_progress = 1.0
		building.is_built = true
		building_constructed.emit(building_id)

## Добавить модуль к постройке
func add_module_to_building(building_id: String, module_type: BuildingModuleType, module_name: String) -> bool:
	var building = buildings.get(building_id)
	if not building:
		return false
	
	if building.modules.size() >= building.module_slots:
		return false
	
	var module_id = "module_%d" % Time.get_ticks_msec()
	var module = BuildingModule.new(module_id, module_type, module_name)
	
	# Устанавливаем начальные параметры модуля в зависимости от типа
	_setup_module_by_type(module)
	
	building.modules[module_id] = module
	_recalculate_building_effects(building)
	module_added.emit(building_id, module_id)
	return true

## Улучшить модуль
func upgrade_module(building_id: String, module_id: String) -> bool:
	var building = buildings.get(building_id)
	if not building:
		return false
	
	var module = building.modules.get(module_id)
	if not module:
		return false
	
	if module.level >= module.max_level:
		return false
	
	# TODO: Проверка ресурсов для улучшения
	# TODO: Удаление ресурсов
	
	module.level += 1
	module.max_health *= 1.2
	module.health = module.max_health
	
	_recalculate_building_effects(building)
	module_upgraded.emit(building_id, module_id, module.level)
	return true

## Улучшить постройку
func upgrade_building(building_id: String) -> bool:
	var building = buildings.get(building_id)
	if not building:
		return false
	
	if building.level >= building.max_level:
		return false
	
	# TODO: Проверка ресурсов для улучшения
	# TODO: Проверка уровня острова
	
	building.level += 1
	building.max_health *= 1.3
	building.health = building.max_health
	building.module_slots += 1  # Добавляем слот модулей
	
	_recalculate_building_effects(building)
	return true

## Повредить постройку
func damage_building(building_id: String, damage: float) -> void:
	var building = buildings.get(building_id)
	if not building:
		return
	
	building.health -= damage
	if building.health <= 0.0:
		destroy_building(building_id)

## Восстановить постройку
func repair_building(building_id: String, amount: float) -> bool:
	var building = buildings.get(building_id)
	if not building:
		return false
	
	if building.health >= building.max_health:
		return false
	
	# TODO: Проверка ресурсов для ремонта
	
	building.health = min(building.health + amount, building.max_health)
	return true

## Уничтожить постройку
func destroy_building(building_id: String) -> void:
	var building = buildings.get(building_id)
	if not building:
		return
	
	buildings.erase(building_id)
	building_destroyed.emit(building_id)

## Получить постройку
func get_building(building_id: String) -> BuildingData:
	return buildings.get(building_id)

## Получить все постройки
func get_all_buildings() -> Dictionary:
	return buildings.duplicate()

## Настроить модуль по типу
func _setup_module_by_type(module: BuildingModule) -> void:
	match module.module_type:
		BuildingModuleType.PROD_FURNACE:
			module.effects = {"crafting_speed": 1.2, "fuel_efficiency": 1.1}
			module.max_health = 150.0
		BuildingModuleType.PROD_ANVIL:
			module.effects = {"crafting_quality": 1.15}
			module.max_health = 200.0
		BuildingModuleType.DEF_TOWER:
			module.effects = {"damage": 10.0, "range": 30.0}
			module.max_health = 300.0
		BuildingModuleType.MAG_RUNIC_TOTEM:
			module.effects = {"magic_power": 1.2, "aura_radius": 50.0}
			module.max_health = 400.0
		_:
			module.max_health = 100.0
	
	module.health = module.max_health

## Пересчитать эффекты здания
func _recalculate_building_effects(building: BuildingData) -> void:
	# Сбрасываем эффекты до базовых
	building.effects.clear()
	
	# Добавляем эффекты от модулей
	for module_id in building.modules.keys():
		var module = building.modules[module_id]
		for effect_key in module.effects.keys():
			if building.effects.has(effect_key):
				# Если эффект уже есть, увеличиваем его
				building.effects[effect_key] = building.effects[effect_key] + module.effects[effect_key]
			else:
				building.effects[effect_key] = module.effects[effect_key]

## Получить эффекты постройки
func get_building_effects(building_id: String) -> Dictionary:
	var building = buildings.get(building_id)
	if not building:
		return {}
	return building.effects.duplicate()

