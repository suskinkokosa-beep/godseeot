extends Node
class_name WorldMapSystem

## Система карты мира для Isleborn Online
## Согласно GDD: карта океана, секторы, биомы, точки интереса

enum MapLayer {
	BIOMES,         # Биомы
	RESOURCES,      # Ресурсы
	MONSTERS,       # Монстры
	RUINS,          # Руины
	PLAYERS,        # Игроки
	AI_GUILDS,      # AI-гильдии
	EVENTS          # События
}

class MapMarker:
	var marker_id: String
	var position: Vector3
	var marker_type: String
	var name: String
	var description: String
	var icon: String = ""
	var visible: bool = true
	
	func _init(_id: String, _type: String, _name: String, _pos: Vector3):
		marker_id = _id
		marker_type = _type
		name = _name
		position = _pos

class MapSector:
	var sector_id: String
	var position: Vector3
	var biome: String
	var discovered: bool = false
	var markers: Array[String] = []  # marker_ids
	var danger_level: float = 0.0  # 0.0-1.0
	var resource_richness: float = 0.5  # 0.0-1.0
	
	func _init(_id: String, _pos: Vector3, _biome: String):
		sector_id = _id
		position = _pos
		biome = _biome

var map_markers: Dictionary = {}  # marker_id -> MapMarker
var map_sectors: Dictionary = {}  # sector_id -> MapSector
var discovered_sectors: Array[String] = []
var active_layers: Array[MapLayer] = [MapLayer.BIOMES]

signal sector_discovered(sector_id: String)
signal marker_added(marker_id: String)
signal marker_removed(marker_id: String)

func _ready() -> void:
	_generate_map_sectors()

func _generate_map_sectors() -> void:
	# Генерируем секторы карты (2x2 км каждый)
	var sector_size = 2000.0  # 2 км
	var world_size = 200000.0  # 200 км
	var sector_count_x = int(world_size / sector_size)
	var sector_count_z = int(world_size / sector_size)
	
	for x in range(sector_count_x):
		for z in range(sector_count_z):
			var sector_pos = Vector3(x * sector_size - world_size/2, 0, z * sector_size - world_size/2)
			var sector_id = "sector_%d_%d" % [x, z]
			var biome = _determine_biome_for_position(sector_pos)
			
			var sector = MapSector.new(sector_id, sector_pos, biome)
			map_sectors[sector_id] = sector

func _determine_biome_for_position(position: Vector3) -> String:
	var distance_from_center = position.length()
	
	if distance_from_center < 50000:  # 50 км от центра
		return "Tropical Shallow"
	elif distance_from_center < 100000:  # 100 км
		return "Deep Blue"
	elif distance_from_center < 150000:  # 150 км
		return "Mist Sea"
	else:
		return "Blackwater"

func discover_sector(sector_id: String) -> bool:
	if not map_sectors.has(sector_id):
		return false
	
	var sector = map_sectors[sector_id]
	
	if sector.discovered:
		return false
	
	sector.discovered = true
	discovered_sectors.append(sector_id)
	sector_discovered.emit(sector_id)
	
	return true

func discover_sector_by_position(position: Vector3) -> String:
	# Находим сектор по позиции
	var sector_id = _get_sector_id_for_position(position)
	if sector_id != "":
		discover_sector(sector_id)
	return sector_id

func _get_sector_id_for_position(position: Vector3) -> String:
	var sector_size = 2000.0
	var world_size = 200000.0
	
	var x = int((position.x + world_size/2) / sector_size)
	var z = int((position.z + world_size/2) / sector_size)
	
	return "sector_%d_%d" % [x, z]

func add_marker(marker_type: String, name: String, position: Vector3, description: String = "") -> String:
	var marker_id = "marker_%d" % Time.get_ticks_msec()
	var marker = MapMarker.new(marker_id, marker_type, name, position)
	marker.description = description
	
	map_markers[marker_id] = marker
	
	# Добавляем маркер в соответствующий сектор
	var sector_id = _get_sector_id_for_position(position)
	if map_sectors.has(sector_id):
		map_sectors[sector_id].markers.append(marker_id)
	
	marker_added.emit(marker_id)
	return marker_id

func remove_marker(marker_id: String) -> void:
	if not map_markers.has(marker_id):
		return
	
	var marker = map_markers[marker_id]
	
	# Удаляем из сектора
	var sector_id = _get_sector_id_for_position(marker.position)
	if map_sectors.has(sector_id):
		var sector = map_sectors[sector_id]
		var index = sector.markers.find(marker_id)
		if index >= 0:
			sector.markers.remove_at(index)
	
	map_markers.erase(marker_id)
	marker_removed.emit(marker_id)

func get_markers_in_area(center: Vector3, radius: float, layer: MapLayer = MapLayer.BIOMES) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for marker_id in map_markers.keys():
		var marker = map_markers[marker_id]
		
		if not marker.visible:
			continue
		
		if marker.position.distance_to(center) <= radius:
			# Фильтруем по слою
			if _is_marker_in_layer(marker, layer):
				result.append({
					"id": marker.marker_id,
					"type": marker.marker_type,
					"name": marker.name,
					"position": marker.position,
					"description": marker.description
				})
	
	return result

func _is_marker_in_layer(marker: MapMarker, layer: MapLayer) -> bool:
	# Определяем, принадлежит ли маркер слою
	match layer:
		MapLayer.RESOURCES:
			return marker.marker_type in ["resource_node", "fishing_spot"]
		MapLayer.RUINS:
			return marker.marker_type == "ruin"
		MapLayer.MONSTERS:
			return marker.marker_type == "monster_spawn"
		MapLayer.AI_GUILDS:
			return marker.marker_type == "ai_guild"
		MapLayer.EVENTS:
			return marker.marker_type == "event"
		_:
			return true

func get_sector_info(sector_id: String) -> Dictionary:
	if not map_sectors.has(sector_id):
		return {}
	
	var sector = map_sectors[sector_id]
	var markers_info: Array[Dictionary] = []
	
	for marker_id in sector.markers:
		if map_markers.has(marker_id):
			var marker = map_markers[marker_id]
			markers_info.append({
				"id": marker.marker_id,
				"type": marker.marker_type,
				"name": marker.name,
				"position": marker.position
			})
	
	return {
		"id": sector.sector_id,
		"position": sector.position,
		"biome": sector.biome,
		"discovered": sector.discovered,
		"danger_level": sector.danger_level,
		"resource_richness": sector.resource_richness,
		"markers": markers_info
	}

func get_discovered_sectors() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for sector_id in discovered_sectors:
		if map_sectors.has(sector_id):
			result.append(get_sector_info(sector_id))
	
	return result

func set_layer_visibility(layer: MapLayer, visible: bool) -> void:
	if visible:
		if layer not in active_layers:
			active_layers.append(layer)
	else:
		var index = active_layers.find(layer)
		if index >= 0:
			active_layers.remove_at(index)

func get_map_data_for_display(center: Vector3, view_radius: float) -> Dictionary:
	return {
		"sectors": get_discovered_sectors(),
		"markers": get_markers_in_area(center, view_radius),
		"active_layers": active_layers
	}

