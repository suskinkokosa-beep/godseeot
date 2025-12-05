extends Node
class_name IslandDefenseSystem

## Система защиты острова от монстров для Isleborn Online
## Согласно GDD: рейды монстров, защитные постройки, волны атак

enum RaidType {
	SMALL,          # Малый рейд (T1-T2)
	MEDIUM,         # Средний рейд (T2-T3)
	LARGE,          # Большой рейд (T3-T4)
	ELITE,          # Элитный рейд (T4-T5)
	BOSS            # Босс рейд
}

enum RaidStatus {
	INCOMING,       # Приближается
	ACTIVE,         # Идёт
	DEFEATED,       # Отражён
	FAILED          # Остров захвачен
}

class RaidWave:
	var wave_id: String
	var monster_ids: Array[String] = []
	var spawn_position: Vector3
	var spawn_radius: float = 10.0
	var spawn_time: float = 0.0
	var spawned: bool = false
	
	func _init(_id: String, _monsters: Array[String], _pos: Vector3):
		wave_id = _id
		monster_ids = _monsters
		spawn_position = _pos

class IslandRaid:
	var raid_id: String
	var island_id: String
	var raid_type: RaidType
	var status: RaidStatus = RaidStatus.INCOMING
	var waves: Array[RaidWave] = []
	var current_wave: int = 0
	var start_time: int = 0
	var duration: float = 0.0
	var monsters_alive: int = 0
	var total_monsters: int = 0
	var reward_multiplier: float = 1.0
	
	func _init(_id: String, _island: String, _type: RaidType):
		raid_id = _id
		island_id = _island
		raid_type = _type
		start_time = Time.get_unix_time_from_system()

class DefenseStructure:
	var structure_id: String
	var position: Vector3
	var structure_type: String  # tower, wall, trap
	var damage: float = 10.0
	var range: float = 20.0
	var attack_speed: float = 1.0  # Атак в секунду
	var health: float = 100.0
	var max_health: float = 100.0
	var last_attack_time: float = 0.0
	var target_monster_id: String = ""
	
	func _init(_id: String, _pos: Vector3, _type: String):
		structure_id = _id
		position = _pos
		structure_type = _type

var active_raids: Dictionary = {}  # raid_id -> IslandRaid
var defense_structures: Dictionary = {}  # structure_id -> DefenseStructure
var raid_schedule: Array[Dictionary] = []  # Расписание рейдов

signal raid_started(raid_id: String, raid_type: RaidType)
signal raid_wave_spawned(raid_id: String, wave_number: int)
signal raid_defeated(raid_id: String, rewards: Dictionary)
signal raid_failed(raid_id: String)
signal structure_destroyed(structure_id: String)

func _ready() -> void:
	_schedule_initial_raids()

func _process(delta: float) -> void:
	_update_active_raids(delta)
	_update_defense_structures(delta)
	_check_raid_schedule()

func _schedule_initial_raids() -> void:
	# Рейды происходят каждые 2-6 часов реального времени
	# TODO: Интегрировать с системой времени

func start_raid(island_id: String, raid_type: RaidType) -> String:
	var raid_id = "raid_%d" % Time.get_ticks_msec()
	var raid = IslandRaid.new(raid_id, island_id, raid_type)
	
	# Генерируем волны в зависимости от типа рейда
	_generate_raid_waves(raid)
	
	active_raids[raid_id] = raid
	raid_started.emit(raid_id, raid_type)
	
	return raid_id

