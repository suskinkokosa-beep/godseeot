extends Control

@onready var server_list: OptionButton = $VBox/ServerList

var servers := [
	{"name": "Local Gateway", "ws_url": "ws://localhost:8080/ws"},
]

func _ready() -> void:
	UIThemeManager.apply_theme_to_control(self)
	_setup_background()
	for s in servers:
		server_list.add_item(s["name"])
	$VBox/ConnectButton.pressed.connect(_on_connect_pressed)

func _setup_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.1, 0.15, 1.0)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)


func _on_connect_pressed() -> void:
	var idx := server_list.get_selected_id()
	if idx < 0 or idx >= servers.size():
		return
	var sel := servers[idx]
	# Сохраняем выбранный адрес в Auth (на будущее, если захотим менять WORLD_WS)
	if Auth.has_method("set_world_ws"):
		Auth.set_world_ws(sel["ws_url"])
	get_tree().change_scene_to_file("res://scenes/main/character_creation.tscn")


