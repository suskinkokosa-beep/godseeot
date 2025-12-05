extends Node
class_name NotificationSystem

## Система уведомлений для Isleborn Online
## Централизованная система уведомлений игроку

enum NotificationType {
	INFO,           # Информация
	WARNING,        # Предупреждение
	ERROR,          # Ошибка
	SUCCESS,        # Успех
	QUEST,          # Квест
	ACHIEVEMENT,    # Достижение
	TRADE,          # Торговля
	COMBAT,         # Бой
	SYSTEM          # Системное
}

enum NotificationPriority {
	LOW,            # Низкий приоритет
	NORMAL,         # Обычный
	HIGH,           # Высокий
	CRITICAL        # Критический
}

class Notification:
	var notification_id: String
	var notification_type: NotificationType
	var priority: NotificationPriority
	var title: String
	var message: String
	var duration: float = 5.0  # Секунды
	var icon: String = ""
	var action: Dictionary = {}  # {type: "open_menu", target: "inventory"}
	var timestamp: int
	
	func _init(_id: String, _type: NotificationType, _title: String, _message: String):
		notification_id = _id
		notification_type = _type
		title = _title
		message = _message
		priority = NotificationPriority.NORMAL
		timestamp = Time.get_unix_time_from_system()

var active_notifications: Array[Notification] = []
var notification_history: Array[Notification] = []
var max_visible: int = 5
var max_history: int = 100

signal notification_shown(notification: Notification)
signal notification_dismissed(notification_id: String)
signal notification_clicked(notification: Notification)

func _ready() -> void:
	pass

func show_notification(notification_type: NotificationType, title: String, message: String, duration: float = 5.0, priority: NotificationPriority = NotificationPriority.NORMAL) -> String:
	var notification_id = "notif_%d" % Time.get_ticks_msec()
	var notification = Notification.new(notification_id, notification_type, title, message)
	notification.duration = duration
	notification.priority = priority
	notification.icon = _get_icon_for_type(notification_type)
	
	# Добавляем в активные
	active_notifications.append(notification)
	
	# Сортируем по приоритету
	active_notifications.sort_custom(func(a, b): return a.priority > b.priority)
	
	# Ограничиваем количество видимых
	if active_notifications.size() > max_visible:
		var removed = active_notifications.pop_back()
		notification_history.append(removed)
	
	notification_shown.emit(notification)
	
	# Автоматически удаляем через duration
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		dismiss_notification(notification_id)
	
	return notification_id

func dismiss_notification(notification_id: String) -> void:
	var index = -1
	for i in range(active_notifications.size()):
		if active_notifications[i].notification_id == notification_id:
			index = i
			break
	
	if index >= 0:
		var notification = active_notifications[index]
		active_notifications.remove_at(index)
		
		# Добавляем в историю
		notification_history.append(notification)
		if notification_history.size() > max_history:
			notification_history.pop_front()
		
		notification_dismissed.emit(notification_id)

func _get_icon_for_type(notification_type: NotificationType) -> String:
	match notification_type:
		NotificationType.INFO:
			return "info_icon"
		NotificationType.WARNING:
			return "warning_icon"
		NotificationType.ERROR:
			return "error_icon"
		NotificationType.SUCCESS:
			return "success_icon"
		NotificationType.QUEST:
			return "quest_icon"
		NotificationType.ACHIEVEMENT:
			return "achievement_icon"
		NotificationType.TRADE:
			return "trade_icon"
		NotificationType.COMBAT:
			return "combat_icon"
		NotificationType.SYSTEM:
			return "system_icon"
		_:
			return ""

func get_color_for_type(notification_type: NotificationType) -> Color:
	match notification_type:
		NotificationType.INFO:
			return Color(0.5, 0.7, 1.0)  # Синий
		NotificationType.WARNING:
			return Color(1.0, 0.8, 0.0)  # Жёлтый
		NotificationType.ERROR:
			return Color(1.0, 0.3, 0.3)  # Красный
		NotificationType.SUCCESS:
			return Color(0.3, 1.0, 0.5)  # Зелёный
		NotificationType.QUEST:
			return Color(0.8, 0.6, 1.0)  # Фиолетовый
		NotificationType.ACHIEVEMENT:
			return Color(1.0, 0.8, 0.0)  # Золотой
		NotificationType.TRADE:
			return Color(0.5, 1.0, 0.8)  # Бирюзовый
		NotificationType.COMBAT:
			return Color(1.0, 0.5, 0.5)  # Красно-розовый
		NotificationType.SYSTEM:
			return Color(0.7, 0.7, 0.7)  # Серый
		_:
			return Color.WHITE

func notify_quest_completed(quest_name: String) -> void:
	show_notification(NotificationType.QUEST, "Квест выполнен", "Квест '%s' завершён!" % quest_name, 5.0, NotificationPriority.HIGH)

func notify_achievement(achievement_name: String) -> void:
	show_notification(NotificationType.ACHIEVEMENT, "Достижение", "Разблокировано: %s" % achievement_name, 7.0, NotificationPriority.HIGH)

func notify_item_received(item_name: String, quantity: int = 1) -> void:
	var message = "Получено: %s" % item_name
	if quantity > 1:
		message += " x%d" % quantity
	show_notification(NotificationType.SUCCESS, "Предмет получен", message, 3.0, NotificationPriority.NORMAL)

func notify_level_up(new_level: int) -> void:
	show_notification(NotificationType.SUCCESS, "Уровень!", "Вы достигли уровня %d!" % new_level, 5.0, NotificationPriority.HIGH)

func notify_death(reason: String = "") -> void:
	var message = "Вы умерли"
	if reason != "":
		message += ": %s" % reason
	show_notification(NotificationType.ERROR, "Смерть", message, 5.0, NotificationPriority.CRITICAL)

func notify_trade_success(item_name: String, amount: int) -> void:
	show_notification(NotificationType.TRADE, "Торговля", "Продано: %s x%d" % [item_name, amount], 3.0, NotificationPriority.NORMAL)

func get_active_notifications() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for notification in active_notifications:
		result.append({
			"id": notification.notification_id,
			"type": notification.notification_type,
			"priority": notification.priority,
			"title": notification.title,
			"message": notification.message,
			"duration": notification.duration,
			"icon": notification.icon,
			"color": get_color_for_type(notification.notification_type),
			"timestamp": notification.timestamp
		})
	
	return result

func get_notification_history(limit: int = 20) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var start_index = max(0, notification_history.size() - limit)
	
	for i in range(start_index, notification_history.size()):
		var notification = notification_history[i]
		result.append({
			"id": notification.notification_id,
			"type": notification.notification_type,
			"title": notification.title,
			"message": notification.message,
			"timestamp": notification.timestamp
		})
	
	return result

