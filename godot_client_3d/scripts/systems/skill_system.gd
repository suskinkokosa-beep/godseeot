extends Node
class_name SkillSystem

## Система навыков персонажа Isleborn Online
## Активные навыки: 5 слотов, пассивные: 3 слота
## Навыки получаются из книг навыков

enum SkillType {
	ACTIVE,
	PASSIVE
}

enum SkillRarity {
	COMMON,        # Обычный
	RARE,          # Редкий
	LEGENDARY,     # Легендарный
	MYTHIC         # Мифический
}

enum SkillCategory {
	# Активные категории
	MELEE,          # Ближний бой
	RANGED,         # Дальний бой
	MAGIC,          # Магия
	ALCHEMY,        # Алхимия
	SAILING,        # Мореплавание
	GATHERING,      # Собирательство
	DEFENSE,        # Защита
	MOVEMENT,       # Движение
	
	# Универсальные (для пассивных)
	UNIVERSAL       # Универсальный
}

## Данные навыка
class SkillData:
	var id: String
	var name: String
	var description: String
	var skill_type: SkillType
	var rarity: SkillRarity
	var category: SkillCategory
	var max_level: int = 1
	var current_level: int = 0
	
	var stat_requirements: Dictionary = {}
	var class_restrictions: Array[String] = []  # Пусто = все классы
	
	var cooldown: float = 0.0
	var mana_cost: float = 0.0
	var stamina_cost: float = 0.0
	
	var effects: Dictionary = {}
	var scaling: Dictionary = {}  # Масштабирование с уровнем
	
	func is_learned() -> bool:
		return current_level > 0
	
	func can_level_up() -> bool:
		return current_level < max_level

var known_skills: Dictionary = {}  # skill_id -> SkillData
var active_skills: Array[String] = ["", "", "", "", ""]  # 5 слотов
var passive_skills: Array[String] = ["", "", ""]  # 3 слота

var skill_points: int = 0  # Очки навыков

signal skill_learned(skill_id: String)
signal skill_leveled_up(skill_id: String, new_level: int)
signal skill_equipped(skill_id: String, slot: int)
signal skill_unequipped(skill_id: String)

func _ready() -> void:
	pass

## Изучить навык из книги
func learn_skill_from_book(skill_book_id: String) -> bool:
	# Получаем данные книги
	var skill_id = SkillBookDatabase.get_skill_from_book(skill_book_id)
	if skill_id == "":
		return false
	
	# Проверяем, не изучен ли уже
	if known_skills.has(skill_id):
		return false  # Уже изучен
	
	# Получаем данные навыка
	var skill_data = SkillDatabase.get_skill(skill_id)
	if skill_data.is_empty():
		return false
	
	# Создаём запись навыка
	var skill = SkillData.new()
	skill.id = skill_data.get("id", "")
	skill.name = skill_data.get("name", "")
	skill.description = skill_data.get("description", "")
	skill.skill_type = skill_data.get("skill_type", SkillType.ACTIVE)
	skill.rarity = skill_data.get("rarity", SkillRarity.COMMON)
	skill.category = skill_data.get("category", SkillCategory.UNIVERSAL)
	skill.max_level = skill_data.get("max_level", 1)
	skill.current_level = 1
	skill.stat_requirements = skill_data.get("stat_requirements", {})
	skill.class_restrictions = skill_data.get("class_restrictions", [])
	skill.cooldown = skill_data.get("cooldown", 0.0)
	skill.mana_cost = skill_data.get("mana_cost", 0.0)
	skill.stamina_cost = skill_data.get("stamina_cost", 0.0)
	skill.effects = skill_data.get("effects", {})
	skill.scaling = skill_data.get("scaling", {})
	
	known_skills[skill_id] = skill
	skill_learned.emit(skill_id)
	return true

## Улучшить навык (требует очко навыка)
func level_up_skill(skill_id: String) -> bool:
	if not known_skills.has(skill_id):
		return false
	
	if skill_points <= 0:
		return false
	
	var skill = known_skills[skill_id]
	if not skill.can_level_up():
		return false
	
	skill_points -= 1
	skill.current_level += 1
	skill_leveled_up.emit(skill_id, skill.current_level)
	return true

## Забыть навык
func forget_skill(skill_id: String) -> bool:
	if not known_skills.has(skill_id):
		return false
	
	# Снимаем с экипированных слотов
	unequip_skill(skill_id)
	
	known_skills.erase(skill_id)
	return true

## Экипировать активный навык
func equip_active_skill(skill_id: String, slot: int) -> bool:
	if slot < 0 or slot >= 5:
		return false
	
	if not known_skills.has(skill_id):
		return false
	
	var skill = known_skills[skill_id]
	if skill.skill_type != SkillType.ACTIVE:
		return false
	
	# Снимаем навык с других слотов
	unequip_skill(skill_id)
	
	# Если в слоте уже есть навык, снимаем его
	if active_skills[slot] != "":
		var old_skill_id = active_skills[slot]
	
	active_skills[slot] = skill_id
	skill_equipped.emit(skill_id, slot)
	return true

## Экипировать пассивный навык
func equip_passive_skill(skill_id: String, slot: int) -> bool:
	if slot < 0 or slot >= 3:
		return false
	
	if not known_skills.has(skill_id):
		return false
	
	var skill = known_skills[skill_id]
	if skill.skill_type != SkillType.PASSIVE:
		return false
	
	unequip_skill(skill_id)
	
	if passive_skills[slot] != "":
		var old_skill_id = passive_skills[slot]
	
	passive_skills[slot] = skill_id
	skill_equipped.emit(skill_id, slot)
	return true

## Снять навык со слотов
func unequip_skill(skill_id: String) -> void:
	for i in range(active_skills.size()):
		if active_skills[i] == skill_id:
			active_skills[i] = ""
			skill_unequipped.emit(skill_id)
	
	for i in range(passive_skills.size()):
		if passive_skills[i] == skill_id:
			passive_skills[i] = ""
			skill_unequipped.emit(skill_id)

## Получить изученные навыки
func get_known_skills() -> Dictionary:
	return known_skills.duplicate()

## Получить навык по ID
func get_skill(skill_id: String) -> SkillData:
	return known_skills.get(skill_id, null)

## Добавить очко навыка
func add_skill_point() -> void:
	skill_points += 1

## Получить количество очков навыков
func get_skill_points() -> int:
	return skill_points

## Получить экипированные активные навыки
func get_equipped_active_skills() -> Array[String]:
	return active_skills.duplicate()

## Получить экипированные пассивные навыки
func get_equipped_passive_skills() -> Array[String]:
	return passive_skills.duplicate()
