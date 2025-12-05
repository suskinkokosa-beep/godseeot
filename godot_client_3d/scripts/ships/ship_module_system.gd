extends Node
class_name ShipModuleSystem

## Система модулей корабля
## Управляет установкой и работой модулей корпуса, мачт, орудий

enum ModuleType {
	HULL,        # Корпус
	MAST,        # Мачта
	SAIL,        # Парус
	WEAPON,      # Орудие
	SPECIAL,     # Специальный модуль
	DECORATION   # Декоративный модуль
}

## Данные модуля
class ShipModule:
	var id: String
	var module_type: ModuleType
	var name: String
	var level: int = 1
	var durability: float = 100.0
	var max_durability: float = 100.0
	
	var stats: Dictionary = {}
	var abilities: Array[String] = []
	
	func _init(_id: String, _name: String, _type: ModuleType):
		id = _id
		name = _name
		module_type = _type

var ship_modules: Dictionary = {}  # module_id -> ShipModule
var installed_modules: Dictionary = {}  # slot_id -> module_id

func _ready() -> void:
	_initialize_module_templates()

## Инициализирует шаблоны модулей
func _initialize_module_templates() -> void:
	# Модули корпуса
	_create_module_template("hull_basic", "Базовый корпус", ModuleType.HULL, {"health": 100.0})
	_create_module_template("hull_reinforced", "Усиленный корпус", ModuleType.HULL, {"health": 150.0})
	_create_module_template("hull_metal", "Металлический корпус", ModuleType.HULL, {"health": 200.0})
	
	# Мачты
	_create_module_template("mast_basic", "Базовая мачта", ModuleType.MAST, {"speed": 1.0})
	_create_module_template("mast_improved", "Улучшенная мачта", ModuleType.MAST, {"speed": 1.2})
	_create_module_template("mast_storm", "Штормовая мачта", ModuleType.MAST, {"speed": 1.0, "storm_resistance": 0.8})
	
	# Паруса
	_create_module_template("sail_basic", "Базовый парус", ModuleType.SAIL, {"speed": 1.0})
	_create_module_template("sail_improved", "Улучшенный парус", ModuleType.SAIL, {"speed": 1.3})
	_create_module_template("sail_blackwind", "Парус Blackwind", ModuleType.SAIL, {"speed": 2.0})
	
	# Орудия
	_create_module_template("cannon_light", "Лёгкое орудие", ModuleType.WEAPON, {"damage": 50.0, "range": 100.0})
	_create_module_template("cannon_heavy", "Тяжёлое орудие", ModuleType.WEAPON, {"damage": 100.0, "range": 150.0})
	_create_module_template("harpoon", "Гарпун", ModuleType.WEAPON, {"damage": 30.0, "range": 50.0, "grapple": true})
	
	# Специальные модули
	_create_module_template("echolocator", "Эхолокатор", ModuleType.SPECIAL, {}, ["detect_monsters", "detect_resources"])
	_create_module_template("auto_sail", "Автопарус", ModuleType.SPECIAL, {}, ["auto_sail"])
	_create_module_template("fog_generator", "Генератор тумана", ModuleType.SPECIAL, {}, ["fog_cloud"])
	_create_module_template("storm_stabilizer", "Стабилизатор шторма", ModuleType.SPECIAL, {"storm_resistance": 0.5})

func _create_module_template(id: String, name: String, type: ModuleType, stats: Dictionary, abilities: Array[String] = []) -> void:
	var module = ShipModule.new(id, name, type)
	module.stats = stats.duplicate()
	module.abilities = abilities.duplicate()
	ship_modules[id] = module

## Устанавливает модуль в слот
func install_module(module_id: String, slot_id: String) -> bool:
	if not ship_modules.has(module_id):
		return false
	
	# Создаём копию модуля для установки
	var template = ship_modules[module_id]
	var module = ShipModule.new(module_id, template.name, template.module_type)
	module.stats = template.stats.duplicate()
	module.abilities = template.abilities.duplicate()
	module.max_durability = 100.0
	module.durability = 100.0
	
	installed_modules[slot_id] = module_id
	return true

## Снимает модуль со слота
func uninstall_module(slot_id: String) -> bool:
	if not installed_modules.has(slot_id):
		return false
	
	installed_modules.erase(slot_id)
	return true

## Получить модуль из слота
func get_module_in_slot(slot_id: String) -> ShipModule:
	if not installed_modules.has(slot_id):
		return null
	
	var module_id = installed_modules[slot_id]
	if not ship_modules.has(module_id):
		return null
	
	return ship_modules[module_id]

## Получить все установленные модули
func get_installed_modules() -> Dictionary:
	return installed_modules.duplicate()

## Вычисляет суммарные характеристики корабля с учётом модулей
func calculate_ship_stats(base_stats: Dictionary) -> Dictionary:
	var final_stats = base_stats.duplicate()
	
	for slot_id in installed_modules.keys():
		var module_id = installed_modules[slot_id]
		if ship_modules.has(module_id):
			var module = ship_modules[module_id]
			var module_stats = module.stats
			
			# Применяем бонусы модуля
			for stat_name in module_stats.keys():
				if final_stats.has(stat_name):
					final_stats[stat_name] += module_stats[stat_name]
				else:
					final_stats[stat_name] = module_stats[stat_name]
	
	return final_stats

## Проверяет, есть ли у корабля определённую способность
func has_ability(ability_name: String) -> bool:
	for slot_id in installed_modules.keys():
		var module_id = installed_modules[slot_id]
		if ship_modules.has(module_id):
			var module = ship_modules[module_id]
			if ability_name in module.abilities:
				return true
	return false

## Повреждает модуль
func damage_module(slot_id: String, damage: float) -> bool:
	var module = get_module_in_slot(slot_id)
	if not module:
		return false
	
	module.durability -= damage
	if module.durability <= 0.0:
		module.durability = 0.0
		# Модуль сломан, но остаётся на месте (требуется ремонт)
		return true
	
	return false

## Ремонтирует модуль
func repair_module(slot_id: String, amount: float) -> bool:
	var module = get_module_in_slot(slot_id)
	if not module:
		return false
	
	module.durability = min(module.durability + amount, module.max_durability)
	return true

