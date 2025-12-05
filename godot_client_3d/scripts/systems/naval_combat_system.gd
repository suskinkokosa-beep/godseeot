extends Node
class_name NavalCombatSystem

## Система морского боя для Isleborn Online
## Согласно GDD: морской бой кораблей с баллистикой, абордажем, таранами

enum CombatState {
	IDLE,           # Не в бою
	ENGAGING,       # Сближение
	EXCHANGING,     # Обмен выстрелами
	RAMMING,        # Таранят
	BOARDING,       # Абордаж
	RETREATING,     # Отступление
	DISABLED        # Отключен (сломан)
}

enum WeaponType {
	CANNON_LIGHT,   # Лёгкие орудия
	CANNON_HEAVY,   # Тяжёлые орудия
	HARPOON,        # Гарпун
	BALLISTA,       # Баллиста
	MAGIC_COIL      # Магическая катушка
}

class Projectile:
	var projectile_id: String
	var owner_ship_id: String
	var position: Vector3
	var velocity: Vector3
	var damage: float
	var weapon_type: WeaponType
	var lifetime: float = 10.0
	
	func _init(_id: String, _owner: String, _pos: Vector3, _vel: Vector3, _dmg: float, _type: WeaponType):
		projectile_id = _id
		owner_ship_id = _owner
		position = _pos
		velocity = _vel
		damage = _dmg
		weapon_type = _type

class ShipCombatData:
	var ship_id: String
	var health: float = 100.0
	var max_health: float = 100.0
	var hull_integrity: float = 100.0  # Целостность корпуса
	var position: Vector3
	var rotation: float = 0.0
	var velocity: Vector3
	var combat_state: CombatState = CombatState.IDLE
	var target_ship_id: String = ""
	var weapons: Array[Dictionary] = []  # {type: WeaponType, cooldown: float, ammo: int}
	var crew_count: int = 1
	var boarding_crew: int = 0  # Экипаж, готовый к абордажу
	var stability: float = 100.0  # Стабильность корабля
	var fire_status: float = 0.0  # Огонь на корабле (0-100)
	
	func _init(_id: String, _pos: Vector3):
		ship_id = _id
		position = _pos

var combat_ships: Dictionary = {}  # ship_id -> ShipCombatData
var active_projectiles: Dictionary = {}  # projectile_id -> Projectile
var combat_sessions: Dictionary = {}  # session_id -> {ships: [], start_time: int}

signal ship_health_changed(ship_id: String, health: float, max_health: float)
signal ship_destroyed(ship_id: String)
signal projectile_fired(projectile_id: String, owner_id: String, target_pos: Vector3)
signal boarding_started(ship_id: String, target_id: String)
signal ship_disabled(ship_id: String)

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	_update_projectiles(delta)
	_update_combat_states(delta)
	_update_fire_status(delta)

func _update_projectiles(delta: float) -> void:
	var expired: Array[String] = []
	
	for proj_id in active_projectiles.keys():
		var proj = active_projectiles[proj_id]
		proj.position += proj.velocity * delta
		proj.lifetime -= delta
		
		if proj.lifetime <= 0.0:
			expired.append(proj_id)
			continue
		
		# Проверка попаданий
		_check_projectile_hits(proj)
	
	for proj_id in expired:
		active_projectiles.erase(proj_id)

func _update_combat_states(delta: float) -> void:
	for ship_id in combat_ships.keys():
		var ship = combat_ships[ship_id]
		
		# Обновляем кулдауны орудий
		for i in range(ship.weapons.size()):
			if ship.weapons[i].get("cooldown", 0.0) > 0.0:
				ship.weapons[i]["cooldown"] = max(0.0, ship.weapons[i]["cooldown"] - delta)
		
		# Обновляем состояние боя
		match ship.combat_state:
			CombatState.ENGAGING:
				_process_engaging(ship, delta)
			CombatState.EXCHANGING:
				_process_exchanging(ship, delta)
			CombatState.RAMMING:
				_process_ramming(ship, delta)
			CombatState.BOARDING:
				_process_boarding(ship, delta)

func _update_fire_status(delta: float) -> void:
	for ship_id in combat_ships.keys():
		var ship = combat_ships[ship_id]
		if ship.fire_status > 0.0:
			# Огонь наносит урон
			var fire_damage = ship.fire_status * 2.0 * delta
			damage_ship(ship_id, fire_damage)
			
			# Огонь распространяется, но можно тушить
			if randf() < 0.1 * delta:  # 10% шанс в секунду увеличиться
				ship.fire_status = min(100.0, ship.fire_status + 5.0)
			else:
				ship.fire_status = max(0.0, ship.fire_status - 1.0 * delta)  # Постепенно тухнет

func register_ship_for_combat(ship_id: String, position: Vector3, max_health: float = 100.0) -> void:
	if combat_ships.has(ship_id):
		return
	
	var ship = ShipCombatData.new(ship_id, position)
	ship.max_health = max_health
	ship.health = max_health
	combat_ships[ship_id] = ship

