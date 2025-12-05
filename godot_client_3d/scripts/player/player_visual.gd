extends Node3D
class_name PlayerVisual

## Визуальное представление игрока
## Интегрирует модели, анимации и текстуры

@export var gender: String = "male"
@export var character_variant: String = "default"
@export var animation_player_path: NodePath

var model_instance: Node3D = null
var animation_player: AnimationPlayer = null
var character_integration: CharacterVisualIntegration = null

signal animation_finished(animation_name: String)

func _ready() -> void:
	# Находим системы интеграции
	var world = get_tree().current_scene
	if world:
		character_integration = world.find_child("CharacterVisualIntegration", true, false)
	
	# Находим AnimationPlayer
	if animation_player_path != NodePath():
		animation_player = get_node(animation_player_path)
	else:
		animation_player = find_child("AnimationPlayer", true, false)
		if not animation_player:
			# Создаём AnimationPlayer если его нет
			animation_player = AnimationPlayer.new()
			animation_player.name = "AnimationPlayer"
			add_child(animation_player)
	
	# Применяем модель
	apply_character_model()

func apply_character_model() -> void:
	if character_integration:
		character_integration.apply_character_model(self, gender, character_variant)
		character_integration.apply_character_animations(self, animation_player)
	else:
		_create_placeholder_model()

func _create_placeholder_model() -> void:
	# Создаём простой placeholder
	var capsule = MeshInstance3D.new()
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.radius = 0.3
	capsule_mesh.height = 1.6
	capsule.mesh = capsule_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.6, 0.4) if gender == "male" else Color(1.0, 0.8, 0.7)
	capsule.material_override = material
	capsule.name = "Model"
	
	add_child(capsule)
	model_instance = capsule

func play_animation(animation_name: String) -> void:
	if animation_player and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
	else:
		push_warning("Animation not found: %s" % animation_name)

func set_gender(new_gender: String) -> void:
	gender = new_gender
	apply_character_model()

func set_character_variant(new_variant: String) -> void:
	character_variant = new_variant
	apply_character_model()

