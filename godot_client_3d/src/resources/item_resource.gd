extends Resource
class_name ItemResource

@export var id: StringName
@export var name: String
@export var description: String = ""
@export var icon: Texture2D

enum ItemRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
@export var rarity: ItemRarity = ItemRarity.COMMON

@export var max_stack: int = 99
@export var weight: float = 1.0
@export var sell_price: int = 0