func unregister_ship(ship_id: String) -> void:
	combat_ships.erase(ship_id)

func update_ship_position(ship_id: String, position: Vector3, rotation: float, velocity: Vector3) -> void:
	if not combat_ships.has(ship_id):
		return
	
	var ship = combat_ships[ship_id]
	ship.position = position
	ship.rotation = rotation
	ship.velocity = velocity

func add_weapon_to_ship(ship_id: String, weapon_type: WeaponType, ammo: int = 100) -> void:
	if not combat_ships.has(ship_id):
		return
	
	var ship = combat_ships[ship_id]
	ship.weapons.append({
		"type": weapon_type,
		"cooldown": 0.0,
		"ammo": ammo,
		"damage": _get_weapon_damage(weapon_type),
		"range": _get_weapon_range(weapon_type)
	})

func fire_weapon(ship_id: String, weapon_index: int, target_position: Vector3) -> bool:
	if not combat_ships.has(ship_id):
		return false
	
	var ship = combat_ships[ship_id]
	if weapon_index >= ship.weapons.size():
		return false
	
	var weapon = ship.weapons[weapon_index]
	if weapon.get("cooldown", 0.0) > 0.0:
		return false  # На кулдауне
	
	if weapon.get("ammo", 0) <= 0:
		return false  # Нет боеприпасов
	
	# Вычисляем направление
	var direction = (target_position - ship.position).normalized()
	var distance = ship.position.distance_to(target_position)
	
	if distance > weapon.get("range", 100.0):
		return false  # Слишком далеко
	
	# Создаём снаряд
	var proj_id = "proj_%d" % Time.get_ticks_msec()
	var proj_velocity = direction * _get_weapon_projectile_speed(weapon["type"])
	var proj = Projectile.new(proj_id, ship_id, ship.position, proj_velocity, weapon["damage"], weapon["type"])
	
	active_projectiles[proj_id] = proj
	
	# Обновляем орудие
	weapon["cooldown"] = _get_weapon_cooldown(weapon["type"])
	weapon["ammo"] = weapon.get("ammo", 0) - 1
	
	projectile_fired.emit(proj_id, ship_id, target_position)
	return true

func damage_ship(ship_id: String, damage: float, damage_type: String = "physical") -> void:
	if not combat_ships.has(ship_id):
		return
	
	var ship = combat_ships[ship_id]
	
	# Учитываем тип урона
	match damage_type:
		"fire":
			ship.fire_status = min(100.0, ship.fire_status + damage * 0.5)
			damage *= 1.2  # Огонь наносит больше урона
		"ram":
			damage *= 1.5  # Таранящий урон
			ship.stability -= damage * 0.5
	
	ship.health -= damage
	ship.hull_integrity = (ship.health / ship.max_health) * 100.0
	
	ship_health_changed.emit(ship_id, ship.health, ship.max_health)
	
	if ship.health <= 0.0:
		destroy_ship(ship_id)
	elif ship.hull_integrity < 30.0:
		ship.combat_state = CombatState.DISABLED
		ship_disabled.emit(ship_id)

func destroy_ship(ship_id: String) -> void:
	if not combat_ships.has(ship_id):
		return
	
	ship_destroyed.emit(ship_id)
	combat_ships.erase(ship_id)
	
	# Удаляем все снаряды, выпущенные этим кораблём
	var expired_proj: Array[String] = []
	for proj_id in active_projectiles.keys():
		if active_projectiles[proj_id].owner_ship_id == ship_id:
			expired_proj.append(proj_id)
	
	for proj_id in expired_proj:
		active_projectiles.erase(proj_id)

func start_boarding(ship_id: String, target_ship_id: String) -> bool:
	if not combat_ships.has(ship_id) or not combat_ships.has(target_ship_id):
		return false
	
	var ship = combat_ships[ship_id]
	var target = combat_ships[target_ship_id]
	
	# Проверяем дистанцию
	if ship.position.distance_to(target.position) > 10.0:
		return false  # Слишком далеко для абордажа
	
	# Проверяем наличие экипажа для абордажа
	if ship.boarding_crew <= 0:
		return false
	
	ship.combat_state = CombatState.BOARDING
	target.combat_state = CombatState.BOARDING
	ship.target_ship_id = target_ship_id
	
	boarding_started.emit(ship_id, target_ship_id)
	return true

func attempt_ram(ship_id: String, target_ship_id: String) -> bool:
	if not combat_ships.has(ship_id) or not combat_ships.has(target_ship_id):
		return false
	
	var ship = combat_ships[ship_id]
	var target = combat_ships[target_ship_id]
	
	# Проверяем, что корабли достаточно близко
	if ship.position.distance_to(target.position) > 15.0:
		return false
	
	# Вычисляем урон от тарана
	var ram_damage = ship.velocity.length() * 10.0
	damage_ship(target_ship_id, ram_damage, "ram")
	
	# Таранящий корабль тоже получает урон
	damage_ship(ship_id, ram_damage * 0.3, "ram")
	
	return true

