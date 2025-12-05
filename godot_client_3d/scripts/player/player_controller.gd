extends Node3D

## Thin wrapper around existing prototype player logic.
## TODO: later split networking, input and visualization into separate components.

@export var token := ""

var ws := WebSocketClient.new()
var connected := false
var peer_id := -1
var players := {} # eid -> MeshInstance3D node
var myself_eid := ""
var raft_spawned := false
var click_move_target: Vector3 = Vector3.ZERO
var has_click_move: bool = false
var is_pvp_enabled: bool = false
var current_target: Node = null

# Движение по вертикали / состояния (прыжок, плавание, ныряние)
var visual_y_offset: float = 0.0
var vertical_velocity: float = 0.0
const GRAVITY: float = -20.0
const JUMP_SPEED: float = 6.0
const SWIM_ASCEND_SPEED: float = 2.0
const SWIM_DESCEND_SPEED: float = 2.0
const MAX_DIVE_DEPTH: float = -5.0
const WATER_SURFACE_Y: float = 0.0

var island_radius: float = 3.0
var player_hp: int = 100

func _ready():
	# connect to Gateway. If Auth has token/world_ws, используем их.
	if token == "" and Auth.token != "":
		token = Auth.token
	# connect to Gateway. Ensure Gateway is running at ws://localhost:8080/ws (or Auth.world_ws)
	if token == "":
		print("Warning: token empty. For real testing, set a token or use login menu.")
	var url := ""
	if Auth.world_ws != "":
		url = Auth.world_ws
	else:
		url = "ws://localhost:8080/ws"
	ws.connect_to_url(url, [], ["Authorization: Bearer " + token])
	set_process(true)
	# setup a basic player mesh for local (capsule)
	var cap := MeshInstance3D.new()
	cap.mesh = CapsuleMesh.new()
	cap.name = "LocalPlayer"
	# Применяем цвет в соответствии с кастомизацией
	if Auth.appearance.has("color"):
		var idx := int(Auth.appearance["color"])
		var mat := StandardMaterial3D.new()
		match idx:
			0:
				mat.albedo_color = Color(0.1, 0.5, 0.9) # Ocean Blue
			1:
				mat.albedo_color = Color(0.2, 0.8, 0.5) # Tropical Green
			2:
				mat.albedo_color = Color(0.9, 0.5, 0.2) # Sunset Orange
			_:
				mat.albedo_color = Color(0.8, 0.8, 0.8)
		cap.set_surface_override_material(0, mat)
	add_child(cap)
	cap.translation = Vector3(0, 1, 0)
	
	# Интегрируем визуализацию персонажа
	_integrate_character_visual(cap)


