extends Node
class_name GuildWarSystem

## Система гильдейских войн для Isleborn Online
## Согласно GDD: осады островов, битвы флагманов, PvP-захваты биомов

enum WarType {
	ISLAND_SIEGE,   # Осада острова
	FLAGSHIP_BATTLE, # Битва флагманов
	BIOME_CONTROL,  # Контроль биома
	TERRITORY_WAR   # Война за территорию
}

enum WarStatus {
	DECLARED,       # Объявлена
	PREPARATION,    # Подготовка
	ACTIVE,         # Активна
	DEFENDING_WIN,  # Защита победила
	ATTACKING_WIN,  # Атака победила
	CANCELLED       # Отменена
}

class GuildWar:
	var war_id: String
	var attacker_guild_id: String
	var defender_guild_id: String
	var war_type: WarType
	var status: WarStatus = WarStatus.DECLARED
	var declared_at: int
	var start_time: int
	var end_time: int
	var duration_hours: int = 24
	var target: Dictionary = {}  # Остров, биом, территория
	var participants: Dictionary = {}  # guild_id -> [player_ids]
	var war_score: Dictionary = {}  # guild_id -> score
	var rewards: Dictionary = {}
	
	func _init(_id: String, _attacker: String, _defender: String, _type: WarType):
		war_id = _id
		attacker_guild_id = _attacker
		defender_guild_id = _defender
		war_type = _type
		declared_at = Time.get_unix_time_from_system()

var active_wars: Dictionary = {}  # war_id -> GuildWar
var war_history: Array[GuildWar] = []

signal war_declared(war: GuildWar)
signal war_started(war_id: String)
signal war_ended(war_id: String, winner_guild_id: String)
signal war_score_updated(war_id: String, attacker_score: int, defender_score: int)

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	_update_active_wars(delta)

func declare_war(attacker_guild_id: String, defender_guild_id: String, war_type: WarType, target: Dictionary = {}) -> String:
	# Проверяем, не идёт ли уже война
	if _is_war_active(attacker_guild_id, defender_guild_id):
		return ""
	
	var war_id = "war_%d" % Time.get_ticks_msec()
	var war = GuildWar.new(war_id, attacker_guild_id, defender_guild_id, war_type)
	war.target = target
	war.status = WarStatus.DECLARED
	war.start_time = war.declared_at + 3600  # Начинается через 1 час
	
	# Инициализируем счёт
	war.war_score[attacker_guild_id] = 0
	war.war_score[defender_guild_id] = 0
	
	active_wars[war_id] = war
	war_declared.emit(war)
	
	return war_id

func start_war(war_id: String) -> bool:
	if not active_wars.has(war_id):
		return false
	
	var war = active_wars[war_id]
	
	if war.status != WarStatus.DECLARED:
		return false
	
	var current_time = Time.get_unix_time_from_system()
	if current_time < war.start_time:
		return false  # Ещё не время
	
	war.status = WarStatus.ACTIVE
	war.end_time = current_time + (war.duration_hours * 3600)
	
	war_started.emit(war_id)
	return true

func _update_active_wars(delta: float) -> void:
	var current_time = Time.get_unix_time_from_system()
	
	for war_id in active_wars.keys():
		var war = active_wars[war_id]
		
		# Автоматически запускаем объявленные войны
		if war.status == WarStatus.DECLARED and current_time >= war.start_time:
			start_war(war_id)
		
		# Проверяем окончание войны
		if war.status == WarStatus.ACTIVE:
			if current_time >= war.end_time:
				_end_war_by_time(war_id)
			else:
				_check_war_victory_conditions(war_id)

