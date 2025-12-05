extends Node
class_name ExpeditionSystem

## Система экспедиций Isleborn Online
## Игроки могут отправлять NPC, корабли и флоты в экспедиции

enum ExpeditionType {
	GATHER_RESOURCES,    # Собрать ресурсы
	EXPLORE_BIOME,       # Исследовать биом
	HUNT_MONSTERS,       # Охота на монстров
	FIND_TREASURE,       # Поиск затонувших сокровищ
	TRADE_ROUTE,         # Торговый маршрут
	BLACKWATER_RIFT      # Исследование Blackwater разлома
}

enum ExpeditionStatus {
	PREPARING,          # Подготовка
	IN_PROGRESS,        # В пути
	COMPLETED,          # Завершена
	FAILED,             # Провалена
	CANCELLED           # Отменена
}

## Данные экспедиции
class ExpeditionData:
	var id: String
	var expedition_type: ExpeditionType
	var status: ExpeditionStatus = ExpeditionStatus.PREPARING
	
	var owner_id: String
	var participants: Array[String] = []  # NPC или игроки
	var ships: Array[String] = []  # ID кораблей
	
	var destination: Dictionary = {}  # {"x": float, "y": float, "biome": String}
	var duration_hours: float = 1.0  # Реальное время в часах
	
	var started_at: int = 0
	var ends_at: int = 0
	
	var requirements: Dictionary = {}  # Требования для участия
	var rewards: Dictionary = {}  # Награды при успехе
	var risks: Dictionary = {}  # Риски и возможные потери
	
	var progress: float = 0.0  # Прогресс 0-100%
	var current_location: Dictionary = {}  # Текущая позиция
	
	func is_active() -> bool:
		return status == ExpeditionStatus.IN_PROGRESS
	
	func get_remaining_time_seconds() -> int:
		if ends_at <= 0:
			return 0
		var now = Time.get_unix_time_from_system()
		return max(0, ends_at - now)
	
	func get_progress_percent() -> float:
		return progress

var expeditions: Dictionary = {}  # expedition_id -> ExpeditionData
var expedition_timer: Timer = null

signal expedition_started(expedition_id: String, expedition: ExpeditionData)
signal expedition_completed(expedition_id: String, rewards: Dictionary)
signal expedition_failed(expedition_id: String, reason: String)
signal expedition_progress_updated(expedition_id: String, progress: float)

func _ready() -> void:
	expedition_timer = Timer.new()
	expedition_timer.wait_time = 60.0  # Проверка каждую минуту
	expedition_timer.timeout.connect(_update_expeditions)
	expedition_timer.autostart = true
	add_child(expedition_timer)

## Создать новую экспедицию
func create_expedition(owner_id: String, expedition_type: ExpeditionType, destination: Dictionary, duration_hours: float = 1.0) -> ExpeditionData:
	var expedition = ExpeditionData.new()
	expedition.id = "expedition_%d_%d" % [Time.get_unix_time_from_system(), randi() % 10000]
	expedition.owner_id = owner_id
	expedition.expedition_type = expedition_type
	expedition.destination = destination
	expedition.duration_hours = duration_hours
	
	_setup_expedition_data(expedition)
	
	expeditions[expedition.id] = expedition
	return expedition

