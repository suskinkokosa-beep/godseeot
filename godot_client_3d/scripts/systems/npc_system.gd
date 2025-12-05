extends Node
class_name NPCSystem

## Система NPC для острова
## Работники, стражники, рыбаки и т.д.

enum NPCType {
	WORKER,      # Рабочий
	GUARD,       # Стражник
	FISHER,      # Рыбак
	SMITH,       # Кузнец
	BUILDER,     # Строитель
	NAVIGATOR    # Навигатор
}

enum NPCState {
	IDLE,        # Ожидание
	WORKING,     # Работа
	PATROL,      # Патрулирование
	FIGHTING,    # Бой
	RESTING      # Отдых
}

## Базовый класс для NPC
class NPCData:
	var id: String
	var name: String
	var npc_type: NPCType
	var level: int = 1
	var experience: float = 0.0
	
	var skills: Dictionary = {}
	var mood: float = 50.0  # 0-100
	var loyalty: float = 50.0  # 0-100
	
	var current_state: NPCState = NPCState.IDLE
	var assignment: String = ""  # ID задания/строения
	var schedule: Dictionary = {}
	
	var health: float = 100.0
	var max_health: float = 100.0
	
	func _init(_id: String, _name: String, _type: NPCType):
		id = _id
		name = _name
		npc_type = _type

var npcs: Dictionary = {}  # id -> NPCData

func _ready() -> void:
	pass

## Создаёт нового NPC
func create_npc(name: String, npc_type: NPCType, level: int = 1) -> NPCData:
	var id = "npc_%s_%d" % [name, Time.get_ticks_msec()]
	var npc = NPCData.new(id, name, npc_type)
	npc.level = level
	npc.max_health = 80.0 + (level * 5.0)
	npc.health = npc.max_health
	
	# Инициализация навыков в зависимости от типа
	_initialize_npc_skills(npc, npc_type)
	
	npcs[id] = npc
	return npc

## Инициализирует навыки NPC
func _initialize_npc_skills(npc: NPCData, npc_type: NPCType) -> void:
	match npc_type:
		NPCType.WORKER:
			npc.skills = {
				"gathering": 5,
				"construction": 3
			}
		NPCType.GUARD:
			npc.skills = {
				"combat": 8,
				"patrol": 6,
				"alertness": 7
			}
		NPCType.FISHER:
			npc.skills = {
				"fishing": 8,
				"boat_handling": 5
			}
		NPCType.SMITH:
			npc.skills = {
				"crafting": 8,
				"metalwork": 7
			}
		NPCType.BUILDER:
			npc.skills = {
				"construction": 8,
				"repair": 6
			}
		NPCType.NAVIGATOR:
			npc.skills = {
				"navigation": 8,
				"exploration": 6
			}

## Назначает задание NPC
func assign_task(npc_id: String, task_id: String, task_type: String) -> bool:
	if not npcs.has(npc_id):
		return false
	
	var npc = npcs[npc_id]
	npc.assignment = task_id
	
	match task_type:
		"gather":
			npc.current_state = NPCState.WORKING
		"patrol":
			npc.current_state = NPCState.PATROL
		"craft":
			npc.current_state = NPCState.WORKING
		_:
			npc.current_state = NPCState.WORKING
	
	return true

## Улучшает навык NPC
func improve_skill(npc_id: String, skill_name: String, amount: float = 1.0) -> void:
	if not npcs.has(npc_id):
		return
	
	var npc = npcs[npc_id]
	if not npc.skills.has(skill_name):
		npc.skills[skill_name] = 0.0
	
	npc.skills[skill_name] += amount
	
	# При достижении определённых порогов NPC получает опыт
	var skill_level = npc.skills[skill_name]
	if int(skill_level) % 5 == 0:
		add_npc_experience(npc_id, 10.0)

## Добавляет опыт NPC
func add_npc_experience(npc_id: String, amount: float) -> void:
	if not npcs.has(npc_id):
		return
	
	var npc = npcs[npc_id]
	npc.experience += amount
	
	# Проверка повышения уровня
	var exp_needed = 50.0 * pow(npc.level, 1.5)
	if npc.experience >= exp_needed:
		npc.level += 1
		npc.max_health += 5.0
		npc.health = npc.max_health
		npc.experience = 0.0

## Изменяет настроение NPC
func change_mood(npc_id: String, amount: float) -> void:
	if not npcs.has(npc_id):
		return
	
	var npc = npcs[npc_id]
	npc.mood = clamp(npc.mood + amount, 0.0, 100.0)
	
	# Низкое настроение снижает эффективность
	if npc.mood < 30.0:
		# NPC работает хуже
		pass

## Изменяет лояльность NPC
func change_loyalty(npc_id: String, amount: float) -> void:
	if not npcs.has(npc_id):
		return
	
	var npc = npcs[npc_id]
	npc.loyalty = clamp(npc.loyalty + amount, 0.0, 100.0)
	
	# Очень низкая лояльность может привести к дезертирству
	if npc.loyalty < 20.0:
		# TODO: Система дезертирства
		pass

## Получить NPC по ID
func get_npc(npc_id: String) -> NPCData:
	return npcs.get(npc_id, null)

## Получить всех NPC определённого типа
func get_npcs_by_type(npc_type: NPCType) -> Array[NPCData]:
	var result: Array[NPCData] = []
	for npc_id in npcs:
		var npc = npcs[npc_id]
		if npc.npc_type == npc_type:
			result.append(npc)
	return result

## Удалить NPC
func remove_npc(npc_id: String) -> void:
	npcs.erase(npc_id)

