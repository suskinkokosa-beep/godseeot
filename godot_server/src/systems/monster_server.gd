extends Node
class_name MonsterServer

## Серверная система управления монстрами
## Поддерживает монстров на воде и под водой

enum MonsterEnvironment {
	SURFACE,      # На поверхности воды
	UNDERWATER,   # Под водой
	LAND,         # На суше (острова)
	BOTH          # Может быть и на воде, и под водой
}

class MonsterEntity:
	var id: String
	var monster_type: String
	var position: Vector3
	var environment: MonsterEnvironment
	var depth: float = 0.0  # Глубина под водой (0 = на поверхности, >0 = под водой)
	var health: float = 100.0
	var max_health: float = 100.0
	var level: int = 1
	var last_update: int
	var target_id: String = ""
	var state: String = "idle"  # idle, chasing, attacking, fleeing
	
	func _init(_id: String, _type: String, _pos: Vector3, _env: MonsterEnvironment, _depth: float = 0.0):
		id = _id
		monster_type = _type
		position = _pos
		environment = _env
		depth = _depth
		last_update = Time.get_unix_time_from_system()

var monsters: Dictionary = {}  # monster_id -> MonsterEntity
var spawn_zones: Array = []    # Зоны спавна монстров

signal monster_spawned(monster_id: String, monster: MonsterEntity)
signal monster_died(monster_id: String)
signal monster_moved(monster_id: String, position: Vector3, depth: float)

const WATER_SURFACE_Y: float = 0.0
const SPAWN_INTERVAL: float = 30.0  # секунд между спавнами
var spawn_timer: float = 0.0

func _ready() -> void:
	_initialize_spawn_zones()
	set_process(true)

func _process(delta: float) -> void:
	spawn_timer += delta
	if spawn_timer >= SPAWN_INTERVAL:
		spawn_timer = 0.0
		_try_spawn_monsters()
	
	_update_monsters(delta)

func _initialize_spawn_zones() -> void:
	# Инициализация зон спавна (пример)
	# В реальной игре зоны загружаются из конфига или базы данных
	spawn_zones.append({
		"center": Vector3(100, 0, 100),
		"radius": 50.0,
		"environment": MonsterEnvironment.SURFACE,
		"monster_types": ["reef_eel", "sea_snake"],
		"max_count": 5
	})
	
	spawn_zones.append({
		"center": Vector3(-50, -10, -50),
		"radius": 30.0,
		"environment": MonsterEnvironment.UNDERWATER,
		"monster_types": ["deep_seeker", "abyssal_eel"],
		"max_count": 3,
		"depth_min": 5.0,
		"depth_max": 20.0
	})
	
	spawn_zones.append({
		"center": Vector3(0, 0, 0),
		"radius": 100.0,
		"environment": MonsterEnvironment.BOTH,
		"monster_types": ["giant_shark", "kraken"],
		"max_count": 2
	})

func _try_spawn_monsters() -> void:
	for zone in spawn_zones:
		var current_count = _count_monsters_in_zone(zone)
		if current_count >= zone.get("max_count", 5):
			continue
		
		var monster_type = zone["monster_types"][randi() % zone["monster_types"].size()]
		var spawn_pos = _get_random_spawn_position(zone)
		
		var environment = zone.get("environment", MonsterEnvironment.SURFACE)
		var depth = 0.0
		
		if environment == MonsterEnvironment.UNDERWATER:
			depth = randf_range(zone.get("depth_min", 5.0), zone.get("depth_max", 20.0))
			spawn_pos.y = -depth
		elif environment == MonsterEnvironment.SURFACE:
			spawn_pos.y = WATER_SURFACE_Y
		elif environment == MonsterEnvironment.BOTH:
			if randf() > 0.5:
				depth = randf_range(5.0, 15.0)
				spawn_pos.y = -depth
				environment = MonsterEnvironment.UNDERWATER
			else:
				spawn_pos.y = WATER_SURFACE_Y
				environment = MonsterEnvironment.SURFACE
		
		spawn_monster(monster_type, spawn_pos, environment, depth)

func _count_monsters_in_zone(zone: Dictionary) -> int:
	var count = 0
	var center = zone["center"]
	var radius = zone.get("radius", 50.0)
	
	for monster_id in monsters.keys():
		var monster = monsters[monster_id]
		if monster.position.distance_to(center) <= radius:
			count += 1
	
	return count

