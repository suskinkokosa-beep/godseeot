extends Node
class_name AssetManager

## Система управления ассетами для Isleborn Online
## Загружает и управляет всеми игровыми ресурсами

enum AssetType {
	MODEL,
	TEXTURE,
	SHADER,
	SOUND,
	ANIMATION
}

var loaded_assets: Dictionary = {}  # path -> Resource
var asset_cache: Dictionary = {}     # path -> Resource

signal asset_loaded(asset_path: String, asset: Resource)
signal asset_failed(asset_path: String, error: String)

func _ready() -> void:
	_preload_critical_assets()

func _preload_critical_assets() -> void:
	# Предзагрузка критически важных ассетов
	pass

## Загрузить ассет
func load_asset(path: String, asset_type: AssetType = AssetType.MODEL) -> Resource:
	if loaded_assets.has(path):
		return loaded_assets[path]
	
	if asset_cache.has(path):
		var cached = asset_cache[path]
		loaded_assets[path] = cached
		return cached
	
	var resource: Resource = null
	
	match asset_type:
		AssetType.MODEL:
			resource = load(path) as PackedScene
		AssetType.TEXTURE:
			resource = load(path) as Texture2D
		AssetType.SHADER:
			resource = load(path) as Shader
		AssetType.SOUND:
			resource = load(path) as AudioStream
		AssetType.ANIMATION:
			resource = load(path) as Animation
	
	if resource:
		loaded_assets[path] = resource
		asset_cache[path] = resource
		asset_loaded.emit(path, resource)
		return resource
	else:
		asset_failed.emit(path, "Failed to load asset")
		return null

## Загрузить модель персонажа
func load_character_model(gender: String, variant: String = "default") -> PackedScene:
	var path = "res://assets/models/characters/%s/%s.tscn" % [gender, variant]
	return load_asset(path, AssetType.MODEL) as PackedScene

## Загрузить анимацию персонажа
func load_character_animation(animation_name: String) -> Animation:
	var path = "res://assets/models/characters/animations/%s.tres" % animation_name
	return load_asset(path, AssetType.ANIMATION) as Animation

## Загрузить модель монстра
func load_monster_model(monster_id: String) -> PackedScene:
	var path = "res://assets/models/monsters/%s.tscn" % monster_id
	return load_asset(path, AssetType.MODEL) as PackedScene

## Загрузить модель босса
func load_boss_model(boss_id: String) -> PackedScene:
	var path = "res://assets/models/bosses/%s.tscn" % boss_id
	return load_asset(path, AssetType.MODEL) as PackedScene

## Загрузить модель постройки
func load_building_model(building_type: String) -> PackedScene:
	var path = "res://assets/models/buildings/%s.tscn" % building_type
	return load_asset(path, AssetType.MODEL) as PackedScene

## Загрузить текстуру
func load_texture(texture_path: String) -> Texture2D:
	var path = "res://assets/textures/%s" % texture_path
	return load_asset(path, AssetType.TEXTURE) as Texture2D

## Загрузить звук
func load_sound(sound_path: String) -> AudioStream:
	var path = "res://assets/sounds/%s" % sound_path
	return load_asset(path, AssetType.SOUND) as AudioStream

## Загрузить шейдер
func load_shader(shader_name: String) -> Shader:
	var path = "res://assets/shaders/%s.gdshader" % shader_name
	return load_asset(path, AssetType.SHADER) as Shader

## Выгрузить ассет из памяти
func unload_asset(path: String) -> void:
	if loaded_assets.has(path):
		loaded_assets.erase(path)

## Очистить кэш
func clear_cache() -> void:
	loaded_assets.clear()
	asset_cache.clear()

## Получить список доступных моделей персонажей
func get_available_character_models(gender: String) -> Array[String]:
	var models: Array[String] = []
	var dir_path = "res://assets/models/characters/%s/" % gender
	
	if DirAccess.dir_exists_absolute(dir_path):
		var dir = DirAccess.open(dir_path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tscn"):
					models.append(file_name.get_basename())
				file_name = dir.get_next()
	
	return models

## Получить список доступных анимаций
func get_available_animations() -> Array[String]:
	var animations: Array[String] = []
	var dir_path = "res://assets/models/characters/animations/"
	
	if DirAccess.dir_exists_absolute(dir_path):
		var dir = DirAccess.open(dir_path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tres"):
					animations.append(file_name.get_basename())
				file_name = dir.get_next()
	
	return animations

