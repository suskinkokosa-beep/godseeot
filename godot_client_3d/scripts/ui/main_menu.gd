extends Control

func _ready() -> void:
	UIThemeManager.apply_theme_to_control(self)
	_setup_background()
	$VBox/PlayButton.pressed.connect(_on_play_pressed)
	$VBox/QuitButton.pressed.connect(_on_quit_pressed)

func _setup_background() -> void:
	# Создаём фон в морском стиле
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.1, 0.15, 1.0)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/login_menu.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


