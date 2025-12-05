extends Control

## Меню управления экспедициями

@onready var active_list: VBoxContainer = $VBox/HBox/ActiveExpeditionsPanel/VBoxActive/ActiveList/ActiveItems
@onready var type_option: OptionButton = $VBox/HBox/CreatePanel/VBoxCreate/TypeOption
@onready var duration_spinbox: SpinBox = $VBox/HBox/CreatePanel/VBoxCreate/DurationSpinBox
@onready var create_button: Button = $VBox/HBox/CreatePanel/VBoxCreate/CreateButton
@onready var close_button: Button = $VBox/CloseButton

var expedition_system: ExpeditionSystem = null
var player_id: String = ""

func _ready() -> void:
	UIThemeManager.apply_theme_to_control(self)
	_setup_background()
	
	close_button.pressed.connect(_on_close_pressed)
	create_button.pressed.connect(_on_create_pressed)
	
	# Получаем ссылки на системы
	var world = get_tree().current_scene
	if world:
		expedition_system = world.find_child("ExpeditionSystem", true, false)
	
	_populate_type_options()
	_update_display()

func setup(player_id_param: String) -> void:
	player_id = player_id_param
	_update_display()

func _setup_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.1, 0.15, 1.0)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

func _populate_type_options() -> void:
	type_option.add_item("Собрать ресурсы")
	type_option.add_item("Исследовать биом")
	type_option.add_item("Охота на монстров")
	type_option.add_item("Поиск сокровищ")
	type_option.add_item("Торговый маршрут")
	type_option.add_item("Blackwater разлом")

func _update_display() -> void:
	_update_active_expeditions()

func _update_active_expeditions() -> void:
	# Очищаем список
	for child in active_list.get_children():
		child.queue_free()
	
	if not expedition_system or player_id == "":
		return
	
	var expeditions = expedition_system.get_player_expeditions(player_id)
	for expedition in expeditions:
		if expedition.is_active():
			var widget = _create_expedition_widget(expedition)
			active_list.add_child(widget)

func _create_expedition_widget(expedition: ExpeditionSystem.ExpeditionData) -> Control:
	var container := VBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 100)
	
	var name_label := Label.new()
	name_label.text = _get_expedition_type_name(expedition.expedition_type)
	name_label.theme_override_font_sizes/font_size = 16
	
	var progress_label := Label.new()
	progress_label.text = "Прогресс: %.0f%%" % expedition.get_progress_percent()
	
	var time_label := Label.new()
	var remaining = expedition.get_remaining_time_seconds()
	var hours = remaining / 3600
	var minutes = (remaining % 3600) / 60
	time_label.text = "Осталось: %dч %dм" % [hours, minutes]
	
	var progress_bar := ProgressBar.new()
	progress_bar.max_value = 100.0
	progress_bar.value = expedition.get_progress_percent()
	progress_bar.custom_minimum_size = Vector2(0, 30)
	
	container.add_child(name_label)
	container.add_child(progress_label)
	container.add_child(time_label)
	container.add_child(progress_bar)
	
	return container

func _get_expedition_type_name(expedition_type: ExpeditionSystem.ExpeditionType) -> String:
	match expedition_type:
		ExpeditionSystem.ExpeditionType.GATHER_RESOURCES:
			return "Сбор ресурсов"
		ExpeditionSystem.ExpeditionType.EXPLORE_BIOME:
			return "Исследование биома"
		ExpeditionSystem.ExpeditionType.HUNT_MONSTERS:
			return "Охота на монстров"
		ExpeditionSystem.ExpeditionType.FIND_TREASURE:
			return "Поиск сокровищ"
		ExpeditionSystem.ExpeditionType.TRADE_ROUTE:
			return "Торговый маршрут"
		ExpeditionSystem.ExpeditionType.BLACKWATER_RIFT:
			return "Blackwater разлом"
		_:
			return "Неизвестно"

func _on_create_pressed() -> void:
	if not expedition_system:
		return
	
	var selected_type = type_option.selected
	var duration = duration_spinbox.value
	
	var expedition_type: ExpeditionSystem.ExpeditionType
	match selected_type:
		0:
			expedition_type = ExpeditionSystem.ExpeditionType.GATHER_RESOURCES
		1:
			expedition_type = ExpeditionSystem.ExpeditionType.EXPLORE_BIOME
		2:
			expedition_type = ExpeditionSystem.ExpeditionType.HUNT_MONSTERS
		3:
			expedition_type = ExpeditionSystem.ExpeditionType.FIND_TREASURE
		4:
			expedition_type = ExpeditionSystem.ExpeditionType.TRADE_ROUTE
		5:
			expedition_type = ExpeditionSystem.ExpeditionType.BLACKWATER_RIFT
	
	var destination = {"x": 0.0, "y": 0.0, "biome": "tropical_shallow"}
	var expedition = expedition_system.create_expedition(player_id, expedition_type, destination, duration)
	
	# TODO: Добавить корабли и NPC
	
	if expedition_system.start_expedition(expedition.id):
		_update_display()

func _on_close_pressed() -> void:
	queue_free()

