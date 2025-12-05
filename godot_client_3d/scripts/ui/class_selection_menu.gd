extends Control

## Меню выбора класса на 10 уровне

@onready var classes_container: HBoxContainer = $VBox/ClassesContainer
@onready var confirm_button: Button = $VBox/ConfirmButton
@onready var cancel_button: Button = $VBox/CancelButton

var selected_class: CharacterClass.Archetype = CharacterClass.Archetype.NONE
var class_widgets: Array[Control] = []

var character_progression: CharacterProgression = null

func _ready() -> void:
	UIThemeManager.apply_theme_to_control(self)
	_setup_background()
	_create_class_widgets()
	
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

func _setup_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.1, 0.15, 1.0)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

func _create_class_widgets() -> void:
	var classes = [
		{
			"archetype": CharacterClass.Archetype.GATHERER,
			"name": "Собиратель",
			"icon": "🔍",
			"description": "Мастер добычи ресурсов"
		},
		{
			"archetype": CharacterClass.Archetype.FIGHTER,
			"name": "Боец",
			"icon": "⚔️",
			"description": "Великий воин ближнего боя"
		},
		{
			"archetype": CharacterClass.Archetype.RANGER,
			"name": "Стрелок",
			"icon": "🏹",
			"description": "Мастер дальнего боя"
		},
		{
			"archetype": CharacterClass.Archetype.SAILOR,
			"name": "Моряк",
			"icon": "⛵",
			"description": "Искусный мореплаватель"
		},
		{
			"archetype": CharacterClass.Archetype.ALCHEMIST,
			"name": "Алхимик",
			"icon": "⚗️",
			"description": "Мастер зелий"
		},
		{
			"archetype": CharacterClass.Archetype.MYSTIC,
			"name": "Мистик",
			"icon": "✨",
			"description": "Владелец магии океана"
		},
		{
			"archetype": CharacterClass.Archetype.BUILDER,
			"name": "Строитель",
			"icon": "🏗️",
			"description": "Мастер строительства"
		}
	]
	
	for class_data in classes:
		var widget := _create_class_widget(class_data)
		classes_container.add_child(widget)
		class_widgets.append(widget)

func _create_class_widget(class_data: Dictionary) -> Control:
	var container := VBoxContainer.new()
	container.custom_minimum_size = Vector2(200, 300)
	
	var button := Button.new()
	button.text = "%s\n%s" % [class_data.get("icon", ""), class_data.get("name", "")]
	button.custom_minimum_size = Vector2(180, 100)
	
	var desc_label := Label.new()
	desc_label.text = class_data.get("description", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	container.add_child(button)
	container.add_child(desc_label)
	
	button.pressed.connect(func(): _on_class_selected(class_data.get("archetype", CharacterClass.Archetype.NONE)))
	
	return container

func _on_class_selected(archetype: CharacterClass.Archetype) -> void:
	selected_class = archetype
	confirm_button.disabled = false
	
	# Подсвечиваем выбранный класс
	for widget in class_widgets:
		pass  # TODO: Визуальная обратная связь

func _on_confirm_pressed() -> void:
	if selected_class == CharacterClass.Archetype.NONE:
		return
	
	if character_progression:
		if character_progression.select_class(selected_class):
			# Класс выбран, закрываем меню
			get_tree().change_scene_to_file("res://scenes/main/world.tscn")
		else:
			print("Ошибка выбора класса")

func _on_cancel_pressed() -> void:
	# Можно выбрать позже
	get_tree().change_scene_to_file("res://scenes/main/world.tscn")

