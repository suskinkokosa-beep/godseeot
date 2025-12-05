extends Node
class_name OceanCurrentsSystem

## Система течений океана для Isleborn Online
## Согласно GDD: течения ускоряют корабли, открывают скрытые зоны

enum CurrentType {
	NORMAL,         # Обычное течение
	STRONG,         # Сильное течение
	WHIRLPOOL,      # Водоворот (Blackwater)
	MAGICAL,        # Магическое течение
	STORM           # Штормовое течение
}

class CurrentData:
	var current_id: String
	var position: Vector3
	var direction: Vector3
	var strength: float = 1.0  # Множитель скорости
	var radius: float = 100.0  # Радиус влияния
	var current_type: CurrentType = CurrentType.NORMAL
	var is_active: bool = true
	var biome: String = ""
	var effects: Dictionary = {}
	
	func _init(_id: String, _pos: Vector3, _dir: Vector3):
		current_id = _id
		position = _pos
		direction = _dir.normalized()

var ocean_currents: Dictionary = {}  # current_id -> CurrentData
var current_zones: Array[Dictionary] = []  # Зоны течений для быстрого поиска

signal current_entered(current_id: String, ship_id: String)
signal current_exited(current_id: String, ship_id: String)

func _ready() -> void:
	_generate_initial_currents()

func _generate_initial_currents() -> void:
	# Генерируем базовые течения в разных биомах
	_create_current("current_tropical_1", Vector3(100, 0, 100), Vector3(1, 0, 0), CurrentType.NORMAL, 1.2, 150.0, "Tropical Shallow")
	_create_current("current_deep_blue_1", Vector3(500, -20, 500), Vector3(0, 0, 1), CurrentType.STRONG, 1.5, 200.0, "Deep Blue")
	_create_current("current_mist_1", Vector3(800, -10, 800), Vector3(-1, 0, 1), CurrentType.MAGICAL, 1.3, 180.0, "Mist Sea")
	_create_current("current_blackwater_1", Vector3(1500, -200, 1500), Vector3(0, -0.2, 1), CurrentType.WHIRLPOOL, 2.0, 100.0, "Blackwater")

func _create_current(current_id: String, position: Vector3, direction: Vector3, 
                    current_type: CurrentType, strength: float, radius: float, biome: String) -> void:
	var current = CurrentData.new(current_id, position, direction)
	current.current_type = current_type
	current.strength = strength
	current.radius = radius
	current.biome = biome
	
	# Устанавливаем эффекты в зависимости от типа
	match current_type:
		CurrentType.NORMAL:
			current.effects = {"speed_multiplier": strength}
		CurrentType.STRONG:
			current.effects = {"speed_multiplier": strength, "stability_reduction": 0.1}
		CurrentType.WHIRLPOOL:
			current.effects = {"speed_multiplier": strength, "damage_per_second": 5.0, "teleport_chance": 0.05}
		CurrentType.MAGICAL:
			current.effects = {"speed_multiplier": strength, "mana_regen_boost": 2.0}
		CurrentType.STORM:
			current.effects = {"speed_multiplier": strength, "visibility_reduction": 0.5, "damage_per_second": 2.0}
	
	ocean_currents[current_id] = current
	
	# Добавляем в зоны для быстрого поиска
	current_zones.append({
		"current_id": current_id,
		"position": position,
		"radius": radius
	})

## Получить влияние течения на позицию
func get_current_influence(position: Vector3) -> Dictionary:
	var result: Dictionary = {
		"direction": Vector3.ZERO,
		"strength": 0.0,
		"effects": {},
		"current_ids": []
	}
	
	for current_id in ocean_currents.keys():
		var current = ocean_currents[current_id]
		if not current.is_active:
			continue
		
		var distance = position.distance_to(current.position)
		if distance > current.radius:
			continue
		
		# Влияние уменьшается с расстоянием
		var influence_factor = 1.0 - (distance / current.radius)
		var effective_strength = current.strength * influence_factor
		
		# Комбинируем направление
		result["direction"] += current.direction * effective_strength
		result["strength"] = max(result["strength"], effective_strength)
		
		# Комбинируем эффекты
		for effect_key in current.effects.keys():
			if result["effects"].has(effect_key):
				result["effects"][effect_key] += current.effects[effect_key] * influence_factor
			else:
				result["effects"][effect_key] = current.effects[effect_key] * influence_factor
		
		result["current_ids"].append(current_id)
	
	# Нормализуем направление
	if result["direction"].length() > 0.0:
		result["direction"] = result["direction"].normalized()
	
	return result

## Применить влияние течения на корабль
func apply_current_to_ship(ship_position: Vector3, ship_velocity: Vector3, ship_id: String = "") -> Vector3:
	var influence = get_current_influence(ship_position)
	
	if influence["strength"] <= 0.0:
		return ship_velocity
	
	# Добавляем влияние течения к скорости корабля
	var current_velocity = influence["direction"] * influence["strength"] * 2.0
	var new_velocity = ship_velocity + current_velocity
	
	# Ограничиваем максимальную скорость
	var max_speed = 10.0  # TODO: Получать из параметров корабля
	if new_velocity.length() > max_speed:
		new_velocity = new_velocity.normalized() * max_speed
	
	return new_velocity

## Создать новое течение
func create_current(position: Vector3, direction: Vector3, current_type: CurrentType = CurrentType.NORMAL, 
                   strength: float = 1.0, radius: float = 100.0, biome: String = "") -> String:
	var current_id = "current_%d" % Time.get_ticks_msec()
	_create_current(current_id, position, direction, current_type, strength, radius, biome)
	return current_id

## Удалить течение
func remove_current(current_id: String) -> void:
	if ocean_currents.has(current_id):
		ocean_currents.erase(current_id)
		
		# Удаляем из зон
		for i in range(current_zones.size() - 1, -1, -1):
			if current_zones[i]["current_id"] == current_id:
				current_zones.remove_at(i)
				break

## Получить ближайшее течение
func get_nearest_current(position: Vector3) -> CurrentData:
	var nearest: CurrentData = null
	var nearest_distance: float = INF
	
	for current_id in ocean_currents.keys():
		var current = ocean_currents[current_id]
		if not current.is_active:
			continue
		
		var distance = position.distance_to(current.position)
		if distance < current.radius and distance < nearest_distance:
			nearest_distance = distance
			nearest = current
	
	return nearest

## Получить все течения в радиусе
func get_currents_in_radius(position: Vector3, radius: float) -> Array[CurrentData]:
	var result: Array[CurrentData] = []
	
	for current_id in ocean_currents.keys():
		var current = ocean_currents[current_id]
		if not current.is_active:
			continue
		
		var distance = position.distance_to(current.position)
		if distance <= radius:
			result.append(current)
	
	return result

## Изменить активность течения
func set_current_active(current_id: String, active: bool) -> void:
	if ocean_currents.has(current_id):
		ocean_currents[current_id].is_active = active

## Получить информацию о течении
func get_current_info(current_id: String) -> Dictionary:
	if not ocean_currents.has(current_id):
		return {}
	
	var current = ocean_currents[current_id]
	return {
		"id": current.current_id,
		"position": current.position,
		"direction": current.direction,
		"strength": current.strength,
		"radius": current.radius,
		"type": current.current_type,
		"biome": current.biome,
		"effects": current.effects.duplicate()
	}

