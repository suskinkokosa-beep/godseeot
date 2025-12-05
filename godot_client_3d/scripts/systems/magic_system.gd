extends Node
class_name MagicSystem

## Система магии и рун для Isleborn Online
## Согласно GDD: магические способности, руны, зачарования

enum MagicElement {
	WATER,          # Вода
	EARTH,          # Земля
	AIR,            # Воздух
	FIRE,           # Огонь
	VOID,           # Пустота (Blackwater)
	LIGHT,          # Свет
	DARK            # Тьма
}

enum RuneType {
	OFFENSIVE,      # Атакующие руны
	DEFENSIVE,      # Защитные руны
	UTILITY,        # Утилитарные руны
	ENHANCEMENT,    # Усиливающие руны
	CURSE           # Проклятия
}

enum SpellType {
	INSTANT,        # Мгновенная
	CHANNELED,      # Канальная (нужно удерживать)
	SUSTAINED,      # Поддерживаемая (активна пока мана тратится)
	PASSIVE         # Пассивная (активна постоянно)
}

class RuneData:
	var rune_id: String
	var name: String
	var rune_type: RuneType
	var element: MagicElement
	var level: int = 1
	var max_level: int = 5
	var description: String
	var effects: Dictionary = {}
	var mana_cost: float = 10.0
	var cooldown: float = 5.0
	
	func _init(_id: String, _name: String, _type: RuneType, _element: MagicElement):
		rune_id = _id
		name = _name
		rune_type = _type
		element = _element

class SpellData:
	var spell_id: String
	var name: String
	var spell_type: SpellType
	var element: MagicElement
	var level: int = 1
	var required_level: int = 1
	var description: String
	var mana_cost: float = 20.0
	var cooldown: float = 10.0
	var cast_time: float = 1.0
	var range: float = 50.0
	var damage: float = 0.0
	var effects: Dictionary = {}
	var rune_requirements: Array[String] = []  # Требуемые руны
	
	func _init(_id: String, _name: String, _type: SpellType, _element: MagicElement):
		spell_id = _id
		name = _name
		spell_type = _type
		element = _element

class EnchantmentData:
	var enchantment_id: String
	var name: String
	var description: String
	var element: MagicElement
	var level: int = 1
	var effects: Dictionary = {}
	var duration: float = -1.0  # -1 = постоянное
	var mana_cost: float = 0.0
	
	func _init(_id: String, _name: String, _element: MagicElement):
		enchantment_id = _id
		name = _name
		element = _element

var known_runes: Dictionary = {}  # rune_id -> RuneData
var known_spells: Dictionary = {}  # spell_id -> SpellData
var active_enchantments: Dictionary = {}  # enchantment_id -> EnchantmentData
var rune_inventory: Dictionary = {}  # rune_id -> quantity

var current_mana: float = 100.0
var max_mana: float = 100.0
var mana_regeneration: float = 5.0  # per second

signal rune_learned(rune_id: String)
signal spell_learned(spell_id: String)
signal spell_cast(spell_id: String)
signal enchantment_applied(enchantment_id: String, target_id: String)
signal enchantment_removed(enchantment_id: String)

func _ready() -> void:
	_initialize_rune_database()
	_initialize_spell_database()

func _process(delta: float) -> void:
	# Регенерация маны
	if current_mana < max_mana:
		current_mana = min(current_mana + mana_regeneration * delta, max_mana)
	
	# Обновление зачарований с ограниченным временем
	var expired_enchantments: Array[String] = []
	for enchant_id in active_enchantments.keys():
		var enchant = active_enchantments[enchant_id]
		if enchant.duration > 0.0:
			enchant.duration -= delta
			if enchant.duration <= 0.0:
				expired_enchantments.append(enchant_id)
	
	for enchant_id in expired_enchantments:
		remove_enchantment(enchant_id)

func _initialize_rune_database() -> void:
	# Атакующие руны
	_register_rune("rune_water_bolt", "Руна водяного снаряда", RuneType.OFFENSIVE, MagicElement.WATER)
	_register_rune("rune_fire_blast", "Руна огненного взрыва", RuneType.OFFENSIVE, MagicElement.FIRE)
	_register_rune("rune_earth_spike", "Руна земляного шипа", RuneType.OFFENSIVE, MagicElement.EARTH)
	_register_rune("rune_lightning_bolt", "Руна молнии", RuneType.OFFENSIVE, MagicElement.AIR)
	
	# Защитные руны
	_register_rune("rune_water_shield", "Руна водяного щита", RuneType.DEFENSIVE, MagicElement.WATER)
	_register_rune("rune_stone_armor", "Руна каменной брони", RuneType.DEFENSIVE, MagicElement.EARTH)
	_register_rune("rune_wind_barrier", "Руна ветряного барьера", RuneType.DEFENSIVE, MagicElement.AIR)
	
	# Утилитарные руны
	_register_rune("rune_water_breathing", "Руна подводного дыхания", RuneType.UTILITY, MagicElement.WATER)
	_register_rune("rune_light_path", "Руна светлого пути", RuneType.UTILITY, MagicElement.LIGHT)
	_register_rune("rune_void_portal", "Руна портала пустоты", RuneType.UTILITY, MagicElement.VOID)
	
	# Усиливающие руны
	_register_rune("rune_mana_boost", "Руна усиления маны", RuneType.ENHANCEMENT, MagicElement.LIGHT)
	_register_rune("rune_power_flow", "Руна потока силы", RuneType.ENHANCEMENT, MagicElement.VOID)

