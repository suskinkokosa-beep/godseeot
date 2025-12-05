extends Node
class_name WorldEventsSystem

## Система мировых событий Isleborn Online
## Глобальные события, затрагивающие весь сервер

enum EventType {
	KRAKEN_INVASION,      # Нашествие Кракенов
	LEVIATHAN_STORM,      # Бури Левиафана
	SIREN_ATTACK,         # Сирены-душегубки
	ICE_STORM,            # Ледяной шторм
	AI_GUILD_UPRISING,    # Восстание AI-гильдий
	VOID_PORTAL,          # Открытие порталов бездны
	SEASONAL_EVENT        # Сезонное событие
}

enum EventStatus {
	ANNOUNCED,           # Объявлено (предупреждение)
	ACTIVE,              # Активно
	FADING,              # Затухает
	COMPLETED            # Завершено
}

## Данные события
class WorldEventData:
	var id: String
	var event_type: EventType
	var status: EventStatus = EventStatus.ANNOUNCED
	
	var name: String
	var description: String
	
	var location: Dictionary = {}  # {"x": float, "y": float, "radius": float}
	var started_at: int = 0
	var duration_minutes: int = 30
	var ends_at: int = 0
	
	var participants: Array[String] = []  # ID игроков
	var progress: Dictionary = {}  # Прогресс события
	var rewards: Dictionary = {}  # Общие награды
	
	var effects: Dictionary = {}  # Эффекты на мир
	var requirements: Dictionary = {}  # Требования для участия
	
	func is_active() -> bool:
		return status == EventStatus.ACTIVE
	
	func get_remaining_time_seconds() -> int:
		if ends_at <= 0:
			return 0
		var now = Time.get_unix_time_from_system()
		return max(0, ends_at - now)

var active_events: Dictionary = {}  # event_id -> WorldEventData
var event_history: Array[WorldEventData] = []

signal event_announced(event_id: String, event: WorldEventData)
signal event_started(event_id: String, event: WorldEventData)
signal event_completed(event_id: String, event: WorldEventData)
signal event_progress_updated(event_id: String, progress: Dictionary)

func _ready() -> void:
	pass

## Создать новое мировое событие
func create_event(event_type: EventType, location: Dictionary, duration_minutes: int = 30) -> WorldEventData:
	var event = WorldEventData.new()
	event.id = "event_%d_%d" % [Time.get_unix_time_from_system(), randi() % 10000]
	event.event_type = event_type
	event.location = location
	event.duration_minutes = duration_minutes
	
	_setup_event_data(event)
	
	active_events[event.id] = event
	event_announced.emit(event.id, event)
	
	# Запускаем событие через 60 секунд после объявления
	await get_tree().create_timer(60.0).timeout
	start_event(event.id)
	
	return event

## Настроить данные события в зависимости от типа
func _setup_event_data(event: WorldEventData) -> void:
	match event.event_type:
		EventType.KRAKEN_INVASION:
			event.name = "Нашествие Кракенов"
			event.description = "Гигантские Кракены вышли на охоту. Огромная тень размером с биом появилась в океане."
			event.effects = {
				"spawn_elite_monsters": true,
				"rare_resources": true,
				"danger_level": 5
			}
			event.rewards = {
				"experience_multiplier": 2.0,
				"rare_loot_chance": 0.3,
				"kraken_parts": true
			}
		
		EventType.LEVIATHAN_STORM:
			event.name = "Бури Левиафана"
			event.description = "Гигантская тень размером с биом появилась в океане. Элитные монстры и редкие ресурсы появляются повсюду."
			event.effects = {
				"weather_change": "STORM",
				"elite_monster_spawn": 0.5,
				"rare_resources": true
			}
			event.rewards = {
				"experience": 500.0,
				"rare_items": true
			}
		
		EventType.SIREN_ATTACK:
			event.name = "Сирены-душегубки"
			event.description = "Ночью в тумане Сирены атакуют любые корабли. Остерегайтесь их песен!"
			event.effects = {
				"fog": true,
				"night_only": true,
				"siren_spawn": true,
				"ship_attacks": true
			}
			event.rewards = {
				"siren_loot": true,
				"reputation": {"faction": "sea_guard", "amount": 20}
			}
		
		EventType.ICE_STORM:
			event.name = "Ледяной шторм"
			event.description = "Морозная буря обрушилась на океан. Ледяные монстры появляются из глубин."
			event.effects = {
				"weather_change": "BLIZZARD",
				"ice_monsters": true,
				"movement_slowdown": 0.5
			}
			event.rewards = {
				"ice_resources": true,
				"winter_loot": true
			}
		
		EventType.AI_GUILD_UPRISING:
			event.name = "Восстание AI-гильдий"
			event.description = "AI-гильдии объединились и начали нападения на игроков. Защищайте свои острова!"
			event.effects = {
				"ai_attacks": true,
				"island_raids": true,
				"guild_wars": true
			}
			event.rewards = {
				"guild_reputation": true,
				"unique_items": true
			}
		
		EventType.VOID_PORTAL:
			event.name = "Открытие порталов бездны"
			event.description = "Разломы в пространстве открылись в океане. Blackwater-монстры выходят на поверхность."
			event.effects = {
				"blackwater_monsters": true,
				"void_zones": true,
				"extreme_danger": true
			}
			event.rewards = {
				"blackwater_resources": true,
				"legendary_loot": true,
				"experience": 1000.0
			}
		
		EventType.SEASONAL_EVENT:
			event.name = "Сезонное событие"
			event.description = "Особое событие, происходящее только в определённый сезон."
			event.effects = {
				"seasonal_bonuses": true
			}
			event.rewards = {
				"seasonal_items": true,
				"exclusive_cosmetics": true
			}

