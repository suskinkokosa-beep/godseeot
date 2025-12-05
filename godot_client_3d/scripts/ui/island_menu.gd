extends Control

## Меню управления островом

@onready var level_label: Label = $VBox/HBox/InfoPanel/VBoxInfo/LevelLabel
@onready var size_label: Label = $VBox/HBox/InfoPanel/VBoxInfo/SizeLabel
@onready var xp_bar: ProgressBar = $VBox/HBox/InfoPanel/VBoxInfo/XPBar
@onready var xp_label: Label = $VBox/HBox/InfoPanel/VBoxInfo/XPLabel
@onready var cost_label: Label = $VBox/HBox/UpgradePanel/VBoxUpgrade/CostLabel
@onready var upgrade_button: Button = $VBox/HBox/UpgradePanel/VBoxUpgrade/UpgradeButton
@onready var buildings_list: VBoxContainer = $VBox/HBox/BuildingsPanel/VBoxBuildings/BuildingsList
@onready var close_button: Button = $VBox/CloseButton

var island_progression: IslandProgression = null
var inventory_system: Node = null

func _ready() -> void:
	UIThemeManager.apply_theme_to_control(self)
	_setup_background()
	
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Получаем ссылки на системы
	var world = get_tree().current_scene
	if world:
		island_progression = world.find_child("IslandProgression", true, false)
		inventory_system = world.find_child("Inventory", true, false)
	
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
	if not island_progression:
		return
	
	# Обновляем информацию об уровне
	var level = island_progression.current_level
	level_label.text = "Уровень острова: %d" % level
	
	# Обновляем размер
	var radius = island_progression.get_current_radius()
	var diameter = radius * 2.0
	size_label.text = "Размер: %.1f x %.1f м" % [diameter, diameter]
	
	# Обновляем опыт
	var current_exp = island_progression.current_experience
	var needed_exp = IslandProgression.get_experience_for_level(level + 1)
	xp_bar.max_value = needed_exp
	xp_bar.value = current_exp
	xp_label.text = "Опыт: %.0f / %.0f" % [current_exp, needed_exp]
	
	# Обновляем стоимость расширения
	var next_cost = island_progression.get_next_level_cost()
	cost_label.text = "Стоимость следующего уровня: %.0f" % next_cost
	
	# Проверяем, можно ли расширить
	upgrade_button.disabled = not _can_upgrade()

func _can_upgrade() -> bool:
	if not island_progression or not inventory_system:
		return false
	
	# TODO: Проверка наличия ресурсов для расширения
	# Пока возвращаем true если есть опыт
	var needed_exp = IslandProgression.get_experience_for_level(island_progression.current_level + 1)
	return island_progression.current_experience >= needed_exp

func _on_upgrade_pressed() -> void:
	if island_progression and _can_upgrade():
		# TODO: Проверить и потратить ресурсы
		# Пока просто добавляем опыт для тестирования
		island_progression.add_experience(100.0)
		_update_display()

func _on_close_pressed() -> void:
	queue_free()

