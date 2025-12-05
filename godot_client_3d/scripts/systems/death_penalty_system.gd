extends Node
class_name DeathPenaltySystem

## Система штрафов за смерть и PvP для Isleborn Online
## Согласно GDD: штрафы за смерть, разные для PvE и PvP

enum DeathType {
	PVE,            # Смерть от монстра/окружения
	PVP,            # Смерть от игрока
	DROWNING,       # Утопление
	ENVIRONMENT     # Окружающая среда (падение, огонь)
}

enum PenaltyType {
	EXPERIENCE_LOSS,    # Потеря опыта
	ITEM_LOSS,          # Потеря предметов
	CURRENCY_LOSS,      # Потеря валюты
	RESPAWN_TIME,       # Время респавна
	DEBUFF,             # Временный дебафф
	RESPAWN_LOCATION    # Место респавна
}

class DeathPenalty:
	var penalty_type: PenaltyType
	var value: float
	var duration: float = 0.0  # Для дебаффов
	var description: String = ""
	
	func _init(_type: PenaltyType, _value: float, _desc: String = ""):
		penalty_type = _type
		value = _value
		description = _desc

class ActiveDebuff:
	var debuff_id: String
	var debuff_type: String
	var duration: float
	var value: float
	var description: String
	
	func _init(_id: String, _type: String, _dur: float, _val: float, _desc: String):
		debuff_id = _id
		debuff_type = _type
		duration = _dur
		value = _val
		description = _desc

var active_debuffs: Dictionary = {}  # debuff_id -> ActiveDebuff
var death_count: int = 0  # Количество смертей
var last_death_time: int = 0
var respawn_location: Vector3 = Vector3.ZERO

signal player_died(death_type: DeathType, penalties: Array[DeathPenalty])
signal penalty_applied(penalty_type: PenaltyType, value: float)
signal debuff_applied(debuff: ActiveDebuff)
signal debuff_expired(debuff_id: String)
signal respawn_ready

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	_update_debuffs(delta)

func handle_player_death(death_type: DeathType, death_position: Vector3 = Vector3.ZERO, killer_id: String = "") -> void:
	death_count += 1
	last_death_time = Time.get_unix_time_from_system()
	
	var penalties = _calculate_penalties(death_type, death_position, killer_id)
	
	# Применяем штрафы
	for penalty in penalties:
		_apply_penalty(penalty)
	
	player_died.emit(death_type, penalties)
	
	# Устанавливаем место респавна
	_set_respawn_location(death_position)

func _calculate_penalties(death_type: DeathType, death_position: Vector3, killer_id: String) -> Array[DeathPenalty]:
	var penalties: Array[DeathPenalty] = []
	
	match death_type:
		DeathType.PVE:
			# Смерть от PvE: потеря опыта, возможна потеря предметов
			var exp_loss_percent = 0.05  # 5% опыта
			penalties.append(DeathPenalty.new(PenaltyType.EXPERIENCE_LOSS, exp_loss_percent, "Потеря 5% опыта"))
			
			# Шанс потерять предмет (низкий)
			if randf() < 0.1:  # 10% шанс
				penalties.append(DeathPenalty.new(PenaltyType.ITEM_LOSS, 1.0, "Потеря случайного предмета"))
			
			# Временный дебафф слабости
			penalties.append(DeathPenalty.new(PenaltyType.DEBUFF, 0.1, "Слабость: -10% к урону на 5 минут"))
			penalties.append(DeathPenalty.new(PenaltyType.RESPAWN_TIME, 10.0, "Время респавна: 10 секунд"))
		
		DeathType.PVP:
			# Смерть от PvP: более суровые штрафы
			var exp_loss_percent = 0.10  # 10% опыта
			penalties.append(DeathPenalty.new(PenaltyType.EXPERIENCE_LOSS, exp_loss_percent, "Потеря 10% опыта"))
			
			# Потеря валюты
			var currency_loss_percent = 0.05  # 5% валюты
			penalties.append(DeathPenalty.new(PenaltyType.CURRENCY_LOSS, currency_loss_percent, "Потеря 5% валюты"))
			
			# Высокий шанс потерять предмет
			if randf() < 0.3:  # 30% шанс
				penalties.append(DeathPenalty.new(PenaltyType.ITEM_LOSS, 1.0, "Потеря случайного предмета"))
			
			# Более сильный дебафф
			penalties.append(DeathPenalty.new(PenaltyType.DEBUFF, 0.2, "Травма: -20% к характеристикам на 10 минут"))
			penalties.append(DeathPenalty.new(PenaltyType.RESPAWN_TIME, 30.0, "Время респавна: 30 секунд"))
		
		DeathType.DROWNING:
			# Утопление: средние штрафы
			var exp_loss_percent = 0.03  # 3% опыта
			penalties.append(DeathPenalty.new(PenaltyType.EXPERIENCE_LOSS, exp_loss_percent, "Потеря 3% опыта"))
			
			penalties.append(DeathPenalty.new(PenaltyType.DEBUFF, 0.05, "Последствия утопления: -5% к выносливости на 3 минуты"))
			penalties.append(DeathPenalty.new(PenaltyType.RESPAWN_TIME, 5.0, "Время респавна: 5 секунд"))
		
		DeathType.ENVIRONMENT:
			# Окружающая среда: минимальные штрафы
			var exp_loss_percent = 0.02  # 2% опыта
			penalties.append(DeathPenalty.new(PenaltyType.EXPERIENCE_LOSS, exp_loss_percent, "Потеря 2% опыта"))
			
			penalties.append(DeathPenalty.new(PenaltyType.RESPAWN_TIME, 5.0, "Время респавна: 5 секунд"))
	
	# Если смертей много подряд - увеличиваем штрафы
	if death_count > 3:
		var multiplier = 1.0 + (death_count - 3) * 0.1
		for penalty in penalties:
			if penalty.penalty_type == PenaltyType.EXPERIENCE_LOSS:
				penalty.value *= multiplier
	
	return penalties

