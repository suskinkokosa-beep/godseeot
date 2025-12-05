extends Node
class_name ResourceGatheringSystem

## Расширенная система добычи ресурсов для Isleborn Online
## Согласно GDD: сети, ловушки, фермы, автоматические установки, NPC-добытчики

enum GatheringMethod {
	HAND,           # Ручная добыча
	TOOL,           # С инструментом
	NET,            # Сеть
	TRAP,           # Ловушка
	FARM,           # Ферма
	AUTOMATED,      # Автоматическая установка
	NPC             # NPC-добытчик
}

enum ResourceType {
	WOOD,           # Дерево
	STONE,          # Камень
	FISH,           # Рыба
	WATER,          # Вода
	FIBER,          # Тростник
	SALT,           # Соль
	METAL,          # Металл
	CRYSTAL,        # Магические кристаллы
	ESSENCE,        # Эссенции монстров
	CORE            # Земляные ядра
}

enum ResourceRarity {
	COMMON,         # Обычные
	UNCOMMON,       # Необычные
	RARE,           # Редкие
	UNIQUE          # Уникальные
}

class ResourceNode:
	var node_id: String
	var resource_type: ResourceType
	var rarity: ResourceRarity
	var position: Vector3
	var amount: float = 100.0  # Количество ресурса
	var max_amount: float = 100.0
	var respawn_time: float = 300.0  # Время респавна в секундах
	var last_harvested: int = 0
	var gathering_methods: Array[GatheringMethod] = []
	var biome: String = ""
	var depth: float = 0.0  # Глубина (для подводных ресурсов)
	
	func _init(_id: String, _type: ResourceType, _pos: Vector3):
		node_id = _id
		resource_type = _type
		position = _pos

class GatheringTool:
	var tool_id: String
	var name: String
	var gathering_method: GatheringMethod
	var efficiency: float = 1.0  # Множитель эффективности
	var durability: float = 100.0
	var max_durability: float = 100.0
	var required_level: int = 1
	
	func _init(_id: String, _name: String, _method: GatheringMethod):
		tool_id = _id
		name = _name
		gathering_method = _method

var resource_nodes: Dictionary = {}  # node_id -> ResourceNode
var gathering_tools: Dictionary = {}  # tool_id -> GatheringTool
var active_gathering_tasks: Dictionary = {}  # task_id -> {node_id, player_id, progress, method}

signal resource_harvested(node_id: String, resource_type: ResourceType, amount: float, player_id: String)
signal resource_node_depleted(node_id: String)
signal resource_node_respawned(node_id: String)

func _ready() -> void:
	_initialize_tools()

func _process(delta: float) -> void:
	_update_resource_respawn(delta)
	_update_gathering_tasks(delta)

func _initialize_tools() -> void:
	# Базовые инструменты
	_register_tool("stone_axe", "Каменный топор", GatheringMethod.TOOL, 1.2, 1)
	_register_tool("stone_pickaxe", "Каменная кирка", GatheringMethod.TOOL, 1.3, 1)
	_register_tool("fishing_rod", "Удочка", GatheringMethod.NET, 1.0, 1)
	_register_tool("fishing_net", "Рыболовная сеть", GatheringMethod.NET, 1.5, 3)
	_register_tool("metal_axe", "Металлический топор", GatheringMethod.TOOL, 1.5, 5)
	_register_tool("metal_pickaxe", "Металлическая кирка", GatheringMethod.TOOL, 1.6, 5)

func _register_tool(tool_id: String, name: String, method: GatheringMethod, efficiency: float, level: int) -> void:
	var tool = GatheringTool.new(tool_id, name, method)
	tool.efficiency = efficiency
	tool.required_level = level
	gathering_tools[tool_id] = tool

func create_resource_node(resource_type: ResourceType, position: Vector3, amount: float = 100.0, rarity: ResourceRarity = ResourceRarity.COMMON, biome: String = "") -> String:
	var node_id = "resource_%d" % Time.get_ticks_msec()
	var node = ResourceNode.new(node_id, resource_type, position)
	node.amount = amount
	node.max_amount = amount
	node.rarity = rarity
	node.biome = biome
	
	# Устанавливаем методы добычи в зависимости от типа
	_setup_gathering_methods(node)
	
	resource_nodes[node_id] = node
	return node_id

