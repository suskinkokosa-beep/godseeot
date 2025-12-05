extends Control

## Меню экипировки персонажа

@onready var visual_mode_button: Button = $VBox/VisualModeButton
@onready var equipment_slots: VBoxContainer = $VBox/HBox/EquipmentSlots
@onready var stats_label: Label = $VBox/HBox/StatsPanel/StatsLabel
@onready var close_button: Button = $VBox/CloseButton

var equipment_system: EquipmentSystem = null
var inventory_system: Node = null

var slot_widgets: Dictionary = {}  # slot -> Control

func _ready() -> void:
	UIThemeManager.apply_theme_to_control(self)
	_setup_background()
	
	visual_mode_button.pressed.connect(_on_visual_mode_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Получаем ссылки на системы
	var world = get_tree().current_scene
	if world:
		equipment_system = world.find_child("EquipmentSystem", true, false)
		inventory_system = world.find_child("Inventory", true, false)
	
	_create_slot_widgets()
	_update_display()

func _setup_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.1, 0.15, 1.0)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

func _create_slot_widgets() -> void:
	var slot_names = {
		EquipmentSystem.EquipmentSlot.WEAPON_MAIN: "Основное оружие",
		EquipmentSystem.EquipmentSlot.WEAPON_OFFHAND: "Доп. оружие/Щит",
		EquipmentSystem.EquipmentSlot.HELMET: "Шлем",
		EquipmentSystem.EquipmentSlot.CHEST: "Нагрудник",
		EquipmentSystem.EquipmentSlot.LEGS: "Поножи",
		EquipmentSystem.EquipmentSlot.BOOTS: "Сапоги",
		EquipmentSystem.EquipmentSlot.GLOVES: "Перчатки",
		EquipmentSystem.EquipmentSlot.ACCESSORY_1: "Аксессуар 1",
		EquipmentSystem.EquipmentSlot.ACCESSORY_2: "Аксессуар 2",
		EquipmentSystem.EquipmentSlot.ACCESSORY_3: "Аксессуар 3"
	}
	
	var slot_nodes = [
		$VBox/HBox/EquipmentSlots/WeaponMainSlot,
		$VBox/HBox/EquipmentSlots/WeaponOffhandSlot,
		$VBox/HBox/EquipmentSlots/HelmetSlot,
		$VBox/HBox/EquipmentSlots/ChestSlot,
		$VBox/HBox/EquipmentSlots/LegsSlot,
		$VBox/HBox/EquipmentSlots/BootsSlot,
		$VBox/HBox/EquipmentSlots/GlovesSlot,
		$VBox/HBox/EquipmentSlots/Accessory1Slot,
		$VBox/HBox/EquipmentSlots/Accessory2Slot,
		$VBox/HBox/EquipmentSlots/Accessory3Slot
	]
	
	var slot_index = 0
	for slot in slot_names.keys():
		var slot_node = slot_nodes[slot_index]
		var widget = _create_slot_widget(slot, slot_names[slot])
		slot_node.add_child(widget)
		slot_widgets[slot] = widget
		slot_index += 1

func _create_slot_widget(slot: EquipmentSystem.EquipmentSlot, slot_name: String) -> Control:
	var container := HBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 50)
	
	var label := Label.new()
	label.text = slot_name
	label.custom_minimum_size = Vector2(150, 0)
	
	var item_label := Label.new()
	item_label.name = "ItemLabel"
	item_label.text = "Пусто"
	item_label.custom_minimum_size = Vector2(150, 0)
	
	var unequip_button := Button.new()
	unequip_button.text = "Снять"
	unequip_button.disabled = true
	unequip_button.pressed.connect(func(): _on_unequip_pressed(slot))
	
	container.add_child(label)
	container.add_child(item_label)
	container.add_child(unequip_button)
	
	return container

func _update_display() -> void:
	if not equipment_system:
		return
	
	# Обновляем режим визуализации
	var show_equipment = equipment_system.is_showing_equipment()
	visual_mode_button.text = "Показать стиль" if show_equipment else "Показать экипировку"
	
	# Обновляем слоты
	for slot in slot_widgets.keys():
		var widget = slot_widgets[slot]
		var item_label = widget.find_child("ItemLabel", true, false)
		var unequip_button = widget.get_child(2)  # Кнопка "Снять"
		
		var equipped = equipment_system.get_equipped_item(slot)
		if equipped:
			var enhancement_text = ""
			if equipped.enhancement_level > 0:
				enhancement_text = " +%d" % equipped.enhancement_level
			item_label.text = "%s%s" % [equipped.item_id, enhancement_text]
			unequip_button.disabled = false
		else:
			item_label.text = "Пусто"
			unequip_button.disabled = true
	
	# Обновляем статы
	var total_stats = equipment_system.get_total_equipment_stats()
	var stats_text = "Статы от экипировки:\n"
	if total_stats.is_empty():
		stats_text += "Нет экипировки"
	else:
		for stat in total_stats.keys():
			stats_text += "%s: +%.1f\n" % [stat, total_stats[stat]]
	stats_label.text = stats_text

func _on_visual_mode_pressed() -> void:
	if equipment_system:
		equipment_system.toggle_visual_mode()
		_update_display()

func _on_unequip_pressed(slot: EquipmentSystem.EquipmentSlot) -> void:
	if equipment_system:
		equipment_system.unequip_item(slot, inventory_system)
		_update_display()

func _on_close_pressed() -> void:
	queue_free()

