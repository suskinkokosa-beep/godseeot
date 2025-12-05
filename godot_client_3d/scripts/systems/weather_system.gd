extends Node
class_name WeatherSystem

## Система погоды Isleborn Online
## Влияет на корабли, добычу, монстров, события

enum WeatherType {
	CLEAR,           # Ясная погода
	LIGHT_WIND,      # Лёгкий ветер
	STRONG_WIND,     # Сильный ветер
	CLOUDY,          # Облачно
	FOG,             # Туман
	HEAVY_FOG,       # Густой туман
	DARK_FOG,        # Тёмный туман (Blackwater)
	RAIN,            # Дождь
	STORM,           # Шторм
	THUNDERSTORM,    # Гроза
	SUPERSTORM,      # Супершторм
	BLACK_STORM,     # Чёрный шторм (Blackwater)
	SNOW,            # Снег
	BLIZZARD,        # Метель
	VOID_STORM,      # Буря бездны
	ABYSS_CURRENT    # Течение бездны
}

var current_weather: WeatherType = WeatherType.CLEAR
var weather_transition_time: float = 0.0
var weather_duration: float = 600.0  # 10 минут по умолчанию
var time_until_change: float = 0.0

signal weather_changed(new_weather: WeatherType)
signal weather_transition_started(from: WeatherType, to: WeatherType)

func _ready() -> void:
	time_until_change = weather_duration

func _process(delta: float) -> void:
	time_until_change -= delta
	
	if time_until_change <= 0.0:
		_change_weather()
		time_until_change = weather_duration

## Изменяет погоду на случайную
func _change_weather() -> void:
	var biome_id = "tropical_shallow"  # TODO: Получить текущий биом
	var biome = BiomeDatabase.get_biome(biome_id)
	
	if biome.is_empty():
		return
	
	var weather_weights = biome.get("weather_weights", {})
	if weather_weights.is_empty():
		return
	
	var new_weather = _select_weather_by_weights(weather_weights)
	if new_weather != current_weather:
		weather_transition_started.emit(current_weather, new_weather)
		current_weather = new_weather
		weather_changed.emit(current_weather)

## Выбирает погоду на основе весов
func _select_weather_by_weights(weights: Dictionary) -> WeatherType:
	var total_weight = 0.0
	for weight in weights.values():
		total_weight += weight
	
	var random = randf() * total_weight
	var current = 0.0
	
	for weather_name in weights.keys():
		current += weights[weather_name]
		if random <= current:
			return _weather_name_to_type(weather_name)
	
	return WeatherType.CLEAR

## Преобразует имя погоды в тип
func _weather_name_to_type(name: String) -> WeatherType:
	match name:
		"clear":
			return WeatherType.CLEAR
		"light_wind":
			return WeatherType.LIGHT_WIND
		"strong_wind":
			return WeatherType.STRONG_WIND
		"cloudy":
			return WeatherType.CLOUDY
		"fog":
			return WeatherType.FOG
		"heavy_fog":
			return WeatherType.HEAVY_FOG
		"dark_fog":
			return WeatherType.DARK_FOG
		"rain":
			return WeatherType.RAIN
		"storm":
			return WeatherType.STORM
		"thunderstorm":
			return WeatherType.THUNDERSTORM
		"superstorm":
			return WeatherType.SUPERSTORM
		"black_storm":
			return WeatherType.BLACK_STORM
		"snow":
			return WeatherType.SNOW
		"blizzard":
			return WeatherType.BLIZZARD
		"void_storm":
			return WeatherType.VOID_STORM
		"abyss_current":
			return WeatherType.ABYSS_CURRENT
		_:
			return WeatherType.CLEAR

