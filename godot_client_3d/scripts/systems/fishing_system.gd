extends Node
class_name FishingSystem

## Полноценная система рыбалки для Isleborn Online
## Согласно GDD: рыбалка сетями, удочками, ловушками

enum FishingMethod {
	ROD,            # Удочка (активная рыбалка)
	NET,            # Сеть (пассивная)
	TRAP,           # Ловушка
	SPEAR,          # Гарпун (подводная)
	COMMERCIAL      # Коммерческая сеть (NPC/автоматизация)
}

enum FishType {
	COMMON,         # Обычная рыба
	RARE,           # Редкая рыба
	LEGENDARY,      # Легендарная рыба
	TREASURE        # Сокровище (случайный предмет)
}

class FishData:
	var fish_id: String
	var name: String
	var fish_type: FishType
	var size: float = 1.0  # Размер рыбы
	var weight: float = 1.0  # Вес в кг
	var rarity: float = 0.5  # Редкость (0.0-1.0)
	var biome: String = ""  # В каком биоме встречается
	var depth_range: Vector2 = Vector2(0, 10)  # Диапазон глубин
	var value: float = 10.0  # Стоимость
	var description: String = ""
	
	func _init(_id: String, _name: String, _type: FishType):
		fish_id = _id
		name = _name
		fish_type = _type

class FishingSpot:
	var spot_id: String
	var position: Vector3
	var biome: String
	var depth: float
	var fish_pool: Array[String] = []  # fish_id доступных рыб
	var quality: float = 1.0  # Качество места (влияет на шанс)
	var exhaustion: float = 0.0  # Истощение места
	var max_exhaustion: float = 100.0
	var regeneration_rate: float = 5.0  # Восстановление в секунду
	
	func _init(_id: String, _pos: Vector3, _biome: String):
		spot_id = _id
		position = _pos
		biome = _biome

class ActiveFishingSession:
	var session_id: String
	var player_id: String
	var spot_id: String
	var fishing_method: FishingMethod
	var started_at: int
	var duration: float = 0.0
	var caught_fish: Array[String] = []  # fish_id пойманной рыбы
	var bait_id: String = ""
	
	func _init(_id: String, _player: String, _spot: String, _method: FishingMethod):
		session_id = _id
		player_id = _player
		spot_id = _spot
		fishing_method = _method
		started_at = Time.get_unix_time_from_system()

var fish_database: Dictionary = {}  # fish_id -> FishData
var fishing_spots: Dictionary = {}  # spot_id -> FishingSpot
var active_sessions: Dictionary = {}  # session_id -> ActiveFishingSession

signal fish_caught(session_id: String, fish_id: String, size: float)
signal fishing_session_started(session_id: String, spot_id: String)
signal fishing_session_ended(session_id: String, total_caught: int)
signal spot_exhausted(spot_id: String)

func _ready() -> void:
	_initialize_fish_database()
	_generate_fishing_spots()

func _process(delta: float) -> void:
	_update_fishing_sessions(delta)
	_regenerate_spots(delta)

func _initialize_fish_database() -> void:
	# Обычная рыба
	_register_fish("fish_anchovy", "Анчоус", FishType.COMMON, 0.15, 0.05, 0.8, "Tropical Shallow", Vector2(0, 5), 5.0)
	_register_fish("fish_tuna", "Тунец", FishType.COMMON, 1.5, 50.0, 0.6, "Deep Blue", Vector2(10, 50), 20.0)
	_register_fish("fish_salmon", "Лосось", FishType.RARE, 0.8, 10.0, 0.3, "Coldwater Expanse", Vector2(5, 30), 50.0)
	_register_fish("fish_ghost", "Призрачная рыба", FishType.LEGENDARY, 0.3, 2.0, 0.05, "Mist Sea", Vector2(20, 60), 500.0)
	_register_fish("fish_abyssal", "Бездонная рыба", FishType.LEGENDARY, 2.0, 100.0, 0.02, "Blackwater", Vector2(100, 500), 2000.0)

