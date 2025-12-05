extends Control

@onready var email_edit: LineEdit = $VBox/Email
@onready var password_edit: LineEdit = $VBox/Password
@onready var status_label: Label = $VBox/Status

func _ready() -> void:
	UIThemeManager.apply_theme_to_control(self)
	_setup_background()
	$VBox/LoginButton.pressed.connect(_on_login_pressed)
	Auth.login_success.connect(_on_login_success)
	Auth.login_failed.connect(_on_login_failed)

func _setup_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.1, 0.15, 1.0)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)


func _on_login_pressed() -> void:
	var email := email_edit.text.strip_edges()
	var password := password_edit.text.strip_edges()
	if email == "" or password == "":
		status_label.text = "Введите email и пароль."
		return
	status_label.text = "Авторизация..."
	Auth.login_email_existing(email, password)


func _on_login_success() -> void:
	status_label.text = "Успех. Переход к выбору сервера..."
	get_tree().change_scene_to_file("res://scenes/main/server_select.tscn")


func _on_login_failed(reason: String) -> void:
	status_label.text = "Ошибка: %s" % reason


