extends Node
class_name CharacterClass

## Система классов персонажа Isleborn Online
## До 10 уровня - без класса, затем выбор специальности

enum Archetype {
	NONE,           # Без класса (до 10 уровня)
	GATHERER,       # Собиратель
	FIGHTER,        # Боец
	RANGER,         # Стрелок
	SAILOR,         # Моряк
	ALCHEMIST,      # Алхимик
	MYSTIC,         # Мистик
	BUILDER         # Строитель
}

enum ArchetypeSpecialization {
	# Gatherer
	GATHERER_EXPLORER,      # Исследователь
	GATHERER_TRADER,        # Торговец
	GATHERER_HARVESTER,     # Жнец
	
	# Fighter
	FIGHTER_BERSERKER,      # Берсерк
	FIGHTER_DEFENDER,       # Защитник
	FIGHTER_DUELIST,        # Дуэлянт
	
	# Ranger
	RANGER_HUNTER,          # Охотник
	RANGER_SNIPER,          # Снайпер
	RANGER_TRAPPER,         # Ловец
	
	# Sailor
	SAILOR_CAPTAIN,         # Капитан
	SAILOR_NAVIGATOR,       # Навигатор
	SAILOR_CANNONEER,       # Пушкарь
	
	# Alchemist
	ALCHEMIST_ELIXIRIST,    # Эликсирщик
	ALCHEMIST_BOMBER,       # Бомбардир
	ALCHEMIST_ENCHANTER,    # Зачарователь
	
	# Mystic
	MYSTIC_ELEMENTALIST,    # Элементалист
	MYSTIC_SUMMONER,        # Призыватель
	MYSTIC_DIVINER,         # Предсказатель
	
	# Builder
	BUILDER_ARCHITECT,      # Архитектор
	BUILDER_ENGINEER,       # Инженер
	BUILDER_DECORATOR       # Декоратор
}

## Данные класса
class ClassData:
	var archetype: Archetype
	var specialization: ArchetypeSpecialization = -1
	var name: String
	var description: String
	var stat_bonuses: Dictionary = {}
	var allowed_skill_types: Array[String] = []
	var forbidden_skill_types: Array[String] = []
	var starting_skills: Array[String] = []

var current_class: ClassData = null
var level: int = 1
var available_classes: Array[ClassData] = []

func _ready() -> void:
	_initialize_classes()

func _initialize_classes() -> void:
	# Собиратель
	var gatherer = ClassData.new()
	gatherer.archetype = Archetype.GATHERER
	gatherer.name = "Собиратель"
	gatherer.description = "Мастер добычи ресурсов и исследования океана"
	gatherer.stat_bonuses = {"focus": 3, "stamina": 2}
	gatherer.allowed_skill_types = ["gathering", "exploration", "trade"]
	gatherer.forbidden_skill_types = ["heavy_combat", "magic_offensive"]
	available_classes.append(gatherer)
	
	# Боец
	var fighter = ClassData.new()
	fighter.archetype = Archetype.FIGHTER
	fighter.name = "Боец"
	fighter.description = "Великий воин ближнего боя"
	fighter.stat_bonuses = {"strength": 5, "vitality": 3}
	fighter.allowed_skill_types = ["melee", "defense", "berserker"]
	fighter.forbidden_skill_types = ["ranged", "magic"]
	available_classes.append(fighter)
	
	# Стрелок
	var ranger = ClassData.new()
	ranger.archetype = Archetype.RANGER
	ranger.name = "Стрелок"
	ranger.description = "Мастер дальнего боя и точности"
	ranger.stat_bonuses = {"agility": 5, "perception": 3}
	ranger.allowed_skill_types = ["ranged", "hunting", "traps"]
	ranger.forbidden_skill_types = ["heavy_armor", "magic"]
	available_classes.append(ranger)
	
	# Моряк
	var sailor = ClassData.new()
	sailor.archetype = Archetype.SAILOR
	sailor.name = "Моряк"
	sailor.description = "Искусный мореплаватель и капитан"
	sailor.stat_bonuses = {"seamanship": 5, "leadership": 3}
	sailor.allowed_skill_types = ["sailing", "ship_combat", "navigation"]
	sailor.forbidden_skill_types = []
	available_classes.append(sailor)
	
	# Алхимик
	var alchemist = ClassData.new()
	alchemist.archetype = Archetype.ALCHEMIST
	alchemist.name = "Алхимик"
	alchemist.description = "Мастер зелий и взрывчатых веществ"
	alchemist.stat_bonuses = {"intelligence": 5, "crafting": 3}
	alchemist.allowed_skill_types = ["alchemy", "bomb", "enchanting"]
	alchemist.forbidden_skill_types = ["heavy_combat"]
	available_classes.append(alchemist)
	
	# Мистик
	var mystic = ClassData.new()
	mystic.archetype = Archetype.MYSTIC
	mystic.name = "Мистик"
	mystic.description = "Владелец тайной магии океана"
	mystic.stat_bonuses = {"magic": 5, "wisdom": 3}
	mystic.allowed_skill_types = ["magic", "elemental", "summoning"]
	mystic.forbidden_skill_types = ["physical_combat"]
	mystic.starting_skills = ["basic_water_bolt"]
	available_classes.append(mystic)
	
	# Строитель
	var builder = ClassData.new()
	builder.archetype = Archetype.BUILDER
	builder.name = "Строитель"
	builder.description = "Мастер строительства и архитектуры"
	builder.stat_bonuses = {"construction": 5, "engineering": 3}
	builder.allowed_skill_types = ["building", "automation", "defense_structures"]
	builder.forbidden_skill_types = ["combat_offensive"]
	available_classes.append(builder)

## Выбрать класс (на 10 уровне)
func select_class(archetype: Archetype) -> bool:
	if level < 10:
		return false
	
	if current_class != null:
		return false  # Класс уже выбран
	
	for class_data in available_classes:
		if class_data.archetype == archetype:
			current_class = class_data
			return true
	
	return false

## Получить доступные классы для выбора
func get_available_classes_for_selection() -> Array[ClassData]:
	return available_classes.duplicate()

## Проверить, может ли персонаж использовать навык
func can_use_skill(skill_type: String) -> bool:
	if current_class == null:
		# До выбора класса можно использовать только универсальные навыки
		return skill_type == "universal"
	
	# Проверка запрещённых типов
	if skill_type in current_class.forbidden_skill_types:
		return false
	
	# Проверка разрешённых типов
	if current_class.allowed_skill_types.is_empty():
		return true  # Нет ограничений
	
	return skill_type in current_class.allowed_skill_types or skill_type == "universal"

## Получить бонусы класса к статам
func get_class_stat_bonuses() -> Dictionary:
	if current_class == null:
		return {}
	return current_class.stat_bonuses.duplicate()

## Получить текущий класс
func get_current_class() -> ClassData:
	return current_class

## Проверить, выбран ли класс
func is_class_selected() -> bool:
	return current_class != null