func _generate_raid_waves(raid: IslandRaid) -> void:
	var wave_count = _get_wave_count_for_type(raid.raid_type)
	var monsters_per_wave = _get_monsters_per_wave(raid.raid_type)
	
	var island_position = Vector3.ZERO  # TODO: Получить позицию острова
	
	for i in range(wave_count):
		var wave_id = "wave_%d_%d" % [Time.get_ticks_msec(), i]
		var monsters: Array[String] = []
		
		# Генерируем монстров для волны
		for j in range(monsters_per_wave):
			var monster_id = _get_random_monster_for_raid(raid.raid_type)
			monsters.append(monster_id)
		
		# Позиция спавна вокруг острова
		var angle = (i / float(wave_count)) * TAU
		var distance = 15.0 + (i * 2.0)  # Каждая волна дальше
		var spawn_pos = island_position + Vector3(
			cos(angle) * distance,
			0.0,
			sin(angle) * distance
		)
		
		var wave = RaidWave.new(wave_id, monsters, spawn_pos)
		wave.spawn_time = 10.0 + (i * 15.0)  # Интервал между волнами
		raid.waves.append(wave)
		raid.total_monsters += monsters.size()

func _get_wave_count_for_type(raid_type: RaidType) -> int:
	match raid_type:
		RaidType.SMALL: return 2
		RaidType.MEDIUM: return 3
		RaidType.LARGE: return 4
		RaidType.ELITE: return 5
		RaidType.BOSS: return 3  # Меньше волн, но сильные
		_: return 2

func _get_monsters_per_wave(raid_type: RaidType) -> int:
	match raid_type:
		RaidType.SMALL: return 3
		RaidType.MEDIUM: return 5
		RaidType.LARGE: return 8
		RaidType.ELITE: return 6  # Меньше, но сильнее
		RaidType.BOSS: return 1  # Только босс
		_: return 3

func _get_random_monster_for_raid(raid_type: RaidType) -> String:
	# TODO: Получить монстров из базы данных в зависимости от типа рейда
	match raid_type:
		RaidType.SMALL:
			return "reef_eel"  # T1
		RaidType.MEDIUM:
			return "sea_snake_young"  # T2
		RaidType.LARGE:
			return "giant_shark"  # T3
		RaidType.ELITE:
			return "sea_serpent_mastodon"  # T4
		RaidType.BOSS:
			return "leviathan"  # T5
		_:
			return "reef_eel"

func _update_active_raids(delta: float) -> void:
	for raid_id in active_raids.keys():
		var raid = active_raids[raid_id]
		
		if raid.status == RaidStatus.INCOMING:
			# Проверяем, пора ли спавнить волны
			var elapsed_time = Time.get_unix_time_from_system() - raid.start_time
			_process_raid_waves(raid, elapsed_time, delta)
		
		elif raid.status == RaidStatus.ACTIVE:
			# Проверяем состояние рейда
			if raid.monsters_alive <= 0:
				if raid.current_wave >= raid.waves.size():
					# Все волны пройдены
					_complete_raid(raid_id, true)
				else:
					# Переходим к следующей волне
					raid.current_wave += 1
		
		elif raid.status in [RaidStatus.DEFEATED, RaidStatus.FAILED]:
			# Рейд завершён, можно удалить через некоторое время
			pass

func _process_raid_waves(raid: IslandRaid, elapsed_time: float, delta: float) -> void:
	for i in range(raid.waves.size()):
		var wave = raid.waves[i]
		
		if wave.spawned:
			continue
		
		if elapsed_time >= wave.spawn_time:
			# Спавним волну
			_spawn_wave(raid, wave, i)
			wave.spawned = true
			raid.status = RaidStatus.ACTIVE
			raid.current_wave = i

func _spawn_wave(raid: IslandRaid, wave: RaidWave, wave_number: int) -> void:
	for monster_id in wave.monster_ids:
		# TODO: Создать монстра на позиции
		# spawn_monster(monster_id, wave.spawn_position)
		raid.monsters_alive += 1
	
	raid_wave_spawned.emit(raid.raid_id, wave_number)

func register_defense_structure(structure_id: String, position: Vector3, structure_type: String, damage: float = 10.0, range_distance: float = 20.0) -> void:
	var structure = DefenseStructure.new(structure_id, position, structure_type)
	structure.damage = damage
	structure.range = range_distance
	defense_structures[structure_id] = structure

