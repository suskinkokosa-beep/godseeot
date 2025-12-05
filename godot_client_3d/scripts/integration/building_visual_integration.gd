extends Node
class_name BuildingVisualIntegration

## Интеграция визуальных моделей построек

@export var asset_manager_path: NodePath
var asset_manager: AssetManager

func _ready() -> void:
	if asset_manager_path != NodePath():
		asset_manager = get_node(asset_manager_path)
	else:
		asset_manager = get_node("/root/World/AssetManager") if get_tree().has_group("asset_manager") else null

## Создать визуализацию постройки
func create_building_visual(building_type: String, position: Vector3, rotation: float = 0.0) -> Node3D:
	if not asset_manager:
		push_error("AssetManager not found!")
		return _create_placeholder_building(building_type, position)
	
	var model_scene = asset_manager.load_building_model(building_type)
	if not model_scene:
		push_warning("Building model not found: %s" % building_type)
		return _create_placeholder_building(building_type, position)
	
	var building_instance = model_scene.instantiate()
	building_instance.position = position
	building_instance.rotation.y = rotation
	building_instance.name = "Building_%s" % building_type
	
	# Применяем текстуру
	_apply_building_texture(building_instance, building_type)
	
	return building_instance

func _apply_building_texture(building_node: Node3D, building_type: String) -> void:
	if not asset_manager:
		return
	
	var texture = asset_manager.load_texture("buildings/%s_diffuse.png" % building_type)
	if texture:
		_apply_texture_recursive(building_node, texture)

func _apply_texture_recursive(node: Node, texture: Texture2D) -> void:
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		var material = StandardMaterial3D.new()
		material.albedo_texture = texture
		mesh_instance.material_override = material
	
	for child in node.get_children():
		_apply_texture_recursive(child, texture)

func _create_placeholder_building(building_type: String, position: Vector3) -> Node3D:
	# Создаём простой placeholder
	var placeholder = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(2.0, 2.0, 2.0)
	placeholder.mesh = box
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.4, 0.2)
	placeholder.material_override = material
	placeholder.position = position
	placeholder.name = "Building_%s_Placeholder" % building_type
	
	return placeholder

