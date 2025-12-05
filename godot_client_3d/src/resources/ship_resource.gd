extends Resource
class_name ShipResource

enum ShipClass { RAFT, CANOE, BOAT, SCHOONER, FRIGATE, GALLEON, FLAGSHIP }

@export var id: StringName
@export var name: String
@export var ship_class: ShipClass = ShipClass.RAFT

@export var base_health: float = 100.0
@export var base_speed: float = 5.0
@export var cargo_capacity: int = 0
@export var crew_capacity: int = 1
@export var weapon_slots: int = 0
@export var module_slots: int = 0

@export var cost: Dictionary = {}


