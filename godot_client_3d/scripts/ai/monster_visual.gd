extends Node3D
class_name MonsterVisual

## Визуальное представление монстра
## Интегрирует модели и текстуры монстров

@export var monster_id: String = ""
@export var animation_player_path: NodePath

var model_instance: Node3D = null
var animation_player: AnimationPlayer = null
var monster_integration: MonsterVisualIntegration = null

func _ready() -> void:
	# Находим системы интеграции
	var world = get_tree().current_scene
	if world:
		monster_integration = world.find_child("MonsterVisualIntegration", true, false)
	
	# Находим AnimationPlayer
	if animation_player_path != NodePath():
		animation_player = get_node(animation_player_path)
	else:
		animation_player = find_child("AnimationPlayer", true, false)
		if not animation_player:
			animation_player = AnimationPlayer.new()
			animation_player.name = "AnimationPlayer"
			add_child(animation_player)
	
	# Применяем модель
	if monster_id != "":
		apply_monster_model()

func apply_monster_model() -> void:
	if monster_integration and monster_id != "":
		var visual = monster_integration.create_monster_visual(monster_id, Vector3.ZERO)
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
	var capsule = MeshInstance3D.new()
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.radius = 0.4
	capsule_mesh.height = 1.2
	capsule.mesh = capsule_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.6, 0.2)
	capsule.material_override = material
	capsule.name = "Model"
	
	add_child(capsule)
	model_instance = capsule

func play_animation(animation_name: String) -> void:
	if animation_player and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)

