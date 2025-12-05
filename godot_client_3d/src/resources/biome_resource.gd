extends Resource
class_name BiomeResource

@export var id: StringName
@export var name: String

@export var depth_range: Vector2 = Vector2(0.0, 100.0)
@export var temperature_range: Vector2 = Vector2(0.0, 30.0)

@export var monster_spawns: Array[Resource] = []
@export var resource_spawns: Array[Resource] = []
@export var weather_weights: Dictionary = {}


