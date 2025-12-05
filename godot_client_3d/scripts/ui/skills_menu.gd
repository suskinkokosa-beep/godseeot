extends Control

## Меню навыков персонажа

@onready var skills_list: VBoxContainer = $VBox/HBox/KnownSkillsPanel/VBoxKnown/ScrollContainer/SkillsList
@onready var active_slots: VBoxContainer = $VBox/HBox/ActiveSkillsPanel/VBoxActive/ActiveSlots
@onready var passive_slots: VBoxContainer = $VBox/HBox/PassiveSkillsPanel/VBoxPassive/PassiveSlots
@onready var close_button: Button = $VBox/CloseButton

var skill_system: SkillSystem = null
var character_progression: CharacterProgression = null

func _ready() -> void:
	UIThemeManager.apply_theme_to_control(self)
	_setup_background()
	close_button.pressed.connect(_on_close_pressed)
	
	# Получаем ссылки на системы
	var world = get_tree().current_scene
	if world:
		character_progression = world.find_child("CharacterProgression", true, false)
		if character_progression:
			skill_system = character_progression.skill_system
	
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
	if not skill_system:
		return
	
	_update_known_skills()
	_update_active_slots()
	_update_passive_slots()

func _update_known_skills() -> void:
	# Очищаем список
	for child in skills_list.get_children():
		child.queue_free()
	
	if not skill_system:
		return
	
	var known_skills = skill_system.get_known_skills()
	for skill_id in known_skills.keys():
		var skill = known_skills[skill_id]
		var item = _create_skill_item(skill)
		skills_list.add_child(item)

func _create_skill_item(skill: SkillSystem.SkillData) -> Control:
	var container := HBoxContainer.new()
	
	var label := Label.new()
	label.text = "%s (Ур. %d/%d)" % [skill.name, skill.current_level, skill.max_level]
	label.custom_minimum_size = Vector2(200, 0)
	
	var level_button := Button.new()
	level_button.text = "Улучшить"
	level_button.disabled = not skill.can_level_up() or skill_system.get_skill_points() <= 0
	level_button.pressed.connect(func(): _on_level_up_skill(skill.id))
	
	container.add_child(label)
	container.add_child(level_button)
	
	return container

func _update_active_slots() -> void:
	for child in active_slots.get_children():
		child.queue_free()
	
	for i in range(5):
		var slot_panel := Panel.new()
		slot_panel.custom_minimum_size = Vector2(0, 80)
		
		var label := Label.new()
		label.text = "Слот %d" % (i + 1)
		
		slot_panel.add_child(label)
		active_slots.add_child(slot_panel)

func _update_passive_slots() -> void:
	for child in passive_slots.get_children():
		child.queue_free()
	
	for i in range(3):
		var slot_panel := Panel.new()
		slot_panel.custom_minimum_size = Vector2(0, 80)
		
		var label := Label.new()
		label.text = "Слот %d" % (i + 1)
		
		slot_panel.add_child(label)
		passive_slots.add_child(slot_panel)

func _on_level_up_skill(skill_id: String) -> void:
	if skill_system and skill_system.level_up_skill(skill_id):
		_update_display()

func _on_close_pressed() -> void:
	queue_free()

