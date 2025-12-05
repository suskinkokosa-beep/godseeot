extends Node
class_name BossSystem

## Система боссов для Isleborn Online
## Уникальные сильные монстры с особыми механиками

enum BossTier {
	MINI,           # Мини-босс
	NORMAL,         # Обычный босс
	ELITE,          # Элитный босс
	LEGENDARY,      # Легендарный босс
	MYTHIC          # Мифический босс
}

enum BossStatus {
	SPAWNED,        # Заспавнен
	ACTIVE,         # Активен
	ENRAGED,        # Озлоблен (низкое HP)
	DEFEATED,       # Побеждён
	DESPAWNED       # Исчез
}

class BossData:
	var boss_id: String
	var name: String
	var boss_tier: BossTier
	var status: BossStatus = BossStatus.SPAWNED
	var position: Vector3
	var biome: String = ""
	
	# Характеристики
	var max_health: float = 1000.0
	var current_health: float = 1000.0
	var level: int = 10
	var damage: float = 50.0
	var defense: float = 30.0
	
	# Механики
	var phases: Array[Dictionary] = []
	var current_phase: int = 0
	var special_abilities: Array[String] = []
	var enrage_threshold: float = 0.3  # При 30% HP
	
	# Спавн
	var spawn_conditions: Dictionary = {}
	var respawn_time: float = 3600.0  # 1 час
	var last_defeated: int = 0
	
	# Лут
	var loot_table: Dictionary = {}
	var guaranteed_loot: Array[Dictionary] = []
	
	func _init(_id: String, _name: String, _tier: BossTier):
		boss_id = _id
		name = _name
		boss_tier = _tier

var active_bosses: Dictionary = {}  # boss_id -> BossData
var boss_templates: Dictionary = {}  # boss_id -> BossData (шаблоны)

signal boss_spawned(boss: BossData)
signal boss_defeated(boss_id: String, killer_id: String, rewards: Dictionary)
signal boss_phase_changed(boss_id: String, new_phase: int)
signal boss_enraged(boss_id: String)

func _ready() -> void:
	_initialize_boss_templates()

func _process(delta: float) -> void:
	_update_bosses(delta)
	_check_boss_respawn()

func _initialize_boss_templates() -> void:
	# Легендарные боссы
	_create_boss_template("kraken_ancient", "Древний Кракен", BossTier.LEGENDARY, 50, 50000.0, 500.0, 100.0)
	_create_boss_template("leviathan", "Левиафан", BossTier.MYTHIC, 60, 100000.0, 800.0, 150.0)
	
	# Элитные боссы
	_create_boss_template("sea_serpent_king", "Король Морских Змей", BossTier.ELITE, 40, 20000.0, 300.0, 70.0)
	
	# Обычные боссы
	_create_boss_template("giant_shark_alpha", "Альфа-Акула", BossTier.NORMAL, 20, 5000.0, 150.0, 40.0)

func _create_boss_template(boss_id: String, name: String, tier: BossTier, level: int, health: float, damage: float, defense: float) -> void:
	var boss = BossData.new(boss_id, name, tier)
	boss.level = level
	boss.max_health = health
	boss.current_health = health
	boss.damage = damage
	boss.defense = defense
	
	# Устанавливаем лут
	boss.loot_table = _generate_loot_table(tier)
	boss.guaranteed_loot = _generate_guaranteed_loot(tier)
	
	# Устанавливаем фазы
	boss.phases = _generate_boss_phases(tier)
	
	boss_templates[boss_id] = boss

func _generate_loot_table(tier: BossTier) -> Dictionary:
	match tier:
		BossTier.MINI:
			return {"shells": 100, "common_items": 3}
		BossTier.NORMAL:
			return {"shells": 500, "gold": 10, "rare_items": 2}
		BossTier.ELITE:
			return {"shells": 2000, "gold": 50, "epic_items": 2, "rare_items": 5}
		BossTier.LEGENDARY:
			return {"shells": 5000, "gold": 200, "pearls": 10, "legendary_items": 1, "epic_items": 3}
		BossTier.MYTHIC:
			return {"shells": 10000, "gold": 500, "pearls": 50, "mythic_items": 1, "legendary_items": 2}
		_:
			return {}

func _generate_guaranteed_loot(tier: BossTier) -> Array[Dictionary]:
	var loot: Array[Dictionary] = []
	
	match tier:
		BossTier.LEGENDARY, BossTier.MYTHIC:
			loot.append({"item_id": "boss_essence", "quantity": 1})
			loot.append({"item_id": "unique_blueprint", "quantity": 1})
	
	return loot

func _generate_boss_phases(tier: BossTier) -> Array[Dictionary]:
	var phases: Array[Dictionary] = []
	
	if tier >= BossTier.ELITE:
		phases.append({
			"phase": 1,
			"health_threshold": 0.75,
			"abilities": ["summon_minions"],
			"damage_multiplier": 1.0
		})
		phases.append({
			"phase": 2,
			"health_threshold": 0.5,
			"abilities": ["area_attack", "summon_minions"],
			"damage_multiplier": 1.2
		})
		phases.append({
			"phase": 3,
			"health_threshold": 0.25,
			"abilities": ["enrage", "berserk"],
			"damage_multiplier": 1.5
		})
	
	return phases

