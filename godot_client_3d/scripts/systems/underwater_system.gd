extends Node
class_name UnderwaterSystem

## Система подводного плавания Isleborn Online
## Управляет нырянием, дыханием, глубиной

enum DiveMode {
	SURFACE,        # На поверхности
	SNORKELING,     # С трубкой (до 2м)
	DIVING,         # С маской (до 40м)
	EQUIPPED,       # Со снаряжением (до 100м)
	BLACKWATER      # С магией (до 300м+)
}

var current_dive_mode: DiveMode = DiveMode.SURFACE
var current_depth: float = 0.0
var oxygen_level: float = 100.0
var max_oxygen: float = 100.0
var pressure_level: float = 0.0

var has_dive_equipment: bool = false
var has_snorkel: bool = false
var has_dive_mask: bool = false
var has_magic_breathing: bool = false

signal depth_changed(new_depth: float)
signal oxygen_changed(oxygen: float, max_oxygen: float)
signal pressure_warning(high_pressure: bool)
signal dive_mode_changed(mode: DiveMode)

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	_update_underwater_state(delta)

## Обновление состояния под водой
func _update_underwater_state(delta: float) -> void:
	# Расход кислорода
	if current_dive_mode != DiveMode.SURFACE and current_dive_mode != DiveMode.SNORKELING:
		consume_oxygen(delta * 5.0)
	
	# Давление зависит от глубины
	pressure_level = current_depth / 10.0  # 1 единица давления на 10м
	
	# Предупреждение о высоком давлении
	if pressure_level > 8.0:
		pressure_warning.emit(true)
	else:
		pressure_warning.emit(false)

## Установить глубину
func set_depth(depth: float) -> void:
	current_depth = depth
	
	# Автоматическое определение режима ныряния
	_update_dive_mode()
	depth_changed.emit(depth)

## Обновить режим ныряния на основе глубины
func _update_dive_mode() -> void:
	var new_mode = DiveMode.SURFACE
	
	if current_depth <= 0.0:
		new_mode = DiveMode.SURFACE
	elif current_depth <= 2.0 and has_snorkel:
		new_mode = DiveMode.SNORKELING
	elif current_depth <= 40.0 and has_dive_mask:
		new_mode = DiveMode.DIVING
	elif current_depth <= 100.0 and has_dive_equipment:
		new_mode = DiveMode.EQUIPPED
	elif has_magic_breathing:
		new_mode = DiveMode.BLACKWATER
	
	if new_mode != current_dive_mode:
		current_dive_mode = new_mode
		dive_mode_changed.emit(new_mode)

## Потратить кислород
func consume_oxygen(amount: float) -> void:
	oxygen_level = max(0.0, oxygen_level - amount)
	oxygen_changed.emit(oxygen_level, max_oxygen)
	
	# Кислород закончился - начинается урон
	if oxygen_level <= 0.0:
		_apply_drowning_damage()

## Восстановить кислород (на поверхности или у источника воздуха)
func restore_oxygen(amount: float = 100.0) -> void:
	oxygen_level = min(max_oxygen, oxygen_level + amount)
	oxygen_changed.emit(oxygen_level, max_oxygen)

## Применить урон от утопления
func _apply_drowning_damage() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("take_damage"):
		player.take_damage(10.0)  # 10 урона в секунду

## Получить максимальную глубину для текущего оборудования
func get_max_depth() -> float:
	match current_dive_mode:
		DiveMode.SURFACE:
			return 0.0
		DiveMode.SNORKELING:
			return 2.0
		DiveMode.DIVING:
			return 40.0
		DiveMode.EQUIPPED:
			return 100.0
		DiveMode.BLACKWATER:
			return 300.0
	return 0.0

## Проверить, можно ли нырнуть на глубину
func can_dive_to_depth(depth: float) -> bool:
	return depth <= get_max_depth()

## Получить название режима ныряния
func get_dive_mode_name() -> String:
	match current_dive_mode:
		DiveMode.SURFACE:
			return "На поверхности"
		DiveMode.SNORKELING:
			return "С трубкой"
		DiveMode.DIVING:
			return "С маской"
		DiveMode.EQUIPPED:
			return "Со снаряжением"
		DiveMode.BLACKWATER:
			return "Магическое дыхание"
		_:
			return "Неизвестно"

