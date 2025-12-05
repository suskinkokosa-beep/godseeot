extends Node
class_name TreasureSystem

## Система затонувших сокровищ для Isleborn Online
## Согласно GDD: затонувшие корабли, сундуки с сокровищами, редкие находки

enum TreasureType {
	SHIPWRECK,      # Затонувший корабль
	CHEST,          # Сундук с сокровищами
	ARTIFACT,       # Артефакт
	RUIN_TREASURE,  # Сокровище из руин
	BOSS_LOOT       # Лут босса
}

enum TreasureRarity {
	COMMON,         # Обычное
	UNCOMMON,       # Необычное
	RARE,           # Редкое
	EPIC,           # Эпическое
	LEGENDARY,      # Легендарное
	MYTHIC          # Мифическое
}

class Treasure:
	var treasure_id: String
	var treasure_type: TreasureType
	var rarity: TreasureRarity
	var position: Vector3
	var depth: float = 0.0
	var discovered: bool = false
	var discovered_by: String = ""
	var discovered_at: int = 0
	var loot: Dictionary = {}  # item_id -> quantity
	var required_level: int = 1
	var biome: String = ""
	var respawn_time: float = 0.0  # 0 = не респавнится
	var last_looted: int = 0
	
	func _init(_id: String, _type: TreasureType, _pos: Vector3):
		treasure_id = _id
		treasure_type = _type
		position = _pos

var treasures: Dictionary = {}  # treasure_id -> Treasure
var discovered_treasures: Array[String] = []

signal treasure_discovered(treasure_id: String, treasure: Treasure)
signal treasure_looted(treasure_id: String, loot: Dictionary)
signal treasure_respawned(treasure_id: String)

func _ready() -> void:
	_generate_treasures()

func _process(delta: float) -> void:
	_check_treasure_respawn()

func _generate_treasures() -> void:
	# Генерируем затонувшие сокровища в разных биомах
	_create_treasure("treasure_shipwreck_1", TreasureType.SHIPWRECK, Vector3(2000, -30, 2000), 30.0, TreasureRarity.RARE, "Deep Blue", 10)
	_create_treasure("treasure_chest_1", TreasureType.CHEST, Vector3(1500, -15, 1500), 15.0, TreasureRarity.UNCOMMON, "Tropical Shallow", 5)
	_create_treasure("treasure_artifact_1", TreasureType.ARTIFACT, Vector3(5000, -100, 5000), 100.0, TreasureRarity.LEGENDARY, "Blackwater", 25)

func _create_treasure(treasure_id: String, treasure_type: TreasureType, position: Vector3, depth: float, rarity: TreasureRarity, biome: String, level: int) -> void:
	var treasure = Treasure.new(treasure_id, treasure_type, position)
	treasure.depth = depth
	treasure.rarity = rarity
	treasure.biome = biome
	treasure.required_level = level
	
	# Генерируем лут в зависимости от редкости
	treasure.loot = _generate_treasure_loot(rarity, treasure_type)
	
	# Устанавливаем время респавна (легендарные не респавнятся)
	if rarity < TreasureRarity.LEGENDARY:
		treasure.respawn_time = _get_respawn_time_for_rarity(rarity)
	
	treasures[treasure_id] = treasure

func _generate_treasure_loot(rarity: TreasureRarity, treasure_type: TreasureType) -> Dictionary:
	var loot: Dictionary = {}
	
	# Базовые награды
	match rarity:
		TreasureRarity.COMMON:
			loot["shells"] = randi_range(10, 50)
			loot["common_item"] = randi_range(1, 3)
		
		TreasureRarity.UNCOMMON:
			loot["shells"] = randi_range(50, 200)
			loot["gold"] = randi_range(1, 5)
			loot["uncommon_item"] = randi_range(1, 2)
		
		TreasureRarity.RARE:
			loot["shells"] = randi_range(200, 500)
			loot["gold"] = randi_range(5, 15)
			loot["rare_item"] = 1
		
		TreasureRarity.EPIC:
			loot["shells"] = randi_range(500, 1000)
			loot["gold"] = randi_range(15, 30)
			loot["pearls"] = randi_range(1, 3)
			loot["epic_item"] = 1
		
		TreasureRarity.LEGENDARY:
			loot["shells"] = randi_range(1000, 5000)
			loot["gold"] = randi_range(30, 100)
			loot["pearls"] = randi_range(5, 15)
			loot["legendary_item"] = 1
			loot["blueprint"] = 1
		
		TreasureRarity.MYTHIC:
			loot["shells"] = randi_range(5000, 10000)
			loot["gold"] = randi_range(100, 500)
			loot["pearls"] = randi_range(15, 50)
			loot["mythic_item"] = 1
			loot["legendary_blueprint"] = 1
	
	# Специфичные для типа сокровища
	match treasure_type:
		TreasureType.SHIPWRECK:
			loot["ship_part"] = randi_range(1, 3)
		
		TreasureType.ARTIFACT:
			loot["ancient_artifact"] = 1
	
	return loot

