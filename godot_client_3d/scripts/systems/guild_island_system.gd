extends Node
class_name GuildIslandSystem

## Система гильдейских островов для Isleborn Online
## Согласно GDD: гильдии могут создавать общие острова

class GuildIsland:
	var island_id: String
	var guild_id: String
	var position: Vector3
	var level: int = 1
	var size: Dictionary = {"width": 10.0, "height": 10.0}
	var radius: float = 5.0
	var buildings: Array[Dictionary] = []
	var resources: Array[Dictionary] = []
	var spawn_pos: Vector3
	var created_at: int
	var last_activity: int
	var build_permissions: Dictionary = {}  # rank -> [building_types]
	var upgrade_progress: Dictionary = {}
	
	func _init(_id: String, _guild_id: String, _pos: Vector3):
		island_id = _id
		guild_id = _guild_id
		position = _pos
		spawn_pos = _pos
		created_at = Time.get_unix_time_from_system()
		last_activity = created_at

var guild_islands: Dictionary = {}  # island_id -> GuildIsland
var guild_to_island: Dictionary = {}  # guild_id -> island_id

signal guild_island_created(island_id: String, guild_id: String)
signal guild_island_leveled_up(island_id: String, new_level: int)
signal building_constructed(island_id: String, building_type: String, position: Vector3)

func _ready() -> void:
	pass

func create_guild_island(guild_id: String, position: Vector3) -> String:
	# Проверяем, нет ли уже острова у гильдии
	if guild_to_island.has(guild_id):
		return ""
	
	var island_id = "guild_island_%s_%d" % [guild_id, Time.get_ticks_msec()]
	var island = GuildIsland.new(island_id, guild_id, position)
	
	# Инициализируем базовые ресурсы
	island.resources = _generate_initial_resources()
	
	guild_islands[island_id] = island
	guild_to_island[guild_id] = island_id
	
	guild_island_created.emit(island_id, guild_id)
	
	return island_id

func get_guild_island(guild_id: String) -> GuildIsland:
	var island_id = guild_to_island.get(guild_id, "")
	if island_id == "":
		return null
	
	return guild_islands.get(island_id, null)

func construct_building(island_id: String, building_type: String, position: Vector3, player_rank: int) -> bool:
	var island = guild_islands.get(island_id, null)
	if not island:
		return false
	
	# Проверяем права на строительство
	if not _can_build(island, building_type, player_rank):
		return false
	
	# Добавляем постройку
	var building_data = {
		"type": building_type,
		"position": {"x": position.x, "y": position.y, "z": position.z},
		"built_by": _get_local_player_id(),
		"built_at": Time.get_unix_time_from_system()
	}
	
	island.buildings.append(building_data)
	island.last_activity = Time.get_unix_time_from_system()
	
	building_constructed.emit(island_id, building_type, position)
	
	return true

func _can_build(island: GuildIsland, building_type: String, player_rank: int) -> bool:
	# TODO: Проверить права игрока на строительство
	# TODO: Проверить, что постройка разрешена для ранга
	return true

func level_up_guild_island(island_id: String) -> bool:
	var island = guild_islands.get(island_id, null)
	if not island:
		return false
	
	# Проверяем требования для улучшения
	if not _check_upgrade_requirements(island):
		return false
	
	island.level += 1
	
	# Увеличиваем размер острова
	island.size["width"] *= 1.2
	island.size["height"] *= 1.2
	island.radius *= 1.2
	
	# Добавляем новые ресурсы
	island.resources.append_array(_generate_level_resources(island.level))
	
	guild_island_leveled_up.emit(island_id, island.level)
	
	return true

func _check_upgrade_requirements(island: GuildIsland) -> bool:
	# TODO: Проверить требования (здания, ресурсы, уровень гильдии)
	return true

func _generate_initial_resources() -> Array[Dictionary]:
	return [
		{"type": "palm_tree", "pos": Vector3(1.0, 0.0, 0.5), "amount": 5},
		{"type": "stone_node", "pos": Vector3(-1.2, 0.0, -0.7), "amount": 6}
	]

func _generate_level_resources(level: int) -> Array[Dictionary]:
	var resources: Array[Dictionary] = []
	
	# Добавляем ресурсы в зависимости от уровня
	for i in range(level):
		var angle = (i / float(level)) * TAU
		var distance = 3.0 + (i * 0.5)
		var pos = Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
		
		if i % 2 == 0:
			resources.append({"type": "palm_tree", "pos": pos, "amount": 3})
		else:
			resources.append({"type": "stone_node", "pos": pos, "amount": 4})
	
	return resources

func get_island_info(island_id: String) -> Dictionary:
	var island = guild_islands.get(island_id, null)
	if not island:
		return {}
	
	return {
		"id": island.island_id,
		"guild_id": island.guild_id,
		"position": island.position,
		"level": island.level,
		"size": island.size.duplicate(),
		"radius": island.radius,
		"buildings_count": island.buildings.size(),
		"resources_count": island.resources.size(),
		"spawn_pos": island.spawn_pos
	}

func _get_local_player_id() -> String:
	# TODO: Получить ID локального игрока
	return ""

