extends Node
class_name RuinsSystem

## Система руин и подводных загадок для Isleborn Online
## Согласно GDD: руины содержат загадки, головоломки, уникальные предметы

enum RuinType {
	TEMPLE,         # Храмы Созидателей
	LABORATORY,     # Лаборатории древних
	CITY,           # Затонувшие города
	SHIPWRECK,      # Корабельные кладбища
	PIRATE_LAIR     # Руины чёрных пиратов
}

enum PuzzleType {
	RUNE_CIRCLE,    # Вращающиеся рунические круги
	WATER_PRESSURE, # Подводные переключатели с давлением
	LIGHT_BEAM,     # Лазерные биолюминесцентные лучи
	GRAVITY_TRAP,   # Ловушки гравитации
	SEQUENCE        # Последовательность действий
}

enum RuinStatus {
	UNDISCOVERED,   # Не обнаружено
	DISCOVERED,     # Обнаружено
	IN_PROGRESS,    # В процессе исследования
	COMPLETED,      # Завершено
	LOCKED          # Заблокировано
}

class RuinData:
	var ruin_id: String
	var ruin_type: RuinType
	var name: String
	var description: String
	var position: Vector3
	var depth: float = 0.0
	var status: RuinStatus = RuinStatus.UNDISCOVERED
	var puzzles: Array[Dictionary] = []
	var rewards: Dictionary = {}
	var required_level: int = 1
	var discovery_radius: float = 50.0
	var biome: String = ""
	
	func _init(_id: String, _type: RuinType, _name: String, _pos: Vector3):
		ruin_id = _id
		ruin_type = _type
		name = _name
		position = _pos

class PuzzleData:
	var puzzle_id: String
	var puzzle_type: PuzzleType
	var name: String
	var description: String
	var solution: Dictionary = {}
	var current_state: Dictionary = {}
	var solved: bool = false
	var reward: Dictionary = {}
	
	func _init(_id: String, _type: PuzzleType, _name: String):
		puzzle_id = _id
		puzzle_type = _type
		name = _name

var ruins: Dictionary = {}  # ruin_id -> RuinData
var active_puzzles: Dictionary = {}  # puzzle_id -> PuzzleData
var discovered_ruins: Array[String] = []

signal ruin_discovered(ruin_id: String)
signal puzzle_solved(ruin_id: String, puzzle_id: String, rewards: Dictionary)
signal ruin_completed(ruin_id: String, rewards: Dictionary)

func _ready() -> void:
	_generate_ruins()

func _generate_ruins() -> void:
	# Генерируем руины в разных биомах
	_create_ruin("ruin_temple_1", RuinType.TEMPLE, "Храм Созидателей", Vector3(1000, -30, 1000), 30.0, "Deep Blue", 10)
	_create_ruin("ruin_lab_1", RuinType.LABORATORY, "Лаборатория Древних", Vector3(2000, -100, 2000), 100.0, "Blackwater", 25)
	_create_ruin("ruin_city_1", RuinType.CITY, "Затонувший Город", Vector3(1500, -50, 1500), 50.0, "Deep Blue", 15)

func _create_ruin(ruin_id: String, ruin_type: RuinType, name: String, position: Vector3, depth: float, biome: String, level: int) -> void:
	var ruin = RuinData.new(ruin_id, ruin_type, name, position)
	ruin.depth = depth
	ruin.biome = biome
	ruin.required_level = level
	
	# Генерируем головоломки для руин
	_generate_puzzles_for_ruin(ruin)
	
	# Генерируем награды
	ruin.rewards = _generate_rewards_for_ruin(ruin_type, level)
	
	ruins[ruin_id] = ruin

func _generate_puzzles_for_ruin(ruin: RuinData) -> void:
	var puzzle_count = 1 + (ruin.required_level / 5)  # 1-5 головоломок
	
	for i in range(puzzle_count):
		var puzzle_type = _select_puzzle_type_for_ruin(ruin.ruin_type)
		var puzzle_id = "puzzle_%s_%d" % [ruin.ruin_id, i]
		
		var puzzle = PuzzleData.new(puzzle_id, puzzle_type, "Головоломка %d" % (i + 1))
		puzzle.description = _get_puzzle_description(puzzle_type)
		puzzle.solution = _generate_puzzle_solution(puzzle_type)
		puzzle.reward = _generate_puzzle_reward(ruin.required_level)
		
		ruin.puzzles.append({
			"puzzle_id": puzzle_id,
			"puzzle_type": puzzle_type,
			"solved": false
		})
		
		active_puzzles[puzzle_id] = puzzle

func _select_puzzle_type_for_ruin(ruin_type: RuinType) -> PuzzleType:
	match ruin_type:
		RuinType.TEMPLE:
			return PuzzleType.RUNE_CIRCLE
		RuinType.LABORATORY:
			return PuzzleType.WATER_PRESSURE
		RuinType.CITY:
			return PuzzleType.LIGHT_BEAM
		_:
			return PuzzleType.SEQUENCE

func _get_puzzle_description(puzzle_type: PuzzleType) -> String:
	match puzzle_type:
		PuzzleType.RUNE_CIRCLE:
			return "Поверните рунические круги в правильном порядке"
		PuzzleType.WATER_PRESSURE:
			return "Активируйте переключатели под давлением воды"
		PuzzleType.LIGHT_BEAM:
			return "Направьте световые лучи на цели"
		PuzzleType.GRAVITY_TRAP:
			return "Преодолейте ловушки гравитации"
		PuzzleType.SEQUENCE:
			return "Выполните последовательность действий"
		_:
			return "Решите головоломку"

