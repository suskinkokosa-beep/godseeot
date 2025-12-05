extends Control
class_name SettingsMenu

## Меню настроек игры

@onready var graphics_tab: Control = $Tabs/Graphics
@onready var audio_tab: Control = $Tabs/Audio
@onready var controls_tab: Control = $Tabs/Controls
@onready var gameplay_tab: Control = $Tabs/Gameplay
@onready var close_button: Button = $VBox/CloseButton

# Graphics
@onready var resolution_option: OptionButton
@onready var fullscreen_check: CheckBox
@onready var vsync_check: CheckBox
@onready var quality_slider: HSlider
@onready var render_distance_slider: HSlider

# Audio
@onready var master_volume_slider: HSlider
@onready var music_volume_slider: HSlider
@onready var sfx_volume_slider: HSlider
@onready var voice_volume_slider: HSlider

# Controls
@onready var sensitivity_slider: HSlider
@onready var invert_y_check: CheckBox
@onready var key_bindings_list: ItemList

# Gameplay
@onready var auto_pickup_check: CheckBox
@onready var show_damage_check: CheckBox
@onready var chat_enabled_check: CheckBox

var settings_data: Dictionary = {}

signal settings_changed(category: String, key: String, value)

func _ready() -> void:
	_load_settings()
	_setup_ui()
	_apply_theme()

func _setup_ui() -> void:
	close_button.pressed.connect(_on_close_pressed)
	# TODO: Настроить все элементы UI

func _apply_theme() -> void:
	UIThemeManager.apply_theme_to_control(self)

func _load_settings() -> void:
	# Загружаем настройки из файла или устанавливаем по умолчанию
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		# Используем настройки по умолчанию
		_set_default_settings()
		return
	
	# Загружаем настройки из файла
	settings_data = {}
	settings_data["graphics"] = {
		"resolution": config.get_value("graphics", "resolution", "1920x1080"),
		"fullscreen": config.get_value("graphics", "fullscreen", false),
		"vsync": config.get_value("graphics", "vsync", true),
		"quality": config.get_value("graphics", "quality", 1.0),
		"render_distance": config.get_value("graphics", "render_distance", 1000.0)
	}
	
	settings_data["audio"] = {
		"master_volume": config.get_value("audio", "master_volume", 1.0),
		"music_volume": config.get_value("audio", "music_volume", 0.7),
		"sfx_volume": config.get_value("audio", "sfx_volume", 1.0),
		"voice_volume": config.get_value("audio", "voice_volume", 1.0)
	}
	
	settings_data["controls"] = {
		"sensitivity": config.get_value("controls", "sensitivity", 1.0),
		"invert_y": config.get_value("controls", "invert_y", false)
	}
	
	settings_data["gameplay"] = {
		"auto_pickup": config.get_value("gameplay", "auto_pickup", true),
		"show_damage": config.get_value("gameplay", "show_damage", true),
		"chat_enabled": config.get_value("gameplay", "chat_enabled", true)
	}
	
	_apply_settings()

func _set_default_settings() -> void:
	settings_data["graphics"] = {
		"resolution": "1920x1080",
		"fullscreen": false,
		"vsync": true,
		"quality": 1.0,
		"render_distance": 1000.0
	}
	
	settings_data["audio"] = {
		"master_volume": 1.0,
		"music_volume": 0.7,
		"sfx_volume": 1.0,
		"voice_volume": 1.0
	}
	
	settings_data["controls"] = {
		"sensitivity": 1.0,
		"invert_y": false
	}
	
	settings_data["gameplay"] = {
		"auto_pickup": true,
		"show_damage": true,
		"chat_enabled": true
	}

func _apply_settings() -> void:
	_apply_graphics_settings()
	_apply_audio_settings()
	_apply_control_settings()
	_apply_gameplay_settings()

func _apply_graphics_settings() -> void:
	var graphics = settings_data.get("graphics", {})
	
	# Разрешение
	if graphics.has("resolution"):
		_set_resolution(graphics["resolution"])
	
	# Полноэкранный режим
	if graphics.has("fullscreen"):
		if graphics["fullscreen"]:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	# VSync
	if graphics.has("vsync"):
		if graphics["vsync"]:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		else:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	# Качество графики
	if graphics.has("quality"):
		_set_graphics_quality(graphics["quality"])

func _apply_audio_settings() -> void:
	var audio = settings_data.get("audio", {})
	
	# Громкость
	var master_volume = audio.get("master_volume", 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))
	
	var music_volume = audio.get("music_volume", 0.7)
	# TODO: Установить громкость музыки
	
	var sfx_volume = audio.get("sfx_volume", 1.0)
	# TODO: Установить громкость эффектов

func _apply_control_settings() -> void:
	var controls = settings_data.get("controls", {})
	
	# Чувствительность мыши
	var sensitivity = controls.get("sensitivity", 1.0)
	# TODO: Применить к камере
	
	# Инверсия Y
	var invert_y = controls.get("invert_y", false)
	# TODO: Применить к камере

func _apply_gameplay_settings() -> void:
	var gameplay = settings_data.get("gameplay", {})
	
	# Автоподбор
	var auto_pickup = gameplay.get("auto_pickup", true)
	# TODO: Применить к системе добычи
	
	# Показ урона
	var show_damage = gameplay.get("show_damage", true)
	# TODO: Применить к системе урона

func _set_resolution(resolution_string: String) -> void:
	var parts = resolution_string.split("x")
	if parts.size() == 2:
		var width = int(parts[0])
		var height = int(parts[1])
		DisplayServer.window_set_size(Vector2i(width, height))
		DisplayServer.window_set_position(DisplayServer.screen_get_center() - Vector2i(width, height) / 2)

func _set_graphics_quality(quality: float) -> void:
	# Качество от 0.0 до 1.0
	# TODO: Применить настройки качества (детализация, тени, эффекты)

func save_settings() -> void:
	var config = ConfigFile.new()
	
	# Сохраняем все настройки
	for category in settings_data.keys():
		for key in settings_data[category].keys():
			config.set_value(category, key, settings_data[category][key])
	
	config.save("user://settings.cfg")

func get_setting(category: String, key: String, default_value = null):
	if settings_data.has(category) and settings_data[category].has(key):
		return settings_data[category][key]
	return default_value

func set_setting(category: String, key: String, value) -> void:
	if not settings_data.has(category):
		settings_data[category] = {}
	
	settings_data[category][key] = value
	settings_changed.emit(category, key, value)
	
	# Автоматически применяем изменения
	match category:
		"graphics":
			_apply_graphics_settings()
		"audio":
			_apply_audio_settings()
		"controls":
			_apply_control_settings()
		"gameplay":
			_apply_gameplay_settings()

func _on_close_pressed() -> void:
	save_settings()
	queue_free()