func _process(delta: float) -> void:
	if ws.get_connection_status() == WebSocketClient.CONNECTION_CONNECTED and not connected:
		connected = true
		print("Connected to Gateway (client)")
		# Дополнительный auth_init для совместимости (gateway всё равно шлёт свой)
		var auth := {"t": "auth_init"}
		if Auth.username != "":
			auth["username"] = Auth.username
		ws.get_peer(1).put_packet(JSON.print(auth).to_utf8())

	if ws.get_connection_status() == WebSocketClient.CONNECTION_CONNECTED:
		# receive packets
		while ws.get_peer(1).get_available_packet_count() > 0:
			var pkt := ws.get_peer(1).get_packet().get_string_from_utf8()
			var msg := JSON.parse(pkt)
			if typeof(msg) == TYPE_DICTIONARY and msg.has("t"):
				match msg["t"]:
					"island_state":
						_handle_island_state(msg)
					"spawn":
						myself_eid = msg.get("id", "")
						print("Spawned as", myself_eid, "server name:", msg.get("username", ""))
						# Если у нас есть локальное имя персонажа, сообщим о нём серверу
						if Auth.character_name != "":
							var set_name := {"t": "set_name", "name": Auth.character_name}
							ws.get_peer(1).put_packet(JSON.print(set_name).to_utf8())
					"snapshot":
						_handle_snapshot(msg)
					"player_join":
						_add_remote_player(msg)
					"player_leave":
						_remove_remote_player(msg)
					"resource_update":
						_handle_resource_update(msg)
					"building_added":
						_handle_building_added(msg)
					"hp_update":
						_handle_hp_update(msg)
					"player_dead":
						_handle_player_dead(msg)
					"monster_spawn":
						_handle_monster_spawn(msg)
					"monster_move":
						_handle_monster_move(msg)
					"monster_dead":
						_handle_monster_dead(msg)
					"monster_hp_update":
						_handle_monster_hp_update(msg)
					"pong":
						pass
					_:
						pass
	elif ws.get_connection_status() == WebSocketClient.CONNECTION_DISCONNECTED and connected:
		print("Disconnected")
		connected = false

	# Обновление вертикального смещения (прыжок / плавание / ныряние)
	var lp := get_node_or_null("LocalPlayer")
	if lp:
		var base_pos := lp.translation
		# Определяем, на суше ли мы (в пределах радиуса острова) или в воде
		var horizontal := Vector2(base_pos.x, base_pos.z)
		var dist_from_center := horizontal.length()
		var on_land := dist_from_center <= island_radius + 0.5
		var in_water := not on_land

		if on_land:
			# Обычный прыжок с гравитацией
			if visual_y_offset > 0.0 or vertical_velocity != 0.0:
				vertical_velocity += GRAVITY * delta
				visual_y_offset += vertical_velocity * delta
				if visual_y_offset <= 0.0:
					visual_y_offset = 0.0
					vertical_velocity = 0.0
		elif in_water:
			# В воде считаем, что базовая поверхность = WATER_SURFACE_Y,
			# visual_y_offset задаёт смещение вверх/вниз от поверхности.
			# Здесь гравитация почти не действует, положение управляется вводом (см. _unhandled_input).
			# Лёгкое "выравнивание" к поверхности, если не ныряем глубоко.
			if visual_y_offset > 0.5:
				visual_y_offset = max(visual_y_offset - 0.5 * delta, 0.5)
			elif visual_y_offset < 0.0 and visual_y_offset > MAX_DIVE_DEPTH:
				visual_y_offset = max(visual_y_offset - 0.2 * delta, MAX_DIVE_DEPTH)

		# Применяем смещение к визуальной позиции
		lp.translation.y = WATER_SURFACE_Y + 1.0 + visual_y_offset

	# Click-to-move: двигаем игрока к целевой точке, отправляя input на сервер
	if has_click_move:
		var lp2 := get_node_or_null("LocalPlayer")
		if lp2 and ws.get_connection_status() == WebSocketClient.CONNECTION_CONNECTED:
			var pos2 := lp2.translation
			var flat_target := Vector3(click_move_target.x, pos2.y, click_move_target.z)
			var to_target := flat_target - pos2
			var dist := to_target.length()
			if dist < 0.2:
				has_click_move = false
			else:
				var dir2 := to_target.normalized()
				var speed2 := 0.2
				var dx := dir2.x * speed2
				var dz := dir2.z * speed2
				var req2 := {"t": "move", "dx": dx, "dz": dz}
				ws.get_peer(1).put_packet(JSON.print(req2).to_utf8())


func _handle_snapshot(msg: Dictionary) -> void:
	var players_list := msg.get("players", [])
	for p in players_list:
		var id := p.get("id", "")
		var pos := p.get("pos", [0, 0, 0])
		if id == myself_eid:
			var local := get_node_or_null("LocalPlayer")
			if local:
				# Сервер задаёт базовую позицию, а прыжок/плавание добавляют смещение по Y
				local.translation = Vector3(pos[0], pos[1] + 1 + visual_y_offset, pos[2])
		else:
			if not players.has(id):
				_create_remote_visual(id)
			var node := players[id]
			node.translation = Vector3(pos[0], pos[1] + 1, pos[2])


func _add_remote_player(msg: Dictionary) -> void:
	var id := msg.get("id", "")
	var pos := msg.get("pos", [0, 0, 0])
	if id == myself_eid:
		return
	if not players.has(id):
		_create_remote_visual(id)
	players[id].translation = Vector3(pos[0], pos[1] + 1, pos[2])


func _remove_remote_player(msg: Dictionary) -> void:
	var id := msg.get("id", "")
	if players.has(id):
		var node := players[id]
		node.queue_free()
		players.erase(id)


func _create_remote_visual(id: String) -> void:
	var mesh := MeshInstance3D.new()
	mesh.mesh = SphereMesh.new()
	mesh.scale = Vector3(0.5, 0.5, 0.5)
	mesh.name = id
	add_child(mesh)
	players[id] = mesh
	
	# Интегрируем визуализацию для удалённых игроков
	_integrate_remote_player_visual(mesh)

