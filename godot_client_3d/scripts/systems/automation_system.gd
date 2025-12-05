extends Node
class_name AutomationSystem

## Система автоматизации добычи для Isleborn Online
## Согласно GDD: автоматические установки, NPC-добытчики

enum AutomationType {
	RESOURCE_EXTRACTOR,  # Добытчик ресурсов
	FISHING_NET,         # Автоматическая сеть
	WATER_COLLECTOR,     # Сборщик воды
	FARM,                # Ферма
	MINE,                # Шахта
	CRAFTING_STATION     # Автоматическая мастерская
}

enum AutomationStatus {
	IDLE,           # Простой
	WORKING,        # Работает
	BROKEN,         # Сломано
	NO_RESOURCES,   # Нет ресурсов
	FULL            # Полный склад
}

class AutomationDevice:
	var device_id: String
	var device_type: AutomationType
	var name: String
	var position: Vector3
	var status: AutomationStatus = AutomationStatus.IDLE
	var efficiency: float = 1.0
	var production_rate: float = 1.0  # Ресурсов в секунду
	var storage_capacity: int = 100
	var current_storage: int = 0
	var resource_type: String = ""
	var fuel_consumption: float = 0.0
	var fuel_level: float = 0.0
	var max_fuel: float = 100.0
	var required_level: int = 1
	var is_active: bool = true
	
	func _init(_id: String, _type: AutomationType, _name: String, _pos: Vector3):
		device_id = _id
		device_type = _type
		name = _name
		position = _pos

var automation_devices: Dictionary = {}  # device_id -> AutomationDevice
var device_templates: Dictionary = {}

signal device_created(device_id: String, device_type: AutomationType)
signal device_produced(device_id: String, resource_type: String, amount: int)
signal device_broken(device_id: String)
signal device_storage_full(device_id: String)

func _ready() -> void:
	_initialize_device_templates()

func _process(delta: float) -> void:
	_update_automation_devices(delta)

func _initialize_device_templates() -> void:
	# Автоматический добытчик ресурсов
	device_templates["auto_extractor"] = {
		"type": AutomationType.RESOURCE_EXTRACTOR,
		"name": "Автоматический добытчик",
		"production_rate": 0.5,
		"storage_capacity": 100,
		"fuel_consumption": 0.1,
		"required_level": 15
	}
	
	# Автоматическая рыболовная сеть
	device_templates["auto_fishing_net"] = {
		"type": AutomationType.FISHING_NET,
		"name": "Автоматическая сеть",
		"production_rate": 0.3,
		"storage_capacity": 50,
		"fuel_consumption": 0.0,
		"required_level": 10
	}
	
	# Сборщик воды
	device_templates["water_collector"] = {
		"type": AutomationType.WATER_COLLECTOR,
		"name": "Сборщик воды",
		"production_rate": 1.0,
		"storage_capacity": 200,
		"fuel_consumption": 0.0,
		"required_level": 5
	}
	
	# Ферма
	device_templates["farm"] = {
		"type": AutomationType.FARM,
		"name": "Автоматическая ферма",
		"production_rate": 0.2,
		"storage_capacity": 150,
		"fuel_consumption": 0.05,
		"required_level": 8
	}

func create_automation_device(device_template_id: String, position: Vector3, island_level: int) -> String:
	if not device_templates.has(device_template_id):
		return ""
	
	var template = device_templates[device_template_id]
	
	if island_level < template.get("required_level", 1):
		return ""
	
	var device_id = "auto_%d" % Time.get_ticks_msec()
	var device = AutomationDevice.new(device_id, template["type"], template["name"], position)
	
	device.production_rate = template.get("production_rate", 1.0)
	device.storage_capacity = template.get("storage_capacity", 100)
	device.fuel_consumption = template.get("fuel_consumption", 0.0)
	device.required_level = template.get("required_level", 1)
	
	# Устанавливаем тип ресурса в зависимости от типа устройства
	_set_resource_type_for_device(device)
	
	automation_devices[device_id] = device
	device_created.emit(device_id, device.device_type)
	
	return device_id

func _set_resource_type_for_device(device: AutomationDevice) -> void:
	match device.device_type:
		AutomationType.RESOURCE_EXTRACTOR:
			device.resource_type = "stone"  # По умолчанию
		AutomationType.FISHING_NET:
			device.resource_type = "fish"
		AutomationType.WATER_COLLECTOR:
			device.resource_type = "water"
		AutomationType.FARM:
			device.resource_type = "crop"
		AutomationType.MINE:
			device.resource_type = "metal"
		_:
			device.resource_type = ""

