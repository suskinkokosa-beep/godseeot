extends Node3D
class_name IslandVisualizer

## Визуализирует остров игрока с пляжем, базой и ресурсами

@export var island_radius: float = 3.0
@export var beach_width: float = 0.5

var island_base: MeshInstance3D
var beach_ring: MeshInstance3D

func _ready() -> void:
	_create_island_base()
	_create_beach()

func _create_island_base() -> void:
	# Создаём цилиндрическую базу острова
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = island_radius
	cylinder.bottom_radius = island_radius
	cylinder.height = 0.3
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.3, 0.2)  # Земляной цвет
	mat.roughness = 0.9
	
	island_base = MeshInstance3D.new()
	island_base.mesh = cylinder
	island_base.material_override = mat
	island_base.translation = Vector3(0, -0.15, 0)
	add_child(island_base)

func _create_beach() -> void:
	# Создаём кольцо пляжа вокруг острова
	var torus := TorusMesh.new()
	torus.inner_radius = island_radius - 0.1
	torus.outer_radius = island_radius + beach_width
	torus.ring_inner_radius = 0.05
	torus.ring_outer_radius = 0.15
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.85, 0.7)  # Песчаный цвет
	mat.roughness = 0.8
	
	beach_ring = MeshInstance3D.new()
	beach_ring.mesh = torus
	beach_ring.material_override = mat
	beach_ring.translation = Vector3(0, 0, 0)
	beach_ring.rotation_degrees = Vector3(90, 0, 0)
	add_child(beach_ring)
	
	# Альтернатива: создаём кольцо из отдельных сегментов
	_create_beach_segments()

func _create_beach_segments() -> void:
	# Создаём кольцо пляжа из сегментов
	var beach_mat := StandardMaterial3D.new()
	beach_mat.albedo_color = Color(0.9, 0.85, 0.7)
	beach_mat.roughness = 0.8
	
	var segments := 32
	var angle_step := TAU / segments
	
	for i in range(segments):
		var angle := i * angle_step
		var inner_r := island_radius
		var outer_r := island_radius + beach_width
		
		# Создаём квадрат для сегмента пляжа
		var quad := QuadMesh.new()
		quad.size = Vector2(beach_width, 0.1)
		
		var segment := MeshInstance3D.new()
		segment.mesh = quad
		segment.material_override = beach_mat
		
		# Позиционируем сегмент
		var mid_r := (inner_r + outer_r) / 2.0
		segment.translation = Vector3(
			cos(angle) * mid_r,
			0.05,
			sin(angle) * mid_r
		)
		segment.rotation.y = angle + PI / 2.0
		
		add_child(segment)

func update_radius(new_radius: float) -> void:
	island_radius = new_radius
	# Обновляем визуализацию
	queue_free()
	_ready()

