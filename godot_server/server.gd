extends Node3D

var http_request: HTTPRequest = null
var ISLAND_SERVICE_URL = "http://island_service:5000"
# Headless Godot server (3D) for Isleborn: island-per-player persistence
var ws_server: WebSocketServer
var peers = {} # peer_id -> WebSocketPeer
var peer_to_eid = {} # peer_id -> entity id
var entities = {} # eid -> {pos: [x,y,z], rot: float, last_update: int}
var monster_server: MonsterServer = null

const SNAPSHOT_INTERVAL = 0.5 # seconds
var _snapshot_timer = 0.0

# islands persistence path (relative to server working dir)
var ISLANDS_PATH = "islands"

func _ready():
	# HTTP client for Island Service
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_on_request_completed")

	ws_server = WebSocketServer.new()
	var ok = ws_server.listen(8090)
	if ok != OK:
		push_error("Failed to listen on 8090: %s" % ok)
		return
	print("Godot headless 3D server listening on 8090")
	
	# Инициализация системы монстров
	monster_server = MonsterServer.new()
	add_child(monster_server)
	monster_server.monster_spawned.connect(_on_monster_spawned)
	monster_server.monster_moved.connect(_on_monster_moved)
	monster_server.monster_died.connect(_on_monster_died)
	
	set_process(true)
	set_physics_process(true)

func _physics_process(delta):
	# Accept connections
	while ws_server.is_connection_available():
		var peer = ws_server.take_connection()
		if peer:
			var id = peer.get_unique_id()
			peers[id] = peer
			print("New peer connected:", id)

	# Read available packets
	for id in peers.keys():
		var peer = peers[id]
		while peer.get_available_packet_count() > 0:
			var pkt := peer.get_packet().get_string_from_utf8()
			var ok = false
			var msg = JSON.parse(pkt)
			if typeof(msg) == TYPE_DICTIONARY and msg.has("t"):
				var t = msg["t"]
				if t == "auth_init":
					handle_auth_init(id, peer, msg)
				elif t == "move" or t == "input_move":
					handle_move(id, msg)
				elif t == "gather":
					handle_gather(id, msg)
				elif t == "build":
					handle_build(id, msg)
				elif t == "ping":
					peer.put_packet(JSON.print({"t":"pong"}).to_utf8())
				elif t == "pvp_mode":
					handle_pvp_mode(id, msg)
				elif t == "attack":
					handle_attack(id, msg)
				elif t == "set_name":
					handle_set_name(id, msg)
				elif t == "disconnect":
					handle_disconnect(id)
				else:
					# unknown message
					peer.put_packet(JSON.print({"t":"error","message":"unknown_type"}).to_utf8())

func handle_auth_init(peer_id, peer, msg):
	var sub = msg.has("sub") ? str(msg["sub"]) : null
	var username = msg.has("username") ? str(msg["username"]) : "Player"
	if sub == null:
		# require sub (gateway should set it)
		peer.put_packet(JSON.print({"t":"error","message":"missing_sub"}).to_utf8())
		peer.disconnect_from_host(1000, "missing_sub")
		peers.erase(peer_id)
		return
	# Load or create island for this player
	var island = load_or_create_island(sub, username)
	# send island_state to client
	peer.put_packet(JSON.print({"t":"island_state","island":island}).to_utf8())

	var eid = "p_" + sub
	peer_to_eid[peer_id] = eid
	# initial spawn position - spawn on beach (use island beach pos if exists)
	var spawn_pos = island.get("spawn_pos", [0.0, 0.0, 0.0])
	entities[eid] = {"pos":spawn_pos, "rot":0.0, "username":username, "last_update":OS.get_unix_time(), "pvp":false, "hp":100, "max_hp":100}
	# send spawn confirmation to this peer
	peer.put_packet(JSON.print({"t":"spawn","id":eid,"pos":spawn_pos,"rot":0,"username":username}).to_utf8())
	# broadcast to others about new player
	broadcast({"t":"player_join","id":eid,"pos":spawn_pos,"rot":0,"username":username})

