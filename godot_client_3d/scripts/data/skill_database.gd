extends Node
class_name SkillDatabase

## База данных навыков Isleborn Online
## 100 активных навыков + 50 пассивных навыков

var skills: Dictionary = {}

func _ready() -> void:
	_register_all_skills()

func _register_all_skills() -> void:
	_register_melee_skills()
	_register_ranged_skills()
	_register_magic_skills()
	_register_alchemy_skills()
	_register_sailing_skills()
	_register_gathering_skills()
	_register_defense_skills()
	_register_movement_skills()
	_register_passive_skills()

## ============================================
## АКТИВНЫЕ НАВЫКИ - БЛИЖНИЙ БОЙ (15 навыков)
## ============================================

func _register_melee_skills() -> void:
	# Обычные
	skills["slash"] = {
		"id": "slash",
		"name": "Рез",
		"description": "Быстрая атака мечом",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.COMMON,
		"category": SkillSystem.SkillCategory.MELEE,
		"max_level": 5,
		"cooldown": 2.0,
		"stamina_cost": 15.0,
		"effects": {"damage": 50.0},
		"scaling": {"damage": 10.0}
	}
	
	skills["heavy_strike"] = {
		"id": "heavy_strike",
		"name": "Тяжёлый удар",
		"description": "Мощный удар с пробитием брони",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.COMMON,
		"category": SkillSystem.SkillCategory.MELEE,
		"max_level": 5,
		"cooldown": 4.0,
		"stamina_cost": 25.0,
		"effects": {"damage": 80.0, "armor_penetration": 0.3}
	}
	
	skills["whirlwind"] = {
		"id": "whirlwind",
		"name": "Вихрь",
		"description": "Вращающаяся атака по всем врагам вокруг",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.RARE,
		"category": SkillSystem.SkillCategory.MELEE,
		"max_level": 5,
		"cooldown": 8.0,
		"stamina_cost": 40.0,
		"effects": {"damage": 60.0, "aoe_radius": 3.0}
	}
	
	skills["shield_bash"] = {
		"id": "shield_bash",
		"name": "Удар щитом",
		"description": "Оглушает врага",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.COMMON,
		"category": SkillSystem.SkillCategory.MELEE,
		"max_level": 5,
		"cooldown": 5.0,
		"stamina_cost": 20.0,
		"effects": {"damage": 30.0, "stun_duration": 2.0}
	}
	
	skills["leap_strike"] = {
		"id": "leap_strike",
		"name": "Прыжок-удар",
		"description": "Прыжок к врагу с мощным ударом",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.RARE,
		"category": SkillSystem.SkillCategory.MELEE,
		"max_level": 5,
		"cooldown": 6.0,
		"stamina_cost": 30.0,
		"effects": {"damage": 100.0, "leap_range": 8.0}
	}
	
	skills["bloodthirst"] = {
		"id": "bloodthirst",
		"name": "Кровожадность",
		"description": "Каждая атака восстанавливает здоровье",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.LEGENDARY,
		"category": SkillSystem.SkillCategory.MELEE,
		"max_level": 3,
		"cooldown": 30.0,
		"stamina_cost": 50.0,
		"effects": {"lifesteal": 0.3, "duration": 15.0}
	}
	
	skills["berserker_rage"] = {
		"id": "berserker_rage",
		"name": "Ярость берсерка",
		"description": "Увеличивает урон и скорость атаки, снижает защиту",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.LEGENDARY,
		"category": SkillSystem.SkillCategory.MELEE,
		"max_level": 3,
		"cooldown": 60.0,
		"stamina_cost": 60.0,
		"effects": {"damage_multiplier": 1.5, "attack_speed": 1.3, "defense_reduction": 0.2, "duration": 20.0}
	}
	
	skills["tidal_slash"] = {
		"id": "tidal_slash",
		"name": "Приливный рез",
		"description": "Волна воды наносит урон перед вами",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.RARE,
		"category": SkillSystem.SkillCategory.MELEE,
		"max_level": 5,
		"cooldown": 10.0,
		"mana_cost": 30.0,
		"effects": {"damage": 90.0, "wave_range": 10.0}
	}
	
	# ... продолжение для всех 15 навыков ближнего боя

## ============================================
## АКТИВНЫЕ НАВЫКИ - ДАЛЬНИЙ БОЙ (15 навыков)
## ============================================

