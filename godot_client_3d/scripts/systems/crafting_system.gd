extends Node
class_name CraftingSystem

## Simple client-side crafting that uses RecipeDatabase and InventorySystem.

@export var inventory_path: NodePath

var _inventory: InventorySystem

func _ready() -> void:
	if inventory_path != NodePath():
		_inventory = get_node(inventory_path)


func can_craft(recipe_id: String) -> bool:
	if _inventory == null:
		return false
	var recipe := RecipeDatabase.get_recipe(recipe_id)
	if recipe.is_empty():
		return false
	var ingredients := recipe.get("ingredients", [])
	return _inventory.has_items(ingredients)


func craft(recipe_id: String) -> bool:
	if _inventory == null:
		return false
	var recipe := RecipeDatabase.get_recipe(recipe_id)
	if recipe.is_empty():
		return false
	var ingredients := recipe.get("ingredients", [])
	if not _inventory.apply_requirements(ingredients):
		return false
	var result_id := str(recipe.get("result_item", ""))
	var qty := int(recipe.get("result_quantity", 1))
	if result_id == "":
		return false
	_inventory.add_item(result_id, max(qty, 1))
	return true