func handle_move(peer_id, msg):
	if not peer_to_eid.has(peer_id):
		return
	var eid = peer_to_eid[peer_id]
	if not entities.has(eid):
		return
	var dx = float(msg.get("dx", 0.0))
	var dz = float(msg.get("dz", 0.0))
	# simple speed limit (anti-cheat)
	var max_speed = 1.5 # meters per snapshot interval
	if abs(dx) > max_speed or abs(dz) > max_speed:
		# ignore extreme inputs
		return
	var st = entities[eid]
	st["pos"][0] += dx
	st["pos"][2] += dz
	# enforce island bounds if known
	var island = load_island_for_eid(eid)
	if island != null:
		var bounds = island.get("bounds", {"radius":3.0})
		var bx = st["pos"][0]
		var bz = st["pos"][2]
		var r = bounds.get("radius", 3.0)
		var dist = sqrt(bx*bx + bz*bz)
		if dist > r:
			# clamp to shore
			var nx = bx * r / dist
			var nz = bz * r / dist
			st["pos"][0] = nx
			st["pos"][2] = nz
	st["last_update"] = OS.get_unix_time()
	entities[eid] = st

func handle_disconnect(peer_id):
	if peer_to_eid.has(peer_id):
		var eid = peer_to_eid[peer_id]
		entities.erase(eid)
		peer_to_eid.erase(peer_id)
		peers.erase(peer_id)
		broadcast({"t":"player_leave","id":eid})

func broadcast(msg):
	var s = JSON.print(msg)
	for id in peers.keys():
		var peer = peers[id]
		peer.put_packet(s.to_utf8())

func _process(delta):
	_snapshot_timer += delta
	if _snapshot_timer >= SNAPSHOT_INTERVAL:
		_snapshot_timer = 0.0
		send_snapshot()

func send_snapshot():
	var snapshot = {"t":"snapshot","tick":OS.get_unix_time(),"players":[]}
	for eid in entities.keys():
		var st = entities[eid]
		snapshot["players"].append({"id":eid,"pos":st["pos"],"rot":st["rot"],"username":st.get("username","")})
	
	# Добавляем монстров в снапшот
	if monster_server:
		var monsters_data = monster_server.get_monster_snapshot()
		snapshot["monsters"] = monsters_data.get("monsters", [])
	
	var s = JSON.print(snapshot)
	for id in peers.keys():
		var peer = peers[id]
		peer.put_packet(s.to_utf8())

func _exit_tree():
	if ws_server:
		ws_server.stop()

# -- Island persistence helpers --

func island_file_path(sub):
	var dir = ISLANDS_PATH
	if not Directory.new().dir_exists(dir):
		Directory.new().make_dir_recursive(dir)
	return dir + "/island_" + sub + ".json"

func default_island(sub, username):
	# minimal island data for level 1, size ~5x5 meters, radius 3m
	return {
		"owner": sub,
		"owner_name": username,
		"level": 1,
		"size": {"width":5, "height":5},
		"bounds": {"radius":3.0},
		"spawn_pos": [0.0, 0.0, 0.0],
		"resources": [
			{"type":"palm_tree","pos":[1.0,0.0,0.5],"amount":5},
			{"type":"stone_node","pos":[-1.2,0.0,-0.7],"amount":6}
		],
		"buildings": [
			{"type":"campfire","pos":[0.5,0.0,0.2]}
		]
	}

func load_or_create_island(sub, username):
	# Load via Island Service API; if not found, create via generator endpoint (POST)
	var owner = sub
	var data = api_load_island(owner)
	if data != null:
		return data
	# fallback: create default and POST
	var isl = default_island(sub, username)
	var ok = api_create_island(owner, isl)
	return isl

func save_island(sub, island):
	# Save via Island Service
	var owner = sub
	api_save_island(owner, island)
	return

func load_island_for_eid(eid):
	# eid format: p_<sub>
	if not eid.begins_with("p_"):
		return null
	var sub = eid.substr(2, eid.length()-2)
	return api_load_island(sub)

