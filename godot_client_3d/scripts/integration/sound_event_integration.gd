extends Node
class_name SoundEventIntegration

## Интеграция звуков в игровые события

var sound_integration: SoundIntegration = null

func _ready() -> void:
	var world = get_tree().current_scene
	if world:
		sound_integration = world.find_child("SoundIntegration", true, false)
	
	# Подключаемся к сигналам систем
	_connect_to_systems()

func _connect_to_systems() -> void:
	var world = get_tree().current_scene
	if not world:
		return
	
	# Квесты
	var quest_system = world.find_child("QuestSystem", true, false)
	if quest_system:
		quest_system.quest_completed.connect(_on_quest_completed)
	
	# Достижения
	var achievement_system = world.find_child("AchievementSystem", true, false)
	if achievement_system:
		achievement_system.achievement_unlocked.connect(_on_achievement_unlocked)
	
	# Уведомления
	var notification_system = world.find_child("NotificationSystem", true, false)
	if notification_system:
		notification_system.notification_shown.connect(_on_notification_shown)
	
	# Смерть
	var death_system = world.find_child("DeathPenaltySystem", true, false)
	if death_system:
		death_system.player_died.connect(_on_player_died)

func _on_quest_completed(quest_id: String) -> void:
	if sound_integration:
		sound_integration.play_ui_sound("quest_complete")

func _on_achievement_unlocked(achievement_id: String, achievement) -> void:
	if sound_integration:
		sound_integration.play_ui_sound("achievement")

func _on_notification_shown(notification) -> void:
	if sound_integration:
		match notification.notification_type:
			NotificationSystem.NotificationType.SUCCESS:
				sound_integration.play_ui_sound("success")
			NotificationSystem.NotificationType.ERROR:
				sound_integration.play_ui_sound("error")
			NotificationSystem.NotificationType.WARNING:
				sound_integration.play_ui_sound("warning")
			_:
				sound_integration.play_ui_sound("notification")

func _on_player_died(death_type, penalties) -> void:
	if sound_integration:
		sound_integration.play_combat_sound("death")

