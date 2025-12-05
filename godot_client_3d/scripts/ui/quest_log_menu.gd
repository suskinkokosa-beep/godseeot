extends Control

## Меню журнала квестов

@onready var available_list: VBoxContainer = $VBox/TabContainer/Available/AvailableQuests/QuestsList
@onready var active_list: VBoxContainer = $VBox/TabContainer/Active/ActiveQuests/ActiveList
@onready var close_button: Button = $VBox/CloseButton

var quest_system: QuestSystem = null

func _ready() -> void:
	UIThemeManager.apply_theme_to_control(self)
	_setup_background()
	
	close_button.pressed.connect(_on_close_pressed)
	
	# Получаем ссылку на систему квестов
	var world = get_tree().current_scene
	if world:
		quest_system = world.find_child("QuestSystem", true, false)
	
	_update_display()

func _setup_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.1, 0.15, 1.0)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

func _update_display() -> void:
	if not quest_system:
		return
	
	_update_available_quests()
	_update_active_quests()

func _update_available_quests() -> void:
	# Очищаем список
	for child in available_list.get_children():
		child.queue_free()
	
	if not quest_system:
		return
	
	var available = quest_system.get_available_quests()
	for quest_id in available.keys():
		var quest = available[quest_id]
		var widget = _create_quest_widget(quest, false)
		available_list.add_child(widget)

func _update_active_quests() -> void:
	# Очищаем список
	for child in active_list.get_children():
		child.queue_free()
	
	if not quest_system:
		return
	
	var active = quest_system.get_active_quests()
	for quest_id in active.keys():
		var quest = active[quest_id]
		var widget = _create_quest_widget(quest, true)
		active_list.add_child(widget)

func _create_quest_widget(quest: QuestSystem.QuestData, is_active: bool) -> Control:
	var container := VBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 100)
	
	var name_label := Label.new()
	name_label.text = quest.name
	name_label.theme_override_font_sizes/font_size = 18
	
	var desc_label := Label.new()
	desc_label.text = quest.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	container.add_child(name_label)
	container.add_child(desc_label)
	
	# Показываем прогресс для активных квестов
	if is_active:
		var current_objective = quest.get_current_objective()
		if not current_objective.is_empty():
			var progress_label := Label.new()
			var current = current_objective.get("current", 0)
			var required = current_objective.get("required", 0)
			progress_label.text = "Прогресс: %d / %d" % [current, required]
			container.add_child(progress_label)
		
		# Кнопка отмены
		var cancel_button := Button.new()
		cancel_button.text = "Отменить"
		cancel_button.pressed.connect(func(): _on_cancel_quest(quest.id))
		container.add_child(cancel_button)
	else:
		# Кнопка принятия
		var accept_button := Button.new()
		accept_button.text = "Принять"
		accept_button.pressed.connect(func(): _on_accept_quest(quest.id))
		container.add_child(accept_button)
	
	return container

func _on_accept_quest(quest_id: String) -> void:
	if quest_system and quest_system.accept_quest(quest_id):
		_update_display()

func _on_cancel_quest(quest_id: String) -> void:
	# TODO: Реализовать отмену квеста
	pass

func _on_close_pressed() -> void:
	queue_free()

