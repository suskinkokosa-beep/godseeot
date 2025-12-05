extends Node
class_name CharacterProgression

## Система прогрессии персонажа
## Каждые 5 уровней: 5 очков статов + 1 очко навыка
## На 10 уровне - выбор класса

@export var current_level: int = 1
@export var current_experience: float = 0.0

# Статы
var stat_points: int = 0  # Свободные очки статов
var stats: Dictionary = {
	"strength": 10,      # Сила (урон, переносимый вес)
	"vitality": 10,      # Живучесть (здоровье)
	"agility": 10,       # Ловкость (скорость, уклонение)
	"stamina": 10,       # Выносливость (стамина)
	"focus": 10,         # Фокус (скорость сбора)
	"intelligence": 10,  # Интеллект (мана, крафт)
	"perception": 10,    # Восприятие (заметность, точность)
	"luck": 10           # Удача (крит, дроп)
}

# Класс
var character_class: CharacterClass = null

# Навыки
var skill_system: SkillSystem = null

signal level_up(new_level: int)
signal stat_points_gained(amount: int)
signal skill_point_gained
signal class_selection_available

func _ready() -> void:
	character_class = CharacterClass.new()
	skill_system = SkillSystem.new()
	add_child(character_class)
	add_child(skill_system)

## Вычисляет требуемый опыт для уровня
## После 10 уровня прокачка становится намного труднее
static func get_experience_for_level(level: int) -> float:
	if level <= 10:
		# До 10 уровня: XP = 50 * Level^1.9
		return 50.0 * pow(level, 1.9)
	else:
		# После 10 уровня: XP = BaseXP * (1 + (Level - 10) * 0.5) * Level^2.2
		# Это делает прокачку в 2-3 раза труднее
		var base_xp = 50.0 * pow(10, 1.9)  # Опыт для 10 уровня
		var level_multiplier = 1.0 + (level - 10) * 0.5  # +50% за каждый уровень после 10
		var exponential = pow(level, 2.2)  # Более крутая экспонента
		return base_xp * level_multiplier * (exponential / pow(10, 1.9))

## Добавляет опыт
func add_experience(amount: float) -> void:
	if amount <= 0.0:
		return
	
	current_experience += amount
	
	# Проверяем повышение уровня
	var needed_exp = get_experience_for_level(current_level + 1)
	while current_experience >= needed_exp and current_level < 50:
		current_experience -= needed_exp
		current_level += 1
		
		# Каждые 5 уровней даём награды
		if current_level % 5 == 0:
			stat_points += 5
			skill_system.add_skill_point()
			stat_points_gained.emit(5)
			skill_point_gained.emit()
		
		# На 10 уровне предлагаем выбор класса
		if current_level == 10 and not character_class.is_class_selected():
			class_selection_available.emit()
		
		level_up.emit(current_level)
		
		if current_level < 50:
			needed_exp = get_experience_for_level(current_level + 1)

## Распределить очко стата
func allocate_stat(stat_name: String) -> bool:
	if stat_points <= 0:
		return false
	
	if not stats.has(stat_name):
		return false
	
	stats[stat_name] += 1
	stat_points -= 1
	return true

## Получить стат
func get_stat(stat_name: String) -> int:
	return stats.get(stat_name, 10)

## Получить все статы
func get_all_stats() -> Dictionary:
	var all_stats = stats.duplicate()
	
	# Добавляем бонусы класса
	if character_class:
		var class_bonuses = character_class.get_class_stat_bonuses()
		for stat_name in class_bonuses.keys():
			if all_stats.has(stat_name):
				all_stats[stat_name] += class_bonuses[stat_name]
	
	return all_stats

## Получить свободные очки статов
func get_free_stat_points() -> int:
	return stat_points

## Выбрать класс (на 10 уровне)
func select_class(archetype: CharacterClass.Archetype) -> bool:
	if current_level < 10:
		return false
	
	return character_class.select_class(archetype)

## Получить текущий класс
func get_current_class() -> CharacterClass.ClassData:
	return character_class.get_current_class()

## Проверить, можно ли выбрать класс
func can_select_class() -> bool:
	return current_level >= 10 and not character_class.is_class_selected()

