extends Node3D
class_name MonsterAI

## Базовая система AI для монстров
## Использует FSM (Finite State Machine) для управления состояниями

enum AIState {
	IDLE,           # Ожидание
	PATROL,         # Патрулирование
	INVESTIGATE,    # Исследование
	CHASE,          # Преследование
	ATTACK,         # Атака
	FLEE,           # Бегство
	CALL_GROUP      # Зов стаи
}

@export var monster_id: String = ""
@export var detection_range: float = 10.0
@export var attack_range: float = 1.5
@export var patrol_radius: float = 5.0

var current_state: AIState = AIState.IDLE
var target: Node3D = null
var spawn_position: Vector3
var monster_data: Dictionary = {}
var health: float = 100.0
var max_health: float = 100.0

var patrol_target: Vector3 = Vector3.ZERO
var state_timer: float = 0.0

signal monster_died
signal target_detected(target: Node3D)

func _ready() -> void:
	spawn_position = global_position
	_load_monster_data()
	_initialize_state()

func _load_monster_data() -> void:
	if monster_id != "":
		monster_data = MonsterDatabase.get_monster(monster_id)
		if not monster_data.is_empty():
			max_health = monster_data.get("health", 100.0)
			health = max_health
			attack_range = monster_data.get("attack_range", 1.5)
			detection_range = attack_range * 3.0

func _initialize_state() -> void:
	current_state = AIState.PATROL
	_set_patrol_target()

func _process(delta: float) -> void:
	state_timer += delta
	
	match current_state:
		AIState.IDLE:
			_state_idle(delta)
		AIState.PATROL:
			_state_patrol(delta)
		AIState.INVESTIGATE:
			_state_investigate(delta)
		AIState.CHASE:
			_state_chase(delta)
		AIState.ATTACK:
			_state_attack(delta)
		AIState.FLEE:
			_state_flee(delta)
		AIState.CALL_GROUP:
			_state_call_group(delta)

func _state_idle(delta: float) -> void:
	# Ожидание, затем переход к патрулированию
	if state_timer > 3.0:
		current_state = AIState.PATROL
		_set_patrol_target()
		state_timer = 0.0

func _state_patrol(delta: float) -> void:
	# Патрулирование области вокруг точки спавна
	var distance_to_target = global_position.distance_to(patrol_target)
	
	if distance_to_target < 1.0:
		# Достигли цели патрулирования, выбираем новую
		_set_patrol_target()
	
	# Движение к цели патрулирования
	_move_towards(patrol_target, delta)
	
	# Проверка обнаружения цели
	_check_for_targets()

func _state_investigate(delta: float) -> void:
	# Исследование подозрительной активности
	if state_timer > 5.0:
		# Прекратили исследование
		current_state = AIState.PATROL
		_set_patrol_target()
		state_timer = 0.0
		return
	
	# Движение к месту для исследования
	if target:
		_move_towards(target.global_position, delta)
		var distance = global_position.distance_to(target.global_position)
		if distance < detection_range:
			# Обнаружили цель - начинаем преследование
			current_state = AIState.CHASE
			state_timer = 0.0

func _state_chase(delta: float) -> void:
	# Преследование цели
	if not target or not is_instance_valid(target):
		current_state = AIState.PATROL
		_set_patrol_target()
		return
	
	var distance = global_position.distance_to(target.global_position)
	
	# Проверка здоровья - возможно, пора бежать
	var health_percent = health / max_health
	if health_percent < 0.3:
		current_state = AIState.FLEE
		return
	
	# Проверка расстояния для атаки
	if distance <= attack_range:
		current_state = AIState.ATTACK
		state_timer = 0.0
		return
	
	# Если цель слишком далеко, прекращаем преследование
	if distance > detection_range * 2.0:
		current_state = AIState.PATROL
		_set_patrol_target()
		return
	
	# Продолжаем преследование
	_move_towards(target.global_position, delta)

func _state_attack(delta: float) -> void:
	# Атака цели
	if not target or not is_instance_valid(target):
		current_state = AIState.PATROL
		_set_patrol_target()
		return
	
	var distance = global_position.distance_to(target.global_position)
	
	# Если цель ушла из зоны атаки, преследуем
	if distance > attack_range * 1.5:
		current_state = AIState.CHASE
		return
	
	# Атака (реализация зависит от типа монстра)
	if state_timer > 1.5:  # Задержка между атаками
		_perform_attack()
		state_timer = 0.0

func _state_flee(delta: float) -> void:
	# Бегство от опасности
	var health_percent = health / max_health
	
	if health_percent > 0.5:
		# Восстановили здоровье, возвращаемся к патрулированию
		current_state = AIState.PATROL
		_set_patrol_target()
		return
	
	# Бежим в противоположную сторону от цели
	if target and is_instance_valid(target):
		var flee_direction = (global_position - target.global_position).normalized()
		var flee_target = global_position + flee_direction * 10.0
		_move_towards(flee_target, delta)

func _state_call_group(delta: float) -> void:
	# Призыв других монстров
	if state_timer > 2.0:
		current_state = AIState.ATTACK
		state_timer = 0.0

func _set_patrol_target() -> void:
	# Выбираем случайную точку для патрулирования
	var angle = randf() * TAU
	var distance = randf() * patrol_radius
	patrol_target = spawn_position + Vector3(cos(angle) * distance, 0, sin(angle) * distance)

func _move_towards(target_pos: Vector3, delta: float) -> void:
	var direction = (target_pos - global_position).normalized()
	direction.y = 0  # Движение только по горизонтали
	
	var speed = monster_data.get("speed", 3.0)
	global_position += direction * speed * delta
	
	# Поворот в сторону движения
	if direction.length() > 0.1:
		look_at(global_position + direction, Vector3.UP)

func _check_for_targets() -> void:
	# Простая проверка ближайших объектов
	# TODO: Использовать PhysicsDirectSpaceState3D для более точного определения
	var space = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	
	# Упрощённая проверка - ищем игроков в радиусе
	# В реальной игре это должно быть более сложным

func _perform_attack() -> void:
	if not target:
		return
	
	var damage = monster_data.get("damage", 5.0)
	# TODO: Нанести урон цели через систему боя

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		_die()

func _die() -> void:
	monster_died.emit()
	# TODO: Генерация лута через LootSystem
	queue_free()

func set_target(new_target: Node3D) -> void:
	if target != new_target:
		target = new_target
		if target:
			target_detected.emit(target)
			if current_state == AIState.PATROL or current_state == AIState.IDLE:
				current_state = AIState.INVESTIGATE
				state_timer = 0.0

