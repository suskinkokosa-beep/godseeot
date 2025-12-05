extends Node
class_name ExpandedRecipeDatabase

## Расширенная база данных рецептов Isleborn Online
## Дополняет основную RecipeDatabase

static func register_expanded_recipes(recipe_db: Dictionary) -> void:
	_register_weapon_recipes(recipe_db)
	_register_armor_recipes(recipe_db)
	_register_tool_recipes(recipe_db)
	_register_ship_recipes(recipe_db)
	_register_building_recipes(recipe_db)
	_register_alchemy_recipes(recipe_db)

## Рецепты оружия
static func _register_weapon_recipes(recipes: Dictionary) -> void:
	# Базовое оружие
	recipes["stone_knife"] = {
		"id": "stone_knife",
		"name": "Каменный нож",
		"category": "WEAPONS",
		"result_item": "stone_knife",
		"result_quantity": 1,
		"crafting_time": 2.0,
		"ingredients": [
			{"item_id": "stone", "amount": 2},
			{"item_id": "stick", "amount": 1}
		],
		"required_building": "campfire",
		"required_skill_level": 1,
		"level": 1
	}
	
	recipes["spear"] = {
		"id": "spear",
		"name": "Копьё",
		"category": "WEAPONS",
		"result_item": "spear",
		"result_quantity": 1,
		"crafting_time": 5.0,
		"ingredients": [
			{"item_id": "stick", "amount": 2},
			{"item_id": "stone", "amount": 3},
			{"item_id": "rope", "amount": 1}
		],
		"required_building": "campfire",
		"required_skill_level": 2,
		"level": 3
	}
	
	recipes["wooden_sword"] = {
		"id": "wooden_sword",
		"name": "Деревянный меч",
		"category": "WEAPONS",
		"result_item": "wooden_sword",
		"result_quantity": 1,
		"crafting_time": 8.0,
		"ingredients": [
			{"item_id": "palm_wood", "amount": 3},
			{"item_id": "rope", "amount": 2},
			{"item_id": "stone", "amount": 1}
		],
		"required_building": "workshop_l1",
		"required_skill_level": 3,
		"level": 3
	}
	
	recipes["wooden_bow"] = {
		"id": "wooden_bow",
		"name": "Деревянный лук",
		"category": "WEAPONS",
		"result_item": "wooden_bow",
		"result_quantity": 1,
		"crafting_time": 10.0,
		"ingredients": [
			{"item_id": "palm_wood", "amount": 2},
			{"item_id": "rope", "amount": 3}
		],
		"required_building": "workshop_l1",
		"required_skill_level": 4,
		"level": 5
	}
	
	recipes["iron_sword"] = {
		"id": "iron_sword",
		"name": "Железный меч",
		"category": "WEAPONS",
		"result_item": "iron_sword",
		"result_quantity": 1,
		"crafting_time": 30.0,
		"ingredients": [
			{"item_id": "metal_ingot", "amount": 5},
			{"item_id": "palm_wood", "amount": 2},
			{"item_id": "rope", "amount": 1}
		],
		"required_building": "forge_l1",
		"required_skill_level": 8,
		"level": 12
	}

## Рецепты брони
static func _register_armor_recipes(recipes: Dictionary) -> void:
	recipes["cloth_helmet"] = {
		"id": "cloth_helmet",
		"name": "Тканевый капюшон",
		"category": "ARMOR",
		"result_item": "cloth_helmet",
		"result_quantity": 1,
		"crafting_time": 5.0,
		"ingredients": [
			{"item_id": "fabric", "amount": 2},
			{"item_id": "rope", "amount": 1}
		],
		"required_building": "campfire",
		"required_skill_level": 1,
		"level": 1
	}
	
	recipes["cloth_chest"] = {
		"id": "cloth_chest",
		"name": "Тканевая рубаха",
		"category": "ARMOR",
		"result_item": "cloth_chest",
		"result_quantity": 1,
		"crafting_time": 8.0,
		"ingredients": [
			{"item_id": "fabric", "amount": 4},
			{"item_id": "rope", "amount": 2}
		],
		"required_building": "campfire",
		"required_skill_level": 2,
		"level": 1
	}
	
	recipes["leather_helmet"] = {
		"id": "leather_helmet",
		"name": "Кожаный шлем",
		"category": "ARMOR",
		"result_item": "leather_helmet",
		"result_quantity": 1,
		"crafting_time": 15.0,
		"ingredients": [
			{"item_id": "fabric", "amount": 3},
			{"item_id": "rope", "amount": 2},
			{"item_id": "palm_wood", "amount": 1}
		],
		"required_building": "workshop_l1",
		"required_skill_level": 5,
		"level": 5
	}

