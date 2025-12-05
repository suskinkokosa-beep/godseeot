extends Node
class_name MonsterSpawnHandler

## Обработчик спавна монстров на клиенте

var monster_visual_integration: MonsterVisualIntegration = null
var monsters: Dictionary = {}  # monster_id -> Node3D

func _ready() -> void:
	var world = get_tree().current_scene
	if world:
		monster_visual_integration = world.find_child("MonsterVisualIntegration", true, false)

func handle_monster_spawn(msg: Dictionary) -> void:
	var monster_id = msg.get("id", "")
	var monster_type = msg.get("type", "")
	var pos = msg.get("pos", [0, 0, 0])
	var depth = msg.get("depth", 0.0)
	var environment = msg.get("environment", 0)
	var health = msg.get("health", 100.0)
	var max_health = msg.get("max_health", 100.0)
	
	if monster_id == "":
		return
	
	# Если монстр уже существует, обновляем его
	if monsters.has(monster_id):
		handle_monster_move({
			"id": monster_id,
			"pos": pos,
			"depth": depth
		})
		return
	
	var position = Vector3(pos[0], pos[1], pos[2])
	
	if monster_visual_integration:
		var monster_visual = monster_visual_integration.create_monster_visual(monster_type, position, environment, depth)
		if monster_visual:
			monster_visual.name = "Monster_%s" % monster_id
			monster_visual.set_meta("monster_id", monster_id)
			monster_visual.set_meta("monster_type", monster_type)
			monster_visual.set_meta("health", health)
			monster_visual.set_meta("max_health", max_health)
			
			var world = get_tree().current_scene
			if world:
				var monster_root = world.get_node_or_null("MonsterRoot")
				if not monster_root:
					monster_root = Node3D.new()
					monster_root.name = "MonsterRoot"
					world.add_child(monster_root)
				
				monster_root.add_child(monster_visual)
				monsters[monster_id] = monster_visual

func handle_monster_move(msg: Dictionary) -> void:
	var monster_id = msg.get("id", "")
	var pos = msg.get("pos", [0, 0, 0])
	var depth = msg.get("depth", 0.0)
	
	if not monsters.has(monster_id):
		return
	
	var monster = monsters[monster_id]
	var position = Vector3(pos[0], pos[1], pos[2])
	
	# Обновляем позицию с учётом глубины
	if depth > 0.0:
		position.y = -depth
	
	monster.global_position = position

func handle_monster_dead(msg: Dictionary) -> void:
	var monster_id = msg.get("id", "")
	
	if monsters.has(monster_id):
		var monster = monsters[monster_id]
		# Добавляем эффекты смерти
		monster.queue_free()
		monsters.erase(monster_id)

func handle_monster_hp_update(msg: Dictionary) -> void:
	var monster_id = msg.get("id", "")
	var hp = msg.get("hp", 100.0)
	var max_hp = msg.get("max_hp", 100.0)
	
	if monsters.has(monster_id):
		var monster = monsters[monster_id]
		monster.set_meta("health", hp)
		monster.set_meta("max_health", max_hp)
		
		# В будущем можно добавить визуальную индикацию HP
		# Например, health bar над монстром