func _initialize_spell_database() -> void:
	# Зарегистрируем базовые заклинания
	_register_spell("spell_water_bolt", "Водяной снаряд", SpellType.INSTANT, MagicElement.WATER, 1)
	_register_spell("spell_heal_wave", "Волна исцеления", SpellType.INSTANT, MagicElement.WATER, 3)
	_register_spell("spell_fire_ball", "Огненный шар", SpellType.INSTANT, MagicElement.FIRE, 5)
	_register_spell("spell_earth_wall", "Земляная стена", SpellType.INSTANT, MagicElement.EARTH, 7)
	_register_spell("spell_lightning_storm", "Гроза", SpellType.CHANNELED, MagicElement.AIR, 10)
	_register_spell("spell_void_teleport", "Телепорт пустоты", SpellType.INSTANT, MagicElement.VOID, 15)

func _register_rune(rune_id: String, name: String, rune_type: RuneType, element: MagicElement) -> void:
	var rune = RuneData.new(rune_id, name, rune_type, element)
	
	match rune_type:
		RuneType.OFFENSIVE:
			rune.effects["damage"] = 10.0 + (element * 2.0)
			rune.mana_cost = 15.0
		RuneType.DEFENSIVE:
			rune.effects["defense"] = 5.0 + (element * 1.0)
			rune.mana_cost = 20.0
		RuneType.UTILITY:
			rune.mana_cost = 10.0
		RuneType.ENHANCEMENT:
			rune.effects["mana_boost"] = 1.2
			rune.mana_cost = 25.0
	
	known_runes[rune_id] = rune

func _register_spell(spell_id: String, name: String, spell_type: SpellType, element: MagicElement, required_level: int) -> void:
	var spell = SpellData.new(spell_id, name, spell_type, element)
	spell.required_level = required_level
	
	match spell_type:
		SpellType.INSTANT:
			spell.cast_time = 0.5
			spell.cooldown = 3.0
		SpellType.CHANNELED:
			spell.cast_time = 2.0
			spell.cooldown = 15.0
		SpellType.SUSTAINED:
			spell.cast_time = 0.0
			spell.cooldown = 0.0
	
	# Устанавливаем параметры в зависимости от элемента
	match element:
		MagicElement.WATER:
			spell.damage = 20.0 + (required_level * 5.0)
			spell.effects["slow"] = 0.3
		MagicElement.FIRE:
			spell.damage = 30.0 + (required_level * 6.0)
			spell.effects["burn"] = true
		MagicElement.EARTH:
			spell.damage = 25.0 + (required_level * 5.0)
			spell.effects["stun"] = 0.5
		MagicElement.AIR:
			spell.damage = 22.0 + (required_level * 5.0)
			spell.effects["knockback"] = true
		MagicElement.VOID:
			spell.damage = 40.0 + (required_level * 8.0)
			spell.effects["void_debuff"] = true
	
	known_spells[spell_id] = spell

## Изучить руну (из рунической книги)
func learn_rune(rune_id: String) -> bool:
	if known_runes.has(rune_id):
		return false  # Руна уже изучена
	
	if not known_runes.has(rune_id):
		# Создаём копию из базы данных
		# TODO: Загружать из базы данных рун
		return false
	
	rune_learned.emit(rune_id)
	return true

## Изучить заклинание
func learn_spell(spell_id: String) -> bool:
	if known_spells.has(spell_id):
		return false  # Заклинание уже изучено
	
	# TODO: Проверка требований (руны, уровень персонажа)
	# TODO: Загружать из базы данных заклинаний
	
	known_spells[spell_id] = known_spells.get(spell_id, null)
	if not known_spells.has(spell_id):
		return false
	
	spell_learned.emit(spell_id)
	return true

## Произнести заклинание
func cast_spell(spell_id: String, target_position: Vector3 = Vector3.ZERO, target_id: String = "") -> bool:
	var spell = known_spells.get(spell_id)
	if not spell:
		return false
	
	if current_mana < spell.mana_cost:
		return false  # Недостаточно маны
	
	# TODO: Проверка кулдауна
	# TODO: Проверка дистанции
	
	current_mana -= spell.mana_cost
	spell_cast.emit(spell_id)
	
	# TODO: Применить эффекты заклинания
	
	return true

## Применить зачарование к предмету/постройке
func apply_enchantment(enchantment_id: String, target_id: String, level: int = 1) -> bool:
	# TODO: Проверка ресурсов для зачарования
	
	var enchant = EnchantmentData.new(
		"enchant_%d" % Time.get_ticks_msec(),
		"Enchantment",
		MagicElement.WATER
	)
	enchant.level = level
	
	active_enchantments[enchant.enchantment_id] = enchant
	enchantment_applied.emit(enchantment_id, target_id)
	return true

## Удалить зачарование
func remove_enchantment(enchantment_id: String) -> bool:
	if not active_enchantments.has(enchantment_id):
		return false
	
	active_enchantments.erase(enchantment_id)
	enchantment_removed.emit(enchantment_id)
	return true

## Получить текущую ману
func get_current_mana() -> float:
	return current_mana

## Получить максимальную ману
func get_max_mana() -> float:
	return max_mana

## Установить максимальную ману
func set_max_mana(value: float) -> void:
	max_mana = value
	current_mana = min(current_mana, max_mana)

## Восстановить ману
func restore_mana(amount: float) -> void:
	current_mana = min(current_mana + amount, max_mana)

## Получить известные заклинания
func get_known_spells() -> Dictionary:
	return known_spells.duplicate()

## Получить известные руны
func get_known_runes() -> Dictionary:
	return known_runes.duplicate()

## Получить активные зачарования
func get_active_enchantments() -> Dictionary:
	return active_enchantments.duplicate()