func _register_ranged_skills() -> void:
	skills["quick_shot"] = {
		"id": "quick_shot",
		"name": "Быстрый выстрел",
		"description": "Мгновенный выстрел из лука",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.COMMON,
		"category": SkillSystem.SkillCategory.RANGED,
		"max_level": 5,
		"cooldown": 1.0,
		"stamina_cost": 10.0,
		"effects": {"damage": 40.0, "range": 15.0}
	}
	
	skills["power_shot"] = {
		"id": "power_shot",
		"name": "Мощный выстрел",
		"description": "Заряженный выстрел с пробитием",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.COMMON,
		"category": SkillSystem.SkillCategory.RANGED,
		"max_level": 5,
		"cooldown": 3.0,
		"stamina_cost": 25.0,
		"effects": {"damage": 120.0, "range": 20.0, "armor_penetration": 0.5}
	}
	
	skills["multi_shot"] = {
		"id": "multi_shot",
		"name": "Залп стрел",
		"description": "Выпускает 3 стрелы одновременно",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.RARE,
		"category": SkillSystem.SkillCategory.RANGED,
		"max_level": 5,
		"cooldown": 5.0,
		"stamina_cost": 35.0,
		"effects": {"damage": 50.0, "arrow_count": 3}
	}
	
	skills["piercing_arrow"] = {
		"id": "piercing_arrow",
		"name": "Пронзающая стрела",
		"description": "Стрела пробивает несколько врагов",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.RARE,
		"category": SkillSystem.SkillCategory.RANGED,
		"max_level": 5,
		"cooldown": 6.0,
		"stamina_cost": 30.0,
		"effects": {"damage": 80.0, "pierce_count": 3}
	}
	
	skills["hunter_mark"] = {
		"id": "hunter_mark",
		"name": "Метка охотника",
		"description": "Отмечает врага, увеличивая урон по нему",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.RARE,
		"category": SkillSystem.SkillCategory.RANGED,
		"max_level": 5,
		"cooldown": 15.0,
		"mana_cost": 20.0,
		"effects": {"damage_bonus": 0.25, "duration": 30.0}
	}
	
	skills["explosive_arrow"] = {
		"id": "explosive_arrow",
		"name": "Взрывная стрела",
		"description": "Стрела взрывается при попадании",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.LEGENDARY,
		"category": SkillSystem.SkillCategory.RANGED,
		"max_level": 3,
		"cooldown": 12.0,
		"stamina_cost": 40.0,
		"effects": {"damage": 150.0, "explosion_radius": 3.0}
	}
	
	# ... продолжение для всех 15 навыков дальнего боя

## ============================================
## АКТИВНЫЕ НАВЫКИ - МАГИЯ (20 навыков)
## ============================================

func _register_magic_skills() -> void:
	skills["water_bolt"] = {
		"id": "water_bolt",
		"name": "Водный болт",
		"description": "Базовая магическая атака водой",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.COMMON,
		"category": SkillSystem.SkillCategory.MAGIC,
		"max_level": 5,
		"cooldown": 2.0,
		"mana_cost": 20.0,
		"effects": {"damage": 60.0, "range": 12.0}
	}
	
	skills["water_wave"] = {
		"id": "water_wave",
		"name": "Волна воды",
		"description": "Волна сбивает врагов",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.RARE,
		"category": SkillSystem.SkillCategory.MAGIC,
		"max_level": 5,
		"cooldown": 8.0,
		"mana_cost": 40.0,
		"effects": {"damage": 80.0, "wave_range": 8.0, "knockback": 5.0}
	}
	
	skills["water_shield"] = {
		"id": "water_shield",
		"name": "Водный щит",
		"description": "Поглощает часть урона",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.RARE,
		"category": SkillSystem.SkillCategory.MAGIC,
		"max_level": 5,
		"cooldown": 20.0,
		"mana_cost": 50.0,
		"effects": {"damage_absorption": 0.3, "duration": 15.0}
	}
	
	skills["tidal_vortex"] = {
		"id": "tidal_vortex",
		"name": "Водоворот",
		"description": "Создаёт водоворот, втягивающий врагов",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.LEGENDARY,
		"category": SkillSystem.SkillCategory.MAGIC,
		"max_level": 3,
		"cooldown": 30.0,
		"mana_cost": 80.0,
		"effects": {"damage": 50.0, "vortex_radius": 5.0, "duration": 5.0, "pull_force": 10.0}
	}
	
	skills["void_blast"] = {
		"id": "void_blast",
		"name": "Взрыв пустоты",
		"description": "Магический взрыв из Бездны",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.MYTHIC,
		"category": SkillSystem.SkillCategory.MAGIC,
		"max_level": 1,
		"cooldown": 120.0,
		"mana_cost": 150.0,
		"effects": {"damage": 500.0, "blast_radius": 8.0}
	}
	
	# ... продолжение для всех 20 магических навыков