## Начать событие
func start_event(event_id: String) -> bool:
	if not active_events.has(event_id):
		return false
	
	var event = active_events[event_id]
	event.status = EventStatus.ACTIVE
	event.started_at = Time.get_unix_time_from_system()
	event.ends_at = event.started_at + (event.duration_minutes * 60)
	
	# Применяем эффекты события
	_apply_event_effects(event)
	
	event_started.emit(event_id, event)
	return true

## Применить эффекты события
func _apply_event_effects(event: WorldEventData) -> void:
	# Изменение погоды
	if event.effects.has("weather_change"):
		var weather_system = get_tree().get_first_node_in_group("weather_system")
		if weather_system:
			var weather_type = event.effects["weather_change"]
			# TODO: Изменить погоду
	
	# Спавн монстров
	if event.effects.has("elite_monster_spawn") or event.effects.has("spawn_elite_monsters"):
		# TODO: Заспавнить элитных монстров
		pass
	
	# Другие эффекты
	if event.effects.has("fog"):
		# TODO: Включить туман
		pass

## Обновить прогресс события
func update_event_progress(event_id: String, contribution: Dictionary) -> void:
	if not active_events.has(event_id):
		return
	
	var event = active_events[event_id]
	if not event.is_active():
		return
	
	# Обновляем прогресс
	for key in contribution.keys():
		if not event.progress.has(key):
			event.progress[key] = 0
		event.progress[key] += contribution[key]
	
	event_progress_updated.emit(event_id, event.progress)
	
	# Проверяем завершение
	_check_event_completion(event_id)

## Проверить завершение события
func _check_event_completion(event_id: String) -> void:
	if not active_events.has(event_id):
		return
	
	var event = active_events[event_id]
	if not event.is_active():
		return
	
	# Проверяем условия завершения
	var completed = false
	match event.event_type:
		EventType.KRAKEN_INVASION:
			# Завершается при убийстве всех Кракенов
			if event.progress.get("krakens_killed", 0) >= event.progress.get("krakens_total", 5):
				completed = true
		
		EventType.LEVIATHAN_STORM:
			# Завершается по истечении времени
			var now = Time.get_unix_time_from_system()
			if now >= event.ends_at:
				completed = true
		
		_:
			# По умолчанию завершается по времени
			var now = Time.get_unix_time_from_system()
			if now >= event.ends_at:
				completed = true
	
	if completed:
		_complete_event(event_id)

## Завершить событие
func _complete_event(event_id: String) -> void:
	if not active_events.has(event_id):
		return
	
	var event = active_events[event_id]
	event.status = EventStatus.COMPLETED
	
	# Выдаём награды участникам
	_give_event_rewards(event)
	
	# Убираем эффекты
	_remove_event_effects(event)
	
	event_completed.emit(event_id, event)
	
	# Перемещаем в историю
	event_history.append(event)
	active_events.erase(event_id)

## Выдать награды за событие
func _give_event_rewards(event: WorldEventData) -> void:
	# Выдаём награды всем участникам
	for participant_id in event.participants:
		# TODO: Выдать награды игроку
		pass

## Убрать эффекты события
func _remove_event_effects(event: WorldEventData) -> void:
	# TODO: Убрать эффекты (погода, монстры и т.д.)
	pass

## Получить активные события
func get_active_events() -> Array[WorldEventData]:
	var result: Array[WorldEventData] = []
	for event_id in active_events.keys():
		result.append(active_events[event_id])
	return result

## Получить событие в радиусе
func get_event_in_range(position: Vector3, range: float) -> WorldEventData:
	for event_id in active_events.keys():
		var event = active_events[event_id]
		if not event.is_active():
			continue
		
		var event_pos = Vector3(event.location.get("x", 0), 0, event.location.get("y", 0))
		var distance = position.distance_to(event_pos)
		var event_radius = event.location.get("radius", 0)
		
		if distance <= (event_radius + range):
			return event
	
	return null

## Присоединиться к событию
func join_event(event_id: String, player_id: String) -> bool:
	if not active_events.has(event_id):
		return false
	
	var event = active_events[event_id]
	if not event.is_active():
		return false
	
	if not event.participants.has(player_id):
		event.participants.append(player_id)
	
	return true

