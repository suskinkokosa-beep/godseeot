extends Node
class_name TradeRouteSystem

## Система торговых маршрутов для Isleborn Online
## Согласно GDD: торговые маршруты между островами, AI-караваны, динамические цены

enum RouteStatus {
	PLANNING,       # Планируется
	ACTIVE,         # Активен
	IN_PROGRESS,    # В процессе
	COMPLETED,      # Завершён
	CANCELLED,      # Отменён
	INTERRUPTED     # Прерван
}

enum RouteType {
	PLAYER_TO_PLAYER,   # Игрок -> Игрок
	PLAYER_TO_NPC,      # Игрок -> NPC
	AI_CARAVAN,         # AI-караван
	GUILD_ROUTE         # Гильдейский маршрут
}

class TradeRoute:
	var route_id: String
	var owner_id: String
	var route_type: RouteType
	var status: RouteStatus = RouteStatus.PLANNING
	var from_position: Vector3
	var to_position: Vector3
	var cargo: Dictionary = {}  # item_id -> quantity
	var cargo_value: float = 0.0
	var distance: float = 0.0
	var estimated_time: float = 0.0
	var started_at: int = 0
	var completed_at: int = 0
	var profit: float = 0.0
	var risks: Array[String] = []
	var escorts: Array[String] = []  # player_ids или ship_ids
	var route_waypoints: Array[Vector3] = []
	
	func _init(_id: String, _owner: String, _type: RouteType):
		route_id = _id
		owner_id = _owner
		route_type = _type

class TradeRouteNode:
	var node_id: String
	var position: Vector3
	var node_type: String  # "island", "port", "trade_post"
	var owner_id: String
	var trade_goods: Dictionary = {}  # item_id -> {buy_price, sell_price, stock}
	var reputation_required: int = 0
	var biome: String = ""
	
	func _init(_id: String, _type: String, _pos: Vector3):
		node_id = _id
		node_type = _type
		position = _pos

var active_routes: Dictionary = {}  # route_id -> TradeRoute
var route_nodes: Dictionary = {}  # node_id -> TradeRouteNode
var route_history: Array[TradeRoute] = []

signal route_created(route_id: String)
signal route_started(route_id: String)
signal route_completed(route_id: String, profit: float)
signal route_interrupted(route_id: String, reason: String)

func _ready() -> void:
	_generate_trade_nodes()

func _process(delta: float) -> void:
	_update_active_routes(delta)

func _generate_trade_nodes() -> void:
	# Генерируем торговые узлы (порты, острова игроков, торговые посты)
	# TODO: Интегрировать с существующими системами
	
	# Пример: порт в центре
	_create_trade_node("port_center", "port", Vector3(0, 0, 0))
	
	# AI-торговые посты
	_create_trade_node("ai_trader_1", "trade_post", Vector3(1000, 0, 1000))

func _create_trade_node(node_id: String, node_type: String, position: Vector3) -> void:
	var node = TradeRouteNode.new(node_id, node_type, position)
	
	# Устанавливаем товары в зависимости от типа
	match node_type:
		"port":
			node.trade_goods = {
				"palm_wood": {"buy_price": 5, "sell_price": 8, "stock": 100},
				"metal": {"buy_price": 15, "sell_price": 20, "stock": 50}
			}
		"trade_post":
			node.trade_goods = {
				"fish": {"buy_price": 2, "sell_price": 4, "stock": 200}
			}
	
	route_nodes[node_id] = node

func create_trade_route(owner_id: String, from_node_id: String, to_node_id: String, cargo: Dictionary, route_type: RouteType = RouteType.PLAYER_TO_PLAYER) -> String:
	if not route_nodes.has(from_node_id) or not route_nodes.has(to_node_id):
		return ""
	
	var from_node = route_nodes[from_node_id]
	var to_node = route_nodes[to_node_id]
	
	var route_id = "route_%d" % Time.get_ticks_msec()
	var route = TradeRoute.new(route_id, owner_id, route_type)
	
	route.from_position = from_node.position
	route.to_position = to_node.position
	route.cargo = cargo.duplicate()
	route.distance = from_node.position.distance_to(to_node.position)
	
	# Вычисляем стоимость груза
	route.cargo_value = _calculate_cargo_value(cargo, from_node)
	
	# Вычисляем прибыль
	route.profit = _calculate_expected_profit(cargo, from_node, to_node)
	
	# Вычисляем время в пути (зависит от расстояния и скорости корабля)
	route.estimated_time = route.distance / 5.0  # Пример: 5 м/с
	
	# Генерируем риски
	route.risks = _calculate_route_risks(route)
	
	# Генерируем waypoints
	route.route_waypoints = _generate_waypoints(route.from_position, route.to_position)
	
	active_routes[route_id] = route
	route_created.emit(route_id)
	
	return route_id

