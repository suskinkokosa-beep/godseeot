extends Node
class_name PlayerServer

## Серверная система управления игроками
## Обрабатывает экипировку, статы, прогрессию

var player_data: Dictionary = {}  # eid -> player data

func _ready() -> void:
	pass

## Инициализировать данные игрока
func init_player(eid: String, username: String) -> void:
	player_data[eid] = {
		"username": username,
		"level": 1,
		"experience": 0.0,
		"stats": {
			"strength": 10,
			"vitality": 10,
			"agility": 10,
			"stamina": 10,
			"focus": 10,
			"intelligence": 10,
			"perception": 10,
			"luck": 10
		},
		"equipment": {},
		"inventory": {},
		"class": null,
		"hp": 100,
		"max_hp": 100,
		"pvp": false
	}

## Получить данные игрока
func get_player_data(eid: String) -> Dictionary:
	return player_data.get(eid, {})

## Обновить уровень игрока
func update_player_level(eid: String, new_level: int) -> void:
	if not player_data.has(eid):
		return
	player_data[eid]["level"] = new_level

## Добавить опыт игроку
func add_experience(eid: String, amount: float) -> void:
	if not player_data.has(eid):
		return
	
	var data = player_data[eid]
	var current_exp = data.get("experience", 0.0)
	var current_level = data.get("level", 1)
	
	current_exp += amount
	
	# Проверяем повышение уровня
	var needed_exp = _get_experience_for_level(current_level + 1)
	while current_exp >= needed_exp and current_level < 50:
		current_exp -= needed_exp
		current_level += 1
		needed_exp = _get_experience_for_level(current_level + 1)
	
	data["experience"] = current_exp
	data["level"] = current_level
	player_data[eid] = data

## Вычисляет требуемый опыт для уровня
func _get_experience_for_level(level: int) -> float:
	if level <= 10:
		return 50.0 * pow(level, 1.9)
	else:
		var base_xp = 50.0 * pow(10, 1.9)
		var level_multiplier = 1.0 + (level - 10) * 0.5
		var exponential = pow(level, 2.2)
		return base_xp * level_multiplier * (exponential / pow(10, 1.9))

## Проверить, можно ли экипировать предмет
func can_equip_item(eid: String, item_id: String, item_data: Dictionary) -> bool:
	if not player_data.has(eid):
		return false
	
	var player = player_data[eid]
	var player_level = player.get("level", 1)
	var required_level = item_data.get("required_level", 1)
	
	return player_level >= required_level

## Экипировать предмет
func equip_item(eid: String, item_id: String, slot: String) -> bool:
	if not player_data.has(eid):
		return false
	
	var player = player_data[eid]
	var equipment = player.get("equipment", {})
	
	equipment[slot] = item_id
	player["equipment"] = equipment
	player_data[eid] = player
	
	return true

## Обновить HP игрока
func update_hp(eid: String, new_hp: int) -> void:
	if not player_data.has(eid):
		return
	
	var player = player_data[eid]
	player["hp"] = new_hp
	player_data[eid] = player