## ============================================
## АКТИВНЫЕ НАВЫКИ - АЛХИМИЯ (15 навыков)
## ============================================

func _register_alchemy_skills() -> void:
	skills["healing_potion"] = {
		"id": "healing_potion",
		"name": "Зелье лечения",
		"description": "Мгновенно восстанавливает здоровье",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.COMMON,
		"category": SkillSystem.SkillCategory.ALCHEMY,
		"max_level": 5,
		"cooldown": 30.0,
		"effects": {"heal": 100.0}
	}
	
	skills["poison_bomb"] = {
		"id": "poison_bomb",
		"name": "Ядовитая бомба",
		"description": "Бомба, отравляющая врагов",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.RARE,
		"category": SkillSystem.SkillCategory.ALCHEMY,
		"max_level": 5,
		"cooldown": 8.0,
		"effects": {"damage": 60.0, "poison_duration": 10.0, "explosion_radius": 4.0}
	}
	
	# ... продолжение для всех 15 алхимических навыков

## ============================================
## АКТИВНЫЕ НАВЫКИ - МОРЕПЛАВАНИЕ (15 навыков)
## ============================================

func _register_sailing_skills() -> void:
	skills["wind_boost"] = {
		"id": "wind_boost",
		"name": "Порыв ветра",
		"description": "Временное ускорение корабля",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.COMMON,
		"category": SkillSystem.SkillCategory.SAILING,
		"max_level": 5,
		"cooldown": 60.0,
		"effects": {"speed_boost": 1.5, "duration": 10.0}
	}
	
	skills["emergency_repair"] = {
		"id": "emergency_repair",
		"name": "Экстренный ремонт",
		"description": "Быстрый ремонт корпуса корабля",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.RARE,
		"category": SkillSystem.SkillCategory.SAILING,
		"max_level": 5,
		"cooldown": 120.0,
		"effects": {"repair_amount": 200.0}
	}
	
	# ... продолжение для всех 15 навыков мореплавания

## ============================================
## АКТИВНЫЕ НАВЫКИ - СОБИРАТЕЛЬСТВО (10 навыков)
## ============================================

func _register_gathering_skills() -> void:
	skills["quick_gather"] = {
		"id": "quick_gather",
		"name": "Быстрый сбор",
		"description": "Ускоряет сбор ресурсов",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.COMMON,
		"category": SkillSystem.SkillCategory.GATHERING,
		"max_level": 5,
		"cooldown": 0.0,
		"stamina_cost": 5.0,
		"effects": {"gather_speed": 2.0, "duration": 5.0}
	}
	
	# ... продолжение для всех 10 навыков собирательства

## ============================================
## АКТИВНЫЕ НАВЫКИ - ЗАЩИТА (5 навыков)
## ============================================

func _register_defense_skills() -> void:
	skills["block"] = {
		"id": "block",
		"name": "Блок",
		"description": "Блокирует входящие атаки",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.COMMON,
		"category": SkillSystem.SkillCategory.DEFENSE,
		"max_level": 5,
		"cooldown": 0.0,
		"stamina_cost": 10.0,
		"effects": {"damage_reduction": 0.7, "duration": 3.0}
	}
	
	# ... продолжение для всех 5 навыков защиты

## ============================================
## АКТИВНЫЕ НАВЫКИ - ДВИЖЕНИЕ (5 навыков)
## ============================================

func _register_movement_skills() -> void:
	skills["dash"] = {
		"id": "dash",
		"name": "Рывок",
		"description": "Быстрый рывок вперёд",
		"skill_type": SkillSystem.SkillType.ACTIVE,
		"rarity": SkillSystem.SkillRarity.COMMON,
		"category": SkillSystem.SkillCategory.MOVEMENT,
		"max_level": 5,
		"cooldown": 3.0,
		"stamina_cost": 15.0,
		"effects": {"dash_distance": 8.0}
	}
	
	# ... продолжение для всех 5 навыков движения

