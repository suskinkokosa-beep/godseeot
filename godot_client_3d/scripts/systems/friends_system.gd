extends Node
class_name FriendsSystem

## Система друзей для Isleborn Online
## Управление списком друзей, онлайн статус, приглашения

enum FriendStatus {
	OFFLINE,        # Оффлайн
	ONLINE,         # Онлайн
	IN_GAME,        # В игре
	AWAY,           # Отошёл
	IN_RAID,        # В рейде
	IN_DUNGEON      # В подземелье
}

enum FriendRequestStatus {
	PENDING,        # Ожидает
	ACCEPTED,       # Принято
	DECLINED,       # Отклонено
	BLOCKED         # Заблокировано
}

class FriendData:
	var friend_id: String
	var friend_name: String
	var status: FriendStatus = FriendStatus.OFFLINE
	var level: int = 1
	var last_seen: int = 0
	var notes: String = ""
	var favorite: bool = false
	var relationship_time: int = 0  # Когда стали друзьями
	
	func _init(_id: String, _name: String):
		friend_id = _id
		friend_name = _name
		relationship_time = Time.get_unix_time_from_system()

class FriendRequest:
	var request_id: String
	var from_id: String
	var from_name: String
	var to_id: String
	var status: FriendRequestStatus = FriendRequestStatus.PENDING
	var created_at: int
	
	func _init(_id: String, _from: String, _from_name: String, _to: String):
		request_id = _id
		from_id = _from
		from_name = _from_name
		to_id = _to
		created_at = Time.get_unix_time_from_system()

var friends: Dictionary = {}  # friend_id -> FriendData
var friend_requests: Dictionary = {}  # request_id -> FriendRequest
var blocked_players: Array[String] = []  # player_ids

signal friend_added(friend_id: String, friend: FriendData)
signal friend_removed(friend_id: String)
signal friend_status_changed(friend_id: String, new_status: FriendStatus)
signal friend_request_received(request: FriendRequest)
signal friend_request_accepted(request_id: String)
signal friend_request_declined(request_id: String)

func _ready() -> void:
	pass

func send_friend_request(target_player_id: String, target_player_name: String) -> String:
	# Проверяем, не заблокирован ли игрок
	if target_player_id in blocked_players:
		return ""
	
	# Проверяем, не друзья ли уже
	if friends.has(target_player_id):
		return ""
	
	# Проверяем, нет ли уже запроса
	for request_id in friend_requests.keys():
		var request = friend_requests[request_id]
		if request.from_id == _get_local_player_id() and request.to_id == target_player_id:
			if request.status == FriendRequestStatus.PENDING:
				return ""  # Уже отправлен
	
	var request_id = "friend_request_%d" % Time.get_ticks_msec()
	var request = FriendRequest.new(request_id, _get_local_player_id(), _get_local_player_name(), target_player_id)
	
	friend_requests[request_id] = request
	
	# TODO: Отправить запрос на сервер
	# Если это локальный запрос (оба игрока у нас), обрабатываем сразу
	if target_player_id.begins_with("local_"):
		friend_request_received.emit(request)
	
	return request_id

func accept_friend_request(request_id: String) -> bool:
	if not friend_requests.has(request_id):
		return false
	
	var request = friend_requests[request_id]
	
	if request.status != FriendRequestStatus.PENDING:
		return false
	
	# Проверяем, что запрос адресован нам
	if request.to_id != _get_local_player_id():
		return false
	
	request.status = FriendRequestStatus.ACCEPTED
	
	# Добавляем в друзья (взаимно)
	var friend = FriendData.new(request.from_id, request.from_name)
	friends[request.from_id] = friend
	
	friend_added.emit(request.from_id, friend)
	friend_request_accepted.emit(request_id)
	
	return true

func decline_friend_request(request_id: String) -> bool:
	if not friend_requests.has(request_id):
		return false
	
	var request = friend_requests[request_id]
	
	if request.status != FriendRequestStatus.PENDING:
		return false
	
	request.status = FriendRequestStatus.DECLINED
	friend_request_declined.emit(request_id)
	
	# Удаляем запрос через некоторое время
	await get_tree().create_timer(10.0).timeout
	friend_requests.erase(request_id)
	
	return true

func remove_friend(friend_id: String) -> void:
	if not friends.has(friend_id):
		return
	
	friends.erase(friend_id)
	friend_removed.emit(friend_id)
	
	# TODO: Уведомить друга о удалении

func block_player(player_id: String) -> void:
	if player_id not in blocked_players:
		blocked_players.append(player_id)
	
	# Удаляем из друзей, если был
	if friends.has(player_id):
		remove_friend(player_id)
	
	# Отклоняем все запросы от этого игрока
	for request_id in friend_requests.keys():
		var request = friend_requests[request_id]
		if request.from_id == player_id:
			request.status = FriendRequestStatus.BLOCKED

func unblock_player(player_id: String) -> void:
	var index = blocked_players.find(player_id)
	if index >= 0:
		blocked_players.remove_at(index)

func update_friend_status(friend_id: String, status: FriendStatus, level: int = -1) -> void:
	if not friends.has(friend_id):
		return
	
	var friend = friends[friend_id]
	var old_status = friend.status
	
	friend.status = status
	friend.last_seen = Time.get_unix_time_from_system()
	
	if level > 0:
		friend.level = level
	
	if old_status != status:
		friend_status_changed.emit(friend_id, status)

func set_friend_notes(friend_id: String, notes: String) -> void:
	if friends.has(friend_id):
		friends[friend_id].notes = notes

func set_friend_favorite(friend_id: String, favorite: bool) -> void:
	if friends.has(friend_id):
		friends[friend_id].favorite = favorite

func get_online_friends() -> Array[FriendData]:
	var result: Array[FriendData] = []
	
	for friend_id in friends.keys():
		var friend = friends[friend_id]
		if friend.status != FriendStatus.OFFLINE:
			result.append(friend)
	
	return result

func get_friend_list() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for friend_id in friends.keys():
		var friend = friends[friend_id]
		result.append({
			"id": friend.friend_id,
			"name": friend.friend_name,
			"status": friend.status,
			"level": friend.level,
			"last_seen": friend.last_seen,
			"notes": friend.notes,
			"favorite": friend.favorite
		})
	
	# Сортируем: сначала избранные, потом онлайн, потом оффлайн
	result.sort_custom(func(a, b):
		if a["favorite"] != b["favorite"]:
			return a["favorite"]
		if a["status"] == FriendStatus.OFFLINE and b["status"] != FriendStatus.OFFLINE:
			return false
		if a["status"] != FriendStatus.OFFLINE and b["status"] == FriendStatus.OFFLINE:
			return true
		return a["name"] < b["name"]
	)
	
	return result

func get_pending_requests() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for request_id in friend_requests.keys():
		var request = friend_requests[request_id]
		if request.status == FriendRequestStatus.PENDING:
			if request.to_id == _get_local_player_id():
				# Входящие запросы
				result.append({
					"id": request.request_id,
					"from_id": request.from_id,
					"from_name": request.from_name,
					"type": "incoming"
				})
	
	return result

func _get_local_player_id() -> String:
	# TODO: Получить ID локального игрока
	return ""

func _get_local_player_name() -> String:
	# TODO: Получить имя локального игрока
	return "Player"

