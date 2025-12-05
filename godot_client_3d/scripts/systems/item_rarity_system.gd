extends Node
class_name ItemRaritySystem

## Система редкости предметов Isleborn Online
## Обычное - без бонусов
## Редкое - небольшой бонус
## Легендарное - большой бонус
## Мифическое - особый бонус

enum ItemRarity {
	COMMON,        # Обычное - без бонусов
	RARE,          # Редкое - небольшой бонус
	LEGENDARY,     # Легендарное - большой бонус
	MYTHIC         # Мифическое - особый бонус
}

## Вычисляет бонусы редкости к базовым статам
static func calculate_rarity_bonus(rarity: String, base_stats: Dictionary) -> Dictionary:
	var bonus_stats: Dictionary = {}
	
	match rarity:
		"common":
			# Обычное - без бонусов
			return {}
		"rare":
			# Редкое - +10% к базовым статам
			for stat in base_stats.keys():
				bonus_stats[stat] = base_stats[stat] * 0.1
		"legendary":
			# Легендарное - +25% к базовым статам + дополнительные бонусы
			for stat in base_stats.keys():
				bonus_stats[stat] = base_stats[stat] * 0.25
			# Дополнительные бонусы
			bonus_stats["luck"] = bonus_stats.get("luck", 0.0) + 5.0
		"mythic":
			# Мифическое - +50% к базовым статам + особые бонусы
			for stat in base_stats.keys():
				bonus_stats[stat] = base_stats[stat] * 0.5
			# Особые бонусы
			bonus_stats["luck"] = bonus_stats.get("luck", 0.0) + 10.0
			bonus_stats["vitality"] = bonus_stats.get("vitality", 0.0) + 20.0
	
	return bonus_stats

## Получить цвет редкости для UI
static func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common":
			return Color(0.7, 0.7, 0.7)  # Серый
		"rare":
			return Color(0.2, 0.6, 1.0)  # Синий
		"legendary":
			return Color(1.0, 0.5, 0.0)  # Оранжевый
		"mythic":
			return Color(0.8, 0.0, 0.8)  # Фиолетовый
		_:
			return Color.WHITE

## Получить название редкости
static func get_rarity_name(rarity: String) -> String:
	match rarity:
		"common":
			return "Обычное"
		"rare":
			return "Редкое"
		"legendary":
			return "Легендарное"
		"mythic":
			return "Мифическое"
		_:
			return "Неизвестно"

## Проверить, можно ли экипировать предмет по уровню
static func can_equip_by_level(item_level: int, player_level: int) -> bool:
	return player_level >= item_level

## Вычислить общие статы предмета с учётом редкости и заточки
static func calculate_total_item_stats(item_data: Dictionary, enhancement_level: int = 0) -> Dictionary:
	var base_stats = item_data.get("stats", {})
	var rarity = item_data.get("rarity", "common")
	
	# Бонусы редкости
	var rarity_bonus = calculate_rarity_bonus(rarity, base_stats)
	
	# Бонусы заточки
	var enhancement_bonus = EnhancementSystem.calculate_enhancement_bonus(enhancement_level, item_data)
	
	# Суммируем все статы
	var total_stats: Dictionary = {}
	
	# Базовые статы
	for stat in base_stats.keys():
		total_stats[stat] = base_stats[stat]
	
	# Добавляем бонусы редкости
	for stat in rarity_bonus.keys():
		total_stats[stat] = total_stats.get(stat, 0.0) + rarity_bonus[stat]
	
	# Добавляем бонусы заточки
	for stat in enhancement_bonus.keys():
		total_stats[stat] = total_stats.get(stat, 0.0) + enhancement_bonus[stat]
	
	return total_stats