## ============================================
## ПАССИВНЫЕ НАВЫКИ - УНИВЕРСАЛЬНЫЕ (50 навыков)
## ============================================

func _register_passive_skills() -> void:
	# Обычные пассивные навыки (20)
	skills["vitality_boost"] = {
		"id": "vitality_boost",
		"name": "Усиление живучести",
		"description": "Увеличивает максимальное здоровье",
		"skill_type": SkillSystem.SkillType.PASSIVE,
		"rarity": SkillSystem.SkillRarity.COMMON,
		"category": SkillSystem.SkillCategory.UNIVERSAL,
		"max_level": 5,
		"effects": {"max_health_bonus": 50.0},
		"scaling": {"max_health_bonus": 25.0}
	}
	
	skills["stamina_boost"] = {
		"id": "stamina_boost",
		"name": "Усиление выносливости",
		"description": "Увеличивает максимальную выносливость",
		"skill_type": SkillSystem.SkillType.PASSIVE,
		"rarity": SkillSystem.SkillRarity.COMMON,
		"category": SkillSystem.SkillCategory.UNIVERSAL,
		"max_level": 5,
		"effects": {"max_stamina_bonus": 50.0}
	}
	
	skills["luck_boost"] = {
		"id": "luck_boost",
		"name": "Усиление удачи",
		"description": "Увеличивает удачу",
		"skill_type": SkillSystem.SkillType.PASSIVE,
		"rarity": SkillSystem.SkillRarity.COMMON,
		"category": SkillSystem.SkillCategory.UNIVERSAL,
		"max_level": 5,
		"effects": {"luck_bonus": 5.0}
	}
	
	# Редкие пассивные навыки (15)
	skills["regeneration"] = {
		"id": "regeneration",
		"name": "Регенерация",
		"description": "Медленно восстанавливает здоровье",
		"skill_type": SkillSystem.SkillType.PASSIVE,
		"rarity": SkillSystem.SkillRarity.RARE,
		"category": SkillSystem.SkillCategory.UNIVERSAL,
		"max_level": 5,
		"effects": {"health_regen": 2.0}
	}
	
	skills["critical_strike"] = {
		"id": "critical_strike",
		"name": "Критический удар",
		"description": "Шанс нанести критический урон",
		"skill_type": SkillSystem.SkillType.PASSIVE,
		"rarity": SkillSystem.SkillRarity.RARE,
		"category": SkillSystem.SkillCategory.UNIVERSAL,
		"max_level": 5,
		"effects": {"crit_chance": 0.05, "crit_damage": 1.5}
	}
	
	# Легендарные пассивные навыки (10)
	skills["ocean_sense"] = {
		"id": "ocean_sense",
		"name": "Чувство океана",
		"description": "Мини-карта показывает монстров и ресурсы",
		"skill_type": SkillSystem.SkillType.PASSIVE,
		"rarity": SkillSystem.SkillRarity.LEGENDARY,
		"category": SkillSystem.SkillCategory.UNIVERSAL,
		"max_level": 3,
		"effects": {"detection_radius": 50.0}
	}
	
	# Мифические пассивные навыки (5)
	skills["immortal_soul"] = {
		"id": "immortal_soul",
		"name": "Бессмертная душа",
		"description": "Шанс воскреснуть после смерти",
		"skill_type": SkillSystem.SkillType.PASSIVE,
		"rarity": SkillSystem.SkillRarity.MYTHIC,
		"category": SkillSystem.SkillCategory.UNIVERSAL,
		"max_level": 1,
		"effects": {"resurrection_chance": 0.2}
	}
	
	# ... продолжение для всех 50 пассивных навыков


func get_skill(skill_id: String) -> Dictionary:
	return skills.get(skill_id, {})


func get_skills_by_category(category: SkillSystem.SkillCategory) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for skill_id in skills:
		var skill = skills[skill_id]
		if skill.get("category", SkillSystem.SkillCategory.UNIVERSAL) == category:
			result.append(skill)
	return result


func get_skills_by_rarity(rarity: SkillSystem.SkillRarity) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for skill_id in skills:
		var skill = skills[skill_id]
		if skill.get("rarity", SkillSystem.SkillRarity.COMMON) == rarity:
			result.append(skill)
	return result