func start_route(route_id: String, ship_id: String = "") -> bool:
	if not active_routes.has(route_id):
		return false
	
	var route = active_routes[route_id]
	
	if route.status != RouteStatus.PLANNING:
		return false
	
	route.status = RouteStatus.IN_PROGRESS
	route.started_at = Time.get_unix_time_from_system()
	route.completed_at = route.started_at + int(route.estimated_time)
	
	route_started.emit(route_id)
	return true

func _update_active_routes(delta: float) -> void:
	var current_time = Time.get_unix_time_from_system()
	
	for route_id in active_routes.keys():
		var route = active_routes[route_id]
		
		if route.status == RouteStatus.IN_PROGRESS:
			# Проверяем, завершён ли маршрут
			if current_time >= route.completed_at:
				_complete_route(route_id)
			
			# Проверяем риски
			_check_route_risks(route_id)

func _calculate_cargo_value(cargo: Dictionary, from_node: TradeRouteNode) -> float:
	var total_value = 0.0
	
	for item_id in cargo.keys():
		var quantity = cargo[item_id]
		var buy_price = from_node.trade_goods.get(item_id, {}).get("buy_price", 0)
		total_value += buy_price * quantity
	
	return total_value

func _calculate_expected_profit(cargo: Dictionary, from_node: TradeRouteNode, to_node: TradeRouteNode) -> float:
	var total_profit = 0.0
	
	for item_id in cargo.keys():
		var quantity = cargo[item_id]
		var buy_price = from_node.trade_goods.get(item_id, {}).get("buy_price", 0)
		var sell_price = to_node.trade_goods.get(item_id, {}).get("sell_price", 0)
		
		if sell_price > buy_price:
			total_profit += (sell_price - buy_price) * quantity
	
	return total_profit

func _calculate_route_risks(route: TradeRoute) -> Array[String]:
	var risks: Array[String] = []
	
	# Риск пиратов
	if route.distance > 500.0:
		risks.append("pirates")
	
	# Риск шторма
	if randf() < 0.3:
		risks.append("storm")
	
	# Риск монстров
	if route.distance > 1000.0:
		risks.append("monsters")
	
	return risks

func _check_route_risks(route_id: String) -> void:
	var route = active_routes[route_id]
	if not route:
		return
	
	for risk in route.risks:
		var chance = 0.01  # 1% в секунду
		
		if randf() < chance * get_process_delta_time():
			# Риск сработал
			match risk:
				"pirates":
					_interrupt_route(route_id, "Атакованы пиратами!")
				"storm":
					# Увеличиваем время пути
					route.estimated_time *= 1.5
				"monsters":
					_interrupt_route(route_id, "Атакованы монстрами!")

func _interrupt_route(route_id: String, reason: String) -> void:
	var route = active_routes[route_id]
	if not route:
		return
	
	route.status = RouteStatus.INTERRUPTED
	route_interrupted.emit(route_id, reason)
	
	# Возвращаем часть груза
	# TODO: Вычислить потери

func _complete_route(route_id: String) -> void:
	var route = active_routes[route_id]
	if not route:
		return
	
	route.status = RouteStatus.COMPLETED
	
	# Выдаём прибыль
	_give_route_profit(route)
	
	route_completed.emit(route_id, route.profit)
	
	# Перемещаем в историю
	route_history.append(route)
	active_routes.erase(route_id)

func _give_route_profit(route: TradeRoute) -> void:
	# TODO: Интегрировать с CurrencySystem
	var world = get_tree().current_scene
	if world:
		var currency_system = world.find_child("CurrencySystem", true, false)
		if currency_system:
			currency_system.add_currency(CurrencySystem.CurrencyType.SHELLS, int(route.profit))

func _generate_waypoints(from: Vector3, to: Vector3) -> Array[Vector3]:
	var waypoints: Array[Vector3] = [from]
	
	# Простая линейная траектория (можно улучшить для обхода препятствий)
	waypoints.append(to)
	
	return waypoints

func get_route_info(route_id: String) -> Dictionary:
	if not active_routes.has(route_id):
		return {}
	
	var route = active_routes[route_id]
	var current_time = Time.get_unix_time_from_system()
	var progress = 0.0
	
	if route.status == RouteStatus.IN_PROGRESS:
		var elapsed = current_time - route.started_at
		progress = min(1.0, float(elapsed) / float(route.completed_at - route.started_at))
	
	return {
		"id": route.route_id,
		"type": route.route_type,
		"status": route.status,
		"from": route.from_position,
		"to": route.to_position,
		"cargo": route.cargo.duplicate(),
		"profit": route.profit,
		"distance": route.distance,
		"progress": progress,
		"risks": route.risks.duplicate()
	}

