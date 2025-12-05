extends Resource
class_name RecipeResource

enum RecipeCategory { WEAPONS, ARMOR, TOOLS, SHIPS, BUILDINGS, ALCHEMY, MAGIC }

@export var id: StringName
@export var name: String
@export var category: RecipeCategory = RecipeCategory.WEAPONS

@export var ingredients: Array[Dictionary] = [] # {item_id: StringName, amount: int}
@export var result_item: Resource
@export var result_quantity: int = 1
@export var crafting_time: float = 1.0
@export var required_building: StringName
@export var required_skill_level: int = 0


