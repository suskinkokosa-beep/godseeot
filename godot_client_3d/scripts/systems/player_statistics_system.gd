extends Node
class_name PlayerStatisticsSystem

## Система статистики игрока для Isleborn Online
## Отслеживает все достижения, прогресс и метрики игрока

class PlayerStats:
	var player_id: String
	
	# Общая статистика
	var play_time_seconds: float = 0.0
	var days_played: int = 0
	var total_distance_traveled: float = 0.0
	
	# Боевая статистика
	var monsters_killed: int = 0
	var players_killed: int = 0
	var deaths: int = 0
	var damage_dealt: float = 0.0
	var damage_taken: float = 0.0
	
	# Ресурсы
	var resources_gathered: Dictionary = {}  # resource_type -> amount
	var items_crafted: Dictionary = {}  # item_id -> amount
	var items_sold: Dictionary = {}  # item_id -> amount
	var items_bought: Dictionary = {}  # item_id -> amount
	
	# Остров
	var buildings_built: int = 0
	var island_level: int = 1
	var times_island_raided: int = 0
	var times_island_defended: int = 0
	
	# Корабли
	var ships_built: int = 0
	var ships_lost: int = 0
	var distance_sailed: float = 0.0
	
	# Социальное
	var guilds_joined: int = 0
	var friends_added: int = 0
	var trades_completed: int = 0
	
	# Исследование
	var biomes_discovered: Array[String] = []
	var ruins_found: int = 0
	var treasures_found: int = 0
	
	# Достижения
	var achievements_unlocked: int = 0
	var quests_completed: int = 0
	
	func _init(_player_id: String):
		player_id = _player_id

var player_stats: PlayerStats = null

signal stat_changed(stat_name: String, new_value)
signal milestone_reached(milestone_name: String)

func _ready() -> void:
	player_stats = PlayerStats.new(_get_local_player_id())

func _process(delta: float) -> void:
	if player_stats:
		player_stats.play_time_seconds += delta

func record_monster_kill(monster_id: String) -> void:
	if not player_stats: return
	
	player_stats.monsters_killed += 1
	stat_changed.emit("monsters_killed", player_stats.monsters_killed)
	
	_check_milestones("monsters_killed", player_stats.monsters_killed)

func record_player_kill(player_id: String) -> void:
	if not player_stats: return
	
	player_stats.players_killed += 1
	stat_changed.emit("players_killed", player_stats.players_killed)

func record_death(death_type: String) -> void:
	if not player_stats: return
	
	player_stats.deaths += 1
	stat_changed.emit("deaths", player_stats.deaths)

func record_resource_gathered(resource_type: String, amount: int) -> void:
	if not player_stats: return
	
	if not player_stats.resources_gathered.has(resource_type):
		player_stats.resources_gathered[resource_type] = 0
	
	player_stats.resources_gathered[resource_type] += amount
	stat_changed.emit("resources_gathered", player_stats.resources_gathered)

func record_item_crafted(item_id: String) -> void:
	if not player_stats: return
	
	if not player_stats.items_crafted.has(item_id):
		player_stats.items_crafted[item_id] = 0
	
	player_stats.items_crafted[item_id] += 1
	stat_changed.emit("items_crafted", player_stats.items_crafted)

func record_distance_traveled(distance: float) -> void:
	if not player_stats: return
	
	player_stats.total_distance_traveled += distance
	stat_changed.emit("total_distance_traveled", player_stats.total_distance_traveled)

func record_building_built(building_type: String) -> void:
	if not player_stats: return
	
	player_stats.buildings_built += 1
	stat_changed.emit("buildings_built", player_stats.buildings_built)

func record_island_raided(success: bool) -> void:
	if not player_stats: return
	
	if success:
		player_stats.times_island_raided += 1
	else:
		player_stats.times_island_defended += 1

func record_biome_discovered(biome_id: String) -> void:
	if not player_stats: return
	
	if biome_id not in player_stats.biomes_discovered:
		player_stats.biomes_discovered.append(biome_id)
		stat_changed.emit("biomes_discovered", player_stats.biomes_discovered.size())

func record_ruin_found() -> void:
	if not player_stats: return
	
	player_stats.ruins_found += 1
	stat_changed.emit("ruins_found", player_stats.ruins_found)

func record_treasure_found() -> void:
	if not player_stats: return
	
	player_stats.treasures_found += 1
	stat_changed.emit("treasures_found", player_stats.treasures_found)

func record_quest_completed(quest_id: String) -> void:
	if not player_stats: return
	
	player_stats.quests_completed += 1
	stat_changed.emit("quests_completed", player_stats.quests_completed)

func record_achievement_unlocked() -> void:
	if not player_stats: return
	
	player_stats.achievements_unlocked += 1
	stat_changed.emit("achievements_unlocked", player_stats.achievements_unlocked)

func _check_milestones(stat_name: String, value) -> void:
	var milestones: Dictionary = {
		"monsters_killed": [10, 50, 100, 500, 1000, 5000],
		"quests_completed": [5, 10, 25, 50, 100],
		"buildings_built": [5, 10, 25, 50, 100],
		"treasures_found": [1, 5, 10, 25, 50]
	}
	
	if milestones.has(stat_name):
		var milestone_list = milestones[stat_name]
		for milestone in milestone_list:
			if value == milestone:
				milestone_reached.emit("%s_%d" % [stat_name, milestone])
				break

func get_stat(stat_name: String):
	if not player_stats:
		return null
	
	match stat_name:
		"play_time":
			return player_stats.play_time_seconds
		"monsters_killed":
			return player_stats.monsters_killed
		"players_killed":
			return player_stats.players_killed
		"deaths":
			return player_stats.deaths
		"resources_gathered":
			return player_stats.resources_gathered
		"items_crafted":
			return player_stats.items_crafted
		"buildings_built":
			return player_stats.buildings_built
		"biomes_discovered":
			return player_stats.biomes_discovered.size()
		"ruins_found":
			return player_stats.ruins_found
		"treasures_found":
			return player_stats.treasures_found
		"quests_completed":
			return player_stats.quests_completed
		"achievements_unlocked":
			return player_stats.achievements_unlocked
		_:
			return null

func get_all_stats() -> Dictionary:
	if not player_stats:
		return {}
	
	return {
		"play_time_seconds": player_stats.play_time_seconds,
		"monsters_killed": player_stats.monsters_killed,
		"players_killed": player_stats.players_killed,
		"deaths": player_stats.deaths,
		"resources_gathered": player_stats.resources_gathered.duplicate(),
		"items_crafted": player_stats.items_crafted.duplicate(),
		"buildings_built": player_stats.buildings_built,
		"biomes_discovered": player_stats.biomes_discovered.size(),
		"ruins_found": player_stats.ruins_found,
		"treasures_found": player_stats.treasures_found,
		"quests_completed": player_stats.quests_completed,
		"achievements_unlocked": player_stats.achievements_unlocked
	}

func _get_local_player_id() -> String:
	# TODO: Получить ID локального игрока
	return ""

