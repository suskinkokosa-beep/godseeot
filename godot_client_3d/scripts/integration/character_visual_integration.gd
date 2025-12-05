extends Node
class_name CharacterVisualIntegration

## Интеграция визуальных моделей персонажей в игру

@export var asset_manager_path: NodePath
var asset_manager: AssetManager

func _ready() -> void:
	if asset_manager_path != NodePath():
		asset_manager = get_node(asset_manager_path)
	else:
		asset_manager = get_node("/root/World/AssetManager") if get_tree().has_group("asset_manager") else null

## Применить модель персонажа
func apply_character_model(character_node: Node3D, gender: String, variant: String = "default") -> void:
	if not asset_manager:
		push_error("AssetManager not found!")
		return
	
	var model_scene = asset_manager.load_character_model(gender, variant)
	if not model_scene:
		push_warning("Character model not found: %s/%s" % [gender, variant])
		return
	
	# Удаляем старую модель
	for child in character_node.get_children():
		if child.name == "Model":
			child.queue_free()
	
	# Создаём новую модель
	var model_instance = model_scene.instantiate()
	model_instance.name = "Model"
	character_node.add_child(model_instance)
	
	# Настраиваем позицию
	model_instance.position = Vector3.ZERO

## Применить анимации к персонажу
func apply_character_animations(character_node: Node3D, animation_player: AnimationPlayer) -> void:
	if not asset_manager:
		return
	
	var animations = asset_manager.get_available_animations()
	
	for anim_name in animations:
		var animation = asset_manager.load_character_animation(anim_name)
		if animation:
			animation_player.add_animation(anim_name, animation)

## Применить текстуру к персонажу
func apply_character_texture(character_node: Node3D, texture_name: String) -> void:
	if not asset_manager:
		return
	
	var texture = asset_manager.load_texture("characters/%s" % texture_name)
	if not texture:
		return
	
	# Применяем текстуру ко всем MeshInstance3D
	_apply_texture_recursive(character_node, texture)

func _apply_texture_recursive(node: Node, texture: Texture2D) -> void:
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		var material = StandardMaterial3D.new()
		material.albedo_texture = texture
		mesh_instance.material_override = material
	
	for child in node.get_children():
		_apply_texture_recursive(child, texture)

