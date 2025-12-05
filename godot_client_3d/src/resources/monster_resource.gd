extends Resource
class_name MonsterResource

@export var id: StringName
@export var name: String
@export var tier: int = 1

@export var health: float = 10.0
@export var damage: float = 1.0
@export var speed: float = 1.0
@export var attack_range: float = 1.5

@export var loot_table: Resource
@export var spawn_biomes: Array[StringName] = []


