extends Node
class_name MonsterSpawnVisual

## Интеграция визуализации при спавне монстров

static func spawn_monster_visual(monster_id: String, position: Vector3, parent: Node) -> Node3D:
	var world = parent.get_tree().current_scene if parent.get_tree() else null
	if not world:
		return null
	
	var monster_integration = world.find_child("MonsterVisualIntegration", true, false)
	if not monster_integration:
		# Создаём placeholder
		return _create_placeholder_monster(monster_id, position, parent)
	
	var visual = monster_integration.create_monster_visual(monster_id, position)
	if visual:
		parent.add_child(visual)
		return visual
	
	return _create_placeholder_monster(monster_id, position, parent)

static func _create_placeholder_monster(monster_id: String, position: Vector3, parent: Node) -> Node3D:
	var placeholder = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.5
	placeholder.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.6, 0.2)
	placeholder.material_override = material
	placeholder.position = position
	placeholder.name = "Monster_%s_Placeholder" % monster_id
	
	parent.add_child(placeholder)
	return placeholder

