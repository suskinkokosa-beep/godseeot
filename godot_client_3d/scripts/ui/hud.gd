extends Control

## HUD для отображения игровой информации
## Показывает здоровье, ресурсы, уровень, статы

@onready var resources_label: Label = $VBox/ResourcesLabel
@onready var pvp_label: Label = $VBox/PvPLabel
@onready var hp_bar: ProgressBar = $VBox/HPBar
@onready var level_label: Label = $VBox/LevelLabel
@onready var xp_bar: ProgressBar = $VBox/XPBar

var player_controller: Node = null
var character_progression: CharacterProgression = null

func _ready() -> void:
	# Ищем игрока в сцене
	var world = get_tree().current_scene
	if world:
		player_controller = world.find_child("player_controller", true, false) or world
		character_progression = world.find_child("CharacterProgression", true, false)
	
	# Обновляем UI каждые 0.1 секунды
	_update_ui()

func _process(_delta: float) -> void:
	_update_ui()

func _update_ui() -> void:
	# Ресурсы из инвентаря
	var inventory = get_node_or_null("../Inventory")
	if inventory and inventory.has_method("get_all_items"):
		var items = inventory.get_all_items()
		var resources_text = "Ресурсы: "
		var resource_count = 0
		for item_id in items.keys():
			if resource_count < 5:  # Показываем только первые 5
				resources_text += "%s x%d, " % [item_id, items[item_id]]
				resource_count += 1
		resources_text = resources_text.trim_suffix(", ")
		if resources_label:
			resources_label.text = resources_text
	
	# PvP статус
	if player_controller:
		var is_pvp = player_controller.get("is_pvp_enabled")
		if is_pvp != null and pvp_label:
			pvp_label.text = "PvP: %s" % ("ON" if is_pvp else "OFF")
	
	# HP игрока
	if player_controller:
		var hp = player_controller.get("player_hp")
		if hp != null:
			var max_hp = 100  # TODO: Получать из статов
			if hp_bar:
				hp_bar.max_value = max_hp
				hp_bar.value = hp
				
				# Меняем цвет в зависимости от HP
				if hp <= max_hp * 0.25:
					hp_bar.modulate = Color.RED
				elif hp <= max_hp * 0.5:
					hp_bar.modulate = Color.ORANGE
				else:
					hp_bar.modulate = Color.GREEN
	
	# Уровень и опыт персонажа
	if character_progression:
		var level = character_progression.current_level
		var exp = character_progression.current_experience
		var exp_needed = CharacterProgression.get_experience_for_level(level + 1)
		
		if level_label:
			level_label.text = "Уровень: %d" % level
		
		if xp_bar:
			xp_bar.max_value = exp_needed
			xp_bar.value = exp
			xp_bar.show_percentage = false
