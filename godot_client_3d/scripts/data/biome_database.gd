extends Node
class_name BiomeDatabase

## Полная база данных океанских биомов Isleborn Online
## Согласно GDD: Tropical Shallow, Deep Blue, Mist Sea, Coldwater, Blackwater

var biomes: Dictionary = {}

func _ready() -> void:
	_register_all_biomes()

func _register_all_biomes() -> void:
	# ============================================
	# Тропическое мелководье
	# ============================================
	biomes["tropical_shallow"] = {
		"id": "tropical_shallow",
		"name": "Tropical Shallow",
		"display_name": "Тропическое мелководье",
		"depth_range": Vector2(0.0, 20.0),
		"temperature_range": Vector2(20.0, 30.0),
		"tier": 1,
		"description": "Безопасная начальная зона с тёплой водой",
		"monster_tiers": [1],
		"resource_spawns": ["palm_wood", "fish", "coral", "seaweed"],
		"weather_weights": {
			"clear": 0.5,
			"light_wind": 0.3,
			"rain": 0.15,
			"fog": 0.05
		},
		"water_color": Color(0.2, 0.6, 0.9, 0.8),
		"fog_density": 0.1,
		"ambient_sounds": []
	}
	
	# ============================================
	# Глубокие синие воды
	# ============================================
	biomes["deep_blue"] = {
		"id": "deep_blue",
		"name": "Deep Blue",
		"display_name": "Глубокие синие воды",
		"depth_range": Vector2(20.0, 100.0),
		"temperature_range": Vector2(10.0, 25.0),
		"tier": 2,
		"description": "Основная PvPvE зона с опасными монстрами",
		"monster_tiers": [1, 2, 3],
		"resource_spawns": ["metal_ore", "deep_fish", "crystal", "seaweed"],
		"weather_weights": {
			"clear": 0.3,
			"light_wind": 0.3,
			"rain": 0.2,
			"fog": 0.1,
			"storm": 0.1
		},
		"water_color": Color(0.05, 0.2, 0.4, 0.95),
		"fog_density": 0.2,
		"ambient_sounds": []
	}
	
	# ============================================
	# Туманное море
	# ============================================
	biomes["mist_sea"] = {
		"id": "mist_sea",
		"name": "Mist Sea",
		"display_name": "Туманное море",
		"depth_range": Vector2(50.0, 90.0),
		"temperature_range": Vector2(8.0, 18.0),
		"tier": 3,
		"description": "Постоянный туман, плохая видимость, редкие ресурсы",
		"monster_tiers": [2, 3, 4],
		"resource_spawns": ["ghost_fish", "mist_crystal", "phantom_pearl"],
		"weather_weights": {
			"fog": 0.7,
			"heavy_fog": 0.2,
			"rain": 0.1
		},
		"water_color": Color(0.3, 0.3, 0.5, 0.85),
		"fog_density": 0.6,
		"ambient_sounds": [],
		"visibility_modifier": 0.5  # Снижение видимости на 50%
	}
	
	# ============================================
	# Ледяные воды
	# ============================================
	biomes["coldwater"] = {
		"id": "coldwater",
		"name": "Coldwater Expanse",
		"display_name": "Ледяные воды",
		"depth_range": Vector2(30.0, 100.0),
		"temperature_range": Vector2(-5.0, 10.0),
		"tier": 3,
		"description": "Ледяные моря с редкими ресурсами и опасными монстрами",
		"monster_tiers": [3, 4],
		"resource_spawns": ["ice_crystal", "arctic_fish", "frozen_essence"],
		"weather_weights": {
			"clear": 0.2,
			"snow": 0.4,
			"blizzard": 0.3,
			"fog": 0.1
		},
		"water_color": Color(0.4, 0.6, 0.8, 0.9),
		"fog_density": 0.3,
		"ambient_sounds": [],
		"freezing_effect": true  # Игрок теряет HP без защиты от холода
	}
	
	# ============================================
	# Черноводье (Blackwater)
	# ============================================
	biomes["blackwater"] = {
		"id": "blackwater",
		"name": "Blackwater",
		"display_name": "Черноводье",
		"depth_range": Vector2(200.0, 1000.0),
		"temperature_range": Vector2(0.0, 8.0),
		"tier": 5,
		"description": "Самая опасная зона с мировыми боссами",
		"monster_tiers": [4, 5],
		"resource_spawns": ["void_crystal", "abyss_essence", "deep_core"],
		"weather_weights": {
			"dark_fog": 0.5,
			"void_storm": 0.3,
			"abyss_current": 0.2
		},
		"water_color": Color(0.0, 0.0, 0.1, 0.98),
		"fog_density": 0.9,
		"ambient_sounds": [],
		"visibility_modifier": 0.2,  # Видимость всего 20%
		"pressure_effect": true,  # Постоянный урон без защиты
		"madness_effect": true   # Эффект "срыва разума"
	}
	
	# ============================================
	# Штормовой фронт (Событийный биом)
	# ============================================
	biomes["stormfront"] = {
		"id": "stormfront",
		"name": "Stormfront",
		"display_name": "Штормовой фронт",
		"depth_range": Vector2(0.0, 150.0),
		"temperature_range": Vector2(5.0, 20.0),
		"tier": 4,
		"description": "Временный биом: циклоны, молнии, редкие ресурсы",
		"monster_tiers": [3, 4],
		"resource_spawns": ["storm_crystal", "lightning_essence"],
		"weather_weights": {
			"storm": 0.4,
			"thunderstorm": 0.4,
			"superstorm": 0.2
		},
		"water_color": Color(0.1, 0.2, 0.4, 0.9),
		"fog_density": 0.4,
		"ambient_sounds": [],
		"is_temporary": true  # Временный биом
	}


func get_biome(id: String) -> Dictionary:
	return biomes.get(id, {})


func get_biomes_by_tier(tier: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for biome_id in biomes:
		var biome = biomes[biome_id]
		if biome.get("tier", 0) == tier:
			result.append(biome)
	return result


func get_all_biomes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for biome_id in biomes:
		result.append(biomes[biome_id])
	return result


func get_biome_by_depth(depth: float) -> Dictionary:
	for biome_id in biomes:
		var biome = biomes[biome_id]
		var depth_range = biome.get("depth_range", Vector2(0.0, 0.0))
		if depth >= depth_range.x and depth <= depth_range.y:
			return biome
	return {}