# Gather resource at pos near player, decrement amount, then save island
func handle_gather(peer_id, msg):
	if not peer_to_eid.has(peer_id):
		return
	var eid = peer_to_eid[peer_id]
	var island = load_island_for_eid(eid)
	if island == null:
		return
	var px = float(msg.get("x", 0))
	var pz = float(msg.get("z", 0))
	var resources = island.get("resources", [])
	for r in resources:
		var pos = r.get("pos")
		var rx = pos[0]
		var rz = pos[2]
		if abs(px-rx) < 0.8 and abs(pz-rz) < 0.8:
			var amt = int(r.get("amount", 0))
			if amt > 0:
				amt -= 1
				r["amount"] = amt
				broadcast({"t":"resource_update","type":r.get("type"),"pos":pos,"amount":amt})
				island["resources"] = resources
				save_island(eid.substr(2, eid.length()-2), island)
			return

# Place building at given location and save
func handle_build(peer_id, msg):
	if not peer_to_eid.has(peer_id):
		return
	var eid = peer_to_eid[peer_id]
	var island = load_island_for_eid(eid)
	if island == null:
		return
	var btype = msg.get("type", "campfire")
	var x = float(msg.get("x", 0))
	var z = float(msg.get("z", 0))
	var buildings = island.get("buildings", [])
	var b = {"type":btype, "pos":[x,0.0,z]}
	buildings.append(b)
	island["buildings"] = buildings
	save_island(eid.substr(2, eid.length()-2), island)
	broadcast({"t":"building_added","type":btype,"pos":[x,0.0,z]})

func handle_set_name(peer_id, msg):
	if not peer_to_eid.has(peer_id):
		return
	var eid = peer_to_eid[peer_id]
	if not entities.has(eid):
		return
	var new_name = str(msg.get("name", ""))
	if new_name == "":
		return
	var st = entities[eid]
	st["username"] = new_name
	entities[eid] = st
	# Уведомляем всех, чтобы могли обновить отображаемое имя
	broadcast({"t":"player_rename","id":eid,"username":new_name})

# PvP toggle (простое хранение флага, без логики урона)
func handle_pvp_mode(peer_id, msg):
	if not peer_to_eid.has(peer_id):
		return
	var eid = peer_to_eid[peer_id]
	if not entities.has(eid):
		return
	var enabled = bool(msg.get("enabled", false))
	var st = entities[eid]
	st["pvp"] = enabled
	entities[eid] = st
	# уведомляем только самого игрока
	var peer = peers.get(peer_id, null)
	if peer:
		peer.put_packet(JSON.print({"t":"pvp_mode","enabled":enabled}).to_utf8())

# Обработчик атаки
func handle_attack(peer_id, msg):
	if not peer_to_eid.has(peer_id):
		return
	var eid = peer_to_eid[peer_id]
	var target_id = str(msg.get("target_id", ""))
	var damage = float(msg.get("damage", 10.0))
	var damage_type = str(msg.get("damage_type", "physical"))
	
	# Проверяем, что атакующий не мёртв
	if not entities.has(eid):
		return
	var attacker = entities[eid]
	if attacker.get("dead", false):
		return

	# Находим цель
	var target_eid = ""
	if target_id.begins_with("p_"):
		target_eid = target_id
	elif target_id.begins_with("monster_"):
		# Обработка атаки на монстра
		handle_monster_attack(eid, target_id, damage, damage_type)
		return
	else:
		# Ищем по имени игрока (для обратной совместимости)
		for teid in entities.keys():
			var st = entities[teid]
			if st.get("username", "") == target_id:
				target_eid = teid
				break

	if target_eid == "" or not entities.has(target_eid):
		return

	var target = entities[target_eid]
	
	# Проверяем PvP режим
	var attacker_pvp = attacker.get("pvp", false)
	var target_pvp = target.get("pvp", false)
	
	# Если не оба в PvP режиме и это атака на игрока - отменяем
	if target_eid.begins_with("p_") and not (attacker_pvp and target_pvp):
		# PvP не разрешён
		peers[peer_id].put_packet(JSON.print({
			"t": "attack_blocked",
			"reason": "pvp_disabled"
		}).to_utf8())
		return

	# Вычисляем финальный урон
	var final_damage = calculate_damage(damage, damage_type, attacker, target)
	
	# Применяем урон
	var hp = float(target.get("hp", 100))
	hp -= final_damage
	hp = max(0.0, hp)
	target["hp"] = hp
	entities[target_eid] = target

	# Сообщаем всем об изменении HP
	broadcast({
		"t": "hp_update",
		"id": target_eid,
		"hp": hp,
		"damage": final_damage,
		"attacker_id": eid
	})

	if hp <= 0:
		# Определяем тип смерти
		var death_type = "pve"
		if target_eid.begins_with("p_") and attacker_pvp and target_pvp:
			death_type = "pvp"
		
		# Обрабатываем смерть
		handle_player_death_internal(target_eid, death_type, eid)

