extends Node
class_name BuildingSpawnVisual

## Интеграция визуализации при создании построек

static func spawn_building_visual(building_type: String, position: Vector3, rotation: float, parent: Node) -> Node3D:
	var world = parent.get_tree().current_scene if parent.get_tree() else null
	if not world:
		return _create_placeholder_building(building_type, position, parent)
	
	var building_integration = world.find_child("BuildingVisualIntegration", true, false)
	if not building_integration:
		return _create_placeholder_building(building_type, position, parent)
	
	var visual = building_integration.create_building_visual(building_type, position, rotation)
	if visual:
		parent.add_child(visual)
		return visual
	
	return _create_placeholder_building(building_type, position, parent)

static func _create_placeholder_building(building_type: String, position: Vector3, parent: Node) -> Node3D:
	var placeholder = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(2.0, 2.0, 2.0)
	placeholder.mesh = box
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.4, 0.2)
	placeholder.material_override = material
	placeholder.position = position
	placeholder.name = "Building_%s_Placeholder" % building_type
	
	parent.add_child(placeholder)
	return placeholder

