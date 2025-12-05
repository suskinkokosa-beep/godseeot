extends Node
class_name EnhancementSystem

## Система заточки экипировки Isleborn Online
## Максимальная заточка: +12
## Риски зависят от уровня заточки

enum EnhancementResult {
	SUCCESS,        # Успешная заточка
	FAILURE_SAFE,   # Неудача, но безопасно (до +3)
	FAILURE_DOWN,   # Неудача, сбита заточка на -1 (до +8)
	FAILURE_RESET,  # Неудача, сброс до +3 (с +8 до +10)
	FAILURE_BREAK   # Неудача, предмет сломан (с +10 до +12)
}

const MAX_ENHANCEMENT_LEVEL = 12
const SAFE_ENHANCEMENT_LEVEL = 3
const RISKY_ENHANCEMENT_LEVEL = 8
const DANGEROUS_ENHANCEMENT_LEVEL = 10

## Шансы успеха по уровням (в процентах)
const SUCCESS_CHANCES = {
	0: 100.0,   # +0 -> +1: 100%
	1: 100.0,   # +1 -> +2: 100%
	2: 100.0,   # +2 -> +3: 100%
	3: 95.0,    # +3 -> +4: 95%
	4: 90.0,    # +4 -> +5: 90%
	5: 85.0,    # +5 -> +6: 85%
	6: 80.0,    # +6 -> +7: 80%
	7: 75.0,    # +7 -> +8: 75%
	8: 60.0,    # +8 -> +9: 60%
	9: 50.0,    # +9 -> +10: 50%
	10: 40.0,   # +10 -> +11: 40%
	11: 30.0    # +11 -> +12: 30%
}

## Попытка заточки предмета
static func enhance_item(item_data: Dictionary, enhancement_material: String, luck: float = 0.0) -> Dictionary:
	var current_level = item_data.get("enhancement_level", 0)
	
	if current_level >= MAX_ENHANCEMENT_LEVEL:
		return {
			"result": EnhancementResult.SUCCESS,
			"new_level": current_level,
			"message": "Предмет уже максимально заточен"
		}
	
	# Проверяем наличие материала для заточки
	if not _has_enhancement_material(enhancement_material, current_level):
		return {
			"result": EnhancementResult.FAILURE_SAFE,
			"new_level": current_level,
			"message": "Недостаточно материалов для заточки"
		}
	
	# Вычисляем шанс успеха с учётом удачи
	var base_chance = SUCCESS_CHANCES.get(current_level, 0.0)
	var luck_bonus = luck * 0.1  # +0.1% за единицу удачи
	var final_chance = min(base_chance + luck_bonus, 99.0)  # Максимум 99%
	
	var random = randf() * 100.0
	var result: EnhancementResult
	var new_level: int
	
	if random <= final_chance:
		# Успех
		result = EnhancementResult.SUCCESS
		new_level = current_level + 1
	else:
		# Неудача - определяем тип
		if current_level < SAFE_ENHANCEMENT_LEVEL:
			result = EnhancementResult.FAILURE_SAFE
			new_level = current_level
		elif current_level < RISKY_ENHANCEMENT_LEVEL:
			result = EnhancementResult.FAILURE_DOWN
			new_level = max(0, current_level - 1)
		elif current_level < DANGEROUS_ENHANCEMENT_LEVEL:
			result = EnhancementResult.FAILURE_RESET
			new_level = SAFE_ENHANCEMENT_LEVEL
		else:
			result = EnhancementResult.FAILURE_BREAK
			new_level = -1  # Предмет сломан
	
	return {
		"result": result,
		"new_level": new_level,
		"message": _get_result_message(result, current_level, new_level)
	}

## Вычислить бонусы от заточки
static func calculate_enhancement_bonus(level: int, item_data: Dictionary) -> Dictionary:
	if level <= 0:
		return {}
	
	var base_stats = item_data.get("stats", {})
	var bonus_stats: Dictionary = {}
	
	# Формула: базовый стат * (1 + level * 0.05)
	# Каждый уровень заточки даёт +5% к базовым статам
	var multiplier = 1.0 + (level * 0.05)
	
	for stat in base_stats.keys():
		var base_value = base_stats[stat]
		var bonus = base_value * (multiplier - 1.0)
		bonus_stats[stat] = bonus
	
	return bonus_stats

## Проверить наличие материала для заточки
static func _has_enhancement_material(material_id: String, current_level: int) -> bool:
	# TODO: Проверка наличия материала в инвентаре
	# Пока возвращаем true для тестирования
	return true

## Получить сообщение о результате
static func _get_result_message(result: EnhancementResult, old_level: int, new_level: int) -> String:
	match result:
		EnhancementResult.SUCCESS:
			return "Заточка успешна! Уровень: +%d -> +%d" % [old_level, new_level]
		EnhancementResult.FAILURE_SAFE:
			return "Заточка не удалась, но предмет не пострадал"
		EnhancementResult.FAILURE_DOWN:
			return "Заточка не удалась! Уровень снижен: +%d -> +%d" % [old_level, new_level]
		EnhancementResult.FAILURE_RESET:
			return "Заточка не удалась! Уровень сброшен до +%d" % new_level
		EnhancementResult.FAILURE_BREAK:
			return "КРИТИЧЕСКАЯ НЕУДАЧА! Предмет сломан и не может быть восстановлен!"
		_:
			return "Неизвестный результат"

## Получить шанс успеха для уровня
static func get_success_chance(level: int, luck: float = 0.0) -> float:
	var base_chance = SUCCESS_CHANCES.get(level, 0.0)
	var luck_bonus = luck * 0.1
	return min(base_chance + luck_bonus, 99.0)

## Получить тип риска для уровня
static func get_risk_type(level: int) -> EnhancementResult:
	if level < SAFE_ENHANCEMENT_LEVEL:
		return EnhancementResult.FAILURE_SAFE
	elif level < RISKY_ENHANCEMENT_LEVEL:
		return EnhancementResult.FAILURE_DOWN
	elif level < DANGEROUS_ENHANCEMENT_LEVEL:
		return EnhancementResult.FAILURE_RESET
	else:
		return EnhancementResult.FAILURE_BREAK

