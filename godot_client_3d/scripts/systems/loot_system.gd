extends Node
class_name LootSystem

## Система дропа и лута для монстров
## Использует таблицы дропа из MonsterDatabase
## Включает книги навыков в дроп

const RARITY_WEIGHTS = {
	"common": 70,
	"uncommon": 20,
	"rare": 7,
	"epic": 2.5,
	"legendary": 0.5
}

## Генерирует лут на основе таблицы дропа монстра
## luck: скрытый параметр удачи игрока (0-100)
static func generate_loot(monster_data: Dictionary, luck: float = 0.0) -> Array[Dictionary]:
	var loot: Array[Dictionary] = []
	
	if not monster_data.has("loot_table"):
		return loot
	
	var loot_table = monster_data["loot_table"]
	var monster_tier = monster_data.get("tier", 1)
	
	# Обрабатываем каждую редкость
	for rarity in loot_table.keys():
		var items = loot_table[rarity]
		
		for item_data in items:
			var base_chance = item_data.get("chance", 0.0)
			
			# Формула дропа с учётом удачи: BaseDrop * (1 + Luck/110)
			var drop_chance = base_chance * (1.0 + luck / 110.0)
			
			# Ограничиваем шанс максимумом 95%
			drop_chance = min(drop_chance, 0.95)
			
			if randf() < drop_chance:
				var quantity = item_data.get("quantity", 1)
				var item_id = item_data.get("item_id", "")
				
				# Проверяем, является ли это книгой навыков
				if item_id.begins_with("book_"):
					loot.append({
						"item_id": item_id,
						"quantity": quantity,
						"rarity": rarity,
						"type": "skill_book"
					})
				else:
					loot.append({
						"item_id": item_id,
						"quantity": quantity,
						"rarity": rarity,
						"type": "item"
					})
	
	# Генерируем материалы для заточки
	var enhancement_materials = EnhancementMaterials.generate_material_drop(monster_tier, luck)
	for material_id in enhancement_materials:
		loot.append({
			"item_id": material_id,
			"quantity": 1,
			"rarity": "common",
			"type": "enhancement_material"
		})
	
	return loot


## Генерирует дроп книг навыков на основе уровня монстра
static func generate_skill_book_drop(monster_tier: int, luck: float = 0.0) -> String:
	# Шанс дропа книги навыков зависит от тира монстра
	var base_chance = 0.05 + (monster_tier * 0.02)  # T1: 7%, T5: 15%
	var adjusted_chance = base_chance * (1.0 + luck / 110.0)
	
	if randf() < adjusted_chance:
		# Выбираем случайную книгу навыка на основе тира
		var skill_books = SkillBookDatabase.get_books_by_source("monster_drop")
		var available_books: Array[Dictionary] = []
		
		for book in skill_books:
			var details = book.get("source_details", {})
			var book_tier = details.get("monster_tier", 1)
			if book_tier <= monster_tier:
				available_books.append(book)
		
		if available_books.size() > 0:
			var selected_book = available_books[randi() % available_books.size()]
			return selected_book.get("id", "")
	
	return ""


## Вычисляет базовый шанс дропа с учётом редкости
static func get_base_drop_chance(rarity: String) -> float:
	return RARITY_WEIGHTS.get(rarity, 0.0) / 100.0


## Проверяет, должен ли выпасть лут определённой редкости
static func should_drop_rarity(rarity: String, luck: float = 0.0) -> bool:
	var base_weight = RARITY_WEIGHTS.get(rarity, 0.0)
	if base_weight == 0.0:
		return false
	
	# Увеличиваем шанс с удачей
	var adjusted_weight = base_weight * (1.0 + luck / 110.0)
	var total_weight = 100.0 + luck
	
	return randf() < (adjusted_weight / total_weight)
