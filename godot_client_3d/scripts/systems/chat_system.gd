extends Node
class_name ChatSystem

## Система чата для Isleborn Online
## Согласно GDD: глобальный чат, локальный чат, гильдейский чат, личные сообщения

enum ChatChannel {
	GLOBAL,         # Глобальный чат
	LOCAL,          # Локальный (по дистанции)
	GUILD,          # Гильдейский
	WHISPER,        # Шёпот (личные сообщения)
	SYSTEM,         # Системные сообщения
	TRADE           # Торговый чат
}

class ChatMessage:
	var message_id: String
	var sender_id: String
	var sender_name: String
	var channel: ChatChannel
	var message: String
	var timestamp: int
	var color: Color = Color.WHITE
	
	func _init(_id: String, _sender: String, _name: String, _channel: ChatChannel, _msg: String):
		message_id = _id
		sender_id = _sender
		sender_name = _name
		channel = _channel
		message = _msg
		timestamp = Time.get_unix_time_from_system()

var message_history: Array[ChatMessage] = []
var max_history_size: int = 100
var muted_players: Array[String] = []
var active_channels: Array[ChatChannel] = [ChatChannel.GLOBAL, ChatChannel.LOCAL, ChatChannel.SYSTEM]

signal message_received(message: ChatMessage)
signal system_message(message: String)

func _ready() -> void:
	pass

func send_message(channel: ChatChannel, message: String, target_id: String = "") -> bool:
	var player_id = _get_local_player_id()
	var player_name = _get_local_player_name()
	
	if player_id == "":
		return false
	
	# Фильтрация спама
	if not _check_spam_protection(message):
		return false
	
	# Создаём сообщение
	var msg_id = "msg_%d" % Time.get_ticks_msec()
	var chat_msg = ChatMessage.new(msg_id, player_id, player_name, channel, message)
	
	# Устанавливаем цвет в зависимости от канала
	chat_msg.color = _get_channel_color(channel)
	
	# Добавляем в историю
	_add_message_to_history(chat_msg)
	
	# Отправляем на сервер
	_send_message_to_server(chat_msg, target_id)
	
	message_received.emit(chat_msg)
	return true

func receive_message(msg_data: Dictionary) -> void:
	var sender_id = msg_data.get("sender_id", "")
	var sender_name = msg_data.get("sender_name", "Unknown")
	var channel = msg_data.get("channel", ChatChannel.GLOBAL)
	var message = msg_data.get("message", "")
	
	# Проверяем, не заблокирован ли отправитель
	if sender_id in muted_players:
		return
	
	var msg_id = "msg_%d" % Time.get_ticks_msec()
	var chat_msg = ChatMessage.new(msg_id, sender_id, sender_name, channel, message)
	chat_msg.color = _get_channel_color(channel)
	
	_add_message_to_history(chat_msg)
	message_received.emit(chat_msg)

func send_system_message(message: String, color: Color = Color.YELLOW) -> void:
	var msg_id = "sys_%d" % Time.get_ticks_msec()
	var sys_msg = ChatMessage.new(msg_id, "system", "Система", ChatChannel.SYSTEM, message)
	sys_msg.color = color
	
	_add_message_to_history(sys_msg)
	system_message.emit(message)
	message_received.emit(sys_msg)

func get_message_history(channel: ChatChannel = ChatChannel.GLOBAL, limit: int = 50) -> Array[ChatMessage]:
	var result: Array[ChatMessage] = []
	var count = 0
	
	for i in range(message_history.size() - 1, -1, -1):
		var msg = message_history[i]
		if channel == ChatChannel.GLOBAL or msg.channel == channel:
			result.append(msg)
			count += 1
			if count >= limit:
				break
	
	result.reverse()
	return result

func mute_player(player_id: String) -> void:
	if player_id not in muted_players:
		muted_players.append(player_id)

func unmute_player(player_id: String) -> void:
	var index = muted_players.find(player_id)
	if index >= 0:
		muted_players.remove_at(index)

func set_channel_active(channel: ChatChannel, active: bool) -> void:
	if active:
		if channel not in active_channels:
			active_channels.append(channel)
	else:
		var index = active_channels.find(channel)
		if index >= 0:
			active_channels.remove_at(index)

func _add_message_to_history(message: ChatMessage) -> void:
	message_history.append(message)
	
	# Ограничиваем размер истории
	if message_history.size() > max_history_size:
		message_history.remove_at(0)

func _send_message_to_server(message: ChatMessage, target_id: String) -> void:
	# TODO: Отправить на сервер через WebSocket
	var world = get_tree().current_scene
	if world:
		# Находим WebSocket соединение и отправляем
		pass

func _get_channel_color(channel: ChatChannel) -> Color:
	match channel:
		ChatChannel.GLOBAL:
			return Color(0.8, 0.8, 0.8)  # Серый
		ChatChannel.LOCAL:
			return Color(0.6, 0.8, 1.0)  # Голубой
		ChatChannel.GUILD:
			return Color(0.4, 0.8, 0.4)  # Зелёный
		ChatChannel.WHISPER:
			return Color(1.0, 0.8, 0.6)  # Жёлтый
		ChatChannel.SYSTEM:
			return Color(1.0, 0.9, 0.3)  # Золотой
		ChatChannel.TRADE:
			return Color(0.8, 0.6, 1.0)  # Фиолетовый
		_:
			return Color.WHITE

func _check_spam_protection(message: String) -> bool:
	# Простая защита от спама
	if message.length() < 1:
		return false
	
	if message.length() > 200:
		return false  # Слишком длинное сообщение
	
	# Проверяем частоту сообщений (можно добавить проверку времени)
	return true

func _get_local_player_id() -> String:
	# TODO: Получить ID локального игрока
	return ""

func _get_local_player_name() -> String:
	# TODO: Получить имя локального игрока
	return "Player"