func spawn_boss(boss_template_id: String, position: Vector3, biome: String = "") -> String:
	if not boss_templates.has(boss_template_id):
		return ""
	
	var template = boss_templates[boss_template_id]
	
	# Проверяем респавн
	if template.last_defeated > 0:
		var time_since_defeat = Time.get_unix_time_from_system() - template.last_defeated
		if time_since_defeat < template.respawn_time:
			return ""  # Ещё не респавнился
	
	var boss_id = "%s_%d" % [boss_template_id, Time.get_ticks_msec()]
	var boss = BossData.new(boss_id, template.name, template.boss_tier)
	
	# Копируем характеристики
	boss.level = template.level
	boss.max_health = template.max_health
	boss.current_health = template.max_health
	boss.damage = template.damage
	boss.defense = template.defense
	boss.loot_table = template.loot_table.duplicate()
	boss.guaranteed_loot = template.guaranteed_loot.duplicate()
	boss.phases = template.phases.duplicate()
	boss.position = position
	boss.biome = biome
	
	active_bosses[boss_id] = boss
	boss_spawned.emit(boss)
	
	return boss_id

func damage_boss(boss_id: String, damage: float, attacker_id: String = "") -> void:
	if not active_bosses.has(boss_id):
		return
	
	var boss = active_bosses[boss_id]
	
	# Применяем защиту
	var actual_damage = max(1.0, damage - boss.defense)
	boss.current_health -= actual_damage
	
	# Проверяем фазы
	_check_boss_phases(boss)
	
	# Проверяем озлобление
	if boss.current_health <= boss.max_health * boss.enrage_threshold and boss.status != BossStatus.ENRAGED:
		boss.status = BossStatus.ENRAGED
		boss_enraged.emit(boss_id)
	
	# Проверяем смерть
	if boss.current_health <= 0.0:
		defeat_boss(boss_id, attacker_id)

func _check_boss_phases(boss: BossData) -> void:
	var health_percent = boss.current_health / boss.max_health
	
	for i in range(boss.phases.size()):
		var phase = boss.phases[i]
		var threshold = phase.get("health_threshold", 1.0)
		
		if health_percent <= threshold and boss.current_phase < phase["phase"]:
			boss.current_phase = phase["phase"]
			boss_phase_changed.emit(boss.boss_id, phase["phase"])

func defeat_boss(boss_id: String, killer_id: String) -> void:
	if not active_bosses.has(boss_id):
		return
	
	var boss = active_bosses[boss_id]
	boss.status = BossStatus.DEFEATED
	boss.current_health = 0.0
	boss.last_defeated = Time.get_unix_time_from_system()
	
	# Выдаём лут
	var rewards = _generate_boss_rewards(boss)
	_give_boss_rewards(rewards, killer_id)
	
	boss_defeated.emit(boss_id, killer_id, rewards)
	
	# Удаляем через некоторое время
	await get_tree().create_timer(10.0).timeout
	active_bosses.erase(boss_id)

func _generate_boss_rewards(boss: BossData) -> Dictionary:
	var rewards = boss.loot_table.duplicate()
	rewards["items"] = boss.guaranteed_loot.duplicate()
	rewards["experience"] = boss.level * 100.0 * (boss.boss_tier + 1)
	
	return rewards

func _give_boss_rewards(rewards: Dictionary, player_id: String) -> void:
	var world = get_tree().current_scene
	if world:
		# Валюта
		if rewards.has("shells"):
			var currency_system = world.find_child("CurrencySystem", true, false)
			if currency_system:
				currency_system.add_currency(CurrencySystem.CurrencyType.SHELLS, rewards["shells"])
		
		# Предметы
		if rewards.has("items"):
			var inventory = world.find_child("Inventory", true, false)
			if inventory:
				for item in rewards["items"]:
					inventory.add_item(item["item_id"], item.get("quantity", 1))

func _update_bosses(delta: float) -> void:
	# TODO: Обновлять AI боссов, способности, и т.д.
	pass

func _check_boss_respawn() -> void:
	# TODO: Проверять условия респавна боссов
	pass

func get_boss_info(boss_id: String) -> Dictionary:
	if not active_bosses.has(boss_id):
		return {}
	
	var boss = active_bosses[boss_id]
	var health_percent = (boss.current_health / boss.max_health) * 100.0
	
	return {
		"id": boss.boss_id,
		"name": boss.name,
		"tier": boss.boss_tier,
		"status": boss.status,
		"level": boss.level,
		"health": boss.current_health,
		"max_health": boss.max_health,
		"health_percent": health_percent,
		"current_phase": boss.current_phase,
		"position": boss.position,
		"biome": boss.biome
	}

func get_active_bosses() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for boss_id in active_bosses.keys():
		result.append(get_boss_info(boss_id))
	
	return result