## Настроить данные экспедиции в зависимости от типа
func _setup_expedition_data(expedition: ExpeditionData) -> void:
	match expedition.expedition_type:
		ExpeditionType.GATHER_RESOURCES:
			expedition.requirements = {
				"ship_capacity": 10,
				"crew_size": 2
			}
			expedition.rewards = {
				"resources": {
					"palm_wood": {"min": 20, "max": 50},
					"stone": {"min": 10, "max": 30}
				},
				"experience": 100.0,
				"currency": {"type": CurrencySystem.CurrencyType.SHELLS, "amount": 50}
			}
			expedition.risks = {
				"monster_attack": 0.2,
				"storm": 0.1,
				"ship_damage": 0.15
			}
		
		ExpeditionType.EXPLORE_BIOME:
			expedition.requirements = {
				"ship_speed": 4.0,
				"crew_size": 1
			}
			expedition.rewards = {
				"experience": 200.0,
				"biome_knowledge": true,
				"currency": {"type": CurrencySystem.CurrencyType.SHELLS, "amount": 100}
			}
			expedition.risks = {
				"monster_encounter": 0.3,
				"getting_lost": 0.1
			}
		
		ExpeditionType.HUNT_MONSTERS:
			expedition.requirements = {
				"ship_weapons": 1,
				"crew_combat": 3
			}
			expedition.rewards = {
				"loot": {
					"monster_parts": {"min": 5, "max": 15},
					"experience": 300.0
				},
				"currency": {"type": CurrencySystem.CurrencyType.SHELLS, "amount": 150}
			}
			expedition.risks = {
				"crew_injury": 0.4,
				"ship_damage": 0.3,
				"failure": 0.2
			}
		
		ExpeditionType.FIND_TREASURE:
			expedition.requirements = {
				"ship_capacity": 15,
				"dive_equipment": true
			}
			expedition.rewards = {
				"treasure": {
					"rare_items": {"min": 1, "max": 3},
					"currency": {"type": CurrencySystem.CurrencyType.GOLD, "amount": 50}
				},
				"experience": 500.0
			}
			expedition.risks = {
				"dangerous_monsters": 0.5,
				"failure": 0.3,
				"crew_loss": 0.1
			}
		
		ExpeditionType.TRADE_ROUTE:
			expedition.requirements = {
				"cargo_space": 20,
				"ship_speed": 5.0
			}
			expedition.rewards = {
				"currency": {"type": CurrencySystem.CurrencyType.SHELLS, "amount": 200},
				"reputation": {"faction": "traders", "amount": 10}
			}
			expedition.risks = {
				"pirate_attack": 0.3,
				"cargo_loss": 0.2,
				"storm": 0.15
			}
		
		ExpeditionType.BLACKWATER_RIFT:
			expedition.requirements = {
				"ship_level": 30,
				"magic_equipment": true,
				"crew_experience": 10
			}
			expedition.rewards = {
				"rare_resources": {
					"black_pearls": {"min": 1, "max": 5},
					"void_crystals": {"min": 2, "max": 8}
				},
				"experience": 1000.0
			}
			expedition.risks = {
				"extreme_danger": 0.7,
				"crew_loss": 0.5,
				"ship_destruction": 0.3
			}

## Добавить участника в экспедицию
func add_participant(expedition_id: String, participant_id: String, is_npc: bool = false) -> bool:
	if not expeditions.has(expedition_id):
		return false
	
	var expedition = expeditions[expedition_id]
	if expedition.status != ExpeditionStatus.PREPARING:
		return false
	
	if not expedition.participants.has(participant_id):
		expedition.participants.append(participant_id)
	
	return true

## Добавить корабль в экспедицию
func add_ship(expedition_id: String, ship_id: String) -> bool:
	if not expeditions.has(expedition_id):
		return false
	
	var expedition = expeditions[expedition_id]
	if expedition.status != ExpeditionStatus.PREPARING:
		return false
	
	if not expedition.ships.has(ship_id):
		expedition.ships.append(ship_id)
	
	return true

## Начать экспедицию
func start_expedition(expedition_id: String) -> bool:
	if not expeditions.has(expedition_id):
		return false
	
	var expedition = expeditions[expedition_id]
	if expedition.status != ExpeditionStatus.PREPARING:
		return false
	
	# Проверяем требования
	if not _check_requirements(expedition):
		return false
	
	# Запускаем экспедицию
	expedition.status = ExpeditionStatus.IN_PROGRESS
	expedition.started_at = Time.get_unix_time_from_system()
	expedition.ends_at = expedition.started_at + int(expedition.duration_hours * 3600)
	expedition.progress = 0.0
	
	expedition_started.emit(expedition_id, expedition)
	return true

