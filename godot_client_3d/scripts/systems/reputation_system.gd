extends Node
class_name ReputationSystem

## Система репутации фракций Isleborn Online
## Игроки получают репутацию с различными фракциями

enum FactionType {
	PIRATES,            # Пираты
	CREATORS,           # Созидатели
	SEA_WITCHES,        # Морские Ведьмы
	STORM_ORDER,        # Орден Шторма
	VOID_GUARDIANS,     # Стражи Бездны
	TRADERS,            # Торговцы
	EXPLORERS,          # Исследователи
	AI_SAILING_COIN,    # AI-гильдия: Sailing Coin
	AI_KRAKEN_MAW,      # AI-гильдия: Kraken Maw
	AI_ABYSSAL_CHOIR    # AI-гильдия: Abyssal Choir
}

enum ReputationLevel {
	HOSTILE = -100,     # Враждебно (-100 до -50)
	HATED = -49,        # Ненависть (-49 до -25)
	UNFRIENDLY = -24,   # Недружелюбно (-24 до -10)
	NEUTRAL = -9,       # Нейтрально (-9 до 9)
	FRIENDLY = 10,      # Дружелюбно (10 до 24)
	HONORED = 25,       # Почитаем (25 до 49)
	EXALTED = 50        # Превознесён (50+)
}

## Данные репутации
class ReputationData:
	var player_id: String
	var faction: FactionType
	var value: float = 0.0  # -100 до +100
	var last_updated: int = 0
	
	func get_level() -> ReputationLevel:
		if value <= -50:
			return ReputationLevel.HOSTILE
		elif value <= -25:
			return ReputationLevel.HATED
		elif value <= -10:
			return ReputationLevel.UNFRIENDLY
		elif value < 10:
			return ReputationLevel.NEUTRAL
		elif value < 25:
			return ReputationLevel.FRIENDLY
		elif value < 50:
			return ReputationLevel.HONORED
		else:
			return ReputationLevel.EXALTED
	
	func get_level_name() -> String:
		match get_level():
			ReputationLevel.HOSTILE:
				return "Враждебно"
			ReputationLevel.HATED:
				return "Ненависть"
			ReputationLevel.UNFRIENDLY:
				return "Недружелюбно"
			ReputationLevel.NEUTRAL:
				return "Нейтрально"
			ReputationLevel.FRIENDLY:
				return "Дружелюбно"
			ReputationLevel.HONORED:
				return "Почитаем"
			ReputationLevel.EXALTED:
				return "Превознесён"
		return "Неизвестно"

var player_reputations: Dictionary = {}  # player_id -> Dictionary<FactionType, ReputationData>
var faction_relations: Dictionary = {}  # FactionType -> Dictionary<FactionType, float>  # -1.0 до 1.0

signal reputation_changed(player_id: String, faction: FactionType, new_value: float, old_value: float)
signal reputation_level_changed(player_id: String, faction: FactionType, new_level: ReputationLevel)

func _ready() -> void:
	_initialize_faction_relations()

## Инициализировать отношения между фракциями
func _initialize_faction_relations() -> void:
	# Пираты враждебны всем, кроме других пиратов
	faction_relations[FactionType.PIRATES] = {
		FactionType.CREATORS: -0.8,
		FactionType.SEA_WITCHES: -0.6,
		FactionType.STORM_ORDER: -0.9,
		FactionType.VOID_GUARDIANS: -0.5,
		FactionType.TRADERS: -0.7,
		FactionType.EXPLORERS: -0.4
	}
	
	# Созидатели дружелюбны к торговцам и исследователям
	faction_relations[FactionType.CREATORS] = {
		FactionType.TRADERS: 0.6,
		FactionType.EXPLORERS: 0.5,
		FactionType.PIRATES: -0.8
	}
	
	# Морские Ведьмы нейтральны
	faction_relations[FactionType.SEA_WITCHES] = {
		FactionType.VOID_GUARDIANS: 0.3
	}
	
	# Орден Шторма враждебен пиратам
	faction_relations[FactionType.STORM_ORDER] = {
		FactionType.PIRATES: -0.9,
		FactionType.CREATORS: 0.4
	}