func _integrate_character_visual(local_player: Node3D) -> void:
	# Находим системы интеграции
	var world = get_tree().current_scene
	if not world:
		return
	
	var character_integration = world.find_child("CharacterVisualIntegration", true, false)
	if not character_integration:
		return
	
	# Определяем пол из кастомизации
	var gender = "male"
	if Auth.appearance.has("gender"):
		gender = Auth.appearance["gender"]
	
	var variant = Auth.appearance.get("character_variant", "default")
	
	# Применяем модель персонажа
	character_integration.apply_character_model(local_player, gender, variant)

func _integrate_remote_player_visual(player_node: Node3D) -> void:
	# Для удалённых игроков используем простую визуализацию
	# TODO: Загрузить модель удалённого игрока когда будет доступна информация о нём
	pass


func _unhandled_input(ev: InputEvent) -> void:
	# Клавиатура: WASD + горячие клавиши
	if ev is InputEventKey and ev.pressed:
		if ws.get_connection_status() == WebSocketClient.CONNECTION_CONNECTED:
			var dx := 0.0
			var dz := 0.0
			if Input.is_key_pressed(KEY_W):
				dz -= 0.2
			if Input.is_key_pressed(KEY_S):
				dz += 0.2
			if Input.is_key_pressed(KEY_A):
				dx -= 0.2
			if Input.is_key_pressed(KEY_D):
				dx += 0.2
			if dx != 0.0 or dz != 0.0:
				has_click_move = false # ручное управление прерывает клик‑ту‑мув
				var req := {"t": "move", "dx": dx, "dz": dz}
				ws.get_peer(1).put_packet(JSON.print(req).to_utf8())

			# Пробел: прыжок на суше / всплытие на поверхности воды
			if ev.scancode == KEY_SPACE:
				var lp := get_node_or_null("LocalPlayer")
				if lp:
					var horizontal := Vector2(lp.translation.x, lp.translation.z)
					var dist_from_center := horizontal.length()
					var on_land := dist_from_center <= island_radius + 0.5
					var in_water := not on_land
					if on_land and visual_y_offset == 0.0:
						vertical_velocity = JUMP_SPEED
					elif in_water:
						# Вода: всплываем к поверхности
						visual_y_offset = min(visual_y_offset + SWIM_ASCEND_SPEED * get_process_delta_time(), 2.0)

			# Левый Ctrl: нырять вниз в воде
			if ev.scancode == KEY_CTRL:
				var lpw := get_node_or_null("LocalPlayer")
				if lpw:
					var horizontal2 := Vector2(lpw.translation.x, lpw.translation.z)
					var dist2 := horizontal2.length()
					var on_land2 := dist2 <= island_radius + 0.5
					if not on_land2:
						visual_y_offset = max(visual_y_offset - SWIM_DESCEND_SPEED * get_process_delta_time(), MAX_DIVE_DEPTH)

			# E: gather nearest resource at player position
			if ev.scancode == KEY_E:
				var lp := get_node_or_null("LocalPlayer")
				if lp:
					var pos := lp.translation
					var g := {"t": "gather", "x": pos.x, "z": pos.z}
					ws.get_peer(1).put_packet(JSON.print(g).to_utf8())

			# F: place a simple campfire near player
			if ev.scancode == KEY_F:
				var lp2 := get_node_or_null("LocalPlayer")
				if lp2:
					var pos2 := lp2.translation
					var offset := Vector3(0.5, 0.0, 0.5)
					var b := {"t": "build", "type": "campfire", "x": pos2.x + offset.x, "z": pos2.z + offset.z}
					ws.get_peer(1).put_packet(JSON.print(b).to_utf8())

			# P: toggle PvP / PvE mode (отправляем на сервер, даже если тот пока игнорирует)
			if ev.scancode == KEY_P:
				is_pvp_enabled = not is_pvp_enabled
				var m := {"t": "pvp_mode", "enabled": is_pvp_enabled}
				ws.get_peer(1).put_packet(JSON.print(m).to_utf8())

			# R: spawn a local raft prototype near the island (client-only for now)
			if ev.scancode == KEY_R and not raft_spawned:
				var world := get_parent()
				if world:
					var raft_scene := load("res://scenes/ships/raft.tscn")
					if raft_scene:
						var raft := raft_scene.instantiate()
						raft.translation = Vector3(0.0, 0.0, -4.0)
						world.add_child(raft)
						raft_spawned = true

	# ЛКМ: клик‑ту‑мув / выбор цели, камера берётся из текущего вьюпорта
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
		var cam := get_viewport().get_camera_3d()
		if not cam:
			return
		var from := cam.project_ray_origin(ev.position)
		var dir := cam.project_ray_normal(ev.position)
		var space := get_world_3d().direct_space_state
		var result := space.intersect_ray(from, from + dir * 200.0, [], 1)
		if result:
			var collider := result.collider
			if collider and collider.is_in_group("Enemy"):
				current_target = collider
				print("Selected enemy target:", collider.name)
				# Отправляем простой запрос атаки на сервер (пока без реального урона)
				if ws.get_connection_status() == WebSocketClient.CONNECTION_CONNECTED:
					var attack := {
						"t": "attack",
						"target_name": collider.name
					}
					ws.get_peer(1).put_packet(JSON.print(attack).to_utf8())
			else:
				click_move_target = result.position
				has_click_move = true