## Получить модификатор скорости корабля
func get_ship_speed_modifier() -> float:
	match current_weather:
		WeatherType.CLEAR, WeatherType.CLOUDY:
			return 1.0
		WeatherType.LIGHT_WIND:
			return 1.1  # +10% скорость
		WeatherType.STRONG_WIND:
			return 1.2  # +20% скорость
		WeatherType.RAIN:
			return 0.95  # -5% скорость
		WeatherType.FOG, WeatherType.HEAVY_FOG, WeatherType.DARK_FOG:
			return 0.8  # -20% скорость
		WeatherType.STORM:
			return 0.6  # -40% скорость, риск повреждений
		WeatherType.THUNDERSTORM:
			return 0.5  # -50% скорость, молнии
		WeatherType.SUPERSTORM:
			return 0.3  # -70% скорость, огромные волны
		WeatherType.BLACK_STORM, WeatherType.VOID_STORM:
			return 0.4  # -60% скорость, магические эффекты
		WeatherType.SNOW:
			return 0.9  # -10% скорость
		WeatherType.BLIZZARD:
			return 0.5  # -50% скорость, замерзание
		_:
			return 1.0

## Получить модификатор видимости
func get_visibility_modifier() -> float:
	match current_weather:
		WeatherType.CLEAR, WeatherType.CLOUDY:
			return 1.0
		WeatherType.LIGHT_WIND, WeatherType.STRONG_WIND:
			return 1.0
		WeatherType.FOG:
			return 0.7  # Видимость 70%
		WeatherType.HEAVY_FOG:
			return 0.5  # Видимость 50%
		WeatherType.DARK_FOG:
			return 0.3  # Видимость 30%
		WeatherType.RAIN:
			return 0.8
		WeatherType.STORM:
			return 0.6
		WeatherType.THUNDERSTORM:
			return 0.5
		WeatherType.SUPERSTORM:
			return 0.3
		WeatherType.SNOW:
			return 0.7
		WeatherType.BLIZZARD:
			return 0.2
		WeatherType.BLACK_STORM, WeatherType.VOID_STORM:
			return 0.2
		_:
			return 1.0

## Получить модификатор добычи (для сетей/рыбалки)
func get_gathering_modifier() -> float:
	match current_weather:
		WeatherType.CLEAR, WeatherType.LIGHT_WIND:
			return 1.0
		WeatherType.RAIN:
			return 1.1  # +10% (вода привлекает рыбу)
		WeatherType.STORM:
			return 0.5  # -50% (опасно)
		WeatherType.FOG:
			return 0.8  # -20%
		_:
			return 1.0

## Проверяет, опасна ли текущая погода
func is_dangerous() -> bool:
	return current_weather in [
		WeatherType.STORM,
		WeatherType.THUNDERSTORM,
		WeatherType.SUPERSTORM,
		WeatherType.BLACK_STORM,
		WeatherType.BLIZZARD,
		WeatherType.VOID_STORM
	]

## Получить название текущей погоды
func get_weather_name() -> String:
	match current_weather:
		WeatherType.CLEAR:
			return "Ясная погода"
		WeatherType.LIGHT_WIND:
			return "Лёгкий ветер"
		WeatherType.STRONG_WIND:
			return "Сильный ветер"
		WeatherType.CLOUDY:
			return "Облачно"
		WeatherType.FOG:
			return "Туман"
		WeatherType.HEAVY_FOG:
			return "Густой туман"
		WeatherType.DARK_FOG:
			return "Тёмный туман"
		WeatherType.RAIN:
			return "Дождь"
		WeatherType.STORM:
			return "Шторм"
		WeatherType.THUNDERSTORM:
			return "Гроза"
		WeatherType.SUPERSTORM:
			return "Супершторм"
		WeatherType.BLACK_STORM:
			return "Чёрный шторм"
		WeatherType.SNOW:
			return "Снег"
		WeatherType.BLIZZARD:
			return "Метель"
		WeatherType.VOID_STORM:
			return "Буря бездны"
		WeatherType.ABYSS_CURRENT:
			return "Течение бездны"
		_:
			return "Неизвестно"

## Устанавливает погоду принудительно (для событий)
func set_weather(weather: WeatherType, duration: float = 600.0) -> void:
	if weather != current_weather:
		weather_transition_started.emit(current_weather, weather)
		current_weather = weather
		weather_changed.emit(current_weather)
	
	weather_duration = duration
	time_until_change = duration

