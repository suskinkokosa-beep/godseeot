extends Node3D
class_name OceanManager

## Управляет визуализацией океана в игре Isleborn Online

@export var ocean_size: float = 1000.0
@export var ocean_tile_size: float = 100.0
@export var wave_speed: float = 1.0
@export var wave_height: float = 0.5
@export var shallow_color: Color = Color(0.2, 0.6, 0.9, 0.8)
@export var deep_color: Color = Color(0.05, 0.2, 0.4, 0.95)

var ocean_tiles: Array[Node3D] = []
var shader_material: ShaderMaterial

func _ready() -> void:
	_create_ocean()

func _create_ocean() -> void:
	# Загружаем шейдер
	var shader := load("res://shaders/ocean_water_3d.gdshader") as Shader
	if not shader:
		push_error("Ocean shader not found!")
		return
	
	# Создаём материал из шейдера
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	
	# Устанавливаем параметры материала
	shader_material.set_shader_parameter("time_scale", 0.5)
	shader_material.set_shader_parameter("wave_speed", wave_speed)
	shader_material.set_shader_parameter("wave_height", wave_height)
	shader_material.set_shader_parameter("shallow_color", shallow_color)
	shader_material.set_shader_parameter("deep_color", deep_color)
	shader_material.set_shader_parameter("transparency", 0.7)
	
	# Создаём тайлы океана для покрытия большой области
	var tiles_per_side := int(ceil(ocean_size / ocean_tile_size))
	var offset := -ocean_size / 2.0
	
	for x in range(tiles_per_side):
		for z in range(tiles_per_side):
			var tile := _create_ocean_tile(
				offset + x * ocean_tile_size,
				offset + z * ocean_tile_size
			)
			ocean_tiles.append(tile)
			add_child(tile)

func _create_ocean_tile(x: float, z: float) -> MeshInstance3D:
	var plane := PlaneMesh.new()
	plane.size = Vector2(ocean_tile_size, ocean_tile_size)
	plane.subdivide_width = 32
	plane.subdivide_depth = 32
	
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = plane
	mesh_instance.material_override = shader_material
	mesh_instance.translation = Vector3(x + ocean_tile_size / 2.0, 0.0, z + ocean_tile_size / 2.0)
	mesh_instance.name = "OceanTile_%d_%d" % [x, z]
	
	return mesh_instance

func set_biome_colors(shallow: Color, deep: Color) -> void:
	shallow_color = shallow
	deep_color = deep
	if shader_material:
		shader_material.set_shader_parameter("shallow_color", shallow)
		shader_material.set_shader_parameter("deep_color", deep)