func calculate_damage(base_damage: float, damage_type: String, attacker: Dictionary, target: Dictionary) -> float:
	var damage = base_damage
	
	# Применяем модификаторы атакующего
	var attacker_level = attacker.get("level", 1)
	damage *= (1.0 + attacker_level * 0.05)
	
	# Применяем защиту цели
	var defense = float(target.get("defense", 0))
	var damage_reduction = defense / (defense + 100.0)
	damage *= (1.0 - damage_reduction)
	
	# Случайная вариация ±10%
	damage *= (0.9 + randf() * 0.2)
	
	return max(1.0, damage)

func handle_player_death_internal(eid: String, death_type: String, killer_id: String):
	if not entities.has(eid):
		return
	
	var player = entities[eid]
	
	player["hp"] = 0
	player["dead"] = true
	player["death_time"] = OS.get_unix_time()
	player["death_type"] = death_type
	player["killer_id"] = killer_id if killer_id != "" else null
	
	# Вычисляем штрафы
	var penalties = {}
	match death_type:
		"pve":
			penalties = {
				"exp_loss_percent": 0.05,
				"respawn_time": 10.0
			}
		"pvp":
			penalties = {
				"exp_loss_percent": 0.10,
				"currency_loss_percent": 0.05,
				"respawn_time": 30.0
			}
		_:
			penalties = {
				"exp_loss_percent": 0.02,
				"respawn_time": 5.0
			}
	
	# Применяем потерю опыта
	if penalties.has("exp_loss_percent"):
		var current_exp = player.get("experience", 0.0)
		var loss = current_exp * penalties["exp_loss_percent"]
		player["experience"] = max(0.0, current_exp - loss)
	
	entities[eid] = player
	
	broadcast({
		"t": "player_dead",
		"id": eid,
		"death_type": death_type,
		"killer_id": killer_id,
		"penalties": penalties
	})
	
	# Планируем респавн
	var respawn_time = penalties.get("respawn_time", 10.0)
	schedule_respawn(eid, respawn_time)

func schedule_respawn(eid: String, respawn_time: float):
	var timer = Timer.new()
	timer.wait_time = respawn_time
	timer.one_shot = true
	timer.timeout.connect(func(): respawn_player(eid))
	add_child(timer)
	timer.start()

func respawn_player(eid: String):
	if not entities.has(eid):
		return
	
	var player = entities[eid]
	var island = load_island_for_eid(eid)
	var spawn_pos = [0.0, 0.0, 0.0]
	
	if island:
		spawn_pos = island.get("spawn_pos", [0.0, 0.0, 0.0])
	
	player["hp"] = player.get("max_hp", 100)
	player["dead"] = false
	player["pos"] = spawn_pos
	
	entities[eid] = player
	
	# Отправляем сообщение о респавне
	var peer_id = -1
	for pid in peer_to_eid.keys():
		if peer_to_eid[pid] == eid:
			peer_id = pid
			break
	
	if peer_id != -1 and peers.has(peer_id):
		peers[peer_id].put_packet(JSON.print({
			"t": "respawn",
			"id": eid,
			"pos": spawn_pos
		}).to_utf8())
	
	broadcast({
		"t": "player_respawned",
		"id": eid,
		"pos": spawn_pos
	})

