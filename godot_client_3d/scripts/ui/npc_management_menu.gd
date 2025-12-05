extends Control

## Меню управления NPC-работниками

@onready var npc_list: VBoxContainer = $VBox/HBox/NPCListPanel/VBoxNPCList/NPCList/NPCItems
@onready var npc_name_label: Label = $VBox/HBox/DetailsPanel/VBoxDetails/NPCNameLabel
@onready var npc_type_label: Label = $VBox/HBox/DetailsPanel/VBoxDetails/NPCTypeLabel
@onready var npc_level_label: Label = $VBox/HBox/DetailsPanel/VBoxDetails/NPCLevelLabel
@onready var mood_label: Label = $VBox/HBox/DetailsPanel/VBoxDetails/MoodLabel
@onready var loyalty_label: Label = $VBox/HBox/DetailsPanel/VBoxDetails/LoyaltyLabel
@onready var task_label: Label = $VBox/HBox/DetailsPanel/VBoxDetails/TaskLabel
@onready var tasks_list: VBoxContainer = $VBox/HBox/TasksPanel/VBoxTasks/TasksList/TaskItems
@onready var close_button: Button = $VBox/CloseButton

var npc_system: NPCSystem = null
var npc_worker_system: NPCWorkerSystem = null
var selected_npc_id: String = ""

func _ready() -> void:
	UIThemeManager.apply_theme_to_control(self)
	_setup_background()
	
	close_button.pressed.connect(_on_close_pressed)
	
	# Получаем ссылки на системы
	var world = get_tree().current_scene
	if world:
		npc_system = world.find_child("NPCSystem", true, false)
		npc_worker_system = world.find_child("NPCWorkerSystem", true, false)
	
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
	_update_npc_list()
	_update_tasks_list()
	
	if selected_npc_id != "":
		_update_npc_details()

func _update_npc_list() -> void:
	# Очищаем список
	for child in npc_list.get_children():
		child.queue_free()
	
	if not npc_system:
		return
	
	# Получаем всех NPC
	for npc_id in npc_system.npcs.keys():
		var npc = npc_system.npcs[npc_id]
		var widget = _create_npc_widget(npc)
		npc_list.add_child(widget)

func _create_npc_widget(npc: NPCSystem.NPCData) -> Control:
	var container := HBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 40)
	
	var name_label := Label.new()
	name_label.text = npc.name
	name_label.custom_minimum_size = Vector2(150, 0)
	
	var type_label := Label.new()
	type_label.text = _get_npc_type_name(npc.npc_type)
	type_label.custom_minimum_size = Vector2(100, 0)
	
	var level_label := Label.new()
	level_label.text = "Lv.%d" % npc.level
	level_label.custom_minimum_size = Vector2(50, 0)
	
	var select_button := Button.new()
	select_button.text = "Выбрать"
	select_button.pressed.connect(func(): _on_npc_selected(npc.id))
	
	container.add_child(name_label)
	container.add_child(type_label)
	container.add_child(level_label)
	container.add_child(select_button)
	
	return container

func _update_npc_details() -> void:
	if selected_npc_id == "" or not npc_system:
		return
	
	var npc = npc_system.get_npc(selected_npc_id)
	if not npc:
		return
	
	npc_name_label.text = "Имя: %s" % npc.name
	npc_type_label.text = "Тип: %s" % _get_npc_type_name(npc.npc_type)
	npc_level_label.text = "Уровень: %d" % npc.level
	mood_label.text = "Настроение: %.0f" % npc.mood
	loyalty_label.text = "Лояльность: %.0f" % npc.loyalty
	
	# Получаем задание NPC
	if npc_worker_system:
		var task = npc_worker_system.get_npc_task(selected_npc_id)
		if task:
			task_label.text = "Задание: %s" % _get_task_type_name(task.task_type)
		else:
			task_label.text = "Задание: Нет"

func _update_tasks_list() -> void:
	# Очищаем список
	for child in tasks_list.get_children():
		child.queue_free()
	
	if not npc_worker_system:
		return
	
	var available_tasks = npc_worker_system.get_available_tasks()
	for task in available_tasks:
		var widget = _create_task_widget(task)
		tasks_list.add_child(widget)

func _create_task_widget(task: NPCWorkerSystem.TaskData) -> Control:
	var container := VBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 80)
	
	var name_label := Label.new()
	name_label.text = _get_task_type_name(task.task_type)
	name_label.theme_override_font_sizes/font_size = 16
	
	var priority_label := Label.new()
	priority_label.text = "Приоритет: %d" % task.priority
	
	var assign_button := Button.new()
	assign_button.text = "Назначить выбранному NPC"
	assign_button.disabled = selected_npc_id == ""
	assign_button.pressed.connect(func(): _on_assign_task(task.id))
	
	container.add_child(name_label)
	container.add_child(priority_label)
	container.add_child(assign_button)
	
	return container

func _on_npc_selected(npc_id: String) -> void:
	selected_npc_id = npc_id
	_update_npc_details()
	_update_tasks_list()

func _on_assign_task(task_id: String) -> void:
	if selected_npc_id == "" or not npc_worker_system:
		return
	
	if npc_worker_system.assign_task_to_npc(task_id, selected_npc_id):
		_update_display()

func _get_npc_type_name(npc_type: NPCSystem.NPCType) -> String:
	match npc_type:
		NPCSystem.NPCType.WORKER:
			return "Рабочий"
		NPCSystem.NPCType.GUARD:
			return "Стражник"
		NPCSystem.NPCType.FISHER:
			return "Рыбак"
		NPCSystem.NPCType.SMITH:
			return "Кузнец"
		NPCSystem.NPCType.BUILDER:
			return "Строитель"
		NPCSystem.NPCType.NAVIGATOR:
			return "Навигатор"
		_:
			return "Неизвестно"

func _get_task_type_name(task_type: NPCWorkerSystem.TaskType) -> String:
	match task_type:
		NPCWorkerSystem.TaskType.GATHER_RESOURCE:
			return "Собрать ресурсы"
		NPCWorkerSystem.TaskType.BUILD:
			return "Строить"
		NPCWorkerSystem.TaskType.REPAIR:
			return "Ремонтировать"
		NPCWorkerSystem.TaskType.CRAFT:
			return "Крафтить"
		NPCWorkerSystem.TaskType.FISH:
			return "Рыбачить"
		NPCWorkerSystem.TaskType.PATROL:
			return "Патрулировать"
		NPCWorkerSystem.TaskType.GUARD:
			return "Охранять"
		NPCWorkerSystem.TaskType.FARM:
			return "Ферма"
		_:
			return "Неизвестно"

func _on_close_pressed() -> void:
	queue_free()

