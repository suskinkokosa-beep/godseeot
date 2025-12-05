extends Node
class_name AIGuildSystem

## Система AI-гильдий для Isleborn Online
## Согласно GDD: AI-гильдии ведут себя как живые игроки

enum AIGuildType {
	TRADER,         # Торговцы
	WARRIOR,        # Военные
	PIRATE,         # Пираты
	EXPLORER,       # Исследователи
	RELIGIOUS,      # Религиозные
	CREATOR         # Созидатели
}

enum AIGuildDiplomacy {
	NEUTRAL,        # Нейтралитет
	TRADE,          # Торговля
	PEACE,          # Мир
	WAR,            # Война
	VASSAL          # Вассалитет
}

class AIGuildData:
	var guild_id: String
	var name: String
	var guild_type: AIGuildType
	var level: int = 1
	var experience: float = 0.0
	var island_position: Vector3
	var ships: Array[String] = []  # ship_ids
	var npcs: Array[String] = []   # npc_ids
	var resources: Dictionary = {}
	var territory: Array[Vector3] = []  # Контролируемые точки
	var diplomacy: Dictionary = {}  # player_id or guild_id -> AIGuildDiplomacy
	var behavior_state: String = "patrol"  # patrol, trade, war, build
	var reputation: Dictionary = {}  # player_id -> reputation value
	var trade_routes: Array[Dictionary] = []
	var active_quests: Array[String] = []  # quest_ids для игроков
	
	func _init(_id: String, _name: String, _type: AIGuildType, _pos: Vector3):
		guild_id = _id
		name = _name
		guild_type = _type
		island_position = _pos

var ai_guilds: Dictionary = {}  # guild_id -> AIGuildData

signal guild_spawned(guild_id: String)
signal guild_destroyed(guild_id: String)
signal diplomacy_changed(guild_id: String, target_id: String, new_status: AIGuildDiplomacy)
signal trade_route_opened(guild_id: String, route: Dictionary)

func _ready() -> void:
	_spawn_initial_guilds()

func _process(delta: float) -> void:
	# Обновляем поведение всех AI-гильдий
	for guild_id in ai_guilds.keys():
		_update_guild_behavior(guild_id, delta)

func _spawn_initial_guilds() -> void:
	# Создаём начальные AI-гильдии
	_create_ai_guild("Sailing Coin", AIGuildType.TRADER, Vector3(1000, 0, 1000))
	_create_ai_guild("Kraken Maw", AIGuildType.PIRATE, Vector3(2000, 0, 500))
	_create_ai_guild("Abyssal Choir", AIGuildType.RELIGIOUS, Vector3(3000, -100, 3000))
	_create_ai_guild("Storm Order", AIGuildType.WARRIOR, Vector3(1500, 0, 2000))
	_create_ai_guild("Sea Explorers", AIGuildType.EXPLORER, Vector3(500, 0, 1500))
	_create_ai_guild("The Creators", AIGuildType.CREATOR, Vector3(2500, 0, 1500))

func _create_ai_guild(name: String, guild_type: AIGuildType, position: Vector3) -> AIGuildData:
	var guild_id = "ai_guild_%s_%d" % [name.to_lower().replace(" ", "_"), Time.get_ticks_msec()]
	var guild = AIGuildData.new(guild_id, name, guild_type, position)
	
	# Инициализируем ресурсы в зависимости от типа
	match guild_type:
		AIGuildType.TRADER:
			guild.resources = {"shells": 10000, "gold": 500}
			guild.behavior_state = "trade"
		AIGuildType.PIRATE:
			guild.resources = {"shells": 5000}
			guild.behavior_state = "patrol"
		AIGuildType.WARRIOR:
			guild.resources = {"shells": 7000, "metal": 100}
			guild.behavior_state = "patrol"
		AIGuildType.EXPLORER:
			guild.resources = {"shells": 6000}
			guild.behavior_state = "explore"
		AIGuildType.RELIGIOUS:
			guild.resources = {"shells": 8000, "magic_crystals": 50}
			guild.behavior_state = "patrol"
		AIGuildType.CREATOR:
			guild.resources = {"shells": 12000, "metal": 200, "wood": 300}
			guild.behavior_state = "build"
	
	# Инициализируем территорию
	_generate_territory(guild)
	
	ai_guilds[guild_id] = guild
	guild_spawned.emit(guild_id)
	
	return guild