func _generate_puzzle_solution(puzzle_type: PuzzleType) -> Dictionary:
	match puzzle_type:
		PuzzleType.RUNE_CIRCLE:
			# Случайная последовательность рун
			return {"sequence": [1, 3, 2, 4, 5]}
		PuzzleType.WATER_PRESSURE:
			# Комбинация переключателей
			return {"switches": [true, false, true, true, false]}
		PuzzleType.LIGHT_BEAM:
			# Углы поворота
			return {"angles": [45, 90, 135, 180]}
		_:
			return {}

func _generate_puzzle_reward(ruin_level: int) -> Dictionary:
	return {
		"experience": 50.0 * ruin_level,
		"items": [],
		"currency": {"shells": 10 * ruin_level}
	}

func _generate_rewards_for_ruin(ruin_type: RuinType, level: int) -> Dictionary:
	var rewards = {
		"experience": 200.0 * level,
		"currency": {
			"shells": 50 * level,
			"gold": 5 * level
		},
		"items": []
	}
	
	# Уникальные награды в зависимости от типа
	match ruin_type:
		RuinType.TEMPLE:
			rewards["items"].append("rune_temple_ancient")
		RuinType.LABORATORY:
			rewards["items"].append("blueprint_ancient")
		RuinType.CITY:
			rewards["items"].append("treasure_chest")
	
	return rewards

func discover_ruin(ruin_id: String, player_id: String) -> bool:
	if not ruins.has(ruin_id):
		return false
	
	var ruin = ruins[ruin_id]
	
	if ruin.status != RuinStatus.UNDISCOVERED:
		return false  # Уже обнаружено
	
	ruin.status = RuinStatus.DISCOVERED
	discovered_ruins.append(ruin_id)
	ruin_discovered.emit(ruin_id)
	
	return true

func check_ruin_discovery(player_position: Vector3, player_depth: float) -> void:
	for ruin_id in ruins.keys():
		var ruin = ruins[ruin_id]
		
		if ruin.status != RuinStatus.UNDISCOVERED:
			continue
		
		# Проверяем расстояние
		var distance = player_position.distance_to(ruin.position)
		var depth_diff = abs(player_depth - ruin.depth)
		
		if distance <= ruin.discovery_radius and depth_diff <= 10.0:
			discover_ruin(ruin_id, "")

func start_ruin_exploration(ruin_id: String, player_id: String) -> bool:
	if not ruins.has(ruin_id):
		return false
	
	var ruin = ruins[ruin_id]
	
	if ruin.status == RuinStatus.UNDISCOVERED:
		return false
	
	if ruin.status == RuinStatus.COMPLETED:
		return false  # Уже пройдено
	
	ruin.status = RuinStatus.IN_PROGRESS
	return true

func solve_puzzle(ruin_id: String, puzzle_id: String, solution: Dictionary) -> bool:
	if not ruins.has(ruin_id) or not active_puzzles.has(puzzle_id):
		return false
	
	var ruin = ruins[ruin_id]
	var puzzle = active_puzzles[puzzle_id]
	
	if puzzle.solved:
		return false
	
	# Проверяем решение
	var correct = _check_puzzle_solution(puzzle, solution)
	
	if correct:
		puzzle.solved = true
		puzzle.current_state = solution
		
		# Выдаём награду за головоломку
		puzzle_solved.emit(ruin_id, puzzle_id, puzzle.reward)
		
		# Проверяем, все ли головоломки решены
		_check_ruin_completion(ruin_id)
		
		return true
	
	return false

func _check_puzzle_solution(puzzle: PuzzleData, player_solution: Dictionary) -> bool:
	var correct_solution = puzzle.solution
	
	match puzzle.puzzle_type:
		PuzzleType.RUNE_CIRCLE:
			var player_seq = player_solution.get("sequence", [])
			var correct_seq = correct_solution.get("sequence", [])
			return player_seq == correct_seq
		
		PuzzleType.WATER_PRESSURE:
			var player_switches = player_solution.get("switches", [])
			var correct_switches = correct_solution.get("switches", [])
			return player_switches == correct_switches
		
		_:
			return false

func _check_ruin_completion(ruin_id: String) -> void:
	var ruin = ruins[ruin_id]
	if not ruin:
		return
	
	# Проверяем, решены ли все головоломки
	var all_solved = true
	for puzzle_info in ruin.puzzles:
		var puzzle_id = puzzle_info.get("puzzle_id", "")
		if active_puzzles.has(puzzle_id):
			var puzzle = active_puzzles[puzzle_id]
			if not puzzle.solved:
				all_solved = false
				break
	
	if all_solved:
		ruin.status = RuinStatus.COMPLETED
		
		# Выдаём финальные награды
		ruin_completed.emit(ruin_id, ruin.rewards)

func get_ruin_info(ruin_id: String) -> Dictionary:
	if not ruins.has(ruin_id):
		return {}
	
	var ruin = ruins[ruin_id]
	var puzzles_info: Array[Dictionary] = []
	
	for puzzle_info in ruin.puzzles:
		var puzzle_id = puzzle_info.get("puzzle_id", "")
		if active_puzzles.has(puzzle_id):
			var puzzle = active_puzzles[puzzle_id]
			puzzles_info.append({
				"id": puzzle.puzzle_id,
				"type": puzzle.puzzle_type,
				"name": puzzle.name,
				"solved": puzzle.solved
			})
	
	return {
		"id": ruin.ruin_id,
		"type": ruin.ruin_type,
		"name": ruin.name,
		"description": ruin.description,
		"position": ruin.position,
		"depth": ruin.depth,
		"status": ruin.status,
		"required_level": ruin.required_level,
		"biome": ruin.biome,
		"puzzles": puzzles_info,
		"rewards": ruin.rewards
	}

func get_discovered_ruins() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for ruin_id in discovered_ruins:
		if ruins.has(ruin_id):
			result.append(get_ruin_info(ruin_id))
	
	return result