func _update_automation_devices(delta: float) -> void:
	for device_id in automation_devices.keys():
		var device = automation_devices[device_id]
		
		if not device.is_active:
			continue
		
		if device.status == AutomationStatus.BROKEN:
			continue
		
		# Проверяем топливо
		if device.fuel_consumption > 0.0:
			device.fuel_level -= device.fuel_consumption * delta
			if device.fuel_level <= 0.0:
				device.fuel_level = 0.0
				device.status = AutomationStatus.IDLE
				continue
		
		# Производим ресурсы
		if device.status == AutomationStatus.WORKING:
			_produce_resources(device, delta)
		
		# Проверяем место в хранилище
		if device.current_storage >= device.storage_capacity:
			device.status = AutomationStatus.FULL
			device_storage_full.emit(device_id)
		else:
			if device.status == AutomationStatus.FULL:
				device.status = AutomationStatus.WORKING

func _produce_resources(device: AutomationDevice, delta: float) -> void:
	var production_amount = device.production_rate * device.efficiency * delta
	
	# Округляем и производим
	var whole_amount = int(production_amount)
	if whole_amount > 0:
		var space_available = device.storage_capacity - device.current_storage
		var actual_amount = min(whole_amount, space_available)
		
		if actual_amount > 0:
			device.current_storage += actual_amount
			device_produced.emit(device.device_id, device.resource_type, actual_amount)

func start_device(device_id: String) -> bool:
	if not automation_devices.has(device_id):
		return false
	
	var device = automation_devices[device_id]
	
	if device.fuel_consumption > 0.0 and device.fuel_level <= 0.0:
		return false  # Нет топлива
	
	device.status = AutomationStatus.WORKING
	device.is_active = true
	return true

func stop_device(device_id: String) -> void:
	if not automation_devices.has(device_id):
		return
	
	var device = automation_devices[device_id]
	device.status = AutomationStatus.IDLE
	device.is_active = false

func collect_resources(device_id: String) -> Dictionary:
	if not automation_devices.has(device_id):
		return {}
	
	var device = automation_devices[device_id]
	
	if device.current_storage <= 0:
		return {}
	
	var collected = device.current_storage
	var resource_type = device.resource_type
	
	device.current_storage = 0
	device.status = AutomationStatus.WORKING
	
	# Добавляем ресурсы в инвентарь
	var world = get_tree().current_scene
	if world:
		var inventory = world.find_child("Inventory", true, false)
		if inventory:
			inventory.add_item(resource_type, collected)
	
	return {
		"resource_type": resource_type,
		"amount": collected
	}

func refuel_device(device_id: String, fuel_type: String, amount: float) -> bool:
	if not automation_devices.has(device_id):
		return false
	
	var device = automation_devices[device_id]
	
	if device.fuel_consumption <= 0.0:
		return false  # Устройство не требует топлива
	
	# TODO: Проверить наличие топлива в инвентаре
	device.fuel_level = min(device.max_fuel, device.fuel_level + amount)
	
	if device.status == AutomationStatus.IDLE and device.fuel_level > 0.0:
		device.status = AutomationStatus.WORKING
	
	return true

func repair_device(device_id: String) -> bool:
	if not automation_devices.has(device_id):
		return false
	
	var device = automation_devices[device_id]
	
	if device.status != AutomationStatus.BROKEN:
		return false
	
	# TODO: Проверить наличие материалов для ремонта
	device.status = AutomationStatus.IDLE
	return true

func upgrade_device(device_id: String) -> bool:
	if not automation_devices.has(device_id):
		return false
	
	var device = automation_devices[device_id]
	
	# TODO: Проверить требования для улучшения
	
	device.efficiency *= 1.2  # +20% эффективности
	device.storage_capacity = int(device.storage_capacity * 1.5)  # +50% хранилища
	device.production_rate *= 1.15  # +15% скорости
	
	return true

func get_device_info(device_id: String) -> Dictionary:
	if not automation_devices.has(device_id):
		return {}
	
	var device = automation_devices[device_id]
	return {
		"id": device.device_id,
		"type": device.device_type,
		"name": device.name,
		"status": device.status,
		"resource_type": device.resource_type,
		"current_storage": device.current_storage,
		"storage_capacity": device.storage_capacity,
		"production_rate": device.production_rate,
		"efficiency": device.efficiency,
		"fuel_level": device.fuel_level,
		"max_fuel": device.max_fuel,
		"is_active": device.is_active
	}