func _get_respawn_time_for_rarity(rarity: TreasureRarity) -> float:
	match rarity:
		TreasureRarity.COMMON:
			return 3600.0  # 1 час
		TreasureRarity.UNCOMMON:
			return 7200.0  # 2 часа
		TreasureRarity.RARE:
			return 14400.0  # 4 часа
		TreasureRarity.EPIC:
			return 28800.0  # 8 часов
		_:
			return 0.0

func discover_treasure(treasure_id: String, player_id: String) -> bool:
	if not treasures.has(treasure_id):
		return false
	
	var treasure = treasures[treasure_id]
	
	if treasure.discovered:
		return false  # Уже обнаружено
	
	treasure.discovered = true
	treasure.discovered_by = player_id
	treasure.discovered_at = Time.get_unix_time_from_system()
	discovered_treasures.append(treasure_id)
	
	treasure_discovered.emit(treasure_id, treasure)
	
	# TODO: Интегрировать с AchievementSystem
	var world = get_tree().current_scene
	if world:
		var stats = world.find_child("PlayerStatisticsSystem", true, false)
		if stats:
			stats.record_treasure_found()
	
	return true

func check_treasure_discovery(player_position: Vector3, player_depth: float, discovery_radius: float = 20.0) -> void:
	for treasure_id in treasures.keys():
		var treasure = treasures[treasure_id]
		
		if treasure.discovered and treasure.last_looted > 0:
			continue  # Уже собрано, ждём респавн
		
		var distance = player_position.distance_to(treasure.position)
		var depth_diff = abs(player_depth - treasure.depth)
		
		if distance <= discovery_radius and depth_diff <= 5.0:
			discover_treasure(treasure_id, _get_local_player_id())

func loot_treasure(treasure_id: String, player_id: String) -> Dictionary:
	if not treasures.has(treasure_id):
		return {}
	
	var treasure = treasures[treasure_id]
	
	if not treasure.discovered:
		return {}  # Нужно сначала обнаружить
	
	if treasure.last_looted > 0:
		var time_since_looted = Time.get_unix_time_from_system() - treasure.last_looted
		if treasure.respawn_time > 0 and time_since_looted < treasure.respawn_time:
			return {}  # Ещё не респавнился
	
	# Выдаём лут
	treasure.last_looted = Time.get_unix_time_from_system()
	
	# Сбрасываем обнаружение для респавна
	if treasure.respawn_time > 0:
		treasure.discovered = false
	
	# Добавляем лут в инвентарь
	var world = get_tree().current_scene
	if world:
		var inventory = world.find_child("Inventory", true, false)
		if inventory:
			for item_id in treasure.loot.keys():
				var quantity = treasure.loot[item_id]
				inventory.add_item(item_id, quantity)
	
	treasure_looted.emit(treasure_id, treasure.loot.duplicate())
	
	return treasure.loot.duplicate()

func _check_treasure_respawn() -> void:
	var current_time = Time.get_unix_time_from_system()
	
	for treasure_id in treasures.keys():
		var treasure = treasures[treasure_id]
		
		if treasure.last_looted <= 0 or treasure.respawn_time <= 0:
			continue
		
		var time_since_looted = current_time - treasure.last_looted
		
		if time_since_looted >= treasure.respawn_time:
			# Респавним сокровище
			treasure.discovered = false
			treasure.last_looted = 0
			treasure.loot = _generate_treasure_loot(treasure.rarity, treasure.treasure_type)
			
			# Удаляем из обнаруженных
			var index = discovered_treasures.find(treasure_id)
			if index >= 0:
				discovered_treasures.remove_at(index)
			
			treasure_respawned.emit(treasure_id)

func get_treasure_info(treasure_id: String) -> Dictionary:
	if not treasures.has(treasure_id):
		return {}
	
	var treasure = treasures[treasure_id]
	var can_loot = treasure.discovered and (treasure.last_looted == 0 or treasure.respawn_time <= 0 or (Time.get_unix_time_from_system() - treasure.last_looted) >= treasure.respawn_time)
	
	return {
		"id": treasure.treasure_id,
		"type": treasure.treasure_type,
		"rarity": treasure.rarity,
		"position": treasure.position,
		"depth": treasure.depth,
		"discovered": treasure.discovered,
		"can_loot": can_loot,
		"required_level": treasure.required_level,
		"biome": treasure.biome,
		"loot_preview": treasure.loot.keys()  # Только ключи, не количество
	}

func _get_local_player_id() -> String:
	# TODO: Получить ID локального игрока
	return ""

