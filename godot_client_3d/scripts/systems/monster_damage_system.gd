extends Node
class_name MonsterDamageSystem

## Система урона мобов для Isleborn Online
## Управляет уроном, который наносят и получают мобы

enum DamageType {
	PHYSICAL,       # Физический урон
	FIRE,           # Огонь
	WATER,          # Вода
	EARTH,          # Земля
	LIGHTNING,      # Молния
	POISON,         # Яд
	VOID            # Пустота
}

class DamageInstance:
	var damage_type: DamageType
	var amount: float
	var attacker_id: String
	var target_id: String
	var can_crit: bool = false
	var crit_chance: float = 0.05  # 5% по умолчанию
	var crit_multiplier: float = 1.5
	
	func _init(_type: DamageType, _amount: float, _attacker: String, _target: String):
		damage_type = _type
		amount = _amount
		attacker_id = _attacker
		target_id = _target

var damage_history: Array[DamageInstance] = []  # История урона для анализа

signal damage_dealt(attacker_id: String, target_id: String, damage: float, damage_type: DamageType, is_crit: bool)
signal monster_killed(monster_id: String, killer_id: String)

func _ready() -> void:
	pass

## Вычислить урон от атаки монстра
func calculate_monster_damage(monster_id: String, target_id: String, base_damage: float, damage_type: DamageType = DamageType.PHYSICAL) -> float:
	# TODO: Получить данные монстра из MonsterDatabase
	# TODO: Получить защиту цели (броня, сопротивление)
	
	var final_damage = base_damage
	
	# Применяем модификаторы типа урона
	final_damage = _apply_damage_type_modifier(final_damage, damage_type, target_id)
	
	# Применяем защиту цели
	final_damage = _apply_defense(final_damage, target_id)
	
	# Применяем случайность (±10%)
	var variance = 1.0 + (randf() - 0.5) * 0.2
	final_damage *= variance
	
	# Минимальный урон (не менее 1)
	final_damage = max(1.0, final_damage)
	
	return final_damage

## Вычислить урон от игрока к монстру
func calculate_player_to_monster_damage(player_id: String, monster_id: String, base_damage: float, damage_type: DamageType = DamageType.PHYSICAL) -> float:
	var final_damage = base_damage
	
	# TODO: Получить характеристики игрока (сила, оружие, бонусы)
	# TODO: Получить защиту монстра
	
	# Применяем модификаторы типа урона
	final_damage = _apply_damage_type_modifier(final_damage, damage_type, monster_id)
	
	# Применяем защиту монстра
	final_damage = _apply_monster_defense(final_damage, monster_id)
	
	# Критический удар
	var crit_rolled = randf()
	var crit_chance = 0.05  # TODO: Получить из характеристик игрока
	var is_crit = crit_rolled < crit_chance
	if is_crit:
		final_damage *= 1.5  # 50% увеличение от крита
	
	# Применяем случайность
	var variance = 1.0 + (randf() - 0.5) * 0.2
	final_damage *= variance
	
	final_damage = max(1.0, final_damage)
	
	return final_damage

## Применить урон к цели
func apply_damage(damage_instance: DamageInstance) -> float:
	var actual_damage = damage_instance.amount
	
	# Проверяем критический удар
	var is_crit = false
	if damage_instance.can_crit:
		is_crit = randf() < damage_instance.crit_chance
		if is_crit:
			actual_damage *= damage_instance.crit_multiplier
	
	# Применяем урон к цели
	actual_damage = _deal_damage_to_target(damage_instance.target_id, actual_damage, damage_instance.damage_type)
	
	# Сохраняем в историю
	damage_history.append(damage_instance)
	if damage_history.size() > 100:
		damage_history.remove_at(0)
	
	damage_dealt.emit(damage_instance.attacker_id, damage_instance.target_id, actual_damage, damage_instance.damage_type, is_crit)
	
	return actual_damage

## Нанести урон цели
func _deal_damage_to_target(target_id: String, damage: float, damage_type: DamageType) -> float:
	# TODO: Определить тип цели (игрок/монстр) и применить урон соответственно
	
	# Для игроков - интегрировать с системой здоровья
	var world = get_tree().current_scene
	if world:
		# Проверяем, это игрок или монстр
		if target_id.begins_with("p_"):
			# Игрок
			# TODO: Интегрировать с системой здоровья игрока
			pass
		elif target_id.begins_with("monster_"):
			# Монстр
			# TODO: Интегрировать с системой здоровья монстра
			pass
	
	return damage

## Применить модификатор типа урона
func _apply_damage_type_modifier(damage: float, damage_type: DamageType, target_id: String) -> float:
	# TODO: Получить сопротивления цели и применить
	# Например, водный урон слабее против огненных мобов
	
	match damage_type:
		DamageType.FIRE:
			# Огненный урон сильнее против некоторых типов
			damage *= 1.1
		DamageType.WATER:
			# Водный урон
			damage *= 1.0
		DamageType.LIGHTNING:
			# Молния сильнее против водных
			damage *= 1.15
		_:
			pass
	
	return damage

## Применить защиту цели
func _apply_defense(damage: float, target_id: String) -> float:
	# TODO: Получить защиту цели (броня, сопротивление)
	var defense = 0.0  # TODO: Получить реальную защиту
	
	# Формула снижения урона: damage_reduction = defense / (defense + 100)
	var damage_reduction = defense / (defense + 100.0)
	damage *= (1.0 - damage_reduction)
	
	return damage

## Применить защиту монстра
func _apply_monster_defense(damage: float, monster_id: String) -> float:
	# TODO: Получить защиту монстра из базы данных
	var defense = 10.0  # Базовая защита
	
	var damage_reduction = defense / (defense + 100.0)
	damage *= (1.0 - damage_reduction)
	
	return damage

## Получить урон атаки монстра
func get_monster_attack_damage(monster_id: String, monster_tier: int) -> float:
	# Базовая формула урона по тиру
	var base_damage = 10.0 + (monster_tier * 5.0)
	
	# Вариация урона
	var variance = 1.0 + (randf() - 0.5) * 0.3  # ±15%
	base_damage *= variance
	
	return base_damage

## Получить тип урона монстра
func get_monster_damage_type(monster_id: String) -> DamageType:
	# TODO: Получить из базы данных монстров
	# Пример: электрический скат наносит молнию, огненный - огонь
	return DamageType.PHYSICAL

## Получить защиту монстра
func get_monster_defense(monster_id: String, monster_tier: int) -> float:
	# Базовая формула защиты по тиру
	return 5.0 + (monster_tier * 3.0)

## Проверить, убит ли монстр/игрок
func check_target_death(target_id: String, current_health: float) -> bool:
	if current_health <= 0.0:
		if target_id.begins_with("monster_"):
			monster_killed.emit(target_id, "")
		return true
	return false

## Получить статистику урона
func get_damage_statistics(attacker_id: String = "", target_id: String = "") -> Dictionary:
	var total_damage = 0.0
	var hit_count = 0
	var crit_count = 0
	
	for damage in damage_history:
		if attacker_id != "" and damage.attacker_id != attacker_id:
			continue
		if target_id != "" and damage.target_id != target_id:
			continue
		
		total_damage += damage.amount
		hit_count += 1
		# TODO: Отслеживать критические удары
	
	return {
		"total_damage": total_damage,
		"hit_count": hit_count,
		"average_damage": total_damage / max(1, hit_count),
		"crit_count": crit_count
	}

