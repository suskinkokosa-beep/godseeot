extends Node
class_name SeasonSystem

## Система сезонов для Isleborn Online
## Согласно GDD: сезоны 30-90 дней, глобальные ивенты, новые острова, перезапуск Blackwater

enum SeasonType {
	SPRING,         # Весна
	SUMMER,         # Лето
	AUTUMN,         # Осень
	WINTER          # Зима
}

class SeasonData:
	var season_id: String
	var season_type: SeasonType
	var name: String
	var start_date: int
	var end_date: int
	var duration_days: int = 60
	var global_event: String = ""  # event_id глобального события
	var bonuses: Dictionary = {}
	var exclusive_content: Array[String] = []  # Уникальный контент сезона
	
	func _init(_id: String, _type: SeasonType, _name: String, _duration: int):
		season_id = _id
		season_type = _type
		name = _name
		duration_days = _duration

var current_season: SeasonData = null
var season_history: Array[SeasonData] = []

signal season_started(season: SeasonData)
signal season_ending(season: SeasonData, days_remaining: int)
signal season_ended(season: SeasonData)
signal seasonal_event_started(event_id: String)

func _ready() -> void:
	_initialize_seasons()

func _process(delta: float) -> void:
	_check_season_progress()

func _initialize_seasons() -> void:
	# Запускаем текущий сезон
	var current_time = Time.get_unix_time_from_system()
	var season_type = _determine_season_from_date(current_time)
	_start_season(season_type)

func _determine_season_from_date(timestamp: int) -> SeasonType:
	# Упрощённое определение сезона (можно улучшить)
	var date_dict = Time.get_datetime_dict_from_unix_time(timestamp)
	var month = date_dict.get("month", 1)
	
	if month in [3, 4, 5]:
		return SeasonType.SPRING
	elif month in [6, 7, 8]:
		return SeasonType.SUMMER
	elif month in [9, 10, 11]:
		return SeasonType.AUTUMN
	else:
		return SeasonType.WINTER

func _start_season(season_type: SeasonType) -> void:
	var season_id = "season_%d" % Time.get_ticks_msec()
	var season_name = _get_season_name(season_type)
	var duration = 60 + randi() % 31  # 60-90 дней
	
	var season = SeasonData.new(season_id, season_type, season_name, duration)
	season.start_date = Time.get_unix_time_from_system()
	season.end_date = season.start_date + (duration * 24 * 3600)
	
	# Устанавливаем бонусы сезона
	season.bonuses = _get_season_bonuses(season_type)
	
	# Устанавливаем уникальный контент
	season.exclusive_content = _get_season_content(season_type)
	
	# Запускаем глобальное событие сезона
	season.global_event = _start_seasonal_event(season_type)
	
	current_season = season
	season_started.emit(season)

func _get_season_name(season_type: SeasonType) -> String:
	match season_type:
		SeasonType.SPRING:
			return "Сезон Пробуждения"
		SeasonType.SUMMER:
			return "Сезон Приливов"
		SeasonType.AUTUMN:
			return "Сезон Штормов"
		SeasonType.WINTER:
			return "Сезон Бездны"
		_:
			return "Неизвестный сезон"

func _get_season_bonuses(season_type: SeasonType) -> Dictionary:
	match season_type:
		SeasonType.SPRING:
			return {
				"resource_gathering": 1.1,  # +10%
				"island_growth": 1.15,      # +15%
				"new_islands": true
			}
		SeasonType.SUMMER:
			return {
				"fishing_bonus": 1.2,       # +20%
				"ship_speed": 1.1,          # +10%
				"exploration": 1.15
			}
		SeasonType.AUTUMN:
			return {
				"combat_experience": 1.2,   # +20%
				"raid_frequency": 1.3,      # +30%
				"storm_events": true
			}
		SeasonType.WINTER:
			return {
				"blackwater_reset": true,
				"legendary_drop": 1.3,      # +30%
				"boss_spawn": 1.5
			}
		_:
			return {}

func _get_season_content(season_type: SeasonType) -> Array[String]:
	match season_type:
		SeasonType.SPRING:
			return ["spring_quests", "new_islands", "growth_items"]
		SeasonType.SUMMER:
			return ["summer_quests", "beach_events", "fishing_tournament"]
		SeasonType.AUTUMN:
			return ["autumn_quests", "storm_season", "raiding_events"]
		SeasonType.WINTER:
			return ["winter_quests", "abyss_portal", "legendary_bosses"]
		_:
			return []

func _start_seasonal_event(season_type: SeasonType) -> String:
	# TODO: Интегрировать с WorldEventsSystem
	var world = get_tree().current_scene
	if world:
		var events_system = world.find_child("WorldEventsSystem", true, false)
		if events_system:
			# Создаём сезонное событие
			match season_type:
				SeasonType.SPRING:
					# Событие пробуждения
					return ""  # TODO
				SeasonType.SUMMER:
					# Событие приливов
					return ""  # TODO
				SeasonType.AUTUMN:
					# Событие штормов
					return ""  # TODO
				SeasonType.WINTER:
					# Событие бездны
					return ""  # TODO
	
	return ""

func _check_season_progress() -> void:
	if not current_season:
		return
	
	var current_time = Time.get_unix_time_from_system()
	var days_remaining = (current_season.end_date - current_time) / (24 * 3600)
	
	# Предупреждение за 7 дней до окончания
	if days_remaining <= 7 and days_remaining > 6:
		season_ending.emit(current_season, days_remaining)
	
	# Сезон закончился
	if current_time >= current_season.end_date:
		_end_current_season()

func _end_current_season() -> void:
	if not current_season:
		return
	
	var old_season = current_season
	
	# Перемещаем в историю
	season_history.append(old_season)
	
	# Выдаём сезонные награды
	_give_season_rewards(old_season)
	
	season_ended.emit(old_season)
	
	# Запускаем следующий сезон
	var next_season_type = _get_next_season(old_season.season_type)
	_start_season(next_season_type)

func _get_next_season(current: SeasonType) -> SeasonType:
	match current:
		SeasonType.SPRING: return SeasonType.SUMMER
		SeasonType.SUMMER: return SeasonType.AUTUMN
		SeasonType.AUTUMN: return SeasonType.WINTER
		SeasonType.WINTER: return SeasonType.SPRING
		_: return SeasonType.SPRING

func _give_season_rewards(season: SeasonData) -> void:
	# TODO: Выдать награды игрокам в зависимости от их прогресса в сезоне
	# Награды за участие в сезонных событиях
	pass

func get_current_season() -> Dictionary:
	if not current_season:
		return {}
	
	var current_time = Time.get_unix_time_from_system()
	var days_remaining = max(0, (current_season.end_date - current_time) / (24 * 3600))
	
	return {
		"id": current_season.season_id,
		"type": current_season.season_type,
		"name": current_season.name,
		"days_remaining": days_remaining,
		"bonuses": current_season.bonuses.duplicate(),
		"exclusive_content": current_season.exclusive_content.duplicate()
	}

func get_season_bonus(bonus_key: String) -> float:
	if not current_season:
		return 1.0
	
	return current_season.bonuses.get(bonus_key, 1.0)

func is_seasonal_content_available(content_id: String) -> bool:
	if not current_season:
		return false
	
	return content_id in current_season.exclusive_content

