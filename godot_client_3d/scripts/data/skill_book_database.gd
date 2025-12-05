extends Node
# class_name SkillBookDatabase  # Removed to avoid autoload conflict

## База данных книг навыков
## Книги можно получить из различных источников

var skill_books: Dictionary = {}  # book_id -> skill_id

func _ready() -> void:
	_register_all_skill_books()

func _register_all_skill_books() -> void:
	# Каждый навык имеет свою книгу
	# Книги могут быть получены из:
	# - Дроп с монстров
	# - Награды за квесты
	# - Покупка у NPC
	# - Изучение у других игроков
	# - Находки в руинах
	
	# Примеры книг для разных источников
	
	# Дроп с монстров T1
	skill_books["book_slash_drop"] = {
		"id": "book_slash_drop",
		"skill_id": "slash",
		"name": "Книга: Рез",
		"description": "Обучает навыку 'Рез'",
		"source": "monster_drop",
		"source_details": {"monster_tier": 1, "drop_chance": 0.05}
	}
	
	# Награда за квест
	skill_books["book_water_bolt_quest"] = {
		"id": "book_water_bolt_quest",
		"skill_id": "water_bolt",
		"name": "Книга: Водный болт",
		"description": "Обучает навыку 'Водный болт'",
		"source": "quest_reward",
		"source_details": {"quest_id": "first_magic"}
	}
	
	# Покупка у NPC
	skill_books["book_healing_potion_shop"] = {
		"id": "book_healing_potion_shop",
		"skill_id": "healing_potion",
		"name": "Книга: Зелье лечения",
		"description": "Обучает навыку 'Зелье лечения'",
		"source": "npc_shop",
		"source_details": {"npc_id": "alchemist", "cost": {"shells": 500}}
	}
	
	# Находка в руинах
	skill_books["book_tidal_vortex_ruin"] = {
		"id": "book_tidal_vortex_ruin",
		"skill_id": "tidal_vortex",
		"name": "Древняя книга: Водоворот",
		"description": "Обучает легендарному навыку 'Водоворот'",
		"source": "ruin_find",
		"source_details": {"ruin_type": "ancient_temple", "rarity": "legendary"}
	}
	
	# Дроп с боссов
	skill_books["book_void_blast_boss"] = {
		"id": "book_void_blast_boss",
		"skill_id": "void_blast",
		"name": "Книга Бездны: Взрыв пустоты",
		"description": "Обучает мифическому навыку 'Взрыв пустоты'",
		"source": "boss_drop",
		"source_details": {"boss_id": "abyss_lady", "drop_chance": 0.01}
	}


func get_skill_from_book(book_id: String) -> String:
	var book = skill_books.get(book_id, {})
	return book.get("skill_id", "")


func get_book(book_id: String) -> Dictionary:
	return skill_books.get(book_id, {})


func get_books_by_source(source: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for book_id in skill_books:
		var book = skill_books[book_id]
		if book.get("source", "") == source:
			result.append(book)
	return result


func get_books_for_skill(skill_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for book_id in skill_books:
		var book = skill_books[book_id]
		if book.get("skill_id", "") == skill_id:
			result.append(book)
	return result