# HTTPRequest callback (basic logger)
func _on_request_completed(result, response_code, headers, body):
	# body is PoolByteArray
	# convert to string for logging
	var s = ""
	if body and body.size() > 0:
		s = String(body.get_string_from_utf8())
	print("HTTPRequest completed:", result, response_code, s)

func api_load_island(owner: String) -> Dictionary:
	var url = ISLAND_SERVICE_URL + "/island/" + owner
	var err = http_request.request(url, [], true, HTTPClient.METHOD_GET)
	if err != OK:
		print("api_load_island: request failed", err)
		return {}
	# wait for response
	yield(http_request, "request_completed")
	var body = http_request.get_response_body()
	if body.size() == 0:
		return {}
	var txt = body.get_string_from_utf8()
	var parsed = JSON.parse(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}

func api_save_island(owner: String, island: Dictionary) -> bool:
	var url = ISLAND_SERVICE_URL + "/island/" + owner
	var payload = {"island": island}
	var txt = JSON.print(payload)
	var headers = ["Content-Type: application/json"]
	var err = http_request.request(url, headers, true, HTTPClient.METHOD_PUT, txt.to_utf8())
	if err != OK:
		print("api_save_island: request failed", err)
		return false
	yield(http_request, "request_completed")
	return true

func api_create_island(owner: String, island: Dictionary) -> bool:
	var url = ISLAND_SERVICE_URL + "/island"
	var payload = {"owner": owner, "owner_name": island.get("owner_name", owner), "island": island}
	var txt = JSON.print(payload)
	var headers = ["Content-Type: application/json"]
	var err = http_request.request(url, headers, true, HTTPClient.METHOD_POST, txt.to_utf8())
	if err != OK:
		print("api_create_island: request failed", err)
		return false
	yield(http_request, "request_completed")
	return true

# -- Monster Server Integration --

func _on_monster_spawned(monster_id: String, monster: MonsterServer.MonsterEntity):
	# Уведомляем всех клиентов о появлении монстра
	broadcast({
		"t": "monster_spawn",
		"id": monster.id,
		"type": monster.monster_type,
		"pos": [monster.position.x, monster.position.y, monster.position.z],
		"depth": monster.depth,
		"environment": monster.environment,
		"health": monster.health,
		"max_health": monster.max_health
	})

func _on_monster_moved(monster_id: String, position: Vector3, depth: float):
	# Уведомляем всех клиентов о движении монстра
	broadcast({
		"t": "monster_move",
		"id": monster_id,
		"pos": [position.x, position.y, position.z],
		"depth": depth
	})

func _on_monster_died(monster_id: String):
	# Уведомляем всех клиентов о смерти монстра
	broadcast({
		"t": "monster_dead",
		"id": monster_id
	})

func handle_monster_attack(attacker_eid: String, monster_id: String, damage: float, damage_type: String):
	if not monster_server:
		return
	
	var monster = monster_server.get_monster(monster_id)
	if not monster:
		return
	
	var attacker = entities.get(attacker_eid, {})
	var final_damage = calculate_damage(damage, damage_type, attacker, {
		"hp": monster.health,
		"max_hp": monster.max_health,
		"defense": 0
	})
	
	var killed = monster_server.damage_monster(monster_id, final_damage)
	
	if killed:
		# Монстр убит - отправляем лут
		broadcast({
			"t": "monster_dead",
			"id": monster_id,
			"killer_id": attacker_eid
		})
	else:
		# Монстр повреждён
		var monster_after = monster_server.get_monster(monster_id)
		if monster_after:
			broadcast({
				"t": "monster_hp_update",
				"id": monster_id,
				"hp": monster_after.health,
				"max_hp": monster_after.max_health,
				"damage": final_damage
			})