func unregister_defense_structure(structure_id: String) -> void:
	defense_structures.erase(structure_id)

func _update_defense_structures(delta: float) -> void:
	for structure_id in defense_structures.keys():
		var structure = defense_structures[structure_id]
		
		# Ищем ближайшего монстра в радиусе
		var target = _find_nearest_monster_in_range(structure.position, structure.range)
		
		if target != "":
			structure.target_monster_id = target
			
			# Атакуем с интервалом
			var time_since_attack = Time.get_ticks_msec() / 1000.0 - structure.last_attack_time
			if time_since_attack >= (1.0 / structure.attack_speed):
				_attack_monster(structure, target)
				structure.last_attack_time = Time.get_ticks_msec() / 1000.0
		else:
			structure.target_monster_id = ""

func _find_nearest_monster_in_range(position: Vector3, range_distance: float) -> String:
	# TODO: Найти ближайшего монстра в радиусе от активных рейдов
	var nearest_id = ""
	var nearest_distance = INF
	
	# Проверяем всех монстров из активных рейдов
	for raid_id in active_raids.keys():
		var raid = active_raids[raid_id]
		if raid.status != RaidStatus.ACTIVE:
			continue
		
		# TODO: Получить позиции монстров и проверить дистанцию
		# Пока возвращаем пустую строку
	
	return nearest_id

func _attack_monster(structure: DefenseStructure, monster_id: String) -> void:
	# TODO: Нанести урон монстру
	var damage = structure.damage
	# apply_damage_to_monster(monster_id, damage)

func on_monster_killed(monster_id: String, raid_id: String) -> void:
	if not active_raids.has(raid_id):
		return
	
	var raid = active_raids[raid_id]
	raid.monsters_alive = max(0, raid.monsters_alive - 1)
	
	# Проверяем, завершён ли рейд
	if raid.monsters_alive <= 0 and raid.current_wave >= raid.waves.size() - 1:
		_complete_raid(raid_id, true)

func _complete_raid(raid_id: String, success: bool) -> void:
	if not active_raids.has(raid_id):
		return
	
	var raid = active_raids[raid_id]
	
	if success:
		raid.status = RaidStatus.DEFEATED
		
		# Выдаём награды
		var rewards = _calculate_raid_rewards(raid)
		raid_defeated.emit(raid_id, rewards)
	else:
		raid.status = RaidStatus.FAILED
		raid_failed.emit(raid_id)
	
	# Удаляем рейд через некоторое время
	await get_tree().create_timer(10.0).timeout
	active_raids.erase(raid_id)

func _calculate_raid_rewards(raid: IslandRaid) -> Dictionary:
	var base_rewards = {
		"experience": 100.0 * (raid.raid_type + 1),
		"currency": {
			"shells": 50 * (raid.raid_type + 1)
		},
		"items": []
	}
	
	# Множитель награды в зависимости от успеха
	base_rewards["experience"] *= raid.reward_multiplier
	
	return base_rewards

func _check_raid_schedule() -> void:
	# TODO: Проверять расписание и запускать рейды
	pass

func damage_structure(structure_id: String, damage: float) -> void:
	if not defense_structures.has(structure_id):
		return
	
	var structure = defense_structures[structure_id]
	structure.health -= damage
	
	if structure.health <= 0.0:
		structure.health = 0.0
		structure_destroyed.emit(structure_id)
		defense_structures.erase(structure_id)

func get_raid_info(raid_id: String) -> Dictionary:
	if not active_raids.has(raid_id):
		return {}
	
	var raid = active_raids[raid_id]
	return {
		"id": raid.raid_id,
		"type": raid.raid_type,
		"status": raid.status,
		"current_wave": raid.current_wave,
		"total_waves": raid.waves.size(),
		"monsters_alive": raid.monsters_alive,
		"total_monsters": raid.total_monsters
	}

