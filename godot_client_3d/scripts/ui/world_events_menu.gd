extends Control

## Меню мировых событий

@onready var events_list: VBoxContainer = $VBox/EventsList/EventsItems
@onready var close_button: Button = $VBox/CloseButton

var world_events_system: WorldEventsSystem = null
var player_id: String = ""

func _ready() -> void:
	UIThemeManager.apply_theme_to_control(self)
	_setup_background()
	
	close_button.pressed.connect(_on_close_pressed)
	
	# Получаем ссылки на системы
	var world = get_tree().current_scene
	if world:
		world_events_system = world.find_child("WorldEventsSystem", true, false)
	
	if world_events_system:
		world_events_system.event_started.connect(_on_event_started)
		world_events_system.event_completed.connect(_on_event_completed)
	
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
	_update_events_list()

func _update_events_list() -> void:
	# Очищаем список
	for child in events_list.get_children():
		child.queue_free()
	
	if not world_events_system:
		return
	
	var active_events = world_events_system.get_active_events()
	for event in active_events:
		var widget = _create_event_widget(event)
		events_list.add_child(widget)

func _create_event_widget(event: WorldEventsSystem.WorldEventData) -> Control:
	var container := VBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 150)
	
	var name_label := Label.new()
	name_label.text = event.name
	name_label.theme_override_font_sizes/font_size = 20
	
	var desc_label := Label.new()
	desc_label.text = event.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	var status_label := Label.new()
	match event.status:
		WorldEventsSystem.EventStatus.ANNOUNCED:
			status_label.text = "Объявлено"
		WorldEventsSystem.EventStatus.ACTIVE:
			status_label.text = "Активно"
		WorldEventsSystem.EventStatus.FADING:
			status_label.text = "Затухает"
		WorldEventsSystem.EventStatus.COMPLETED:
			status_label.text = "Завершено"
	
	var time_label := Label.new()
	if event.is_active():
		var remaining = event.get_remaining_time_seconds()
		var minutes = remaining / 60
		var seconds = remaining % 60
		time_label.text = "Осталось: %dм %dс" % [minutes, seconds]
	else:
		time_label.text = "Скоро начнётся"
	
	var join_button := Button.new()
	join_button.text = "Присоединиться"
	join_button.disabled = not event.is_active()
	join_button.pressed.connect(func(): _on_join_event(event.id))
	
	container.add_child(name_label)
	container.add_child(desc_label)
	container.add_child(status_label)
	container.add_child(time_label)
	container.add_child(join_button)
	
	return container

func _on_join_event(event_id: String) -> void:
	if world_events_system and player_id != "":
		world_events_system.join_event(event_id, player_id)
		_update_display()

func _on_event_started(event_id: String, event: WorldEventsSystem.WorldEventData) -> void:
	_update_display()

func _on_event_completed(event_id: String, event: WorldEventsSystem.WorldEventData) -> void:
	_update_display()

func _on_close_pressed() -> void:
	queue_free()