func _check_projectile_hits(proj: Projectile) -> void:
	for ship_id in combat_ships.keys():
		var ship = combat_ships[ship_id]
		
		# Не попадаем в свой корабль
		if ship.ship_id == proj.owner_ship_id:
			continue
		
		# Проверяем попадание
		if ship.position.distance_to(proj.position) < 5.0:  # Радиус попадания
			damage_ship(ship_id, proj.damage, _get_damage_type_from_weapon(proj.weapon_type))
			
			# Удаляем снаряд
			if active_projectiles.has(proj.projectile_id):
				active_projectiles.erase(proj.projectile_id)
			
			break

func _process_engaging(ship: ShipCombatData, delta: float) -> void:
	if not ship.target_ship_id or not combat_ships.has(ship.target_ship_id):
		ship.combat_state = CombatState.IDLE
		return
	
	var target = combat_ships[ship.target_ship_id]
	var distance = ship.position.distance_to(target.position)
	
	# Если достаточно близко, начинаем обмен выстрелами
	if distance < 50.0:
		ship.combat_state = CombatState.EXCHANGING

func _process_exchanging(ship: ShipCombatData, delta: float) -> void:
	if not ship.target_ship_id or not combat_ships.has(ship.target_ship_id):
		ship.combat_state = CombatState.IDLE
		return
	
	var target = combat_ships[ship.target_ship_id]
	
	# Автоматическая стрельба (можно переопределить)
	for i in range(ship.weapons.size()):
		var weapon = ship.weapons[i]
		if weapon.get("cooldown", 0.0) <= 0.0 and weapon.get("ammo", 0) > 0:
			fire_weapon(ship.ship_id, i, target.position)

func _process_ramming(ship: ShipCombatData, delta: float) -> void:
	if not ship.target_ship_id or not combat_ships.has(ship.target_ship_id):
		ship.combat_state = CombatState.IDLE
		return
	
	# Логика тарана обрабатывается через attempt_ram

func _process_boarding(ship: ShipCombatData, delta: float) -> void:
	if not ship.target_ship_id or not combat_ships.has(ship.target_ship_id):
		ship.combat_state = CombatState.IDLE
		return
	
	var target = combat_ships[ship.target_ship_id]
	
	# Логика абордажа: проверка экипажа, урон, захват корабля
	# TODO: Реализовать детальную логику абордажа

func _get_weapon_damage(weapon_type: WeaponType) -> float:
	match weapon_type:
		WeaponType.CANNON_LIGHT: return 15.0
		WeaponType.CANNON_HEAVY: return 35.0
		WeaponType.HARPOON: return 10.0
		WeaponType.BALLISTA: return 25.0
		WeaponType.MAGIC_COIL: return 40.0
		_: return 10.0

func _get_weapon_range(weapon_type: WeaponType) -> float:
	match weapon_type:
		WeaponType.CANNON_LIGHT: return 80.0
		WeaponType.CANNON_HEAVY: return 120.0
		WeaponType.HARPOON: return 40.0
		WeaponType.BALLISTA: return 100.0
		WeaponType.MAGIC_COIL: return 150.0
		_: return 50.0

func _get_weapon_cooldown(weapon_type: WeaponType) -> float:
	match weapon_type:
		WeaponType.CANNON_LIGHT: return 3.0
		WeaponType.CANNON_HEAVY: return 8.0
		WeaponType.HARPOON: return 2.0
		WeaponType.BALLISTA: return 5.0
		WeaponType.MAGIC_COIL: return 10.0
		_: return 5.0

func _get_weapon_projectile_speed(weapon_type: WeaponType) -> float:
	match weapon_type:
		WeaponType.CANNON_LIGHT: return 20.0
		WeaponType.CANNON_HEAVY: return 25.0
		WeaponType.HARPOON: return 15.0
		WeaponType.BALLISTA: return 30.0
		WeaponType.MAGIC_COIL: return 35.0
		_: return 15.0

func _get_damage_type_from_weapon(weapon_type: WeaponType) -> String:
	match weapon_type:
		WeaponType.CANNON_LIGHT, WeaponType.CANNON_HEAVY:
			return "physical"
		WeaponType.MAGIC_COIL:
			return "magic"
		_:
			return "physical"

## Получить состояние боя корабля
func get_ship_combat_state(ship_id: String) -> Dictionary:
	if not combat_ships.has(ship_id):
		return {}
	
	var ship = combat_ships[ship_id]
	return {
		"health": ship.health,
		"max_health": ship.max_health,
		"hull_integrity": ship.hull_integrity,
		"combat_state": ship.combat_state,
		"target": ship.target_ship_id,
		"fire_status": ship.fire_status,
		"stability": ship.stability,
		"crew": ship.crew_count,
		"boarding_crew": ship.boarding_crew
	}