func _register_fish(fish_id: String, name: String, fish_type: FishType, size: float, weight: float, rarity: float, biome: String, depth_range: Vector2, value: float) -> void:
	var fish = FishData.new(fish_id, name, fish_type)
	fish.size = size
	fish.weight = weight
	fish.rarity = rarity
	fish.biome = biome
	fish.depth_range = depth_range
	fish.value = value
	fish_database[fish_id] = fish

func _generate_fishing_spots() -> void:
	# Генерируем точки для рыбалки в разных биомах
	_create_fishing_spot("spot_tropical_1", Vector3(50, -2, 50), "Tropical Shallow", 2.0)
	_create_fishing_spot("spot_deep_1", Vector3(500, -20, 500), "Deep Blue", 25.0)
	_create_fishing_spot("spot_mist_1", Vector3(800, -15, 800), "Mist Sea", 40.0)

func _create_fishing_spot(spot_id: String, position: Vector3, biome: String, depth: float) -> void:
	var spot = FishingSpot.new(spot_id, position, biome, depth)
	
	# Добавляем рыб, доступных в этом месте
	for fish_id in fish_database.keys():
		var fish = fish_database[fish_id]
		if fish.biome == biome and depth >= fish.depth_range.x and depth <= fish.depth_range.y:
			spot.fish_pool.append(fish_id)
	
	fishing_spots[spot_id] = spot

func start_fishing(player_id: String, spot_id: String, fishing_method: FishingMethod, bait_id: String = "") -> String:
	if not fishing_spots.has(spot_id):
		return ""
	
	var spot = fishing_spots[spot_id]
	
	# Проверяем истощение места
	if spot.exhaustion >= spot.max_exhaustion:
		spot_exhausted.emit(spot_id)
		return ""
	
	var session_id = "fishing_%d" % Time.get_ticks_msec()
	var session = ActiveFishingSession.new(session_id, player_id, spot_id, fishing_method)
	session.bait_id = bait_id
	
	active_sessions[session_id] = session
	fishing_session_started.emit(session_id, spot_id)
	
	return session_id

func stop_fishing(session_id: String) -> void:
	if not active_sessions.has(session_id):
		return
	
	var session = active_sessions[session_id]
	var total_caught = session.caught_fish.size()
	
	active_sessions.erase(session_id)
	fishing_session_ended.emit(session_id, total_caught)

func _update_fishing_sessions(delta: float) -> void:
	for session_id in active_sessions.keys():
		var session = active_sessions[session_id]
		var spot = fishing_spots.get(session.spot_id)
		
		if not spot:
			stop_fishing(session_id)
			continue
		
		session.duration += delta
		
		# В зависимости от метода рыбалки определяем частоту поклёвок
		var catch_interval = _get_catch_interval(session.fishing_method)
		
		if session.duration >= catch_interval:
			# Поклёвка!
			_attempt_catch(session, spot)
			session.duration = 0.0

func _attempt_catch(session: ActiveFishingSession, spot: FishingSpot) -> void:
	if spot.fish_pool.is_empty():
		return
	
	# Выбираем случайную рыбу из пула с учётом редкости
	var fish_id = _select_fish_from_pool(spot)
	if fish_id == "":
		return
	
	var fish = fish_database[fish_id]
	
	# Проверяем шанс поймать (зависит от редкости, качества места, приманки)
	var catch_chance = _calculate_catch_chance(fish, spot, session.bait_id)
	
	if randf() < catch_chance:
		# Поймали!
		var fish_size = fish.size * (0.8 + randf() * 0.4)  # Вариация размера
		session.caught_fish.append(fish_id)
		
		# Увеличиваем истощение места
		spot.exhaustion += fish.rarity * 10.0
		
		# Добавляем рыбу в инвентарь
		_add_fish_to_inventory(session.player_id, fish_id, fish_size)
		
		fish_caught.emit(session.session_id, fish_id, fish_size)
		
		# Если место истощено
		if spot.exhaustion >= spot.max_exhaustion:
			spot_exhausted.emit(spot.spot_id)