func _handle_island_state(msg: Dictionary) -> void:
	var island := msg.get("island", {})
	print("Received island state, resources:", island.get("resources", []).size(), "buildings:", island.get("buildings", []).size())
	island_radius = island.get("bounds", {}).get("radius", 3.0)
	_create_island_visual(island)
	_create_resource_visuals(island)

func _create_island_visual(island: Dictionary) -> void:
	var island_vis := get_node_or_null("IslandVisual")
	if island_vis:
		island_vis.queue_free()
	
	var radius := island.get("bounds", {}).get("radius", 3.0)
	
	# Создаём базу острова
	var island_base := CylinderMesh.new()
	island_base.top_radius = radius
	island_base.bottom_radius = radius
	island_base.height = 0.3
	
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.4, 0.3, 0.2)  # Земляной цвет
	base_mat.roughness = 0.9
	
	var base_mesh := MeshInstance3D.new()
	base_mesh.mesh = island_base
	base_mesh.material_override = base_mat
	base_mesh.translation = Vector3(0, -0.15, 0)
	base_mesh.name = "IslandVisual"
	add_child(base_mesh)
	
	# Создаём пляж
	_create_beach_ring(radius)


func _create_resource_visuals(island: Dictionary) -> void:
	# Создаём/обновляем визуализацию острова
	_create_island_visual(island)
	
	var rr := get_node_or_null("ResourceRoot")
	var br := get_node_or_null("BuildingRoot")
	if not rr:
		rr = Node3D.new()
		rr.name = "ResourceRoot"
		add_child(rr)
	if not br:
		br = Node3D.new()
		br.name = "BuildingRoot"
		add_child(br)

	for c in rr.get_children():
		c.queue_free()
	for c in br.get_children():
		c.queue_free()

	var resources := island.get("resources", [])
	for r in resources:
		var t := r.get("type", "palm_tree")
		var pos := r.get("pos", [0, 0, 0])
		var node := null
		if t == "palm_tree":
			node = load("res://scenes/resources/palm_tree.tscn").instantiate()
		elif t == "stone_node":
			node = load("res://scenes/resources/rock.tscn").instantiate()
		else:
			node = MeshInstance3D.new()
		if node:
			node.translation = Vector3(pos[0], pos[1], pos[2])
			rr.add_child(node)

	var buildings := island.get("buildings", [])
	for b in buildings:
		var bt := b.get("type", "campfire")
		var bpos := b.get("pos", [0, 0, 0])
		var bnode := null
		if bt == "campfire":
			bnode = load("res://scenes/buildings/campfire.tscn").instantiate()
		if bnode:
			bnode.translation = Vector3(bpos[0], bpos[1], bpos[2])
			br.add_child(bnode)


func _handle_resource_update(msg: Dictionary) -> void:
	var pos := msg.get("pos", [0, 0, 0])
	var rr := get_node_or_null("ResourceRoot")
	if not rr:
		return
	for c in rr.get_children():
		if c.translation.distance_to(Vector3(pos[0], pos[1], pos[2])) < 0.5:
			var amt := msg.get("amount", 0)
			if amt <= 0:
				c.queue_free()
			# Award local resource to inventory (client-side prototype only).
			var world := get_parent()
			if world and world.has_node("Inventory"):
				var inv := world.get_node("Inventory")
				var rtype := msg.get("type", "")
				var item_id := ""
				match rtype:
					"palm_tree":
						item_id = "palm_wood"
					"stone_node":
						item_id = "stone"
					_:
						item_id = ""
				if item_id != "":
					inv.add_item(item_id, 1)
			return