## Проверить требования для экспедиции
func _check_requirements(expedition: ExpeditionData) -> bool:
	# TODO: Проверить требования (корабли, NPC, ресурсы)
	return true

## Обновить все активные экспедиции
func _update_expeditions() -> void:
	var now = Time.get_unix_time_from_system()
	
	for expedition_id in expeditions.keys():
		var expedition = expeditions[expedition_id]
		if not expedition.is_active():
			continue
		
		# Обновляем прогресс
		var elapsed = now - expedition.started_at
		var total_time = expedition.ends_at - expedition.started_at
		if total_time > 0:
			expedition.progress = min(100.0, (elapsed / float(total_time)) * 100.0)
		
		expedition_progress_updated.emit(expedition_id, expedition.progress)
		
		# Проверяем завершение
		if now >= expedition.ends_at:
			_complete_expedition(expedition_id)

## Завершить экспедицию
func _complete_expedition(expedition_id: String) -> void:
	if not expeditions.has(expedition_id):
		return
	
	var expedition = expeditions[expedition_id]
	
	# Проверяем риски
	var failed = _check_risks(expedition)
	
	if failed:
		expedition.status = ExpeditionStatus.FAILED
		expedition_failed.emit(expedition_id, "Экспедиция провалилась из-за опасностей")
	else:
		expedition.status = ExpeditionStatus.COMPLETED
		_give_rewards(expedition)
		expedition_completed.emit(expedition_id, expedition.rewards)
	
	# TODO: Вернуть участников и корабли

## Проверить риски экспедиции
func _check_risks(expedition: ExpeditionData) -> bool:
	for risk_name in expedition.risks.keys():
		var risk_chance = expedition.risks[risk_name]
		if randf() < risk_chance:
			# Риск сработал
			match risk_name:
				"failure", "extreme_danger":
					return true  # Экспедиция провалена
				"ship_destruction":
					# Корабль уничтожен
					pass
				"crew_loss":
					# Потеря экипажа
					pass
	
	return false

## Выдать награды за экспедицию
func _give_rewards(expedition: ExpeditionData) -> void:
	var rewards = expedition.rewards
	
	# Опыт
	if rewards.has("experience"):
		var progression = get_tree().get_first_node_in_group("character_progression")
		if progression and progression.has_method("add_experience"):
			progression.add_experience(rewards["experience"])
	
	# Валюта
	if rewards.has("currency"):
		var currency_data = rewards["currency"]
		var currency_system = get_tree().get_first_node_in_group("currency_system")
		if currency_system:
			currency_system.add_currency(currency_data["type"], currency_data["amount"])
	
	# Ресурсы
	if rewards.has("resources"):
		var inventory = get_tree().get_first_node_in_group("inventory")
		if inventory:
			for resource_id in rewards["resources"].keys():
				var range_data = rewards["resources"][resource_id]
				var amount = randi_range(range_data["min"], range_data["max"])
				inventory.add_item(resource_id, amount)
	
	# Репутация
	if rewards.has("reputation"):
		var rep_data = rewards["reputation"]
		# TODO: Добавить репутацию

## Получить экспедицию
func get_expedition(expedition_id: String) -> ExpeditionData:
	return expeditions.get(expedition_id, null)

## Получить все экспедиции игрока
func get_player_expeditions(player_id: String) -> Array[ExpeditionData]:
	var result: Array[ExpeditionData] = []
	for expedition_id in expeditions.keys():
		var expedition = expeditions[expedition_id]
		if expedition.owner_id == player_id:
			result.append(expedition)
	return result

## Отменить экспедицию
func cancel_expedition(expedition_id: String) -> bool:
	if not expeditions.has(expedition_id):
		return false
	
	var expedition = expeditions[expedition_id]
	if expedition.status != ExpeditionStatus.PREPARING:
		return false
	
	expedition.status = ExpeditionStatus.CANCELLED
	expeditions.erase(expedition_id)
	return true

