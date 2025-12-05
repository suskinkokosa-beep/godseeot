extends Control

## Меню управления гильдией

@onready var guild_name_label: Label = $VBox/GuildName
@onready var level_label: Label = $VBox/HBox/InfoPanel/VBoxInfo/LevelLabel
@onready var members_label: Label = $VBox/HBox/InfoPanel/VBoxInfo/MembersLabel
@onready var xp_bar: ProgressBar = $VBox/HBox/InfoPanel/VBoxInfo/XPBar
@onready var members_list: VBoxContainer = $VBox/HBox/MembersPanel/VBoxMembers/MembersList/MemberItems
@onready var close_button: Button = $VBox/CloseButton

var guild_system: GuildSystem = null
var current_guild_id: String = ""
var player_id: String = ""

func _ready() -> void:
	UIThemeManager.apply_theme_to_control(self)
	_setup_background()
	
	close_button.pressed.connect(_on_close_pressed)
	
	# Получаем ссылки на системы
	var world = get_tree().current_scene
	if world:
		guild_system = world.find_child("GuildSystem", true, false)
	
	_update_display()

func setup(player_id_param: String) -> void:
	player_id = player_id_param
	if guild_system:
		var guild = guild_system.get_player_guild(player_id)
		if guild:
			current_guild_id = guild.id
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
	if not guild_system or current_guild_id == "":
		_show_no_guild()
		return
	
	var guild = guild_system.guilds.get(current_guild_id)
	if not guild:
		_show_no_guild()
		return
	
	guild_name_label.text = "%s [%s]" % [guild.name, guild.tag]
	level_label.text = "Уровень гильдии: %d" % guild.level
	
	var members = guild_system.get_guild_members(current_guild_id)
	members_label.text = "Участники: %d / %d" % [members.size(), guild.member_limit]
	
	# XP бар
	var needed_xp = 1000.0 * pow(guild.level + 1, 1.5)
	xp_bar.max_value = needed_xp
	xp_bar.value = guild.experience
	
	_update_members_list(members)

func _show_no_guild() -> void:
	guild_name_label.text = "Вы не состоите в гильдии"
	level_label.text = ""
	members_label.text = ""
	xp_bar.value = 0

func _update_members_list(members: Array) -> void:
	# Очищаем список
	for child in members_list.get_children():
		child.queue_free()
	
	for member in members:
		var widget = _create_member_widget(member)
		members_list.add_child(widget)

func _create_member_widget(member: GuildSystem.GuildMember) -> Control:
	var container := HBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 40)
	
	var name_label := Label.new()
	name_label.text = member.player_name
	name_label.custom_minimum_size = Vector2(200, 0)
	
	var rank_label := Label.new()
	rank_label.text = _get_rank_name(member.rank)
	rank_label.custom_minimum_size = Vector2(150, 0)
	
	var contribution_label := Label.new()
	contribution_label.text = "Вклад: %.0f" % member.contribution
	contribution_label.custom_minimum_size = Vector2(150, 0)
	
	container.add_child(name_label)
	container.add_child(rank_label)
	container.add_child(contribution_label)
	
	return container

func _get_rank_name(rank: GuildSystem.GuildRank) -> String:
	match rank:
		GuildSystem.GuildRank.LEADER:
			return "Лидер"
		GuildSystem.GuildRank.OFFICER:
			return "Офицер"
		GuildSystem.GuildRank.MASTER:
			return "Мастер"
		GuildSystem.GuildRank.CAPTAIN:
			return "Капитан"
		GuildSystem.GuildRank.MEMBER:
			return "Участник"
		_:
			return "Неизвестно"

func _on_close_pressed() -> void:
	queue_free()

