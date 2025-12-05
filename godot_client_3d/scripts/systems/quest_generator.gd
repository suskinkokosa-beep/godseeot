extends Node
class_name QuestGenerator

## Генератор квестов Isleborn Online
## Генерирует квесты по уровням и типу сложности

enum QuestDifficulty {
	EASY,        # Лёгкий
	NORMAL,      # Обычный
	HARD,        # Сложный
	EXPERT,      # Экспертный
	MASTER       # Мастерский
}

## Генерирует квесты для уровня игрока
static func generate_quests_for_level(player_level: int, count: int = 3) -> Array[QuestSystem.QuestData]:
	var quests: Array[QuestSystem.QuestData] = []
	
	# Определяем сложность на основе уровня
	var difficulty = _get_difficulty_for_level(player_level)
	
	# Генерируем квесты разных типов
	for i in range(count):
		var quest_type = _get_random_quest_type()
		var quest = _generate_quest(player_level, difficulty, quest_type)
		if quest:
			quests.append(quest)
	
	return quests

## Определяет сложность на основе уровня
static func _get_difficulty_for_level(level: int) -> QuestDifficulty:
	if level <= 5:
		return QuestDifficulty.EASY
	elif level <= 15:
		return QuestDifficulty.NORMAL
	elif level <= 30:
		return QuestDifficulty.HARD
	elif level <= 40:
		return QuestDifficulty.EXPERT
	else:
		return QuestDifficulty.MASTER

## Получить случайный тип квеста
static func _get_random_quest_type() -> QuestSystem.QuestType:
	var types = [
		QuestSystem.QuestType.KILL,
		QuestSystem.QuestType.GATHER,
		QuestSystem.QuestType.DELIVER,
		QuestSystem.QuestType.CRAFT
	]
	return types[randi() % types.size()]

## Генерирует квест
static func _generate_quest(level: int, difficulty: QuestDifficulty, quest_type: QuestSystem.QuestType) -> QuestSystem.QuestData:
	var quest = QuestSystem.QuestData.new()
	quest.id = _generate_quest_id()
	quest.level_requirement = level
	quest.quest_type = quest_type
	
	match quest_type:
		QuestSystem.QuestType.KILL:
			_generate_kill_quest(quest, level, difficulty)
		QuestSystem.QuestType.GATHER:
			_generate_gather_quest(quest, level, difficulty)
		QuestSystem.QuestType.CRAFT:
			_generate_craft_quest(quest, level, difficulty)
		QuestSystem.QuestType.DELIVER:
			_generate_deliver_quest(quest, level, difficulty)
	
	return quest

## Генерирует квест на убийство
static func _generate_kill_quest(quest: QuestSystem.QuestData, level: int, difficulty: QuestDifficulty) -> void:
	# Определяем тир монстров на основе уровня
	var monster_tier = _get_monster_tier_for_level(level)
	var monster_count = _get_monster_count(difficulty)
	
	# Получаем случайного монстра подходящего тира
	var monster_id = _get_random_monster_for_tier(monster_tier)
	
	quest.name = "Охота на монстров"
	quest.description = "Убейте %d монстров" % monster_count
	quest.objectives = [
		{
			"type": "kill",
			"monster_id": monster_id,
			"required": monster_count,
			"current": 0,
			"completed": false
		}
	]
	
	quest.experience_reward = _calculate_experience_reward(level, difficulty)
	quest.item_rewards = _generate_item_rewards(level, difficulty)

## Генерирует квест на сбор
static func _generate_gather_quest(quest: QuestSystem.QuestData, level: int, difficulty: QuestDifficulty) -> void:
	var item_id = _get_random_resource()
	var quantity = _get_resource_quantity(difficulty)
	
	quest.name = "Сбор ресурсов"
	quest.description = "Соберите %d %s" % [quantity, item_id]
	quest.objectives = [
		{
			"type": "gather",
			"item_id": item_id,
			"required": quantity,
			"current": 0,
			"completed": false
		}
	]
	
	quest.experience_reward = _calculate_experience_reward(level, difficulty)
	quest.item_rewards = _generate_item_rewards(level, difficulty)

## Генерирует квест на создание
static func _generate_craft_quest(quest: QuestSystem.QuestData, level: int, difficulty: QuestDifficulty) -> void:
	var item_id = _get_random_craftable_item(level)
	
	quest.name = "Мастерство"
	quest.description = "Создайте %s" % item_id
	quest.objectives = [
		{
			"type": "craft",
			"item_id": item_id,
			"required": 1,
			"current": 0,
			"completed": false
		}
	]
	
	quest.experience_reward = _calculate_experience_reward(level, difficulty)
	quest.item_rewards = _generate_item_rewards(level, difficulty)

