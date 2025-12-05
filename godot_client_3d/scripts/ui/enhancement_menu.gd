extends Control

## Меню заточки предметов

@onready var item_label: Label = $VBox/ItemLabel
@onready var current_level_label: Label = $VBox/CurrentLevelLabel
@onready var success_chance_label: Label = $VBox/SuccessChanceLabel
@onready var risk_label: Label = $VBox/RiskLabel
@onready var material_list: VBoxContainer = $VBox/MaterialList
@onready var enhance_button: Button = $VBox/EnhanceButton
@onready var result_label: Label = $VBox/ResultLabel
@onready var close_button: Button = $VBox/CloseButton

var current_item_data: Dictionary = {}
var selected_material: String = ""
var inventory_system: Node = null
var character_progression: CharacterProgression = null

func _ready() -> void:
	UIThemeManager.apply_theme_to_control(self)
	_setup_background()
	
	enhance_button.pressed.connect(_on_enhance_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Получаем ссылки на системы
	var world = get_tree().current_scene
	if world:
		inventory_system = world.find_child("Inventory", true, false)
		character_progression = world.find_child("CharacterProgression", true, false)

func _setup_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.1, 0.15, 1.0)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

## Установить предмет для заточки
func set_item(item_data: Dictionary) -> void:
	current_item_data = item_data
	_update_display()

func _update_display() -> void:
	if current_item_data.is_empty():
		item_label.text = "Предмет: Не выбран"
		current_level_label.text = "Текущий уровень: +0"
		enhance_button.disabled = true
		return
	
	var item_id = current_item_data.get("id", "")
	var current_level = current_item_data.get("enhancement_level", 0)
	
	item_label.text = "Предмет: %s" % item_id
	current_level_label.text = "Текущий уровень: +%d" % current_level
	
	# Вычисляем шанс успеха
	var luck = 0.0
	if character_progression:
		luck = character_progression.get_stat("luck")
	
	var success_chance = EnhancementSystem.get_success_chance(current_level, luck)
	success_chance_label.text = "Шанс успеха: %.1f%%" % success_chance
	
	# Определяем риск
	var risk_type = EnhancementSystem.get_risk_type(current_level)
	var risk_text = ""
	var risk_color = Color.GREEN
	
	match risk_type:
		EnhancementSystem.EnhancementResult.FAILURE_SAFE:
			risk_text = "Риск: Безопасно"
			risk_color = Color.GREEN
		EnhancementSystem.EnhancementResult.FAILURE_DOWN:
			risk_text = "Риск: Может сбить на -1"
			risk_color = Color.YELLOW
		EnhancementSystem.EnhancementResult.FAILURE_RESET:
			risk_text = "Риск: Может сбросить до +3"
			risk_color = Color.ORANGE
		EnhancementSystem.EnhancementResult.FAILURE_BREAK:
			risk_text = "Риск: Может сломать предмет!"
			risk_color = Color.RED
	
	risk_label.text = risk_text
	risk_label.modulate = risk_color
	
	# Обновляем список материалов
	_update_material_list()
	
	# Проверяем, можно ли заточить
	enhance_button.disabled = current_level >= EnhancementSystem.MAX_ENHANCEMENT_LEVEL or selected_material == ""

func _update_material_list() -> void:
	# Очищаем список
	for child in material_list.get_children():
		child.queue_free()
	
	if current_item_data.is_empty():
		return
	
	var current_level = current_item_data.get("enhancement_level", 0)
	var materials = EnhancementMaterials.get_materials_for_level(current_level)
	
	for material in materials:
		var material_id = material.get("id", "")
		var material_name = material.get("name", "")
		
		# Проверяем наличие в инвентаре
		var has_material = false
		if inventory_system and inventory_system.has_method("has_items"):
			has_material = inventory_system.has_items(material_id, 1)
		
		var button := Button.new()
		button.text = "%s %s" % [material_name, "(есть)" if has_material else "(нет)"]
		button.disabled = not has_material
		button.pressed.connect(func(): _on_material_selected(material_id))
		
		if material_id == selected_material:
			button.modulate = Color.CYAN
		
		material_list.add_child(button)

func _on_material_selected(material_id: String) -> void:
	selected_material = material_id
	_update_display()

func _on_enhance_pressed() -> void:
	if current_item_data.is_empty() or selected_material == "":
		return
	
	var luck = 0.0
	if character_progression:
		luck = character_progression.get_stat("luck")
	
	var result = EnhancementSystem.enhance_item(current_item_data, selected_material, luck)
	
	# Обновляем уровень заточки
	current_item_data["enhancement_level"] = result["new_level"]
	
	# Показываем результат
	result_label.text = result["message"]
	
	match result["result"]:
		EnhancementSystem.EnhancementResult.SUCCESS:
			result_label.modulate = Color.GREEN
		EnhancementSystem.EnhancementResult.FAILURE_BREAK:
			result_label.modulate = Color.RED
			# Предмет сломан, удаляем из инвентаря
			if inventory_system and inventory_system.has_method("remove_item"):
				inventory_system.remove_item(current_item_data.get("id", ""), 1)
			current_item_data = {}
		_:
			result_label.modulate = Color.YELLOW
	
	# Удаляем использованный материал
	if inventory_system and inventory_system.has_method("remove_item"):
		inventory_system.remove_item(selected_material, 1)
	
	selected_material = ""
	_update_display()

func _on_close_pressed() -> void:
	queue_free()

