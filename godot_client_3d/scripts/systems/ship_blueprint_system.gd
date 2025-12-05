extends Node
class_name ShipBlueprintSystem

## Система чертежей кораблей для Isleborn Online
## Согласно GDD: модульная архитектура кораблей, чертежи для строительства

enum BlueprintRarity {
	COMMON,         # Обычный
	UNCOMMON,       # Необычный
	RARE,           # Редкий
	EPIC,           # Эпический
	LEGENDARY       # Легендарный
}

class ShipBlueprint:
	var blueprint_id: String
	var ship_name: String
	var ship_class: String
	var tier: int
	var rarity: BlueprintRarity
	var required_level: int
	var build_time: float  # В секундах
	
	# Требования к материалам
	var materials: Dictionary = {}  # item_id -> quantity
	
	# Модули по умолчанию
	var default_modules: Dictionary = {}  # slot_type -> module_id
	
	# Характеристики корабля
	var base_stats: Dictionary = {}
	
	# Требования к верфи
	var required_shipyard_level: int = 1
	var required_island_level: int = 1
	
	# Описание и источник получения
	var description: String = ""
	var source: String = ""  # Где можно получить чертёж
	
	func _init(_id: String, _name: String, _class: String, _tier: int):
		blueprint_id = _id
		ship_name = _name
		ship_class = _class
		tier = _tier

var known_blueprints: Dictionary = {}  # blueprint_id -> ShipBlueprint
var blueprint_templates: Dictionary = {}

signal blueprint_learned(blueprint_id: String)
signal blueprint_used(blueprint_id: String, ship_id: String)

func _ready() -> void:
	_initialize_blueprint_templates()

func _initialize_blueprint_templates() -> void:
	# Ранние корабли
	_register_blueprint("bp_raft", "Плот", "RAFT", 1, BlueprintRarity.COMMON, {
		"palm_wood": 10
	}, 60.0, 1, 1)
	
	_register_blueprint("bp_canoe", "Каноэ", "CANOE", 1, BlueprintRarity.COMMON, {
		"palm_wood": 15,
		"rope": 2
	}, 120.0, 1, 2)
	
	_register_blueprint("bp_fishing_boat", "Рыбацкая лодка", "BOAT", 1, BlueprintRarity.COMMON, {
		"palm_wood": 25,
		"rope": 5,
		"fabric": 3
	}, 180.0, 1, 3)
	
	# Средние корабли
	_register_blueprint("bp_barge", "Баркас", "BARGE", 2, BlueprintRarity.UNCOMMON, {
		"palm_wood": 50,
		"metal": 10,
		"rope": 15,
		"fabric": 10
	}, 600.0, 2, 5)
	
	_register_blueprint("bp_schooner", "Шхуна", "SCHOONER", 2, BlueprintRarity.UNCOMMON, {
		"palm_wood": 80,
		"metal": 20,
		"rope": 25,
		"fabric": 20
	}, 900.0, 2, 7)
	
	# Поздние корабли
	_register_blueprint("bp_caravel", "Каравелла", "CARAVEL", 3, BlueprintRarity.RARE, {
		"palm_wood": 150,
		"metal": 50,
		"rope": 40,
		"fabric": 30,
		"crystal": 5
	}, 1800.0, 3, 15)
	
	_register_blueprint("bp_frigate", "Фрегат", "FRIGATE", 3, BlueprintRarity.EPIC, {
		"palm_wood": 200,
		"metal": 100,
		"rope": 60,
		"fabric": 50,
		"crystal": 10
	}, 3600.0, 3, 20)
	
	# Уникальные корабли
	_register_blueprint("bp_abyss_runner", "Abyss Runner", "MAGICAL", 4, BlueprintRarity.LEGENDARY, {
		"palm_wood": 300,
		"metal": 150,
		"crystal": 50,
		"essence": 20
	}, 7200.0, 4, 30)

func _register_blueprint(bp_id: String, name: String, ship_class: String, tier: int, rarity: BlueprintRarity, materials: Dictionary, build_time: float, shipyard_level: int, island_level: int) -> void:
	var bp = ShipBlueprint.new(bp_id, name, ship_class, tier)
	bp.rarity = rarity
	bp.materials = materials.duplicate()
	bp.build_time = build_time
	bp.required_shipyard_level = shipyard_level
	bp.required_island_level = island_level
	bp.required_level = island_level
	
	# Устанавливаем базовые характеристики в зависимости от типа
	bp.base_stats = _get_base_stats_for_class(ship_class, tier)
	
	blueprint_templates[bp_id] = bp

