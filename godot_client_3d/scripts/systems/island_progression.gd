extends Node
class_name IslandProgression

## Система прогрессии острова согласно GDD
## Формула: NewArea = BaseArea * (1 + Level * LevelGrowthFactor)
## Уровень стоимости: IslandLevelCost = BaseCost * (Level^1.65)

@export var current_level: int = 1
@export var current_experience: float = 0.0
@export var base_area: float = 25.0  # 5x5 м
@export var level_growth_factor: float = 0.05

var base_cost: float = 100.0
var island_radius: float = 2.5  # Радиус в метрах (для круглого острова)

signal level_up(level: int)
signal experience_gained(amount: float)

func _ready() -> void:
	_update_radius()

## Вычисляет требуемый опыт для уровня
static func get_experience_for_level(level: int) -> float:
	# XP = 50 * Level^1.9 (по GDD)
	return 50.0 * pow(level, 1.9)


## Вычисляет стоимость уровня
static func get_level_cost(level: int, base: float = 100.0) -> float:
	# IslandLevelCost = BaseCost * (Level^1.65)
	return base * pow(level, 1.65)


## Вычисляет размер острова для уровня
static func get_island_size_for_level(level: int, base_area: float = 25.0, growth_factor: float = 0.05) -> float:
	# NewArea = BaseArea * (1 + Level * LevelGrowthFactor)
	var area = base_area * (1.0 + level * growth_factor)
	return area


## Вычисляет радиус острова для уровня
static func get_island_radius_for_level(level: int, base_area: float = 25.0, growth_factor: float = 0.05) -> float:
	var area = get_island_size_for_level(level, base_area, growth_factor)
	# Предполагаем круглый остров: Area = π * r²
	var radius = sqrt(area / PI)
	return radius


## Добавляет опыт острову
func add_experience(amount: float) -> void:
	if amount <= 0.0:
		return
	
	current_experience += amount
	experience_gained.emit(amount)
	
	# Проверяем повышение уровня
	var needed_exp = get_experience_for_level(current_level + 1)
	while current_experience >= needed_exp and current_level < 50:
		current_experience -= needed_exp
		current_level += 1
		
		_update_radius()
		level_up.emit(current_level)
		
		if current_level < 50:
			needed_exp = get_experience_for_level(current_level + 1)


## Получить текущий радиус острова
func get_current_radius() -> float:
	return island_radius


## Получить текущую площадь острова
func get_current_area() -> float:
	return PI * island_radius * island_radius


## Получить стоимость следующего уровня
func get_next_level_cost() -> float:
	return get_level_cost(current_level + 1, base_cost)


## Получить требуемый опыт до следующего уровня
func get_experience_to_next_level() -> float:
	var needed = get_experience_for_level(current_level + 1)
	return needed - current_experience


## Обновляет радиус острова на основе уровня
func _update_radius() -> void:
	island_radius = get_island_radius_for_level(current_level, base_area, level_growth_factor)


## Таблица прогрессии по уровням (для справки)
static func get_progression_table() -> Dictionary:
	var table = {}
	for level in range(1, 51):
		table[level] = {
			"area": get_island_size_for_level(level),
			"radius": get_island_radius_for_level(level),
			"cost": get_level_cost(level),
			"exp_needed": get_experience_for_level(level)
		}
	return table

