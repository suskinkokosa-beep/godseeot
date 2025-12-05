extends Node
class_name NPCWorkerSystem

## Расширенная система NPC-работников Isleborn Online
## Управляет назначением заданий, прогрессией и эффективностью

enum TaskType {
	GATHER_RESOURCE,    # Собрать ресурс
	BUILD,              # Строить
	REPAIR,             # Ремонтировать
	CRAFT,              # Крафтить
	FISH,               # Рыбачить
	PATROL,             # Патрулировать
	GUARD,              # Охранять
	FARM                # Ферма
}

## Данные задания
class TaskData:
	var id: String
	var task_type: TaskType
	var target_id: String  # ID ресурса/здания
	var assigned_npc_id: String = ""
	var priority: int = 1  # 1-5, где 5 - наивысший
	var duration: float = 0.0  # Время выполнения
	var progress: float = 0.0
	var requirements: Dictionary = {}
	var rewards: Dictionary = {}
	
	func is_completed() -> bool:
		return progress >= duration
	
	func get_progress_percent() -> float:
		if duration <= 0:
			return 0.0
		return (progress / duration) * 100.0

var tasks: Dictionary = {}  # task_id -> TaskData
var npc_assignments: Dictionary = {}  # npc_id -> task_id

signal task_created(task_id: String, task: TaskData)
signal task_assigned(task_id: String, npc_id: String)
signal task_completed(task_id: String, npc_id: String)
signal task_progress_updated(task_id: String, progress: float)

func _ready() -> void:
	pass

## Создать новое задание
func create_task(task_type: TaskType, target_id: String, priority: int = 1, duration: float = 10.0) -> TaskData:
	var task = TaskData.new()
	task.id = "task_%d_%d" % [Time.get_ticks_msec(), randi() % 10000]
	task.task_type = task_type
	task.target_id = target_id
	task.priority = priority
	task.duration = duration
	
	tasks[task.id] = task
	task_created.emit(task.id, task)
	return task

## Назначить задание NPC
func assign_task_to_npc(task_id: String, npc_id: String) -> bool:
	if not tasks.has(task_id):
		return false
	
	var task = tasks[task_id]
	
	# Проверяем, не назначено ли уже задание этому NPC
	if npc_assignments.has(npc_id):
		var current_task_id = npc_assignments[npc_id]
		if tasks.has(current_task_id):
			# Освобождаем предыдущее задание
			var current_task = tasks[current_task_id]
			current_task.assigned_npc_id = ""
	
	task.assigned_npc_id = npc_id
	npc_assignments[npc_id] = task_id
	task_assigned.emit(task_id, npc_id)
	return true

## Обновить прогресс задания
func update_task_progress(task_id: String, delta: float, npc_efficiency: float = 1.0) -> void:
	if not tasks.has(task_id):
		return
	
	var task = tasks[task_id]
	task.progress += delta * npc_efficiency
	task_progress_updated.emit(task_id, task.progress)
	
	if task.is_completed():
		complete_task(task_id)

## Завершить задание
func complete_task(task_id: String) -> void:
	if not tasks.has(task_id):
		return
	
	var task = tasks[task_id]
	var npc_id = task.assigned_npc_id
	
	# Выдаём награды
	_give_task_rewards(task)
	
	# Освобождаем NPC
	if npc_id != "":
		npc_assignments.erase(npc_id)
	
	task_completed.emit(task_id, npc_id)
	tasks.erase(task_id)

## Выдать награды за задание
func _give_task_rewards(task: TaskData) -> void:
	var rewards = task.rewards
	
	# Добавляем ресурсы в инвентарь острова
	var island_progression = get_tree().get_first_node_in_group("island_progression")
	if island_progression:
		# TODO: Добавить ресурсы в хранилище острова
		pass
	
	# Даём опыт NPC
	if task.assigned_npc_id != "":
		var npc_system = get_tree().get_first_node_in_group("npc_system")
		if npc_system and npc_system.has_method("add_npc_experience"):
			npc_system.add_npc_experience(task.assigned_npc_id, 10.0)

## Получить доступные задания
func get_available_tasks() -> Array[TaskData]:
	var result: Array[TaskData] = []
	for task_id in tasks.keys():
		var task = tasks[task_id]
		if task.assigned_npc_id == "":
			result.append(task)
	return result

## Получить задание NPC
func get_npc_task(npc_id: String) -> TaskData:
	if not npc_assignments.has(npc_id):
		return null
	
	var task_id = npc_assignments[npc_id]
	return tasks.get(task_id, null)

## Получить эффективность NPC для задания
func get_npc_task_efficiency(npc: NPCSystem.NPCData, task: TaskData) -> float:
	var efficiency = 1.0
	
	# Базовая эффективность зависит от уровня
	efficiency *= 1.0 + (npc.level * 0.05)
	
	# Навыки влияют на эффективность
	match task.task_type:
		TaskType.GATHER_RESOURCE:
			var skill = npc.skills.get("gathering", 0)
			efficiency *= 1.0 + (skill * 0.1)
		TaskType.BUILD, TaskType.REPAIR:
			var skill = npc.skills.get("construction", 0)
			efficiency *= 1.0 + (skill * 0.1)
		TaskType.CRAFT:
			var skill = npc.skills.get("crafting", 0)
			efficiency *= 1.0 + (skill * 0.1)
		TaskType.FISH:
			var skill = npc.skills.get("fishing", 0)
			efficiency *= 1.0 + (skill * 0.1)
	
	# Настроение влияет на эффективность
	var mood_multiplier = 0.5 + (npc.mood / 100.0)
	efficiency *= mood_multiplier
	
	return efficiency

