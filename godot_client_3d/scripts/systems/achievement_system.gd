extends Node
class_name AchievementSystem

## Система достижений для Isleborn Online
## Отслеживает прогресс игрока и выдаёт достижения

enum AchievementCategory {
	EXPLORATION,    # Исследование
	COMBAT,         # Бой
	BUILDING,       # Строительство
	RESOURCES,      # Ресурсы
	SOCIAL,         # Социальное
	COLLECTION,     # Коллекционирование
	MASTERY         # Мастерство
}

enum AchievementRarity {
	COMMON,         # Обычное
	RARE,           # Редкое
	EPIC,           # Эпическое
	LEGENDARY       # Легендарное
}

class Achievement:
	var achievement_id: String
	var name: String
	var description: String
	var category: AchievementCategory
	var rarity: AchievementRarity
	var progress: float = 0.0
	var max_progress: float = 100.0
	var unlocked: bool = false
	var unlocked_at: int = 0
	var reward: Dictionary = {}
	var hidden: bool = false
	
	func _init(_id: String, _name: String, _desc: String, _category: AchievementCategory, _rarity: AchievementRarity):
		achievement_id = _id
		name = _name
		description = _desc
		category = _category
		rarity = _rarity

var achievements: Dictionary = {}  # achievement_id -> Achievement
var unlocked_achievements: Array[String] = []
var progress_tracking: Dictionary = {}

signal achievement_unlocked(achievement_id: String, achievement: Achievement)
signal progress_updated(achievement_id: String, progress: float, max_progress: float)

func _ready() -> void:
	_initialize_achievements()

func _initialize_achievements() -> void:
	# Исследование
	_register_achievement("explore_10_biomes", "Первооткрыватель", "Исследуйте 10 биомов", AchievementCategory.EXPLORATION, AchievementRarity.COMMON, 10.0)
	_register_achievement("explore_all_biomes", "Мастер океана", "Исследуйте все биомы", AchievementCategory.EXPLORATION, AchievementRarity.EPIC, 6.0)
	_register_achievement("discover_ruin", "Археолог", "Обнаружьте руины", AchievementCategory.EXPLORATION, AchievementRarity.COMMON, 1.0)
	
	# Бой
	_register_achievement("kill_100_monsters", "Охотник", "Убейте 100 монстров", AchievementCategory.COMBAT, AchievementRarity.COMMON, 100.0)
	_register_achievement("kill_boss", "Покоритель глубин", "Победите босса", AchievementCategory.COMBAT, AchievementRarity.RARE, 1.0)
	_register_achievement("defend_raid", "Защитник", "Отбейте рейд на остров", AchievementCategory.COMBAT, AchievementRarity.RARE, 1.0)
	
	# Строительство
	_register_achievement("build_10_structures", "Строитель", "Постройте 10 построек", AchievementCategory.BUILDING, AchievementRarity.COMMON, 10.0)
	_register_achievement("upgrade_island_10", "Развиватель", "Развийте остров до 10 уровня", AchievementCategory.BUILDING, AchievementRarity.RARE, 10.0)
	
	# Ресурсы
	_register_achievement("gather_1000_resources", "Добытчик", "Соберите 1000 ресурсов", AchievementCategory.RESOURCES, AchievementRarity.COMMON, 1000.0)
	_register_achievement("catch_100_fish", "Рыбак", "Поймайте 100 рыб", AchievementCategory.RESOURCES, AchievementRarity.COMMON, 100.0)
	
	# Социальное
	_register_achievement("join_guild", "Командный игрок", "Вступите в гильдию", AchievementCategory.SOCIAL, AchievementRarity.COMMON, 1.0)
	_register_achievement("trade_100_items", "Торговец", "Продайте 100 предметов", AchievementCategory.SOCIAL, AchievementRarity.RARE, 100.0)
	
	# Коллекционирование
	_register_achievement("collect_all_fish", "Ихтиолог", "Поймайте все виды рыб", AchievementCategory.COLLECTION, AchievementRarity.EPIC, 30.0)
	
	# Мастерство
	_register_achievement("reach_level_50", "Мастер", "Достигните 50 уровня", AchievementCategory.MASTERY, AchievementRarity.EPIC, 50.0)

func _register_achievement(achievement_id: String, name: String, description: String, category: AchievementCategory, rarity: AchievementRarity, max_progress: float) -> void:
	var achievement = Achievement.new(achievement_id, name, description, category, rarity)
	achievement.max_progress = max_progress
	
	# Награды в зависимости от редкости
	achievement.reward = _generate_reward_for_achievement(rarity)
	
	achievements[achievement_id] = achievement