## Рецепты инструментов
static func _register_tool_recipes(recipes: Dictionary) -> void:
	recipes["fishing_rod"] = {
		"id": "fishing_rod",
		"name": "Удочка",
		"category": "TOOLS",
		"result_item": "fishing_rod",
		"result_quantity": 1,
		"crafting_time": 5.0,
		"ingredients": [
			{"item_id": "stick", "amount": 2},
			{"item_id": "rope", "amount": 1}
		],
		"required_building": "campfire",
		"required_skill_level": 1,
		"level": 1
	}
	
	recipes["pickaxe"] = {
		"id": "pickaxe",
		"name": "Кирка",
		"category": "TOOLS",
		"result_item": "pickaxe",
		"result_quantity": 1,
		"crafting_time": 6.0,
		"ingredients": [
			{"item_id": "stick", "amount": 2},
			{"item_id": "stone", "amount": 3},
			{"item_id": "rope", "amount": 1}
		],
		"required_building": "campfire",
		"required_skill_level": 2,
		"level": 1
	}

## Рецепты кораблей
static func _register_ship_recipes(recipes: Dictionary) -> void:
	recipes["raft"] = {
		"id": "raft",
		"name": "Плот",
		"category": "SHIPS",
		"result_item": "raft",
		"result_quantity": 1,
		"crafting_time": 30.0,
		"ingredients": [
			{"item_id": "palm_wood", "amount": 10},
			{"item_id": "rope", "amount": 2}
		],
		"required_building": "shipyard_l1",
		"required_skill_level": 1,
		"level": 1
	}
	
	recipes["canoe"] = {
		"id": "canoe",
		"name": "Каноэ",
		"category": "SHIPS",
		"result_item": "canoe",
		"result_quantity": 1,
		"crafting_time": 45.0,
		"ingredients": [
			{"item_id": "palm_wood", "amount": 15},
			{"item_id": "rope", "amount": 5},
			{"item_id": "fabric", "amount": 2}
		],
		"required_building": "shipyard_l1",
		"required_skill_level": 3,
		"level": 2
	}
	
	recipes["fishing_boat"] = {
		"id": "fishing_boat",
		"name": "Рыбацкая лодка",
		"category": "SHIPS",
		"result_item": "fishing_boat",
		"result_quantity": 1,
		"crafting_time": 60.0,
		"ingredients": [
			{"item_id": "palm_wood", "amount": 25},
			{"item_id": "rope", "amount": 8},
			{"item_id": "fabric", "amount": 5},
			{"item_id": "metal_ingot", "amount": 2}
		],
		"required_building": "shipyard_l2",
		"required_skill_level": 5,
		"level": 3
	}

## Рецепты построек
static func _register_building_recipes(recipes: Dictionary) -> void:
	recipes["campfire"] = {
		"id": "campfire",
		"name": "Костёр",
		"category": "BUILDINGS",
		"result_item": "campfire",
		"result_quantity": 1,
		"crafting_time": 5.0,
		"ingredients": [
			{"item_id": "stone", "amount": 5},
			{"item_id": "stick", "amount": 3}
		],
		"required_building": null,
		"required_skill_level": 0,
		"level": 1
	}
	
	recipes["workshop_l1"] = {
		"id": "workshop_l1",
		"name": "Мастерская (Уровень 1)",
		"category": "BUILDINGS",
		"result_item": "workshop_l1",
		"result_quantity": 1,
		"crafting_time": 120.0,
		"ingredients": [
			{"item_id": "palm_wood", "amount": 20},
			{"item_id": "stone", "amount": 15},
			{"item_id": "rope", "amount": 5}
		],
		"required_building": null,
		"required_skill_level": 3,
		"level": 3
	}
	
	recipes["shipyard_l1"] = {
		"id": "shipyard_l1",
		"name": "Верфь (Уровень 1)",
		"category": "BUILDINGS",
		"result_item": "shipyard_l1",
		"result_quantity": 1,
		"crafting_time": 180.0,
		"ingredients": [
			{"item_id": "palm_wood", "amount": 30},
			{"item_id": "stone", "amount": 20},
			{"item_id": "rope", "amount": 10},
			{"item_id": "fabric", "amount": 5}
		],
		"required_building": "workshop_l1",
		"required_skill_level": 5,
		"level": 5
	}

## Рецепты алхимии
static func _register_alchemy_recipes(recipes: Dictionary) -> void:
	recipes["healing_herb"] = {
		"id": "healing_herb",
		"name": "Целебная трава",
		"category": "ALCHEMY",
		"result_item": "healing_herb",
		"result_quantity": 3,
		"crafting_time": 5.0,
		"ingredients": [
			{"item_id": "palm_wood", "amount": 1}  # TODO: заменить на травы
		],
		"required_building": "campfire",
		"required_skill_level": 1,
		"level": 1
	}