func harvest_resource(node_id: String, player_id: String, tool_id: String = "", amount: float = 1.0) -> Dictionary:
	if not resource_nodes.has(node_id):
		return {"success": false, "error": "Resource node not found"}
	
	var node = resource_nodes[node_id]
	
	# Проверяем доступность ресурса
	if node.amount <= 0.0:
		return {"success": false, "error": "Resource depleted"}
	
	# Проверяем респавн
	var current_time = Time.get_unix_time_from_system()
	if node.last_harvested > 0:
		var time_since_harvest = current_time - node.last_harvested
		if time_since_harvest < node.respawn_time:
			return {"success": false, "error": "Resource not respawned yet"}
	
	# Определяем эффективность добычи
	var efficiency = 1.0
	var gathering_method = GatheringMethod.HAND
	
	if tool_id != "" and gathering_tools.has(tool_id):
		var tool = gathering_tools[tool_id]
		efficiency = tool.efficiency
		gathering_method = tool.gathering_method
		
		# Проверяем, можно ли использовать этот метод для данного ресурса
		if gathering_method not in node.gathering_methods:
			return {"success": false, "error": "Wrong gathering method"}
		
		# Уменьшаем прочность инструмента
		tool.durability -= 1.0
		if tool.durability <= 0.0:
			return {"success": false, "error": "Tool broken"}
	
	# Вычисляем добытое количество
	var harvested_amount = amount * efficiency
	if harvested_amount > node.amount:
		harvested_amount = node.amount
	
	node.amount -= harvested_amount
	node.last_harvested = current_time
	
	# Если ресурс исчерпан, отправляем сигнал
	if node.amount <= 0.0:
		node.amount = 0.0
		resource_node_depleted.emit(node_id)
	
	resource_harvested.emit(node_id, node.resource_type, harvested_amount, player_id)
	
	return {
		"success": true,
		"amount": harvested_amount,
		"resource_type": node.resource_type,
		"remaining": node.amount
	}

func start_gathering_task(node_id: String, player_id: String, tool_id: String = "", gathering_time: float = 2.0) -> String:
	if not resource_nodes.has(node_id):
		return ""
	
	var node = resource_nodes[node_id]
	if node.amount <= 0.0:
		return ""
	
	var task_id = "gathering_%d" % Time.get_ticks_msec()
	active_gathering_tasks[task_id] = {
		"node_id": node_id,
		"player_id": player_id,
		"tool_id": tool_id,
		"progress": 0.0,
		"time_needed": gathering_time,
		"started_at": Time.get_ticks_msec()
	}
	
	return task_id

func _update_gathering_tasks(delta: float) -> void:
	var completed_tasks: Array[String] = []
	
	for task_id in active_gathering_tasks.keys():
		var task = active_gathering_tasks[task_id]
		task["progress"] += delta
		
		if task["progress"] >= task["time_needed"]:
			# Задача завершена, добываем ресурс
			harvest_resource(task["node_id"], task["player_id"], task.get("tool_id", ""), 1.0)
			completed_tasks.append(task_id)
	
	for task_id in completed_tasks:
		active_gathering_tasks.erase(task_id)

func _update_resource_respawn(delta: float) -> void:
	var current_time = Time.get_unix_time_from_system()
	
	for node_id in resource_nodes.keys():
		var node = resource_nodes[node_id]
		
		# Если ресурс исчерпан, проверяем респавн
		if node.amount <= 0.0 and node.last_harvested > 0:
			var time_since_harvest = current_time - node.last_harvested
			if time_since_harvest >= node.respawn_time:
				# Ресурс респавнится
				node.amount = node.max_amount
				node.last_harvested = 0
				resource_node_respawned.emit(node_id)

func _setup_gathering_methods(node: ResourceNode) -> void:
	match node.resource_type:
		ResourceType.WOOD:
			node.gathering_methods = [GatheringMethod.HAND, GatheringMethod.TOOL]
			node.respawn_time = 600.0  # 10 минут
		ResourceType.STONE:
			node.gathering_methods = [GatheringMethod.TOOL]
			node.respawn_time = 900.0  # 15 минут
		ResourceType.FISH:
			node.gathering_methods = [GatheringMethod.NET, GatheringMethod.TRAP]
			node.respawn_time = 300.0  # 5 минут
		ResourceType.WATER:
			node.gathering_methods = [GatheringMethod.HAND, GatheringMethod.AUTOMATED]
			node.respawn_time = 60.0  # 1 минута
		ResourceType.METAL:
			node.gathering_methods = [GatheringMethod.TOOL]
			node.respawn_time = 1800.0  # 30 минут
		ResourceType.CRYSTAL:
			node.gathering_methods = [GatheringMethod.TOOL]
			node.respawn_time = 3600.0  # 1 час
			node.rarity = ResourceRarity.RARE
		_:
			node.gathering_methods = [GatheringMethod.HAND]
			node.respawn_time = 300.0

func get_resource_node_info(node_id: String) -> Dictionary:
	if not resource_nodes.has(node_id):
		return {}
	
	var node = resource_nodes[node_id]
	return {
		"id": node.node_id,
		"type": node.resource_type,
		"rarity": node.rarity,
		"amount": node.amount,
		"max_amount": node.max_amount,
		"position": node.position,
		"biome": node.biome,
		"methods": node.gathering_methods
	}

func get_available_tools() -> Dictionary:
	return gathering_tools.duplicate()

