extends Node3D
class_name BuildingVisual

## Визуальное представление постройки
## Интегрирует модели построек

@export var building_type: String = ""
@export var building_rotation: float = 0.0

var model_instance: Node3D = null
var building_integration: BuildingVisualIntegration = null

func _ready() -> void:
	# Находим системы интеграции
	var world = get_tree().current_scene
	if world:
		building_integration = world.find_child("BuildingVisualIntegration", true, false)
	
	# Применяем модель
	if building_type != "":
		apply_building_model()

func apply_building_model() -> void:
	if building_integration and building_type != "":
		var visual = building_integration.create_building_visual(building_type, Vector3.ZERO, building_rotation)
		if visual:
			# Удаляем старую модель
			if model_instance:
				model_instance.queue_free()
			
			# Добавляем новую
			visual.name = "Model"
			add_child(visual)
			model_instance = visual
	else:
		_create_placeholder_model()

func _create_placeholder_model() -> void:
	var box = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(2.0, 2.0, 2.0)
	box.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.4, 0.2)
	box.material_override = material
	box.name = "Model"
	
	add_child(box)
	model_instance = box

