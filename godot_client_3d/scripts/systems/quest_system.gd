extends Node
class_name QuestSystem

## Система квестов Isleborn Online
## Поддержка различных типов квестов: убить, собрать, доставить, исследовать

enum QuestType {
	KILL,           # Убить монстров
	GATHER,         # Собрать ресурсы
	DELIVER,        # Доставить предмет
	EXPLORE,        # Исследовать локацию
	CRAFT,          # Создать предмет
	ESCORT,         # Сопроводить NPC
	DEFEND          # Защитить объект
}

enum QuestStatus {
	NOT_ACCEPTED,   # Не принят
	IN_PROGRESS,    # В процессе
	COMPLETED,      # Выполнен
	FAILED          # Провален
}

## Данные квеста
class QuestData:
	var id: String
	var name: String
	var description: String
	var quest_type: QuestType
	var status: QuestStatus = QuestStatus.NOT_ACCEPTED
	
	# Цели квеста
	var objectives: Array[Dictionary] = []
	var current_objective_index: int = 0
	
	# Награды
	var experience_reward: float = 0.0
	var item_rewards: Array[Dictionary] = []
	var currency_reward: Dictionary = {}
	
	# Требования
	var level_requirement: int = 1
	var prerequisite_quests: Array[String] = []
	
	# Временные ограничения (опционально)
	var time_limit: float = 0.0  # 0 = без ограничения
	var start_time: float = 0.0
	
	func is_completed() -> bool:
		return status == QuestStatus.COMPLETED
	
	func get_current_objective() -> Dictionary:
		if current_objective_index < objectives.size():
			return objectives[current_objective_index]
		return {}
	
	func update_progress(objective_data: Dictionary) -> void:
		if current_objective_index >= objectives.size():
			return
		
		var current = objectives[current_objective_index]
		var current_progress = current.get("current", 0)
		var required = current.get("required", 0)
		
		match quest_type:
			QuestType.KILL:
				current_progress += objective_data.get("killed", 0)
			QuestType.GATHER:
				current_progress += objective_data.get("gathered", 0)
			QuestType.CRAFT:
				current_progress += objective_data.get("crafted", 0)
		
		current["current"] = min(current_progress, required)
		
		# Проверяем, выполнена ли текущая цель
		if current_progress >= required:
			current["completed"] = true
			# Переходим к следующей цели
			if current_objective_index < objectives.size() - 1:
				current_objective_index += 1
			else:
				# Все цели выполнены
				status = QuestStatus.COMPLETED

var available_quests: Dictionary = {}  # quest_id -> QuestData
var active_quests: Dictionary = {}     # quest_id -> QuestData
var completed_quests: Array[String] = []

signal quest_accepted(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)
signal quest_progress_updated(quest_id: String, objective: Dictionary)

func _ready() -> void:
	_register_initial_quests()

## Регистрация начальных квестов
func _register_initial_quests() -> void:
	# Квест для новичков: собрать ресурсы
	var quest1 = QuestData.new()
	quest1.id = "first_steps"
	quest1.name = "Первые шаги"
	quest1.description = "Собери 10 пальмовой древесины для начала"
	quest1.quest_type = QuestType.GATHER
	quest1.level_requirement = 1
	quest1.objectives = [
		{
			"type": "gather",
			"item_id": "palm_wood",
			"required": 10,
			"current": 0,
			"completed": false
		}
	]
	quest1.experience_reward = 100.0
	quest1.item_rewards = [{"item_id": "stone_knife", "quantity": 1}]
	available_quests["first_steps"] = quest1
	
	# Квест: убить монстров
	var quest2 = QuestData.new()
	quest2.id = "monster_hunter"
	quest2.name = "Охотник на монстров"
	quest2.description = "Убей 5 рифовых угрей"
	quest2.quest_type = QuestType.KILL
	quest2.level_requirement = 3
	quest2.prerequisite_quests = ["first_steps"]
	quest2.objectives = [
		{
			"type": "kill",
			"monster_id": "reef_eel",
			"required": 5,
			"current": 0,
			"completed": false
		}
	]
	quest2.experience_reward = 250.0
	quest2.item_rewards = [{"item_id": "wooden_sword", "quantity": 1}]
	available_quests["monster_hunter"] = quest2