## Получить репутацию игрока с фракцией
func get_reputation(player_id: String, faction: FactionType) -> ReputationData:
	if not player_reputations.has(player_id):
		player_reputations[player_id] = {}
	
	var player_reps = player_reputations[player_id]
	if not player_reps.has(faction):
		# Создаём новую репутацию (начинаем с 0)
		var rep = ReputationData.new()
		rep.player_id = player_id
		rep.faction = faction
		rep.value = 0.0
		rep.last_updated = Time.get_unix_time_from_system()
		player_reps[faction] = rep
	
	return player_reps[faction]

## Изменить репутацию
func change_reputation(player_id: String, faction: FactionType, amount: float, reason: String = "") -> void:
	var rep = get_reputation(player_id, faction)
	var old_value = rep.value
	var old_level = rep.get_level()
	
	rep.value = clamp(rep.value + amount, -100.0, 100.0)
	rep.last_updated = Time.get_unix_time_from_system()
	
	var new_level = rep.get_level()
	
	# Если уровень изменился
	if new_level != old_level:
		reputation_level_changed.emit(player_id, faction, new_level)
	
	reputation_changed.emit(player_id, faction, rep.value, old_value)
	
	# Влияние на связанные фракции
	_apply_relation_effects(player_id, faction, amount)

## Применить эффекты отношений между фракциями
func _apply_relation_effects(player_id: String, changed_faction: FactionType, amount: float) -> void:
	if not faction_relations.has(changed_faction):
		return
	
	var relations = faction_relations[changed_faction]
	
	# Изменяем репутацию с связанными фракциями (в меньшей степени)
	for related_faction in relations.keys():
		var relation_value = relations[related_faction]
		var bonus_amount = amount * relation_value * 0.3  # 30% от основного изменения
		
		if abs(bonus_amount) > 0.1:  # Игнорируем очень маленькие изменения
			change_reputation(player_id, related_faction, bonus_amount, "Влияние отношений фракций")

## Получить все репутации игрока
func get_all_reputations(player_id: String) -> Dictionary:
	if not player_reputations.has(player_id):
		return {}
	
	return player_reputations[player_id].duplicate()

## Получить название фракции
static func get_faction_name(faction: FactionType) -> String:
	match faction:
		FactionType.PIRATES:
			return "Пираты"
		FactionType.CREATORS:
			return "Созидатели"
		FactionType.SEA_WITCHES:
			return "Морские Ведьмы"
		FactionType.STORM_ORDER:
			return "Орден Шторма"
		FactionType.VOID_GUARDIANS:
			return "Стражи Бездны"
		FactionType.TRADERS:
			return "Торговцы"
		FactionType.EXPLORERS:
			return "Исследователи"
		FactionType.AI_SAILING_COIN:
			return "Sailing Coin"
		FactionType.AI_KRAKEN_MAW:
			return "Kraken Maw"
		FactionType.AI_ABYSSAL_CHOIR:
			return "Abyssal Choir"
		_:
			return "Неизвестно"

## Проверить, доступен ли контент для игрока
func has_access(player_id: String, faction: FactionType, required_level: ReputationLevel) -> bool:
	var rep = get_reputation(player_id, faction)
	return rep.get_level() >= required_level

## Получить бонусы от репутации
func get_reputation_bonuses(player_id: String, faction: FactionType) -> Dictionary:
	var rep = get_reputation(player_id, faction)
	var level = rep.get_level()
	var bonuses = {}
	
	match level:
		ReputationLevel.EXALTED:
			bonuses = {
				"discount": 0.20,  # 20% скидка
				"unique_recipes": true,
				"special_ships": true,
				"quest_access": true
			}
		ReputationLevel.HONORED:
			bonuses = {
				"discount": 0.15,
				"unique_recipes": true,
				"quest_access": true
			}
		ReputationLevel.FRIENDLY:
			bonuses = {
				"discount": 0.10,
				"quest_access": true
			}
		ReputationLevel.UNFRIENDLY:
			bonuses = {
				"penalty": 0.10  # Штраф
			}
		ReputationLevel.HATED:
			bonuses = {
				"penalty": 0.20,
				"attacked": true  # Атакуют на вид
			}
		ReputationLevel.HOSTILE:
			bonuses = {
				"penalty": 0.30,
				"attacked": true,
				"port_access": false  # Нет доступа в порты
			}
	
	return bonuses

