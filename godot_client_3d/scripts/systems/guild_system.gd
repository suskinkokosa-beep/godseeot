extends Node
class_name GuildSystem

## Система гильдий Isleborn Online
## Управляет гильдиями игроков, рангами, правами

enum GuildRank {
	LEADER,         # Лидер
	OFFICER,        # Офицер
	MASTER,         # Мастер ремесла
	CAPTAIN,        # Морской капитан
	MEMBER          # Обычный член
}

enum GuildPermission {
	INVITE,         # Приглашать игроков
	KICK,           # Исключать игроков
	PROMOTE,        # Повышать в ранге
	DEMOTE,         # Понижать в ранге
	MANAGE_ISLAND,  # Управлять гильдейским островом
	MANAGE_TREASURY, # Управлять казной
	START_WAR,      # Начинать войны
	BUILD,          # Строить на острове
	DEPOSIT,        # Вкладывать ресурсы
	WITHDRAW        # Забирать ресурсы
}

## Данные гильдии
class GuildData:
	var id: String
	var name: String
	var tag: String  # Короткий тег (3-5 символов)
	var leader_id: String
	var level: int = 1
	var experience: float = 0.0
	var member_limit: int = 10
	var created_at: int
	
	var treasury: Dictionary = {}  # currency_type -> amount
	var island_id: String = ""
	var settings: Dictionary = {}
	
	func _init(_id: String, _name: String, _tag: String, _leader_id: String):
		id = _id
		name = _name
		tag = _tag
		leader_id = _leader_id
		created_at = Time.get_unix_time_from_system()

## Данные члена гильдии
class GuildMember:
	var player_id: String
	var player_name: String
	var rank: GuildRank
	var permissions: Array[GuildPermission] = []
	var joined_at: int
	var contribution: float = 0.0  # Вклад в гильдию
	
	func _init(_player_id: String, _player_name: String, _rank: GuildRank):
		player_id = _player_id
		player_name = _player_name
		rank = _rank
		joined_at = Time.get_unix_time_from_system()
		_permissions_for_rank(_rank)
	
	func _permissions_for_rank(rank: GuildRank) -> void:
		match rank:
			GuildRank.LEADER:
				permissions = GuildPermission.values()  # Все права
			GuildRank.OFFICER:
				permissions = [
					GuildPermission.INVITE,
					GuildPermission.KICK,
					GuildPermission.PROMOTE,
					GuildPermission.MANAGE_ISLAND,
					GuildPermission.BUILD,
					GuildPermission.DEPOSIT
				]
			GuildRank.MASTER, GuildRank.CAPTAIN:
				permissions = [
					GuildPermission.BUILD,
					GuildPermission.DEPOSIT
				]
			GuildRank.MEMBER:
				permissions = [GuildPermission.DEPOSIT]

var guilds: Dictionary = {}  # guild_id -> GuildData
var guild_members: Dictionary = {}  # guild_id -> Array[GuildMember]
var player_guilds: Dictionary = {}  # player_id -> guild_id

signal guild_created(guild_id: String, guild: GuildData)
signal member_joined(guild_id: String, member: GuildMember)
signal member_left(guild_id: String, player_id: String)
signal member_rank_changed(guild_id: String, player_id: String, new_rank: GuildRank)

func _ready() -> void:
	pass

## Создать гильдию
func create_guild(name: String, tag: String, leader_id: String, leader_name: String) -> GuildData:
	# Проверяем, не состоит ли уже лидер в гильдии
	if player_guilds.has(leader_id):
		return null
	
	# Проверяем уникальность имени и тега
	for guild_id in guilds.keys():
		var guild = guilds[guild_id]
		if guild.name == name or guild.tag == tag:
			return null
	
	var guild_id = "guild_%d_%d" % [Time.get_unix_time_from_system(), randi() % 10000]
	var guild = GuildData.new(guild_id, name, tag, leader_id)
	
	guilds[guild_id] = guild
	
	# Добавляем лидера как члена
	var leader = GuildMember.new(leader_id, leader_name, GuildRank.LEADER)
	if not guild_members.has(guild_id):
		guild_members[guild_id] = []
	guild_members[guild_id].append(leader)
	
	player_guilds[leader_id] = guild_id
	
	guild_created.emit(guild_id, guild)
	return guild

