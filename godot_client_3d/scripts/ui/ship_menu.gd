extends Control

## Меню управления кораблём

@onready var ship_name_label: Label = $VBox/ShipName
@onready var health_label: Label = $VBox/HBox/InfoPanel/VBoxInfo/HealthLabel
@onready var speed_label: Label = $VBox/HBox/InfoPanel/VBoxInfo/SpeedLabel
@onready var cargo_label: Label = $VBox/HBox/InfoPanel/VBoxInfo/CargoLabel
@onready var crew_label: Label = $VBox/HBox/InfoPanel/VBoxInfo/CrewLabel
@onready var modules_list: VBoxContainer = $VBox/HBox/ModulesPanel/VBoxModules/ModulesList
@onready var close_button: Button = $VBox/CloseButton

var ship_id: String = "raft"
var ship_data: Dictionary = {}

func _ready() -> void:
	UIThemeManager.apply_theme_to_control(self)
	_setup_background()
	
	close_button.pressed.connect(_on_close_pressed)
	
	_update_display()

func setup(ship_id_param: String) -> void:
	ship_id = ship_id_param
	ship_data = ShipDatabase.get_ship(ship_id) if ShipDatabase else {}
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
	if ship_data.is_empty():
		ship_data = ShipDatabase.get_ship(ship_id) if ShipDatabase else {}
	
	if ship_data.is_empty():
		return
	
	var name = ship_data.get("name", ship_id)
	ship_name_label.text = name
	
	var current_health = ship_data.get("current_health", ship_data.get("base_health", 50.0))
	var max_health = ship_data.get("base_health", 50.0)
	health_label.text = "Прочность: %.0f / %.0f" % [current_health, max_health]
	
	var speed = ship_data.get("base_speed", 3.0)
	speed_label.text = "Скорость: %.1f" % speed
	
	var cargo_capacity = ship_data.get("cargo_capacity", 2)
	var current_cargo = ship_data.get("current_cargo", 0)
	cargo_label.text = "Груз: %d / %d" % [current_cargo, cargo_capacity]
	
	var crew_capacity = ship_data.get("crew_capacity", 1)
	var current_crew = ship_data.get("current_crew", 1)
	crew_label.text = "Экипаж: %d / %d" % [current_crew, crew_capacity]
	
	_update_modules_list()

func _update_modules_list() -> void:
	# Очищаем список
	for child in modules_list.get_children():
		child.queue_free()
	
	var modules = ship_data.get("modules", [])
	if modules.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Модули не установлены"
		modules_list.add_child(empty_label)
	else:
		for module in modules:
			var module_label := Label.new()
			module_label.text = module.get("name", "Модуль")
			modules_list.add_child(module_label)

func _on_close_pressed() -> void:
	queue_free()

