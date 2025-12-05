extends Node
class_name MonsterVisualIntegration

## Интеграция визуальных моделей монстров и боссов

@export var asset_manager_path: NodePath
var asset_manager: AssetManager

func _ready() -> void:
	if asset_manager_path != NodePath():
		asset_manager = get_node(asset_manager_path)
	else:
		asset_manager = get_node("/root/World/AssetManager") if get_tree().has_group("asset_manager") else null

## Создать визуализацию монстра
func create_monster_visual(monster_id: String, position: Vector3, environment: int = 0, depth: float = 0.0) -> Node3D:
	if not asset_manager:
		push_error("AssetManager not found!")
		return null
	
	var model_scene = asset_manager.load_monster_model(monster_id)
	if not model_scene:
		push_warning("Monster model not found: %s" % monster_id)
		# Создаём placeholder
		return _create_placeholder_monster(monster_id, position, environment, depth)
	
	var monster_instance = model_scene.instantiate()
	monster_instance.position = position
	
	# Устанавливаем позицию Y в зависимости от окружения
	match environment:
		0:  # SURFACE
			monster_instance.position.y = 0.0
		1:  # UNDERWATER
			monster_instance.position.y = -depth
		2:  # LAND
			monster_instance.position.y = position.y
		3:  # BOTH
			if depth > 0.0:
				monster_instance.position.y = -depth
			else:
				monster_instance.position.y = 0.0
	
	monster_instance.name = "Monster_%s" % monster_id
	
	# Устанавливаем метаданные для системы воды
	monster_instance.set_meta("monster_environment", environment)
	monster_instance.set_meta("depth", depth)
	
	# Применяем текстуру
	_apply_monster_texture(monster_instance, monster_id)
	
	# Добавляем визуальные эффекты для подводных монстров
	if environment == 1 or (environment == 3 and depth > 0.0):
		_add_underwater_effects(monster_instance)
	
	return monster_instance

## Создать визуализацию босса
func create_boss_visual(boss_id: String, position: Vector3) -> Node3D:
	if not asset_manager:
		push_error("AssetManager not found!")
		return null
	
	var model_scene = asset_manager.load_boss_model(boss_id)
	if not model_scene:
		push_warning("Boss model not found: %s" % boss_id)
		return _create_placeholder_boss(boss_id, position)
	
	var boss_instance = model_scene.instantiate()
	boss_instance.position = position
	boss_instance.name = "Boss_%s" % boss_id
	
	# Применяем текстуру
	_apply_monster_texture(boss_instance, boss_id)
	
	# Добавляем эффекты для босса
	_add_boss_effects(boss_instance)
	
	return boss_instance

func _apply_monster_texture(monster_node: Node3D, monster_id: String) -> void:
	if not asset_manager:
		return
	
	var texture = asset_manager.load_texture("monsters/%s_diffuse.png" % monster_id)
	if texture:
		_apply_texture_recursive(monster_node, texture)

func _apply_texture_recursive(node: Node, texture: Texture2D) -> void:
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		var material = StandardMaterial3D.new()
		material.albedo_texture = texture
		mesh_instance.material_override = material
	
	for child in node.get_children():
		_apply_texture_recursive(child, texture)

func _add_boss_effects(boss_node: Node3D) -> void:
	# Добавляем эффект свечения для босса
	var glow_material = StandardMaterial3D.new()
	glow_material.emission_enabled = true
	glow_material.emission = Color(1.0, 0.3, 0.3, 1.0)
	glow_material.emission_energy_multiplier = 2.0
	
	# Применяем к основному мешу
	for child in boss_node.get_children():
		if child is MeshInstance3D:
			child.material_override = glow_material
			break

func _create_placeholder_monster(monster_id: String, position: Vector3) -> Node3D:
	# Создаём простой placeholder
	var placeholder = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	placeholder.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.2, 0.2)
	placeholder.material_override = material
	placeholder.position = position
	placeholder.name = "Monster_%s_Placeholder" % monster_id
	
	return placeholder

func _create_placeholder_boss(boss_id: String, position: Vector3) -> Node3D:
	# Создаём большой placeholder для босса
	var placeholder = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 2.0
	sphere.height = 4.0
	placeholder.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.1, 0.1)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.3, 0.3)
	placeholder.material_override = material
	placeholder.position = position
	placeholder.name = "Boss_%s_Placeholder" % boss_id
	
	return placeholder

