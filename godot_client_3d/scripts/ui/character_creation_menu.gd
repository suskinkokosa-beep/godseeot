extends Control

@onready var name_edit: LineEdit = $VBox/HBox/MainPanel/VBox/NameEdit
@onready var preview_panel: Control = $VBox/HBox/PreviewPanel
@onready var color_picker: ColorPickerButton = $VBox/HBox/MainPanel/VBox/Appearance/VBox/ColorPicker
@onready var skin_tone_slider: HSlider = $VBox/HBox/MainPanel/VBox/Appearance/VBox/SkinToneSlider
@onready var hair_style_opt: OptionButton = $VBox/HBox/MainPanel/VBox/Appearance/VBox/HairStyleOption
@onready var hair_color_picker: ColorPickerButton = $VBox/HBox/MainPanel/VBox/Appearance/VBox/HairColorPicker
@onready var eye_color_picker: ColorPickerButton = $VBox/HBox/MainPanel/VBox/Appearance/VBox/EyeColorPicker
@onready var body_type_opt: OptionButton = $VBox/HBox/MainPanel/VBox/Appearance/VBox/BodyTypeOption
@onready var height_slider: HSlider = $VBox/HBox/MainPanel/VBox/Appearance/VBox/HeightSlider

var appearance_data: Dictionary = {}

func _ready() -> void:
	UIThemeManager.apply_theme_to_control(self)
	_setup_background()
	_setup_appearance_options()
	_initialize_defaults()
	_setup_preview()
	
	$VBox/HBox/MainPanel/VBox/StartButton.pressed.connect(_on_start_pressed)
	$VBox/HBox/MainPanel/VBox/CancelButton.pressed.connect(_on_cancel_pressed)

func _setup_appearance_options() -> void:
	# Стили волос
	hair_style_opt.clear()
	hair_style_opt.add_item("Короткие", 0)
	hair_style_opt.add_item("Средние", 1)
	hair_style_opt.add_item("Длинные", 2)
	hair_style_opt.add_item("Косички", 3)
	hair_style_opt.add_item("Хвост", 4)
	
	# Тип телосложения
	body_type_opt.clear()
	body_type_opt.add_item("Стройное", 0)
	body_type_opt.add_item("Среднее", 1)
	body_type_opt.add_item("Крепкое", 2)
	
	# Подключаем сигналы
	color_picker.color_changed.connect(_on_color_changed)
	skin_tone_slider.value_changed.connect(_on_skin_tone_changed)
	hair_style_opt.item_selected.connect(_on_hair_style_changed)
	hair_color_picker.color_changed.connect(_on_hair_color_changed)
	eye_color_picker.color_changed.connect(_on_eye_color_changed)
	body_type_opt.item_selected.connect(_on_body_type_changed)
	height_slider.value_changed.connect(_on_height_changed)

func _initialize_defaults() -> void:
	appearance_data = {
		"primary_color": Color(0.2, 0.4, 0.6),  # Ocean Blue
		"skin_tone": 0.5,
		"hair_style": 0,
		"hair_color": Color(0.3, 0.2, 0.1),  # Коричневый
		"eye_color": Color(0.4, 0.6, 0.8),  # Голубой
		"body_type": 1,
		"height": 1.0
	}
	
	# Устанавливаем значения по умолчанию
	color_picker.color = appearance_data["primary_color"]
	skin_tone_slider.value = appearance_data["skin_tone"]
	hair_style_opt.selected = appearance_data["hair_style"]
	hair_color_picker.color = appearance_data["hair_color"]
	eye_color_picker.color = appearance_data["eye_color"]
	body_type_opt.selected = appearance_data["body_type"]
	height_slider.value = appearance_data["height"]

func _setup_preview() -> void:
	# TODO: Создать 3D превью персонажа
	pass

func _on_color_changed(color: Color) -> void:
	appearance_data["primary_color"] = color
	_update_preview()

func _on_skin_tone_changed(value: float) -> void:
	appearance_data["skin_tone"] = value
	_update_preview()

func _on_hair_style_changed(index: int) -> void:
	appearance_data["hair_style"] = index
	_update_preview()

func _on_hair_color_changed(color: Color) -> void:
	appearance_data["hair_color"] = color
	_update_preview()

func _on_eye_color_changed(color: Color) -> void:
	appearance_data["eye_color"] = color
	_update_preview()

func _on_body_type_changed(index: int) -> void:
	appearance_data["body_type"] = index
	_update_preview()

func _on_height_changed(value: float) -> void:
	appearance_data["height"] = value
	_update_preview()

func _update_preview() -> void:
	# TODO: Обновить 3D превью персонажа
	pass

func _setup_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.1, 0.15, 1.0)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)


func _on_start_pressed() -> void:
	var name := name_edit.text.strip_edges()
	if name == "":
		name = "Sailor"

	Auth.character_name = name

	var app := {}
	app["color"] = color_opt.get_selected_id()
	app["style"] = style_opt.get_selected_id()
	Auth.appearance = app

	get_tree().change_scene_to_file("res://scenes/main/world.tscn")

