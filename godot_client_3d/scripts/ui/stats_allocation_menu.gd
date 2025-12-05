extends Control

## Меню распределения статов персонажа

@onready var free_points_label: Label = $VBox/FreePointsLabel
@onready var stats_container: VBoxContainer = $VBox/StatsContainer
@onready var close_button: Button = $VBox/CloseButton

var character_progression: CharacterProgression = null

var stat_widgets: Dictionary = {}  # stat_name -> Control

func _ready() -> void:
	UIThemeManager.apply_theme_to_control(self)
	_setup_background()
	
	close_button.pressed.connect(_on_close_pressed)
	
	# Получаем ссылку на систему прогрессии
	var world = get_tree().current_scene
	if world:
		character_progression = world.find_child("CharacterProgression", true, false)
	
	_create_stat_widgets()
	_update_display()

func _setup_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.1, 0.15, 1.0)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

func _create_stat_widgets() -> void:
	var stat_names = {
		"strength": {"name": "Сила", "description": "Урон в ближнем бою, переносимый вес"},
		"vitality": {"name": "Живучесть", "description": "Максимальное здоровье"},
		"agility": {"name": "Ловкость", "description": "Скорость движения, уклонение"},
		"stamina": {"name": "Выносливость", "description": "Максимальная стамина"},
		"focus": {"name": "Фокус", "description": "Скорость сбора ресурсов"},
		"intelligence": {"name": "Интеллект", "description": "Мана, эффективность крафта"},
		"perception": {"name": "Восприятие", "description": "Заметность врагов, точность"},
		"luck": {"name": "Удача", "description": "Шанс крита, качество дропа"}
	}
	
	for stat_id in stat_names.keys():
		var stat_info = stat_names[stat_id]
		var widget = _create_stat_widget(stat_id, stat_info)
		stats_container.add_child(widget)
		stat_widgets[stat_id] = widget

func _create_stat_widget(stat_id: String, stat_info: Dictionary) -> Control:
	var container := HBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 60)
	
	var vbox := VBoxContainer.new()
	
	var name_label := Label.new()
	name_label.text = "%s:" % stat_info.get("name", stat_id)
	name_label.theme_override_font_sizes/font_size = 18
	
	var desc_label := Label.new()
	desc_label.text = stat_info.get("description", "")
	desc_label.theme_override_font_sizes/font_size = 12
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	
	vbox.add_child(name_label)
	vbox.add_child(desc_label)
	
	var value_label := Label.new()
	value_label.name = "ValueLabel"
	value_label.text = "10"
	value_label.custom_minimum_size = Vector2(50, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	var minus_button := Button.new()
	minus_button.text = "-"
	minus_button.custom_minimum_size = Vector2(30, 0)
	minus_button.disabled = true
	minus_button.pressed.connect(func(): _on_stat_decrease(stat_id))
	
	var plus_button := Button.new()
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(30, 0)
	plus_button.name = "PlusButton"
	plus_button.pressed.connect(func(): _on_stat_increase(stat_id))
	
	container.add_child(vbox)
	container.add_child(Control.new())  # Spacer
	container.add_child(value_label)
	container.add_child(minus_button)
	container.add_child(plus_button)
	
	return container

func _update_display() -> void:
	if not character_progression:
		return
	
	# Обновляем свободные очки
	var free_points = character_progression.get_free_stat_points()
	free_points_label.text = "Свободных очков: %d" % free_points
	
	# Обновляем значения статов
	var all_stats = character_progression.get_all_stats()
	
	for stat_id in stat_widgets.keys():
		var widget = stat_widgets[stat_id]
		var value_label = widget.find_child("ValueLabel", true, false)
		var plus_button = widget.find_child("PlusButton", true, false)
		
		if value_label:
			value_label.text = str(all_stats.get(stat_id, 10))
		
		if plus_button:
			plus_button.disabled = free_points <= 0

func _on_stat_increase(stat_id: String) -> void:
	if character_progression and character_progression.allocate_stat(stat_id):
		_update_display()

func _on_stat_decrease(stat_id: String) -> void:
	# TODO: Реализовать снятие очков статов (если требуется)
	pass

func _on_close_pressed() -> void:
	queue_free()

