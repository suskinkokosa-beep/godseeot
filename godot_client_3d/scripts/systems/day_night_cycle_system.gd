extends Node
class_name DayNightCycleSystem

## Система дневного/ночного цикла для Isleborn Online
## Согласно GDD: цикл дня/ночи влияет на игровой процесс

enum TimeOfDay {
	DAWN,           # Рассвет (5:00 - 7:00)
	MORNING,        # Утро (7:00 - 12:00)
	NOON,           # Полдень (12:00 - 14:00)
	AFTERNOON,      # День (14:00 - 18:00)
	DUSK,           # Закат (18:00 - 20:00)
	NIGHT,          # Ночь (20:00 - 23:00)
	MIDNIGHT,       # Полночь (23:00 - 2:00)
	LATE_NIGHT      # Поздняя ночь (2:00 - 5:00)
}

class TimeData:
	var game_time: float = 0.0  # Внутреннее время игры (0-24 часа)
	var day_length_minutes: float = 30.0  # Реальное время для одного дня
	var day_number: int = 1
	var time_of_day: TimeOfDay = TimeOfDay.MORNING
	
	func get_hour() -> int:
		return int(game_time)
	
	func get_minute() -> int:
		return int((game_time - float(get_hour())) * 60.0)
	
	func is_daytime() -> bool:
		return time_of_day in [TimeOfDay.DAWN, TimeOfDay.MORNING, TimeOfDay.NOON, TimeOfDay.AFTERNOON, TimeOfDay.DUSK]
	
	func is_nighttime() -> bool:
		return time_of_day in [TimeOfDay.NIGHT, TimeOfDay.MIDNIGHT, TimeOfDay.LATE_NIGHT]

var time_data: TimeData = TimeData.new()
var time_scale: float = 1.0  # Множитель скорости времени

signal time_changed(new_hour: int, new_minute: int)
signal time_of_day_changed(new_time: TimeOfDay)
signal day_changed(day_number: int)

func _ready() -> void:
	time_data.game_time = 8.0  # Начинаем утром

func _process(delta: float) -> void:
	_update_time(delta)

func _update_time(delta: float) -> void:
	# Вычисляем изменение времени
	var real_time_per_hour = (time_data.day_length_minutes * 60.0) / 24.0
	var time_delta = (delta * time_scale) / real_time_per_hour
	
	time_data.game_time += time_delta
	
	# Проверяем переход через сутки
	if time_data.game_time >= 24.0:
		time_data.game_time = fmod(time_data.game_time, 24.0)
		time_data.day_number += 1
		day_changed.emit(time_data.day_number)
	
	# Определяем время суток
	var old_time_of_day = time_data.time_of_day
	time_data.time_of_day = _get_time_of_day(time_data.game_time)
	
	if old_time_of_day != time_data.time_of_day:
		time_of_day_changed.emit(time_data.time_of_day)
	
	# Отправляем сигнал об изменении времени
	time_changed.emit(time_data.get_hour(), time_data.get_minute())

func _get_time_of_day(hour: float) -> TimeOfDay:
	if hour >= 5.0 and hour < 7.0:
		return TimeOfDay.DAWN
	elif hour >= 7.0 and hour < 12.0:
		return TimeOfDay.MORNING
	elif hour >= 12.0 and hour < 14.0:
		return TimeOfDay.NOON
	elif hour >= 14.0 and hour < 18.0:
		return TimeOfDay.AFTERNOON
	elif hour >= 18.0 and hour < 20.0:
		return TimeOfDay.DUSK
	elif hour >= 20.0 and hour < 23.0:
		return TimeOfDay.NIGHT
	elif hour >= 23.0 or hour < 2.0:
		return TimeOfDay.MIDNIGHT
	else:
		return TimeOfDay.LATE_NIGHT

func get_light_intensity() -> float:
	# Возвращает интенсивность света от 0.0 (ночь) до 1.0 (день)
	match time_data.time_of_day:
		TimeOfDay.DAWN:
			return 0.3 + (time_data.game_time - 5.0) / 2.0 * 0.7
		TimeOfDay.MORNING, TimeOfDay.NOON, TimeOfDay.AFTERNOON:
			return 1.0
		TimeOfDay.DUSK:
			return 1.0 - (time_data.game_time - 18.0) / 2.0 * 0.7
		TimeOfDay.NIGHT, TimeOfDay.MIDNIGHT:
			return 0.1
		TimeOfDay.LATE_NIGHT:
			return 0.1 + (time_data.game_time - 2.0) / 3.0 * 0.2
		_:
			return 0.5

func get_ambient_color() -> Color:
	match time_data.time_of_day:
		TimeOfDay.DAWN:
			return Color(1.0, 0.7, 0.5, 1.0)  # Оранжево-розовый
		TimeOfDay.MORNING, TimeOfDay.NOON, TimeOfDay.AFTERNOON:
			return Color(1.0, 1.0, 0.95, 1.0)  # Светлый
		TimeOfDay.DUSK:
			return Color(1.0, 0.6, 0.4, 1.0)  # Золотисто-красный
		TimeOfDay.NIGHT, TimeOfDay.MIDNIGHT:
			return Color(0.2, 0.3, 0.5, 1.0)  # Синий
		TimeOfDay.LATE_NIGHT:
			return Color(0.3, 0.4, 0.6, 1.0)  # Тёмно-синий
		_:
			return Color(0.5, 0.5, 0.5, 1.0)

func get_time_modifiers() -> Dictionary:
	var modifiers = {}
	
	match time_data.time_of_day:
		TimeOfDay.NIGHT, TimeOfDay.MIDNIGHT, TimeOfDay.LATE_NIGHT:
			modifiers["visibility"] = 0.5  # Сниженная видимость
			modifiers["monster_spawn"] = 1.3  # Больше монстров
			modifiers["fishing"] = 0.8  # Хуже рыбалка
		
		TimeOfDay.DAWN, TimeOfDay.DUSK:
			modifiers["visibility"] = 0.7
			modifiers["resource_gathering"] = 1.1  # Лучше собирать ресурсы
		
		TimeOfDay.MORNING, TimeOfDay.NOON, TimeOfDay.AFTERNOON:
			modifiers["visibility"] = 1.0
			modifiers["fishing"] = 1.2  # Лучше рыбалка
			modifiers["building_speed"] = 1.1  # Быстрее строительство
	
	return modifiers

func set_time(hour: float) -> void:
	time_data.game_time = clamp(hour, 0.0, 24.0)
	time_data.time_of_day = _get_time_of_day(time_data.game_time)

func set_time_scale(scale: float) -> void:
	time_scale = clamp(scale, 0.1, 10.0)

func get_current_time_string() -> String:
	var hour = time_data.get_hour()
	var minute = time_data.get_minute()
	return "%02d:%02d" % [hour, minute]

func get_time_info() -> Dictionary:
	return {
		"hour": time_data.get_hour(),
		"minute": time_data.get_minute(),
		"time_of_day": time_data.time_of_day,
		"day_number": time_data.day_number,
		"is_daytime": time_data.is_daytime(),
		"is_nighttime": time_data.is_nighttime(),
		"light_intensity": get_light_intensity(),
		"modifiers": get_time_modifiers()
	}

