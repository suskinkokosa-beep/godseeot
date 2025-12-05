extends Node
class_name FastTravelSystem

## Система быстрого перемещения для Isleborn Online
## Телепортация между открытыми точками

enum TravelPointType {
	ISLAND,         # Остров игрока
	PORT,           # Порт
	GUILD_ISLAND,   # Гильдейский остров
	DISCOVERED_RUIN, # Обнаруженные руины
	TRADE_POST      # Торговый пост
}

class TravelPoint:
	var point_id: String
	var point_type: TravelPointType
	var name: String
	var position: Vector3
	var unlocked: bool = false
	var unlocked_at: int = 0
	var cost: Dictionary = {}  # currency_type -> amount
	var required_level: int = 1
	var cooldown_seconds: float = 300.0  # 5 минут
	var last_used: int = 0
	
	func _init(_id: String, _type: TravelPointType, _name: String, _pos: Vector3):
		point_id = _id
		point_type = _type
		name = _name
		position = _pos

var travel_points: Dictionary = {}  # point_id -> TravelPoint
var unlocked_points: Array[String] = []

signal travel_point_unlocked(point_id: String)
signal fast_travel_started(from_point: String, to_point: String)
signal fast_travel_completed(to_point: String)

func _ready() -> void:
	_initialize_travel_points()

func _initialize_travel_points() -> void:
	# Базовые порты
	_create_travel_point("port_center", TravelPointType.PORT, "Центральный порт", Vector3(0, 0, 0))
	
	# Порты в разных биомах
	_create_travel_point("port_tropical", TravelPointType.PORT, "Тропический порт", Vector3(5000, 0, 5000))
	_create_travel_point("port_deep", TravelPointType.PORT, "Глубоководный порт", Vector3(10000, 0, 10000))

func _create_travel_point(point_id: String, point_type: TravelPointType, name: String, position: Vector3) -> void:
	var point = TravelPoint.new(point_id, point_type, name, position)
	
	# Устанавливаем стоимость в зависимости от типа
	point.cost = _get_cost_for_type(point_type)
	
	travel_points[point_id] = point

func _get_cost_for_type(point_type: TravelPointType) -> Dictionary:
	match point_type:
		TravelPointType.ISLAND:
			return {}  # Бесплатно на свой остров
		TravelPointType.PORT:
			return {"shells": 10}
		TravelPointType.GUILD_ISLAND:
			return {"shells": 5}
		TravelPointType.DISCOVERED_RUIN:
			return {"shells": 20}
		TravelPointType.TRADE_POST:
			return {"shells": 15}
		_:
			return {"shells": 10}

func unlock_travel_point(point_id: String) -> bool:
	if not travel_points.has(point_id):
		return false
	
	var point = travel_points[point_id]
	
	if point.unlocked:
		return false  # Уже открыто
	
	point.unlocked = true
	point.unlocked_at = Time.get_unix_time_from_system()
	unlocked_points.append(point_id)
	
	travel_point_unlocked.emit(point_id)
	
	return true

func auto_unlock_travel_point(point_type: TravelPointType, position: Vector3, name: String = "") -> String:
	# Автоматически создаёт и открывает точку перемещения
	var point_id = "travel_%d" % Time.get_ticks_msec()
	var point = TravelPoint.new(point_id, point_type, name if name != "" else "Точка перемещения", position)
	point.unlocked = true
	point.unlocked_at = Time.get_unix_time_from_system()
	point.cost = _get_cost_for_type(point_type)
	
	travel_points[point_id] = point
	unlocked_points.append(point_id)
	
	travel_point_unlocked.emit(point_id)
	
	return point_id

func can_travel(from_point_id: String, to_point_id: String) -> bool:
	if not travel_points.has(from_point_id) or not travel_points.has(to_point_id):
		return false
	
	var from_point = travel_points[from_point_id]
	var to_point = travel_points[to_point_id]
	
	if not to_point.unlocked:
		return false
	
	# Проверяем кулдаун
	var current_time = Time.get_unix_time_from_system()
	if from_point.last_used > 0:
		var time_since_used = current_time - from_point.last_used
		if time_since_used < from_point.cooldown_seconds:
			return false  # Ещё на кулдауне
	
	# Проверяем стоимость
	if not _can_afford_travel(to_point):
		return false
	
	return true

func _can_afford_travel(point: TravelPoint) -> bool:
	if point.cost.is_empty():
		return true
	
	# TODO: Проверить валюту у игрока
	var world = get_tree().current_scene
	if world:
		var currency_system = world.find_child("CurrencySystem", true, false)
		if currency_system:
			for currency_type_str in point.cost.keys():
				var amount = point.cost[currency_type_str]
				# TODO: Проверить, достаточно ли валюты
				pass
	
	return true

func fast_travel(from_point_id: String, to_point_id: String) -> bool:
	if not can_travel(from_point_id, to_point_id):
		return false
	
	var from_point = travel_points[from_point_id]
	var to_point = travel_points[to_point_id]
	
	# Оплачиваем перемещение
	_pay_travel_cost(to_point)
	
	# Устанавливаем кулдаун
	var current_time = Time.get_unix_time_from_system()
	from_point.last_used = current_time
	
	fast_travel_started.emit(from_point_id, to_point_id)
	
	# Перемещаем игрока (с небольшой задержкой для эффекта)
	await get_tree().create_timer(1.0).timeout
	
	_teleport_player(to_point.position)
	
	fast_travel_completed.emit(to_point_id)
	
	return true

func _pay_travel_cost(point: TravelPoint) -> void:
	if point.cost.is_empty():
		return
	
	# TODO: Списать валюту у игрока
	var world = get_tree().current_scene
	if world:
		var currency_system = world.find_child("CurrencySystem", true, false)
		if currency_system:
			for currency_type_str in point.cost.keys():
				var amount = point.cost[currency_type_str]
				# TODO: Списать валюту
				pass

func _teleport_player(position: Vector3) -> void:
	# TODO: Переместить игрока на позицию
	var world = get_tree().current_scene
	if world:
		var player = world.find_child("LocalPlayer", true, false)
		if player:
			player.global_position = position

func get_travel_points() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for point_id in unlocked_points:
		if travel_points.has(point_id):
			var point = travel_points[point_id]
			var current_time = Time.get_unix_time_from_system()
			var cooldown_remaining = 0.0
			
			if point.last_used > 0:
				var time_since_used = current_time - point.last_used
				cooldown_remaining = max(0.0, point.cooldown_seconds - time_since_used)
			
			result.append({
				"id": point.point_id,
				"type": point.point_type,
				"name": point.name,
				"position": point.position,
				"cost": point.cost.duplicate(),
				"cooldown_remaining": cooldown_remaining
			})
	
	return result

func get_travel_point_info(point_id: String) -> Dictionary:
	if not travel_points.has(point_id):
		return {}
	
	var point = travel_points[point_id]
	var current_time = Time.get_unix_time_from_system()
	var cooldown_remaining = 0.0
	
	if point.last_used > 0:
		var time_since_used = current_time - point.last_used
		cooldown_remaining = max(0.0, point.cooldown_seconds - time_since_used)
	
	return {
		"id": point.point_id,
		"type": point.point_type,
		"name": point.name,
		"position": point.position,
		"unlocked": point.unlocked,
		"cost": point.cost.duplicate(),
		"cooldown_remaining": cooldown_remaining,
		"required_level": point.required_level
	}

