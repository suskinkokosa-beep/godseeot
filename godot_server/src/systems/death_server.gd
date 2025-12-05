extends Node

## Серверная обработка смерти игроков и штрафов

func handle_player_death(peer_id: int, eid: String, death_type: String = "pve", killer_id: String = ""):
    if not entities.has(eid):
        return
    
    var player = entities[eid]
    
    # Устанавливаем HP в 0
    player["hp"] = 0
    player["dead"] = true
    player["death_time"] = OS.get_unix_time()
    player["death_type"] = death_type
    player["killer_id"] = killer_id if killer_id != "" else null
    
    # Вычисляем штрафы
    var penalties = calculate_death_penalties(death_type, player)
    
    # Применяем штрафы
    apply_penalties(eid, penalties)
    
    # Отправляем сообщение о смерти
    broadcast({
        "t": "player_dead",
        "id": eid,
        "death_type": death_type,
        "killer_id": killer_id,
        "penalties": penalties
    })
    
    # Планируем респавн
    schedule_respawn(eid, penalties.get("respawn_time", 10.0))

func calculate_death_penalties(death_type: String, player: Dictionary) -> Dictionary:
    var penalties = {}
    
    match death_type:
        "pve":
            penalties["exp_loss_percent"] = 0.05
            penalties["item_loss_chance"] = 0.1
            penalties["respawn_time"] = 10.0
            penalties["debuff_duration"] = 300.0
        
        "pvp":
            penalties["exp_loss_percent"] = 0.10
            penalties["currency_loss_percent"] = 0.05
            penalties["item_loss_chance"] = 0.3
            penalties["respawn_time"] = 30.0
            penalties["debuff_duration"] = 600.0
        
        "drowning":
            penalties["exp_loss_percent"] = 0.03
            penalties["respawn_time"] = 5.0
            penalties["debuff_duration"] = 180.0
        
        _:
            penalties["exp_loss_percent"] = 0.02
            penalties["respawn_time"] = 5.0
    
    return penalties

func apply_penalties(eid: String, penalties: Dictionary):
    var player = entities[eid]
    if not player:
        return
    
    # Потеря опыта
    if penalties.has("exp_loss_percent"):
        var current_exp = player.get("experience", 0.0)
        var loss = current_exp * penalties["exp_loss_percent"]
        player["experience"] = max(0.0, current_exp - loss)
    
    # Потеря валюты
    if penalties.has("currency_loss_percent"):
        var currency = player.get("currency", {})
        for currency_type in currency.keys():
            var amount = currency[currency_type]
            var loss = amount * penalties["currency_loss_percent"]
            currency[currency_type] = max(0, amount - int(loss))
        player["currency"] = currency
    
    # Сохраняем штрафы в данных игрока
    player["active_penalties"] = penalties
    entities[eid] = player

func schedule_respawn(eid: String, respawn_time: float):
    # Создаём таймер для респавна
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
    
    # Определяем место респавна
    var spawn_pos = get_respawn_location(eid)
    
    # Восстанавливаем HP
    player["hp"] = player.get("max_hp", 100)
    player["dead"] = false
    player["pos"] = spawn_pos
    
    entities[eid] = player
    
    # Отправляем сообщение о респавне
    if peer_to_eid.has(eid):
        var peer_id = _get_peer_by_eid(eid)
        if peer_id != -1:
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

func get_respawn_location(eid: String) -> Array:
    # Респавн на острове игрока
    var island = load_island_for_eid(eid)
    if island:
        return island.get("spawn_pos", [0.0, 0.0, 0.0])
    
    return [0.0, 0.0, 0.0]

func _get_peer_by_eid(eid: String) -> int:
    for peer_id in peer_to_eid.keys():
        if peer_to_eid[peer_id] == eid:
            return peer_id
    return -1