## Принять квест
func accept_quest(quest_id: String) -> bool:
	if not available_quests.has(quest_id):
		return false
	
	var quest = available_quests[quest_id]
	
	# Проверяем требования
	if not _can_accept_quest(quest):
		return false
	
	# Перемещаем в активные
	quest.status = QuestStatus.IN_PROGRESS
	quest.start_time = Time.get_ticks_msec() / 1000.0
	active_quests[quest_id] = quest
	available_quests.erase(quest_id)
	
	quest_accepted.emit(quest_id)
	return true

## Проверить, можно ли принять квест
func _can_accept_quest(quest: QuestData) -> bool:
	# Проверяем уровень
	var character_progression = get_tree().get_first_node_in_group("character_progression")
	if character_progression:
		if character_progression.current_level < quest.level_requirement:
			return false
	
	# Проверяем предварительные квесты
	for prereq_id in quest.prerequisite_quests:
		if prereq_id not in completed_quests:
			return false
	
	return true

## Обновить прогресс квеста
func update_quest_progress(quest_id: String, objective_data: Dictionary) -> void:
	if not active_quests.has(quest_id):
		return
	
	var quest = active_quests[quest_id]
	if quest.status != QuestStatus.IN_PROGRESS:
		return
	
	quest.update_progress(objective_data)
	
	var current_objective = quest.get_current_objective()
	quest_progress_updated.emit(quest_id, current_objective)
	
	# Проверяем, выполнен ли квест
	if quest.is_completed():
		complete_quest(quest_id)

## Завершить квест
func complete_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	
	var quest = active_quests[quest_id]
	quest.status = QuestStatus.COMPLETED
	
	# Выдаём награды
	_give_quest_rewards(quest)
	
	completed_quests.append(quest_id)
	active_quests.erase(quest_id)
	
	quest_completed.emit(quest_id)

## Выдать награды за квест
func _give_quest_rewards(quest: QuestData) -> void:
	# Опыт
	var character_progression = get_tree().get_first_node_in_group("character_progression")
	if character_progression and quest.experience_reward > 0:
		character_progression.add_experience(quest.experience_reward)
	
	# Предметы
	var inventory = get_tree().get_first_node_in_group("inventory")
	if inventory and inventory.has_method("add_item"):
		for reward in quest.item_rewards:
			var item_id = reward.get("item_id", "")
			var quantity = reward.get("quantity", 1)
			inventory.add_item(item_id, quantity)

## Получить доступные квесты
func get_available_quests() -> Dictionary:
	return available_quests.duplicate()

## Получить активные квесты
func get_active_quests() -> Dictionary:
	return active_quests.duplicate()

## Получить квест по ID
func get_quest(quest_id: String) -> QuestData:
	if available_quests.has(quest_id):
		return available_quests[quest_id]
	if active_quests.has(quest_id):
		return active_quests[quest_id]
	return null

## Генерировать квесты для уровня игрока
func generate_quests_for_level(player_level: int, count: int = 3) -> void:
	var generated_quests = QuestGenerator.generate_quests_for_level(player_level, count)
	for quest in generated_quests:
		available_quests[quest.id] = quest

## Обновить доступные квесты на основе уровня игрока
func update_available_quests_by_level(player_level: int) -> void:
	# Генерируем новые квесты для текущего уровня
	generate_quests_for_level(player_level, 3)
	
	# Удаляем квесты, которые стали слишком лёгкими
	var to_remove: Array[String] = []
	for quest_id in available_quests.keys():
		var quest = available_quests[quest_id]
		if quest.level_requirement < player_level - 5:
			to_remove.append(quest_id)
	
	for quest_id in to_remove:
		available_quests.erase(quest_id)

