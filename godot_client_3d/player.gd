extends Node3D
@export var token = ""

var ws = WebSocketClient.new()
var connected = false
var peer_id = -1
var players = {} # eid -> MeshInstance3D node
var myself_eid = ""

func _ready():
    # connect to Gateway. Ensure Gateway is running at ws://localhost:8080/ws
    if token == "":
        print("Warning: token empty. For real testing, set a token.")
    var url = "ws://localhost:8080/ws"
    ws.connect_to_url(url, [], ["Authorization: Bearer " + token])
    set_process(true)
    # setup a basic player mesh for local (capsule)
    var cap = MeshInstance3D.new()
    cap.mesh = CapsuleMesh.new()
    cap.name = "LocalPlayer"
    add_child(cap)
    cap.translation = Vector3(0,1,0)

func _process(delta):
    if ws.get_connection_status() == WebSocketClient.CONNECTION_CONNECTED and not connected:
        connected = true
        print("Connected to Gateway (client)")
        # send auth_init with sub (in production take from token)
        var auth = {"t":"auth_init","sub":"demo_sub","username":"Demo"}
        ws.get_peer(1).put_packet(JSON.print(auth).to_utf8())
    if ws.get_connection_status() == WebSocketClient.CONNECTION_CONNECTED:
        # receive packets
        while ws.get_peer(1).get_available_packet_count() > 0:
            var pkt = ws.get_peer(1).get_packet().get_string_from_utf8()
            var msg = JSON.parse(pkt)
            if typeof(msg) == TYPE_DICTIONARY and msg.has("t"):
                match msg["t"]:
                    "island_state":
                        handle_island_state(msg)
                    
                    "spawn":
                        myself_eid = msg.get("id", "")
                        print("Spawned as", myself_eid)
                    "snapshot":
                        handle_snapshot(msg)
                    "player_join":
                        add_remote_player(msg)
                    "player_leave":
                        remove_remote_player(msg)
                    "pong":
                        pass
                    _:
                        # ignore other messages
                        pass
    elif ws.get_connection_status() == WebSocketClient.CONNECTION_DISCONNECTED and connected:
        print("Disconnected")
        connected = false

func handle_snapshot(msg):
    var players_list = msg.get("players", [])
    for p in players_list:
        var id = p.get("id", "")
        var pos = p.get("pos", [0,0,0])
        if id == myself_eid:
            # move local visual to server authoritative pos
            var local = get_node_or_null("LocalPlayer")
            if local:
                local.translation = Vector3(pos[0], pos[1]+1, pos[2])
        else:
            # update or create remote visual
            if not players.has(id):
                create_remote_visual(id)
            var node = players[id]
            node.translation = Vector3(pos[0], pos[1]+1, pos[2])

func add_remote_player(msg):
    var id = msg.get("id","")
    var pos = msg.get("pos",[0,0,0])
    if id == myself_eid:
        return
    if not players.has(id):
        create_remote_visual(id)
    players[id].translation = Vector3(pos[0], pos[1]+1, pos[2])

func remove_remote_player(msg):
    var id = msg.get("id","")
    if players.has(id):
        var node = players[id]
        node.queue_free()
        players.erase(id)

func create_remote_visual(id):
    var mesh = MeshInstance3D.new()
    mesh.mesh = SphereMesh.new()
    mesh.scale = Vector3(0.5,0.5,0.5)
    mesh.name = id
    add_child(mesh)
    players[id] = mesh

# Simple input sending for movement (WASD)
func _unhandled_input(ev):
    if ev is InputEventKey and ev.pressed:
        var dx = 0.0
        var dz = 0.0
        if Input.is_key_pressed(KEY_W):
            dz -= 0.2
        if Input.is_key_pressed(KEY_S):
            dz += 0.2
        if Input.is_key_pressed(KEY_A):
            dx -= 0.2
        if Input.is_key_pressed(KEY_D):
            dx += 0.2
        if ws.get_connection_status() == WebSocketClient.CONNECTION_CONNECTED:
            var req = {"t":"move","dx":dx,"dz":dz}
            ws.get_peer(1).put_packet(JSON.print(req).to_utf8())


func handle_island_state(msg):
    var island = msg.get("island", {})
    print("Received island state:", island)
    create_resource_visuals(island)
    # simple visualization hint: print bounds radius and resources count
    var r = island.get("bounds", {}).get("radius", 3.0)
    var res = island.get("resources", [])
    print("Island radius:", r, "resources:", res.size())


func create_resource_visuals(island):
    var rr = get_node_or_null("ResourceRoot")
    var br = get_node_or_null("BuildingRoot")
    if not rr:
        rr = Node3D.new()
        rr.name = "ResourceRoot"
        add_child(rr)
    if not br:
        br = Node3D.new()
        br.name = "BuildingRoot"
        add_child(br)
    # clear existing
    for c in rr.get_children():
        c.queue_free()
    for c in br.get_children():
        c.queue_free()
    # spawn resources
    var resources = island.get("resources", [])
    for r in resources:
        var t = r.get("type","palm_tree")
        var pos = r.get("pos", [0,0,0])
        var node = null
        if t == "palm_tree":
            node = load("res://palm_tree.tscn").instantiate()
        elif t == "stone_node":
            node = load("res://rock.tscn").instantiate()
        else:
            node = MeshInstance3D.new()
        if node:
            node.translation = Vector3(pos[0], pos[1], pos[2])
            rr.add_child(node)
    # spawn buildings
    var buildings = island.get("buildings", [])
    for b in buildings:
        var t = b.get("type","campfire")
        var pos = b.get("pos", [0,0,0])
        var node = null
        if t == "campfire":
            node = load("res://campfire.tscn").instantiate()
        if node:
            node.translation = Vector3(pos[0], pos[1], pos[2])
            br.add_child(node)

func handle_island_state(msg):
    var island = msg.get("island", {})
    print("Received island state, resources:", island.get("resources", []).size(), "buildings:", island.get("buildings", []).size())
    create_resource_visuals(island)

func handle_resource_update(msg):
    var pos = msg.get("pos", [0,0,0])
    var rr = get_node_or_null("ResourceRoot")
    if not rr:
        return
    # find nearest child at pos
    for c in rr.get_children():
        if c.translation.distance_to(Vector3(pos[0], pos[1], pos[2])) < 0.5:
            var amt = msg.get("amount", 0)
            if amt <= 0:
                c.queue_free()
            return

func handle_building_added(msg):
    var pos = msg.get("pos", [0,0,0])
    var br = get_node_or_null("BuildingRoot")
    if not br:
        br = Node3D.new(); br.name = "BuildingRoot"; add_child(br)
    var t = msg.get("type","campfire")
    var node = null
    if t == "campfire":
        node = load("res://campfire.tscn").instantiate()
    if node:
        node.translation = Vector3(pos[0], pos[1], pos[2])
        br.add_child(node)
