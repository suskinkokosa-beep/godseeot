extends Node
class_name StyleSystem

## Система стиля персонажа Isleborn Online
## Управляет визуальным стилем и покраской персонажа

enum StylePart {
	HAIR,           # Причёска
	HAIR_COLOR,     # Цвет волос
	SKIN_COLOR,     # Цвет кожи
	EYE_COLOR,      # Цвет глаз
	BODY_TYPE,      # Тип тела
	FACIAL_HAIR,    # Борода/усы
	SCAR,           # Шрамы
	TATTOO          # Татуировки
}

var style_data: Dictionary = {
	"hair": "default",
	"hair_color": Color(0.2, 0.1, 0.05),  # Коричневый
	"skin_color": Color(0.9, 0.8, 0.7),   # Светлый
	"eye_color": Color(0.1, 0.3, 0.6),   # Синий
	"body_type": "average",
	"facial_hair": "none",
	"scar": "none",
	"tattoo": "none"
}

signal style_changed(part: StylePart, value: Variant)

func _ready() -> void:
	pass

## Установить стиль
func set_style(part: StylePart, value: Variant) -> void:
	match part:
		StylePart.HAIR:
			style_data["hair"] = value
		StylePart.HAIR_COLOR:
			style_data["hair_color"] = value
		StylePart.SKIN_COLOR:
			style_data["skin_color"] = value
		StylePart.EYE_COLOR:
			style_data["eye_color"] = value
		StylePart.BODY_TYPE:
			style_data["body_type"] = value
		StylePart.FACIAL_HAIR:
			style_data["facial_hair"] = value
		StylePart.SCAR:
			style_data["scar"] = value
		StylePart.TATTOO:
			style_data["tattoo"] = value
	
	style_changed.emit(part, value)

## Получить стиль
func get_style(part: StylePart) -> Variant:
	match part:
		StylePart.HAIR:
			return style_data.get("hair", "default")
		StylePart.HAIR_COLOR:
			return style_data.get("hair_color", Color.WHITE)
		StylePart.SKIN_COLOR:
			return style_data.get("skin_color", Color.WHITE)
		StylePart.EYE_COLOR:
			return style_data.get("eye_color", Color.BLUE)
		StylePart.BODY_TYPE:
			return style_data.get("body_type", "average")
		StylePart.FACIAL_HAIR:
			return style_data.get("facial_hair", "none")
		StylePart.SCAR:
			return style_data.get("scar", "none")
		StylePart.TATTOO:
			return style_data.get("tattoo", "none")
		_:
			return null

## Получить все данные стиля
func get_all_style_data() -> Dictionary:
	return style_data.duplicate()

## Установить все данные стиля
func set_all_style_data(data: Dictionary) -> void:
	style_data = data.duplicate()
	style_changed.emit(StylePart.HAIR, style_data)