## Генерирует квест на доставку
static func _generate_deliver_quest(quest: QuestSystem.QuestData, level: int, difficulty: QuestDifficulty) -> void:
	var item_id = _get_random_item()
	
	quest.name = "Доставка"
	quest.description = "Доставьте %s" % item_id
	quest.objectives = [
		{
			"type": "deliver",
			"item_id": item_id,
			"quantity": 1,
			"required": 1,
			"current": 0,
			"completed": false
		}
	]
	
	quest.experience_reward = _calculate_experience_reward(level, difficulty)
	quest.item_rewards = _generate_item_rewards(level, difficulty)

## Вычисляет награду опытом
static func _calculate_experience_reward(level: int, difficulty: QuestDifficulty) -> float:
	var base_exp = 50.0 * pow(level, 1.5)
	
	match difficulty:
		QuestDifficulty.EASY:
			return base_exp * 0.8
		QuestDifficulty.NORMAL:
			return base_exp
		QuestDifficulty.HARD:
			return base_exp * 1.5
		QuestDifficulty.EXPERT:
			return base_exp * 2.0
		QuestDifficulty.MASTER:
			return base_exp * 3.0
	
	return base_exp

## Генерирует награды предметами
static func _generate_item_rewards(level: int, difficulty: QuestDifficulty) -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	
	# Всегда даём немного валюты (ракушки)
	var shell_reward = _calculate_shell_reward(level, difficulty)
	rewards.append({
		"item_id": "shells",
		"quantity": shell_reward,
		"type": "currency"
	})
	
	# Иногда даём предметы
	if randf() < 0.3:  # 30% шанс
		var item_id = _get_random_item_for_level(level)
		rewards.append({
			"item_id": item_id,
			"quantity": 1,
			"type": "item"
		})
	
	return rewards

## Вспомогательные функции

static func _generate_quest_id() -> String:
	return "quest_%d_%d" % [Time.get_ticks_msec(), randi() % 10000]

static func _get_monster_tier_for_level(level: int) -> int:
	if level <= 10:
		return 1
	elif level <= 20:
		return 2
	elif level <= 30:
		return 3
	elif level <= 40:
		return 4
	else:
		return 5

static func _get_monster_count(difficulty: QuestDifficulty) -> int:
	match difficulty:
		QuestDifficulty.EASY:
			return randi_range(3, 5)
		QuestDifficulty.NORMAL:
			return randi_range(5, 10)
		QuestDifficulty.HARD:
			return randi_range(10, 15)
		QuestDifficulty.EXPERT:
			return randi_range(15, 25)
		QuestDifficulty.MASTER:
			return randi_range(25, 40)
	return 5

static func _get_random_monster_for_tier(tier: int) -> String:
	# TODO: Получать из MonsterDatabase
	return "reef_eel"

static func _get_random_resource() -> String:
	var resources = ["palm_wood", "stone", "rope", "fabric"]
	return resources[randi() % resources.size()]

static func _get_resource_quantity(difficulty: QuestDifficulty) -> int:
	match difficulty:
		QuestDifficulty.EASY:
			return randi_range(10, 20)
		QuestDifficulty.NORMAL:
			return randi_range(20, 40)
		QuestDifficulty.HARD:
			return randi_range(40, 60)
		QuestDifficulty.EXPERT:
			return randi_range(60, 100)
		QuestDifficulty.MASTER:
			return randi_range(100, 200)
	return 20

static func _get_random_craftable_item(level: int) -> String:
	# TODO: Получать из RecipeDatabase
	return "wooden_sword"

static func _get_random_item() -> String:
	# TODO: Получать из ItemDatabase
	return "healing_herb"

static func _get_random_item_for_level(level: int) -> String:
	# TODO: Получать предметы подходящего уровня
	return "wooden_sword"

static func _calculate_shell_reward(level: int, difficulty: QuestDifficulty) -> int:
	var base = level * 10
	
	match difficulty:
		QuestDifficulty.EASY:
			return base
		QuestDifficulty.NORMAL:
			return base * 2
		QuestDifficulty.HARD:
			return base * 3
		QuestDifficulty.EXPERT:
			return base * 5
		QuestDifficulty.MASTER:
			return base * 10
	
	return base