func _generate_reward_for_achievement(rarity: AchievementRarity) -> Dictionary:
	var reward = {
		"experience": 0.0,
		"currency": {},
		"title": ""
	}
	
	match rarity:
		AchievementRarity.COMMON:
			reward["experience"] = 100.0
			reward["currency"] = {"shells": 50}
		AchievementRarity.RARE:
			reward["experience"] = 500.0
			reward["currency"] = {"shells": 200, "gold": 10}
			reward["title"] = "Редкий"
		AchievementRarity.EPIC:
			reward["experience"] = 2000.0
			reward["currency"] = {"shells": 1000, "gold": 50, "pearls": 5}
			reward["title"] = "Эпический"
		AchievementRarity.LEGENDARY:
			reward["experience"] = 10000.0
			reward["currency"] = {"shells": 5000, "gold": 500, "pearls": 50}
			reward["title"] = "Легендарный"
	
	return reward

func update_progress(achievement_id: String, amount: float) -> void:
	if not achievements.has(achievement_id):
		return
	
	var achievement = achievements[achievement_id]
	
	if achievement.unlocked:
		return  # Уже разблокировано
	
	achievement.progress = min(achievement.progress + amount, achievement.max_progress)
	progress_updated.emit(achievement_id, achievement.progress, achievement.max_progress)
	
	# Проверяем, разблокировано ли достижение
	if achievement.progress >= achievement.max_progress:
		unlock_achievement(achievement_id)

func set_progress(achievement_id: String, progress: float) -> void:
	if not achievements.has(achievement_id):
		return
	
	var achievement = achievements[achievement_id]
	
	if achievement.unlocked:
		return
	
	achievement.progress = clamp(progress, 0.0, achievement.max_progress)
	progress_updated.emit(achievement_id, achievement.progress, achievement.max_progress)
	
	if achievement.progress >= achievement.max_progress:
		unlock_achievement(achievement_id)

func unlock_achievement(achievement_id: String) -> void:
	if not achievements.has(achievement_id):
		return
	
	var achievement = achievements[achievement_id]
	
	if achievement.unlocked:
		return
	
	achievement.unlocked = true
	achievement.unlocked_at = Time.get_unix_time_from_system()
	achievement.progress = achievement.max_progress
	
	unlocked_achievements.append(achievement_id)
	
	# Выдаём награды
	_give_achievement_rewards(achievement)
	
	achievement_unlocked.emit(achievement_id, achievement)

func _give_achievement_rewards(achievement: Achievement) -> void:
	var reward = achievement.reward
	
	# Опыт
	if reward.has("experience"):
		var world = get_tree().current_scene
		if world:
			var progression = world.find_child("CharacterProgression", true, false)
			if progression:
				progression.current_experience += reward["experience"]
	
	# Валюта
	if reward.has("currency"):
		var world = get_tree().current_scene
		if world:
			var currency_system = world.find_child("CurrencySystem", true, false)
			if currency_system:
				var currency = reward["currency"]
				for currency_type_str in currency.keys():
					var amount = currency[currency_type_str]
					# TODO: Преобразовать строку в CurrencyType enum

func get_achievement_info(achievement_id: String) -> Dictionary:
	if not achievements.has(achievement_id):
		return {}
	
	var achievement = achievements[achievement_id]
	return {
		"id": achievement.achievement_id,
		"name": achievement.name,
		"description": achievement.description,
		"category": achievement.category,
		"rarity": achievement.rarity,
		"progress": achievement.progress,
		"max_progress": achievement.max_progress,
		"unlocked": achievement.unlocked,
		"unlocked_at": achievement.unlocked_at,
		"reward": achievement.reward,
		"hidden": achievement.hidden
	}

func get_achievements_by_category(category: AchievementCategory) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for achievement_id in achievements.keys():
		var achievement = achievements[achievement_id]
		if achievement.category == category:
			result.append(get_achievement_info(achievement_id))
	
	return result

func get_unlocked_achievements() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for achievement_id in unlocked_achievements:
		if achievements.has(achievement_id):
			result.append(get_achievement_info(achievement_id))
	
	return result

func get_achievement_progress(achievement_id: String) -> float:
	if not achievements.has(achievement_id):
		return 0.0
	
	return achievements[achievement_id].progress

func get_achievement_completion_percentage(achievement_id: String) -> float:
	if not achievements.has(achievement_id):
		return 0.0
	
	var achievement = achievements[achievement_id]
	if achievement.max_progress <= 0.0:
		return 0.0
	
	return (achievement.progress / achievement.max_progress) * 100.0

func get_total_achievements() -> int:
	return achievements.size()

func get_unlocked_count() -> int:
	return unlocked_achievements.size()

func get_completion_percentage() -> float:
	if achievements.is_empty():
		return 0.0
	
	return (float(unlocked_achievements.size()) / float(achievements.size())) * 100.0

