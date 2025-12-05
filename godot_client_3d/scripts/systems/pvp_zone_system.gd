extends Node
class_name PvPZoneSystem

## Система PvP зон для Isleborn Online
## Согласно GDD: PvP ограничено зонами, нет griefing-а на старте

enum ZoneType {
	SAFE,           # Безопасная зона (нет PvP)
	PvP,            # PvP зона
	CONTESTED,      # Спорная зона
	WAR_ZONE        # Зона войны
}

class PvPZone:
	var zone_id: String
	var zone_type: ZoneType
	var name: String
	var center: Vector3
	var radius: float = 500.0
	var controlling_guild_id: String = ""  # Для спорных зон
	var danger_level: float = 0.0  # 0.0-1.0
	var rewards_multiplier: float = 1.0
	var rules: Dictionary = {}
	
	func _init(_id: String, _type: ZoneType, _name: String, _center: Vector3):
		zone_id = _id
		zone_type = _type
		name = _name
		center = _center

var pvp_zones: Dictionary = {}  # zone_id -> PvPZone
var player_in_zones: Dictionary = {}  # player_id -> zone_id

signal player_entered_zone(player_id: String, zone_id: String)
signal player_left_zone(player_id: String, zone_id: String)
signal zone_control_changed(zone_id: String, controlling_guild_id: String)

func _ready() -> void:
	_generate_pvp_zones()

func _generate_pvp_zones() -> void:
	# Безопасные зоны (стартовые острова)
	_create_zone("safe_start", ZoneType.SAFE, "Безопасная зона", Vector3(0, 0, 0), 100.0)
	
	# PvP зоны (Bluewater)
	_create_zone("pvp_deep_blue", ZoneType.PvP, "Глубокие воды", Vector3(5000, 0, 5000), 2000.0)
	
	# Спорные зоны (ресурсные точки)
	_create_zone("contested_metal", ZoneType.CONTESTED, "Металлический риф", Vector3(8000, 0, 8000), 500.0)
	
	# Зоны войны (Blackwater)
	_create_zone("war_blackwater", ZoneType.WAR_ZONE, "Война Бездны", Vector3(15000, -100, 15000), 1000.0)

func _create_zone(zone_id: String, zone_type: ZoneType, name: String, center: Vector3, radius: float) -> void:
	var zone = PvPZone.new(zone_id, zone_type, name, center)
	zone.radius = radius
	
	# Устанавливаем правила зоны
	zone.rules = _get_zone_rules(zone_type)
	
	pvp_zones[zone_id] = zone

func _get_zone_rules(zone_type: ZoneType) -> Dictionary:
	match zone_type:
		ZoneType.SAFE:
			return {
				"pvp_enabled": false,
				"item_loss": false,
				"death_penalty": 0.5  # Сниженный штраф
			}
		ZoneType.PvP:
			return {
				"pvp_enabled": true,
				"item_loss": true,
				"death_penalty": 1.0,
				"kill_rewards": true
			}
		ZoneType.CONTESTED:
			return {
				"pvp_enabled": true,
				"item_loss": true,
				"death_penalty": 1.0,
				"resource_bonus": 1.5,  # +50% ресурсов
				"control_rewards": true
			}
		ZoneType.WAR_ZONE:
			return {
				"pvp_enabled": true,
				"item_loss": true,
				"death_penalty": 1.5,  # Увеличенный штраф
				"kill_rewards": true,
				"legendary_loot": true
			}
		_:
			return {}

func get_zone_for_position(position: Vector3) -> PvPZone:
	var nearest_zone: PvPZone = null
	var nearest_distance: float = INF
	
	for zone_id in pvp_zones.keys():
		var zone = pvp_zones[zone_id]
		var distance = position.distance_to(zone.center)
		
		if distance <= zone.radius:
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_zone = zone
	
	return nearest_zone

func is_pvp_allowed_at_position(position: Vector3) -> bool:
	var zone = get_zone_for_position(position)
	
	if not zone:
		return false  # Вне зон PvP запрещён
	
	return zone.zone_type != ZoneType.SAFE

func update_player_zone(player_id: String, position: Vector3) -> void:
	var current_zone = player_in_zones.get(player_id)
	var new_zone = get_zone_for_position(position)
	
	if new_zone:
		if current_zone != new_zone.zone_id:
			if current_zone != "":
				player_left_zone.emit(player_id, current_zone)
			
			player_in_zones[player_id] = new_zone.zone_id
			player_entered_zone.emit(player_id, new_zone.zone_id)
	else:
		if current_zone != "":
			player_left_zone.emit(player_id, current_zone)
			player_in_zones.erase(player_id)

func get_zone_rules(zone_id: String) -> Dictionary:
	if not pvp_zones.has(zone_id):
		return {}
	
	return pvp_zones[zone_id].rules.duplicate()

func set_zone_control(zone_id: String, guild_id: String) -> void:
	if not pvp_zones.has(zone_id):
		return
	
	var zone = pvp_zones[zone_id]
	if zone.zone_type != ZoneType.CONTESTED:
		return
	
	zone.controlling_guild_id = guild_id
	zone_control_changed.emit(zone_id, guild_id)

func get_zone_info(zone_id: String) -> Dictionary:
	if not pvp_zones.has(zone_id):
		return {}
	
	var zone = pvp_zones[zone_id]
	return {
		"id": zone.zone_id,
		"type": zone.zone_type,
		"name": zone.name,
		"center": zone.center,
		"radius": zone.radius,
		"controlling_guild": zone.controlling_guild_id,
		"danger_level": zone.danger_level,
		"rules": zone.rules.duplicate()
	}

