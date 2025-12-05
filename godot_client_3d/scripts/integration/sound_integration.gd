extends Node
class_name SoundIntegration

## Интеграция звуков в игру

@export var asset_manager_path: NodePath
var asset_manager: AssetManager

var audio_players: Dictionary = {}  # sound_name -> AudioStreamPlayer

func _ready() -> void:
	if asset_manager_path != NodePath():
		asset_manager = get_node(asset_manager_path)
	else:
		asset_manager = get_node("/root/World/AssetManager") if get_tree().has_group("asset_manager") else null

## Воспроизвести звук UI
func play_ui_sound(sound_name: String) -> void:
	play_sound("ui/%s" % sound_name)

## Воспроизвести звук боя
func play_combat_sound(sound_name: String) -> void:
	play_sound("combat/%s" % sound_name)

## Воспроизвести звук окружения
func play_environment_sound(sound_name: String, loop: bool = true) -> void:
	play_sound("environment/%s" % sound_name, loop)

## Воспроизвести звук эффекта
func play_effect_sound(sound_name: String) -> void:
	play_sound("effects/%s" % sound_name)

## Воспроизвести звук
func play_sound(sound_path: String, loop: bool = false) -> void:
	if not asset_manager:
		push_warning("AssetManager not found, cannot play sound: %s" % sound_path)
		return
	
	var audio_stream = asset_manager.load_sound(sound_path)
	if not audio_stream:
		push_warning("Sound not found: %s" % sound_path)
		return
	
	var player: AudioStreamPlayer = null
	
	if audio_players.has(sound_path):
		player = audio_players[sound_path]
	else:
		player = AudioStreamPlayer.new()
		player.name = "AudioPlayer_%s" % sound_path.replace("/", "_")
		add_child(player)
		audio_players[sound_path] = player
	
	player.stream = audio_stream
	if loop:
		player.stream.set_loop(true)
	
	player.play()

## Остановить звук
func stop_sound(sound_path: String) -> void:
	if audio_players.has(sound_path):
		var player = audio_players[sound_path]
		player.stop()

## Установить громкость
func set_volume(sound_path: String, volume_db: float) -> void:
	if audio_players.has(sound_path):
		var player = audio_players[sound_path]
		player.volume_db = volume_db

