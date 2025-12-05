extends Node
# class_name RecipeDatabase  # Removed to avoid autoload conflict

## Registry of crafting recipes (weapons, tools, ships, buildings, alchemy).

var recipes: Dictionary = {}

func _ready() -> void:
	_register_core_recipes()


func _register_core_recipes() -> void:
	# Регистрируем расширенные рецепты
	ExpandedRecipeDatabase.register_expanded_recipes(recipes)


func get_recipe(id: String) -> Dictionary:
	return recipes.get(id, {})


