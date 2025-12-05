extends Node
class_name MonsterWaterSystem

## Система для управления монстрами на воде и под водой

enum MonsterEnvironment {
	SURFACE,      # На поверхности воды
	UNDERWATER,   # Под водой
	LAND,         # На суше
	BOTH          # Может быть и на воде, и под водой
}

const WATER_SURFACE_Y: float = 0.0

func get_water_level_at_position(position: Vector3) -> float:
	# Возвращает уровень воды в указанной позиции
	# В будущем можно интегрировать с OceanManager для реального уровня воды
	return WATER_SURFACE_Y

func is_position_underwater(position: Vector3) -> bool:
	return position.y < get_water_level_at_position(position)

func is_position_on_surface(position: Vector3) -> bool:
	var water_level = get_water_level_at_position(position)
	return abs(position.y - water_level) < 0.5

func get_monster_environment(monster_position: Vector3, depth: float) -> MonsterEnvironment:
	if depth > 0.0:
		return MonsterEnvironment.UNDERWATER
	elif is_position_on_surface(monster_position):
		return MonsterEnvironment.SURFACE
	else:
		return MonsterEnvironment.LAND

func apply_water_buoyancy(monster: Node3D, environment: MonsterEnvironment, delta: float) -> void:
	if environment != MonsterEnvironment.SURFACE and environment != MonsterEnvironment.UNDERWATER:
		return
	
	var water_level = get_water_level_at_position(monster.global_position)
	
	if environment == MonsterEnvironment.SURFACE:
		# Монстр на поверхности - применить плавучесть
		var target_y = water_level
		if monster.global_position.y < target_y:
			var speed = 2.0  # Скорость всплытия
			monster.global_position.y = min(monster.global_position.y + speed * delta, target_y)
	elif environment == MonsterEnvironment.UNDERWATER:
		# Монстр под водой - может плавать на определенной глубине
		var target_y = water_level - monster.get_meta("depth", 5.0)
		var current_y = monster.global_position.y
		
		if abs(current_y - target_y) > 0.1:
			var speed = 1.0  # Скорость изменения глубины
			if current_y < target_y:
				monster.global_position.y = min(current_y + speed * delta, target_y)
			else:
				monster.global_position.y = max(current_y - speed * delta, target_y)

func apply_water_resistance(monster: Node3D, velocity: Vector3, environment: MonsterEnvironment) -> Vector3:
	if environment == MonsterEnvironment.SURFACE or environment == MonsterEnvironment.UNDERWATER:
		# Уменьшаем скорость в воде
		var resistance = 0.7 if environment == MonsterEnvironment.SURFACE else 0.5
		return velocity * resistance
	return velocity