func _get_random_spawn_position(zone: Dictionary) -> Vector3:
	var center = zone["center"]
	var radius = zone.get("radius", 50.0)
	var angle = randf() * TAU
	var distance = randf() * radius
	return center + Vector3(cos(angle) * distance, 0, sin(angle) * distance)

func spawn_monster(monster_type: String, position: Vector3, environment: MonsterEnvironment, depth: float = 0.0) -> MonsterEntity:
	var monster_id = "monster_%s_%d" % [monster_type, Time.get_ticks_msec()]
	
	# Загружаем данные монстра
	var monster_data = _get_monster_data(monster_type)
	if monster_data.is_empty():
		push_warning("Monster type not found: %s" % monster_type)
		return null
	
	var monster = MonsterEntity.new(monster_id, monster_type, position, environment, depth)
	monster.max_health = monster_data.get("max_health", 100.0)
	monster.health = monster.max_health
	monster.level = monster_data.get("level", 1)
	
	monsters[monster_id] = monster
	monster_spawned.emit(monster_id, monster)
	
	return monster

func _get_monster_data(monster_type: String) -> Dictionary:
	# Заглушка - в реальной игре загружать из базы данных
	# TODO: Интегрировать с MonsterDatabase
	var database: Dictionary = {
		"reef_eel": {
			"max_health": 50.0,
			"level": 1,
			"environment": MonsterEnvironment.SURFACE
		},
		"sea_snake": {
			"max_health": 80.0,
			"level": 2,
			"environment": MonsterEnvironment.SURFACE
		},
		"deep_seeker": {
			"max_health": 120.0,
			"level": 3,
			"environment": MonsterEnvironment.UNDERWATER
		},
		"abyssal_eel": {
			"max_health": 200.0,
			"level": 5,
			"environment": MonsterEnvironment.UNDERWATER
		},
		"giant_shark": {
			"max_health": 300.0,
			"level": 7,
			"environment": MonsterEnvironment.BOTH
		},
		"kraken": {
			"max_health": 1000.0,
			"level": 10,
			"environment": MonsterEnvironment.BOTH
		}
	}
	
	return database.get(monster_type, {})

func _update_monsters(delta: float) -> void:
	for monster_id in monsters.keys():
		var monster = monsters[monster_id]
		_update_monster_ai(monster, delta)

func _update_monster_ai(monster: MonsterEntity, delta: float) -> void:
	# Простая AI логика
	match monster.state:
		"idle":
			# Патрулирование или ожидание
			pass
		"chasing":
			# Преследование цели
			pass
		"attacking":
			# Атака цели
			pass
	
	# Обновляем время последнего обновления
	monster.last_update = Time.get_unix_time_from_system()

func move_monster(monster_id: String, new_position: Vector3, new_depth: float = 0.0) -> void:
	if not monsters.has(monster_id):
		return
	
	var monster = monsters[monster_id]
	monster.position = new_position
	monster.depth = new_depth
	
	if monster.environment == MonsterEnvironment.UNDERWATER or monster.depth > 0.0:
		monster.position.y = -new_depth
	
	monster_moved.emit(monster_id, new_position, new_depth)

func damage_monster(monster_id: String, damage: float) -> bool:
	if not monsters.has(monster_id):
		return false
	
	var monster = monsters[monster_id]
	monster.health -= damage
	monster.health = max(0.0, monster.health)
	
	if monster.health <= 0.0:
		kill_monster(monster_id)
		return true
	
	return false

func kill_monster(monster_id: String) -> void:
	if not monsters.has(monster_id):
		return
	
	monsters.erase(monster_id)
	monster_died.emit(monster_id)

func get_monster(monster_id: String) -> MonsterEntity:
	return monsters.get(monster_id, null)

func get_monsters_in_radius(center: Vector3, radius: float) -> Array:
	var result = []
	for monster_id in monsters.keys():
		var monster = monsters[monster_id]
		if monster.position.distance_to(center) <= radius:
			result.append(monster)
	return result

func get_monster_snapshot() -> Dictionary:
	var snapshot = {
		"monsters": []
	}
	
	for monster_id in monsters.keys():
		var monster = monsters[monster_id]
		snapshot["monsters"].append({
			"id": monster.id,
			"type": monster.monster_type,
			"pos": [monster.position.x, monster.position.y, monster.position.z],
			"depth": monster.depth,
			"environment": monster.environment,
			"health": monster.health,
			"max_health": monster.max_health,
			"level": monster.level,
			"state": monster.state
		})
	
	return snapshot