func _check_war_victory_conditions(war_id: String) -> void:
	if not active_wars.has(war_id):
		return
	
	var war = active_wars[war_id]
	
	# Проверяем условия победы в зависимости от типа войны
	match war.war_type:
		WarType.ISLAND_SIEGE:
			# Проверяем, захвачен ли остров
			if war.war_score.get(war.attacker_guild_id, 0) >= 1000:
				_end_war(war_id, war.attacker_guild_id)
			elif war.war_score.get(war.defender_guild_id, 0) >= 1000:
				_end_war(war_id, war.defender_guild_id)
		
		WarType.FLAGSHIP_BATTLE:
			# Проверяем, уничтожен ли флагман
			# TODO: Проверка состояния флагманов
			pass
		
		WarType.BIOME_CONTROL:
			# Проверяем контроль точек
			if war.war_score.get(war.attacker_guild_id, 0) >= 500:
				_end_war(war_id, war.attacker_guild_id)

func add_war_score(war_id: String, guild_id: String, points: int) -> void:
	if not active_wars.has(war_id):
		return
	
	var war = active_wars[war_id]
	if war.status != WarStatus.ACTIVE:
		return
	
	if not war.war_score.has(guild_id):
		war.war_score[guild_id] = 0
	
	war.war_score[guild_id] += points
	
	war_score_updated.emit(war_id, 
		war.war_score.get(war.attacker_guild_id, 0),
		war.war_score.get(war.defender_guild_id, 0))

func _end_war(war_id: String, winner_guild_id: String) -> void:
	if not active_wars.has(war_id):
		return
	
	var war = active_wars[war_id]
	war.status = WarStatus.ATTACKING_WIN if winner_guild_id == war.attacker_guild_id else WarStatus.DEFENDING_WIN
	
	# Выдаём награды
	_give_war_rewards(war, winner_guild_id)
	
	war_ended.emit(war_id, winner_guild_id)
	
	# Перемещаем в историю
	war_history.append(war)
	active_wars.erase(war_id)

func _end_war_by_time(war_id: String) -> void:
	if not active_wars.has(war_id):
		return
	
	var war = active_wars[war_id]
	
	# Определяем победителя по очкам
	var attacker_score = war.war_score.get(war.attacker_guild_id, 0)
	var defender_score = war.war_score.get(war.defender_guild_id, 0)
	
	var winner = war.defender_guild_id  # По умолчанию защита побеждает
	if attacker_score > defender_score:
		winner = war.attacker_guild_id
	
	_end_war(war_id, winner)

func _give_war_rewards(war: GuildWar, winner_guild_id: String) -> void:
	# TODO: Выдать награды победившей гильдии
	war.rewards = {
		"experience": 1000.0,
		"currency": {"guild_coins": 500},
		"territory": war.target if war.war_type == WarType.BIOME_CONTROL else {}
	}

func _is_war_active(guild1_id: String, guild2_id: String) -> bool:
	for war_id in active_wars.keys():
		var war = active_wars[war_id]
		if (war.attacker_guild_id == guild1_id and war.defender_guild_id == guild2_id) or \
		   (war.attacker_guild_id == guild2_id and war.defender_guild_id == guild1_id):
			if war.status == WarStatus.ACTIVE or war.status == WarStatus.DECLARED:
				return true
	return false

func get_war_info(war_id: String) -> Dictionary:
	if not active_wars.has(war_id):
		return {}
	
	var war = active_wars[war_id]
	var current_time = Time.get_unix_time_from_system()
	var time_remaining = max(0, war.end_time - current_time)
	
	return {
		"id": war.war_id,
		"type": war.war_type,
		"attacker": war.attacker_guild_id,
		"defender": war.defender_guild_id,
		"status": war.status,
		"attacker_score": war.war_score.get(war.attacker_guild_id, 0),
		"defender_score": war.war_score.get(war.defender_guild_id, 0),
		"time_remaining": time_remaining,
		"target": war.target
	}

func get_active_wars_for_guild(guild_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for war_id in active_wars.keys():
		var war = active_wars[war_id]
		if war.attacker_guild_id == guild_id or war.defender_guild_id == guild_id:
			result.append(get_war_info(war_id))
	
	return result