func _select_fish_from_pool(spot: FishingSpot) -> String:
	if spot.fish_pool.is_empty():
		return ""
	
	# Вероятностный выбор с учётом редкости
	var weighted_pool: Array[Dictionary] = []
	
	for fish_id in spot.fish_pool:
		var fish = fish_database[fish_id]
		var weight = 1.0 / (fish.rarity + 0.1)  # Менее редкие имеют больший вес
		weighted_pool.append({"id": fish_id, "weight": weight})
	
	# Выбираем случайную с учётом весов
	var total_weight = 0.0
	for entry in weighted_pool:
		total_weight += entry["weight"]
	
	var random = randf() * total_weight
	var current = 0.0
	
	for entry in weighted_pool:
		current += entry["weight"]
		if random <= current:
			return entry["id"]
	
	return weighted_pool[0]["id"]

func _calculate_catch_chance(fish: FishData, spot: FishingSpot, bait_id: String) -> float:
	var base_chance = 0.5  # Базовая вероятность
	
	# Учитываем редкость рыбы (чем реже, тем сложнее поймать)
	var rarity_penalty = fish.rarity * 0.8
	base_chance -= rarity_penalty
	
	# Учитываем качество места
	base_chance *= spot.quality
	
	# Учитываем истощение (чем больше истощено, тем сложнее)
	var exhaustion_penalty = (spot.exhaustion / spot.max_exhaustion) * 0.5
	base_chance *= (1.0 - exhaustion_penalty)
	
	# Учитываем приманку
	if bait_id != "":
		base_chance += 0.2  # +20% с приманкой
	
	return clamp(base_chance, 0.1, 0.95)  # Минимум 10%, максимум 95%

func _get_catch_interval(fishing_method: FishingMethod) -> float:
	match fishing_method:
		FishingMethod.ROD:
			return 3.0 + randf() * 5.0  # 3-8 секунд
		FishingMethod.NET:
			return 10.0 + randf() * 10.0  # 10-20 секунд
		FishingMethod.TRAP:
			return 60.0  # 1 минута
		FishingMethod.SPEAR:
			return 2.0 + randf() * 3.0  # 2-5 секунд
		FishingMethod.COMMERCIAL:
			return 30.0  # 30 секунд
		_:
			return 5.0

func _regenerate_spots(delta: float) -> void:
	for spot_id in fishing_spots.keys():
		var spot = fishing_spots[spot_id]
		if spot.exhaustion > 0.0:
			spot.exhaustion = max(0.0, spot.exhaustion - spot.regeneration_rate * delta)

func _add_fish_to_inventory(player_id: String, fish_id: String, size: float) -> void:
	# TODO: Интегрировать с InventorySystem
	var world = get_tree().current_scene
	if world:
		var inventory = world.find_child("Inventory", true, false)
		if inventory:
			inventory.add_item(fish_id, 1)

func get_fishing_spot_info(spot_id: String) -> Dictionary:
	if not fishing_spots.has(spot_id):
		return {}
	
	var spot = fishing_spots[spot_id]
	return {
		"id": spot.spot_id,
		"position": spot.position,
		"biome": spot.biome,
		"depth": spot.depth,
		"quality": spot.quality,
		"exhaustion": spot.exhaustion,
		"available_fish": spot.fish_pool.size()
	}

func get_available_fish(spot_id: String) -> Array[Dictionary]:
	if not fishing_spots.has(spot_id):
		return []
	
	var spot = fishing_spots[spot_id]
	var result: Array[Dictionary] = []
	
	for fish_id in spot.fish_pool:
		var fish = fish_database[fish_id]
		result.append({
			"id": fish.fish_id,
			"name": fish.name,
			"type": fish.fish_type,
			"rarity": fish.rarity,
			"value": fish.value
		})
	
	return result