func learn_blueprint(blueprint_id: String, source: String = "") -> bool:
	if known_blueprints.has(blueprint_id):
		return false  # Уже изучен
	
	if not blueprint_templates.has(blueprint_id):
		return false  # Чертежа не существует
	
	var bp = blueprint_templates[blueprint_id].duplicate()
	bp.source = source
	known_blueprints[blueprint_id] = bp
	
	blueprint_learned.emit(blueprint_id)
	return true

func use_blueprint(blueprint_id: String, shipyard_id: String) -> Dictionary:
	if not known_blueprints.has(blueprint_id):
		return {"success": false, "error": "Blueprint not learned"}
	
	var bp = known_blueprints[blueprint_id]
	
	# TODO: Проверка наличия материалов
	# TODO: Проверка уровня верфи
	# TODO: Проверка уровня острова
	
	# Создаём корабль (возвращаем данные для создания)
	var ship_id = "ship_%d" % Time.get_ticks_msec()
	
	blueprint_used.emit(blueprint_id, ship_id)
	
	return {
		"success": true,
		"ship_id": ship_id,
		"blueprint_id": blueprint_id,
		"build_time": bp.build_time,
		"materials_required": bp.materials.duplicate()
	}

func get_blueprint_info(blueprint_id: String) -> Dictionary:
	if not known_blueprints.has(blueprint_id):
		if not blueprint_templates.has(blueprint_id):
			return {}
		# Возвращаем шаблон, если чертёж не изучен (для предпросмотра)
		var bp = blueprint_templates[blueprint_id]
		return {
			"id": bp.blueprint_id,
			"name": bp.ship_name,
			"class": bp.ship_class,
			"tier": bp.tier,
			"rarity": bp.rarity,
			"required_level": bp.required_level,
			"materials": bp.materials.duplicate(),
			"stats": bp.base_stats.duplicate(),
			"learned": false
		}
	
	var bp = known_blueprints[blueprint_id]
	return {
		"id": bp.blueprint_id,
		"name": bp.ship_name,
		"class": bp.ship_class,
		"tier": bp.tier,
		"rarity": bp.rarity,
		"required_level": bp.required_level,
		"materials": bp.materials.duplicate(),
		"stats": bp.base_stats.duplicate(),
		"learned": true,
		"source": bp.source
	}

func get_all_known_blueprints() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for bp_id in known_blueprints.keys():
		result.append(get_blueprint_info(bp_id))
	
	return result

func get_available_blueprints_for_level(level: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for bp_id in blueprint_templates.keys():
		var bp = blueprint_templates[bp_id]
		if bp.required_level <= level:
			result.append(get_blueprint_info(bp_id))
	
	return result

func _get_base_stats_for_class(ship_class: String, tier: int) -> Dictionary:
	var base_stats = {}
	
	match ship_class:
		"RAFT":
			base_stats = {"health": 50.0, "speed": 3.0, "cargo": 2, "crew": 1}
		"CANOE":
			base_stats = {"health": 70.0, "speed": 4.0, "cargo": 3, "crew": 1}
		"BOAT":
			base_stats = {"health": 100.0, "speed": 4.5, "cargo": 5, "crew": 2}
		"BARGE":
			base_stats = {"health": 200.0, "speed": 5.0, "cargo": 15, "crew": 5}
		"SCHOONER":
			base_stats = {"health": 300.0, "speed": 6.0, "cargo": 25, "crew": 8}
		"CARAVEL":
			base_stats = {"health": 500.0, "speed": 7.0, "cargo": 40, "crew": 15}
		"FRIGATE":
			base_stats = {"health": 800.0, "speed": 8.0, "cargo": 60, "crew": 25}
		"MAGICAL":
			base_stats = {"health": 1000.0, "speed": 10.0, "cargo": 80, "crew": 30}
		_:
			base_stats = {"health": 100.0, "speed": 5.0, "cargo": 5, "crew": 1}
	
	# Масштабируем по тиру
	for key in base_stats.keys():
		if key == "health" or key == "cargo" or key == "crew":
			base_stats[key] *= (1.0 + (tier - 1) * 0.5)
	
	return base_stats

