extends Control
class_name QuickBar

## Панель быстрого доступа для навыков и зелий
## Поддерживает 8 слотов (1-8 клавиши)

@onready var slot_container: HBoxContainer = $HBox/Slots
@onready var slots: Array[Button] = []

var quick_bar_items: Array[Dictionary] = []  # {type: "skill"/"potion", id: String, cooldown: float}
var max_slots: int = 8

signal item_used(slot_index: int, item_type: String, item_id: String)

func _ready() -> void:
	_create_slots()
	_apply_theme()
	_setup_input()

func _create_slots() -> void:
	for i in range(max_slots):
		var slot = Button.new()
		slot.custom_minimum_size = Vector2(50, 50)
		slot.name = "Slot%d" % (i + 1)
		slot.pressed.connect(func(idx = i): _on_slot_pressed(idx))
		
		var label = Label.new()
		label.text = str(i + 1)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.anchor_right = 1.0
		label.anchor_bottom = 1.0
		slot.add_child(label)
		
		slots.append(slot)
		slot_container.add_child(slot)
		quick_bar_items.append({})

func _apply_theme() -> void:
	UIThemeManager.apply_theme_to_control(self)

func _setup_input() -> void:
	# Настройка горячих клавиш
	# TODO: Добавить в Input Map

func _process(delta: float) -> void:
	_update_cooldowns(delta)
	_update_slot_display()

func set_slot_item(slot_index: int, item_type: String, item_id: String, icon: Texture2D = null) -> void:
	if slot_index < 0 or slot_index >= max_slots:
		return
	
	quick_bar_items[slot_index] = {
		"type": item_type,
		"id": item_id,
		"cooldown": 0.0,
		"max_cooldown": 0.0,
		"icon": icon
	}
	
	_update_slot_display()

func clear_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= max_slots:
		return
	
	quick_bar_items[slot_index] = {}
	_update_slot_display()

func _on_slot_pressed(slot_index: int) -> void:
	var item = quick_bar_items[slot_index]
	if item.is_empty():
		return
	
	# Проверяем кулдаун
	if item.get("cooldown", 0.0) > 0.0:
		return
	
	# Используем предмет
	_use_item(slot_index, item)

func _use_item(slot_index: int, item: Dictionary) -> void:
	var item_type = item.get("type", "")
	var item_id = item.get("id", "")
	
	if item_type == "skill":
		_use_skill(item_id)
	elif item_type == "potion":
		_use_potion(item_id)
	
	# Устанавливаем кулдаун
	var cooldown_time = _get_cooldown_time(item_type, item_id)
	item["cooldown"] = cooldown_time
	item["max_cooldown"] = cooldown_time
	
	item_used.emit(slot_index, item_type, item_id)

func _use_skill(skill_id: String) -> void:
	# TODO: Интегрировать с SkillSystem
	var world = get_tree().current_scene
	if world:
		var skill_system = world.find_child("SkillSystem", true, false)
		if skill_system:
			skill_system.use_skill(skill_id)

func _use_potion(potion_id: String) -> void:
	# TODO: Интегрировать с InventorySystem
	var world = get_tree().current_scene
	if world:
		var inventory = world.find_child("Inventory", true, false)
		if inventory:
			inventory.use_item(potion_id)

func _get_cooldown_time(item_type: String, item_id: String) -> float:
	match item_type:
		"skill":
			# TODO: Получить кулдаун навыка
			return 5.0
		"potion":
			# Зелья обычно без кулдауна или с небольшим
			return 1.0
		_:
			return 0.0

func _update_cooldowns(delta: float) -> void:
	for item in quick_bar_items:
		if item.is_empty():
			continue
		
		var cooldown = item.get("cooldown", 0.0)
		if cooldown > 0.0:
			item["cooldown"] = max(0.0, cooldown - delta)

func _update_slot_display() -> void:
	for i in range(max_slots):
		var slot = slots[i]
		var item = quick_bar_items[i]
		
		if item.is_empty():
			slot.text = ""
			slot.disabled = false
			continue
		
		# Отображаем иконку
		var icon = item.get("icon", null)
		if icon:
			slot.icon = icon
		else:
			slot.text = item.get("id", "")
		
		# Отображаем кулдаун
		var cooldown = item.get("cooldown", 0.0)
		if cooldown > 0.0:
			var max_cooldown = item.get("max_cooldown", 1.0)
			var progress = cooldown / max_cooldown
			slot.disabled = true
			
			# TODO: Добавить визуализацию кулдауна (ProgressBar или затемнение)
		else:
			slot.disabled = false

func _input(event: InputEvent) -> void:
	# Обработка клавиш 1-8
	if event is InputEventKey and event.pressed:
		var key = event.keycode
		var slot_index = -1
		
		if key >= KEY_1 and key <= KEY_8:
			slot_index = key - KEY_1
		elif key >= KEY_KP_1 and key <= KEY_KP_8:
			slot_index = key - KEY_KP_1
		
		if slot_index >= 0 and slot_index < max_slots:
			_on_slot_pressed(slot_index)