func _generate_territory(guild: AIGuildData) -> void:
	# Генерируем территорию вокруг острова гильдии
	var base_radius = 500.0
	for i in range(8):
		var angle = (i / 8.0) * TAU
		var point = guild.island_position + Vector3(
			cos(angle) * base_radius,
			0.0,
			sin(angle) * base_radius
		)
		guild.territory.append(point)

func _update_guild_behavior(guild_id: String, delta: float) -> void:
	var guild = ai_guilds.get(guild_id)
	if not guild:
		return
	
	match guild.behavior_state:
		"patrol":
			_behavior_patrol(guild, delta)
		"trade":
			_behavior_trade(guild, delta)
		"war":
			_behavior_war(guild, delta)
		"build":
			_behavior_build(guild, delta)
		"explore":
			_behavior_explore(guild, delta)

func _behavior_patrol(guild: AIGuildData, delta: float) -> void:
	# Патрулирование территории
	# TODO: Движение кораблей по маршруту
	pass

func _behavior_trade(guild: AIGuildData, delta: float) -> void:
	# Торговля и установка маршрутов
	if guild.trade_routes.is_empty():
		_create_trade_route(guild)
	# TODO: Отправка торговых кораблей

func _behavior_war(guild: AIGuildData, delta: float) -> void:
	# Военное поведение
	# TODO: Поиск целей, атака

func _behavior_build(guild: AIGuildData, delta: float) -> void:
	# Строительство и развитие
	# TODO: Расширение острова, постройки

func _behavior_explore(guild: AIGuildData, delta: float) -> void:
	# Исследование новых зон
	# TODO: Отправка экспедиций

func _create_trade_route(guild: AIGuildData) -> void:
	# Создаём торговый маршрут
	var route = {
		"from": guild.island_position,
		"to": Vector3(guild.island_position.x + 1000, 0, guild.island_position.z + 1000),
		"goods": {},
		"frequency": 3600.0,  # Раз в час
		"last_trade": Time.get_unix_time_from_system()
	}
	
	guild.trade_routes.append(route)
	trade_route_opened.emit(guild.guild_id, route)

## Изменить дипломатию с игроком или гильдией
func change_diplomacy(guild_id: String, target_id: String, new_status: AIGuildDiplomacy) -> bool:
	var guild = ai_guilds.get(guild_id)
	if not guild:
		return false
	
	var old_status = guild.diplomacy.get(target_id, AIGuildDiplomacy.NEUTRAL)
	guild.diplomacy[target_id] = new_status
	
	if old_status != new_status:
		diplomacy_changed.emit(guild_id, target_id, new_status)
	
	return true

## Изменить репутацию игрока с AI-гильдией
func change_reputation(guild_id: String, player_id: String, amount: int) -> void:
	var guild = ai_guilds.get(guild_id)
	if not guild:
		return
	
	if not guild.reputation.has(player_id):
		guild.reputation[player_id] = 50  # Нейтральная репутация
	
	guild.reputation[player_id] = clamp(guild.reputation[player_id] + amount, 0, 100)
	
	# Автоматически меняем дипломатию на основе репутации
	var rep = guild.reputation[player_id]
	if rep >= 70 and guild.diplomacy.get(player_id, AIGuildDiplomacy.NEUTRAL) != AIGuildDiplomacy.PEACE:
		change_diplomacy(guild_id, player_id, AIGuildDiplomacy.PEACE)
	elif rep <= 30 and guild.diplomacy.get(player_id, AIGuildDiplomacy.NEUTRAL) != AIGuildDiplomacy.WAR:
		if guild.guild_type == AIGuildType.PIRATE:
			change_diplomacy(guild_id, player_id, AIGuildDiplomacy.WAR)

## Получить информацию об AI-гильдии
func get_guild_info(guild_id: String) -> Dictionary:
	var guild = ai_guilds.get(guild_id)
	if not guild:
		return {}
	
	return {
		"id": guild.guild_id,
		"name": guild.name,
		"type": guild.guild_type,
		"level": guild.level,
		"island_position": guild.island_position,
		"behavior_state": guild.behavior_state,
		"diplomacy": guild.diplomacy.duplicate(),
		"reputation": guild.reputation.duplicate()
	}

## Получить все AI-гильдии
func get_all_guilds() -> Dictionary:
	return ai_guilds.duplicate()

## Получить ближайшую AI-гильдию
func get_nearest_guild(position: Vector3) -> AIGuildData:
	var nearest: AIGuildData = null
	var nearest_distance: float = INF
	
	for guild_id in ai_guilds.keys():
		var guild = ai_guilds[guild_id]
		var distance = position.distance_to(guild.island_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = guild
	
	return nearest