## Пригласить игрока в гильдию
func invite_player(guild_id: String, inviter_id: String, player_id: String, player_name: String) -> bool:
	if not guilds.has(guild_id):
		return false
	
	var guild = guilds[guild_id]
	
	# Проверяем права
	var inviter = _get_member(guild_id, inviter_id)
	if not inviter or GuildPermission.INVITE not in inviter.permissions:
		return false
	
	# Проверяем, не состоит ли игрок уже в гильдии
	if player_guilds.has(player_id):
		return false
	
	# Проверяем лимит членов
	var members = guild_members.get(guild_id, [])
	if members.size() >= guild.member_limit:
		return false
	
	# Добавляем игрока
	var new_member = GuildMember.new(player_id, player_name, GuildRank.MEMBER)
	guild_members[guild_id].append(new_member)
	player_guilds[player_id] = guild_id
	
	member_joined.emit(guild_id, new_member)
	return true

## Исключить игрока из гильдии
func kick_member(guild_id: String, kicker_id: String, target_id: String) -> bool:
	if not guilds.has(guild_id):
		return false
	
	var kicker = _get_member(guild_id, kicker_id)
	if not kicker or GuildPermission.KICK not in kicker.permissions:
		return false
	
	var target = _get_member(guild_id, target_id)
	if not target:
		return false
	
	# Нельзя исключить лидера
	if target.rank == GuildRank.LEADER:
		return false
	
	# Нельзя исключить игрока того же или выше ранга
	if target.rank >= kicker.rank:
		return false
	
	# Удаляем из гильдии
	var members = guild_members[guild_id]
	members.erase(target)
	player_guilds.erase(target_id)
	
	member_left.emit(guild_id, target_id)
	return true

## Покинуть гильдию
func leave_guild(guild_id: String, player_id: String) -> bool:
	if not guilds.has(guild_id):
		return false
	
	var member = _get_member(guild_id, player_id)
	if not member:
		return false
	
	# Лидер не может покинуть гильдию (должен передать лидерство или распустить)
	if member.rank == GuildRank.LEADER:
		return false
	
	var members = guild_members[guild_id]
	members.erase(member)
	player_guilds.erase(player_id)
	
	member_left.emit(guild_id, player_id)
	return true

## Изменить ранг члена
func change_member_rank(guild_id: String, changer_id: String, target_id: String, new_rank: GuildRank) -> bool:
	if not guilds.has(guild_id):
		return false
	
	var changer = _get_member(guild_id, changer_id)
	if not changer or GuildPermission.PROMOTE not in changer.permissions:
		return false
	
	var target = _get_member(guild_id, target_id)
	if not target:
		return false
	
	# Нельзя изменить ранг лидера
	if target.rank == GuildRank.LEADER:
		return false
	
	target.rank = new_rank
	target._permissions_for_rank(new_rank)
	
	member_rank_changed.emit(guild_id, target_id, new_rank)
	return true

## Добавить в казну гильдии
func deposit_to_treasury(guild_id: String, player_id: String, currency_type: CurrencySystem.CurrencyType, amount: int) -> bool:
	if not guilds.has(guild_id):
		return false
	
	var member = _get_member(guild_id, player_id)
	if not member or GuildPermission.DEPOSIT not in member.permissions:
		return false
	
	var guild = guilds[guild_id]
	var current = guild.treasury.get(currency_type, 0)
	guild.treasury[currency_type] = current + amount
	
	return true

## Получить гильдию игрока
func get_player_guild(player_id: String) -> GuildData:
	var guild_id = player_guilds.get(player_id, "")
	if guild_id == "":
		return null
	return guilds.get(guild_id, null)

## Получить членов гильдии
func get_guild_members(guild_id: String) -> Array[GuildMember]:
	return guild_members.get(guild_id, []).duplicate()

## Вспомогательная функция
func _get_member(guild_id: String, player_id: String) -> GuildMember:
	var members = guild_members.get(guild_id, [])
	for member in members:
		if member.player_id == player_id:
			return member
	return null

## Вычислить опыт гильдии
func add_guild_experience(guild_id: String, amount: float) -> void:
	if not guilds.has(guild_id):
		return
	
	var guild = guilds[guild_id]
	guild.experience += amount
	
	# Проверка повышения уровня
	var exp_needed = _get_experience_for_guild_level(guild.level + 1)
	while guild.experience >= exp_needed and guild.level < 50:
		guild.experience -= exp_needed
		guild.level += 1
		guild.member_limit += 2  # Увеличиваем лимит членов
		exp_needed = _get_experience_for_guild_level(guild.level + 1)

func _get_experience_for_guild_level(level: int) -> float:
	return 1000.0 * pow(level, 1.5)