func _create_beach_ring(radius: float) -> void:
	# Создаём кольцо пляжа вокруг острова
	var segments := 32
	var angle_step := TAU / segments
	var beach_width := 0.5
	
	var beach_mat := StandardMaterial3D.new()
	beach_mat.albedo_color = Color(0.9, 0.85, 0.7)  # Песчаный цвет
	beach_mat.roughness = 0.8
	
	for i in range(segments):
		var angle := i * angle_step
		var inner_r := radius
		var outer_r := radius + beach_width
		
		var quad := QuadMesh.new()
		quad.size = Vector2(beach_width, 0.1)
		
		var segment := MeshInstance3D.new()
		segment.mesh = quad
		segment.material_override = beach_mat
		
		var mid_r := (inner_r + outer_r) / 2.0
		segment.translation = Vector3(
			cos(angle) * mid_r,
			0.05,
			sin(angle) * mid_r
		)
		segment.rotation.y = angle + PI / 2.0
		segment.name = "BeachSegment_%d" % i
		
		var island_vis := get_node_or_null("IslandVisual")
		if island_vis:
			island_vis.add_child(segment)

func _handle_building_added(msg: Dictionary) -> void:
	var pos := msg.get("pos", [0, 0, 0])
	var br := get_node_or_null("BuildingRoot")
	if not br:
		br = Node3D.new()
		br.name = "BuildingRoot"
		add_child(br)
	var t := msg.get("type", "campfire")
	var node := null
	if t == "campfire":
		node = load("res://scenes/buildings/campfire.tscn").instantiate()
	if node:
		node.translation = Vector3(pos[0], pos[1], pos[2])
		br.add_child(node)


func _handle_hp_update(msg: Dictionary) -> void:
	var id := str(msg.get("id", ""))
	var hp := int(msg.get("hp", 0))
	if id == myself_eid:
		player_hp = hp
		print("My HP updated:", hp)
	else:
		print("HP update for", id, "=", hp)


func _handle_player_dead(msg: Dictionary) -> void:
	var id := str(msg.get("id", ""))
	print("Player died:", id)

var monsters: Dictionary = {}  # monster_id -> Node3D
var monster_spawn_handler: MonsterSpawnHandler = null

func _handle_monster_spawn(msg: Dictionary) -> void:
	if not monster_spawn_handler:
		var world = get_tree().current_scene
		if world:
			monster_spawn_handler = world.find_child("MonsterSpawnHandler", true, false)
			if not monster_spawn_handler:
				monster_spawn_handler = MonsterSpawnHandler.new()
				monster_spawn_handler.name = "MonsterSpawnHandler"
				world.add_child(monster_spawn_handler)
	
	if monster_spawn_handler:
		monster_spawn_handler.handle_monster_spawn(msg)

func _handle_monster_move(msg: Dictionary) -> void:
	if monster_spawn_handler:
		monster_spawn_handler.handle_monster_move(msg)

func _handle_monster_dead(msg: Dictionary) -> void:
	if monster_spawn_handler:
		monster_spawn_handler.handle_monster_dead(msg)

func _handle_monster_hp_update(msg: Dictionary) -> void:
	if monster_spawn_handler:
		monster_spawn_handler.handle_monster_hp_update(msg)

func _handle_monster_from_snapshot(monster_data: Dictionary) -> void:
	var monster_id = monster_data.get("id", "")
	if monster_id == "":
		return
	
	# Если монстр уже существует, обновляем его позицию
	if monsters.has(monster_id):
		var monster = monsters[monster_id]
		var pos = monster_data.get("pos", [0, 0, 0])
		var depth = monster_data.get("depth", 0.0)
		var position = Vector3(pos[0], pos[1], pos[2])
		
		if depth > 0.0:
			position.y = -depth
		
		monster.global_position = position
		return
	
	# Если монстра нет, создаём его
	_handle_monster_spawn({
		"id": monster_id,
		"type": monster_data.get("type", ""),
		"pos": monster_data.get("pos", [0, 0, 0]),
		"depth": monster_data.get("depth", 0.0),
		"environment": monster_data.get("environment", 0),
		"health": monster_data.get("health", 100.0),
		"max_health": monster_data.get("max_health", 100.0)
	})


func get_player_hp() -> int:
	return player_hp


