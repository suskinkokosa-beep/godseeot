extends Control
class_name QuickAccessMenu

## Панель быстрого доступа для меню игры

@onready var inventory_button: Button = $HBox/InventoryButton
@onready var crafting_button: Button = $HBox/CraftingButton
@onready var quest_button: Button = $HBox/QuestButton
@onready var map_button: Button = $HBox/MapButton
@onready var settings_button: Button = $HBox/SettingsButton
@onready var character_button: Button = $HBox/CharacterButton
@onready var island_button: Button = $HBox/IslandButton
@onready var ship_button: Button = $HBox/ShipButton

var menu_scenes: Dictionary = {}

signal menu_opened(menu_name: String)
signal menu_closed(menu_name: String)

func _ready() -> void:
	_setup_menu_scenes()
	_connect_buttons()
	_apply_theme()

func _setup_menu_scenes() -> void:
	menu_scenes["inventory"] = "res://scenes/ui/inventory_menu.tscn"
	menu_scenes["crafting"] = "res://scenes/ui/crafting_menu.tscn"
	menu_scenes["quest"] = "res://scenes/ui/quest_menu.tscn"
	menu_scenes["map"] = "res://scenes/ui/map_menu.tscn"
	menu_scenes["settings"] = "res://scenes/ui/settings_menu.tscn"
	menu_scenes["character"] = "res://scenes/ui/character_menu.tscn"
	menu_scenes["island"] = "res://scenes/ui/island_menu.tscn"
	menu_scenes["ship"] = "res://scenes/ui/ship_menu.tscn"
	menu_scenes["donate_shop"] = "res://scenes/ui/donate_shop_menu.tscn"

func _connect_buttons() -> void:
	inventory_button.pressed.connect(func(): _open_menu("inventory"))
	crafting_button.pressed.connect(func(): _open_menu("crafting"))
	quest_button.pressed.connect(func(): _open_menu("quest"))
	map_button.pressed.connect(func(): _open_menu("map"))
	settings_button.pressed.connect(func(): _open_menu("settings"))
	character_button.pressed.connect(func(): _open_menu("character"))
	island_button.pressed.connect(func(): _open_menu("island"))
	ship_button.pressed.connect(func(): _open_menu("ship"))

func _apply_theme() -> void:
	UIThemeManager.apply_theme_to_control(self)
	
	# Настраиваем кнопки
	var buttons = [inventory_button, crafting_button, quest_button, map_button,
	               settings_button, character_button, island_button, ship_button]
	
	for button in buttons:
		button.custom_minimum_size = Vector2(40, 40)
		if button.icon == null:
			# TODO: Добавить иконки для кнопок

func _open_menu(menu_name: String) -> void:
	if not menu_scenes.has(menu_name):
		push_error("Menu scene not found: %s" % menu_name)
		return
	
	var scene_path = menu_scenes[menu_name]
	
	# Проверяем, не открыто ли уже это меню
	var existing_menu = get_tree().current_scene.find_child("%sMenu" % menu_name.capitalize(), true, false)
	if existing_menu:
		existing_menu.queue_free()
		return
	
	# Загружаем и открываем меню
	var menu_scene = load(scene_path)
	if menu_scene:
		var menu_instance = menu_scene.instantiate()
		get_tree().current_scene.add_child(menu_instance)
		menu_opened.emit(menu_name)

func _input(event: InputEvent) -> void:
	# Горячие клавиши для быстрого доступа
	if event.is_action_pressed("ui_inventory"):
		_open_menu("inventory")
	elif event.is_action_pressed("ui_crafting"):
		_open_menu("crafting")
	elif event.is_action_pressed("ui_quest"):
		_open_menu("quest")
	elif event.is_action_pressed("ui_map"):
		_open_menu("map")
	elif event.is_action_pressed("ui_settings"):
		_open_menu("settings")
	elif event.is_action_pressed("ui_character"):
		_open_menu("character")
	elif event.is_action_pressed("ui_island"):
		_open_menu("island")
	elif event.is_action_pressed("ui_ship"):
		_open_menu("ship")