func _apply_penalty(penalty: DeathPenalty) -> void:
	match penalty.penalty_type:
		PenaltyType.EXPERIENCE_LOSS:
			_apply_experience_loss(penalty.value)
		
		PenaltyType.ITEM_LOSS:
			_apply_item_loss(int(penalty.value))
		
		PenaltyType.CURRENCY_LOSS:
			_apply_currency_loss(penalty.value)
		
		PenaltyType.DEBUFF:
			_apply_debuff(penalty)
		
		PenaltyType.RESPAWN_TIME:
			_apply_respawn_time(penalty.value)
	
	penalty_applied.emit(penalty.penalty_type, penalty.value)

func _apply_experience_loss(percent: float) -> void:
	# TODO: Интегрировать с CharacterProgression
	var world = get_tree().current_scene
	if world:
		var progression = world.find_child("CharacterProgression", true, false)
		if progression:
			var current_exp = progression.current_experience
			var loss = current_exp * percent
			progression.current_experience = max(0.0, current_exp - loss)
			print("Lost %.0f experience (%.1f%%)" % [loss, percent * 100.0])

func _apply_item_loss(quantity: int) -> void:
	# TODO: Интегрировать с InventorySystem
	var world = get_tree().current_scene
	if world:
		var inventory = world.find_child("Inventory", true, false)
		if inventory:
			# Выбираем случайный предмет для потери
			var items = inventory.get_all_items()
			if items.size() > 0:
				var random_item = items.keys()[randi() % items.size()]
				inventory.remove_item(random_item, 1)
				print("Lost item: %s" % random_item)

func _apply_currency_loss(percent: float) -> void:
	# TODO: Интегрировать с CurrencySystem
	var world = get_tree().current_scene
	if world:
		var currency_system = world.find_child("CurrencySystem", true, false)
		if currency_system:
			# Потеря базовой валюты
			var shells = currency_system.get_currency_amount(CurrencySystem.CurrencyType.SHELLS)
			var loss = shells * percent
			currency_system.spend_currency(CurrencySystem.CurrencyType.SHELLS, int(loss))
			print("Lost %.0f shells (%.1f%%)" % [loss, percent * 100.0])

func _apply_debuff(penalty: DeathPenalty) -> void:
	var debuff_id = "death_debuff_%d" % Time.get_ticks_msec()
	var duration = 300.0  # 5 минут по умолчанию
	
	# Определяем тип дебаффа в зависимости от значения
	var debuff_type = "weakness"
	if penalty.value >= 0.2:
		debuff_type = "severe_injury"
	elif penalty.value >= 0.1:
		debuff_type = "injury"
	
	var debuff = ActiveDebuff.new(debuff_id, debuff_type, duration, penalty.value, penalty.description)
	active_debuffs[debuff_id] = debuff
	debuff_applied.emit(debuff)

func _apply_respawn_time(seconds: float) -> void:
	# TODO: Показать таймер респавна в UI
	await get_tree().create_timer(seconds).timeout
	respawn_ready.emit()

func _update_debuffs(delta: float) -> void:
	var expired: Array[String] = []
	
	for debuff_id in active_debuffs.keys():
		var debuff = active_debuffs[debuff_id]
		debuff.duration -= delta
		
		if debuff.duration <= 0.0:
			expired.append(debuff_id)
	
	for debuff_id in expired:
		active_debuffs.erase(debuff_id)
		debuff_expired.emit(debuff_id)

func _set_respawn_location(death_position: Vector3) -> void:
	# Респавн происходит на острове игрока или в ближайшем безопасном месте
	# TODO: Интегрировать с IslandProgression для определения позиции респавна
	respawn_location = Vector3(0, 0, 0)  # По умолчанию - центр острова

func get_respawn_location() -> Vector3:
	return respawn_location

func get_active_debuffs() -> Array[ActiveDebuff]:
	var result: Array[ActiveDebuff] = []
	for debuff in active_debuffs.values():
		result.append(debuff)
	return result

func get_debuff_multiplier(stat_name: String) -> float:
	var multiplier = 1.0
	
	for debuff in active_debuffs.values():
		match debuff.debuff_type:
			"weakness":
				if stat_name in ["strength", "damage"]:
					multiplier *= (1.0 - debuff.value)
			"injury", "severe_injury":
				multiplier *= (1.0 - debuff.value)
			"exhaustion":
				if stat_name in ["stamina", "speed"]:
					multiplier *= (1.0 - debuff.value)
	
	return multiplier

func reset_death_count() -> void:
	# Сбрасываем счётчик смертей (например, после успешного восстановления)
	death_count = 0

## Получить информацию о штрафах
func get_penalty_info(death_type: DeathType) -> Dictionary:
	var penalties = _calculate_penalties(death_type, Vector3.ZERO, "")
	var info: Dictionary = {
		"type": death_type,
		"penalties": [],
		"total_exp_loss": 0.0,
		"respawn_time": 10.0
	}
	
	for penalty in penalties:
		info["penalties"].append({
			"type": penalty.penalty_type,
			"value": penalty.value,
			"description": penalty.description
		})
		
		if penalty.penalty_type == PenaltyType.EXPERIENCE_LOSS:
			info["total_exp_loss"] += penalty.value
		if penalty.penalty_type == PenaltyType.RESPAWN_TIME:
			info["respawn_time"] = penalty.value
	
	return info

