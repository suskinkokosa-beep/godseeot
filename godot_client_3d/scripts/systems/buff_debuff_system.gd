extends Node
class_name BuffDebuffSystem

## Система баффов и дебаффов для Isleborn Online
## Временные эффекты на игрока

enum EffectType {
	BUFF,           # Бафф
	DEBUFF,         # Дебафф
	NEUTRAL         # Нейтральный эффект
}

enum EffectCategory {
	STAT,           # Изменение характеристик
	DAMAGE,         # Урон
	HEALING,        # Лечение
	MOVEMENT,       # Движение
	RESISTANCE,     # Сопротивление
	UTILITY         # Утилита
}

class StatusEffect:
	var effect_id: String
	var name: String
	var description: String
	var effect_type: EffectType
	var category: EffectCategory
	var duration: float = 60.0
	var remaining_time: float = 60.0
	var stack_count: int = 1
	var max_stacks: int = 1
	var is_permanent: bool = false
	
	# Модификаторы
	var stat_modifiers: Dictionary = {}  # stat_name -> value
	var damage_modifier: float = 0.0
	var healing_modifier: float = 0.0
	var speed_modifier: float = 0.0
	var resistance_modifiers: Dictionary = {}  # damage_type -> value
	
	# Визуальные эффекты
	var icon: String = ""
	var particle_effect: String = ""
	var color: Color = Color.WHITE
	
	func _init(_id: String, _name: String, _type: EffectType, _category: EffectCategory):
		effect_id = _id
		name = _name
		effect_type = _type
		category = _category

var active_effects: Dictionary = {}  # effect_id -> StatusEffect

signal effect_applied(effect: StatusEffect)
signal effect_removed(effect_id: String)
signal effect_expired(effect_id: String)
signal effect_stacked(effect_id: String, new_stack_count: int)

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	_update_effects(delta)

func apply_effect(effect: StatusEffect) -> void:
	if active_effects.has(effect.effect_id):
		# Эффект уже активен
		var existing = active_effects[effect.effect_id]
		
		if existing.max_stacks > 1 and existing.stack_count < existing.max_stacks:
			# Увеличиваем стаки
			existing.stack_count += 1
			existing.remaining_time = existing.duration  # Обновляем время
			effect_stacked.emit(effect.effect_id, existing.stack_count)
		else:
			# Обновляем время существующего эффекта
			existing.remaining_time = existing.duration
	else:
		# Новый эффект
		active_effects[effect.effect_id] = effect
		effect_applied.emit(effect)

func remove_effect(effect_id: String) -> void:
	if not active_effects.has(effect_id):
		return
	
	var effect = active_effects[effect_id]
	active_effects.erase(effect_id)
	effect_removed.emit(effect_id)

func remove_all_effects(effect_type: EffectType = EffectType.NEUTRAL) -> void:
	var to_remove: Array[String] = []
	
	for effect_id in active_effects.keys():
		var effect = active_effects[effect_id]
		if effect_type == EffectType.NEUTRAL or effect.effect_type == effect_type:
			to_remove.append(effect_id)
	
	for effect_id in to_remove:
		remove_effect(effect_id)

func _update_effects(delta: float) -> void:
	var expired: Array[String] = []
	
	for effect_id in active_effects.keys():
		var effect = active_effects[effect_id]
		
		if not effect.is_permanent:
			effect.remaining_time -= delta
			
			if effect.remaining_time <= 0.0:
				expired.append(effect_id)
	
	for effect_id in expired:
		var effect = active_effects[effect_id]
		active_effects.erase(effect_id)
		effect_expired.emit(effect_id)

func create_buff(buff_id: String, name: String, duration: float, stat_modifiers: Dictionary = {}) -> StatusEffect:
	var buff = StatusEffect.new(buff_id, name, EffectType.BUFF, EffectCategory.STAT)
	buff.duration = duration
	buff.remaining_time = duration
	buff.stat_modifiers = stat_modifiers
	buff.icon = "buff_icon"
	buff.color = Color.GREEN
	
	return buff

func create_debuff(debuff_id: String, name: String, duration: float, stat_modifiers: Dictionary = {}) -> StatusEffect:
	var debuff = StatusEffect.new(debuff_id, name, EffectType.DEBUFF, EffectCategory.STAT)
	debuff.duration = duration
	debuff.remaining_time = duration
	debuff.stat_modifiers = stat_modifiers
	debuff.icon = "debuff_icon"
	debuff.color = Color.RED
	
	return debuff

func get_stat_modifier(stat_name: String) -> float:
	var total_modifier = 0.0
	
	for effect_id in active_effects.keys():
		var effect = active_effects[effect_id]
		if effect.stat_modifiers.has(stat_name):
			total_modifier += effect.stat_modifiers[stat_name] * effect.stack_count
	
	return total_modifier

func get_damage_modifier() -> float:
	var total_modifier = 0.0
	
	for effect_id in active_effects.keys():
		var effect = active_effects[effect_id]
		total_modifier += effect.damage_modifier * effect.stack_count
	
	return total_modifier

func get_speed_modifier() -> float:
	var total_modifier = 0.0
	
	for effect_id in active_effects.keys():
		var effect = active_effects[effect_id]
		total_modifier += effect.speed_modifier * effect.stack_count
	
	return total_modifier

func get_resistance(damage_type: String) -> float:
	var total_resistance = 0.0
	
	for effect_id in active_effects.keys():
		var effect = active_effects[effect_id]
		if effect.resistance_modifiers.has(damage_type):
			total_resistance += effect.resistance_modifiers[damage_type] * effect.stack_count
	
	return total_resistance

func has_effect(effect_id: String) -> bool:
	return active_effects.has(effect_id)

func get_effect(effect_id: String) -> StatusEffect:
	return active_effects.get(effect_id, null)

func get_active_effects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for effect_id in active_effects.keys():
		var effect = active_effects[effect_id]
		result.append({
			"id": effect.effect_id,
			"name": effect.name,
			"type": effect.effect_type,
			"category": effect.category,
			"remaining_time": effect.remaining_time,
			"duration": effect.duration,
			"stack_count": effect.stack_count,
			"icon": effect.icon,
			"color": effect.color
		})
	
	return result

