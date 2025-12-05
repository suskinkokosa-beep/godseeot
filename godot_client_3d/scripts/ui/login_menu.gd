extends Control

@onready var email_edit: LineEdit = $CenterContainer/Panel/VBox/Email
@onready var password_edit: LineEdit = $CenterContainer/Panel/VBox/Password
@onready var status_label: Label = $CenterContainer/Panel/VBox/Status
@onready var login_button: Button = $CenterContainer/Panel/VBox/LoginButton

func _ready() -> void:
	login_button.pressed.connect(_on_login_pressed)
	if Auth:
		if Auth.has_signal("login_success"):
			Auth.login_success.connect(_on_login_success)
		if Auth.has_signal("login_failed"):
			Auth.login_failed.connect(_on_login_failed)
	email_edit.text_submitted.connect(func(_t): password_edit.grab_focus())
	password_edit.text_submitted.connect(func(_t): _on_login_pressed())

func _on_login_pressed() -> void:
	var email := email_edit.text.strip_edges()
	var password := password_edit.text.strip_edges()
	if email == "" or password == "":
		status_label.text = "Введите email и пароль"
		return
	status_label.text = "Авторизация..."
	login_button.disabled = true
	if Auth and Auth.has_method("login_email_existing"):
		Auth.login_email_existing(email, password)
	else:
		_simulate_login(email, password)

func _simulate_login(email: String, _password: String) -> void:
	await get_tree().create_timer(1.0).timeout
	status_label.text = "Успешный вход!"
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/main/server_select.tscn")

func _on_login_success() -> void:
	status_label.text = "Успех! Переход к выбору сервера..."
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/main/server_select.tscn")

func _on_login_failed(reason: String) -> void:
	status_label.text = "Ошибка: %s" % reason
	login_button.disabled = false
