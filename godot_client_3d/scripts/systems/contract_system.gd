extends Node
class_name ContractSystem

## Система контрактов для Isleborn Online
## Динамические задания от NPC, игроков и гильдий

enum ContractType {
	DELIVERY,       # Доставка
	ESCORT,         # Сопровождение
	HUNT,           # Охота
	COLLECT,        # Сбор
	CRAFT,          # Крафт
	PROTECT,        # Защита
	EXPLORE         # Исследование
}

enum ContractStatus {
	AVAILABLE,      # Доступен
	ACCEPTED,       # Принят
	IN_PROGRESS,    # В процессе
	COMPLETED,      # Завершён
	FAILED,         # Провален
	EXPIRED         # Истёк
}

enum ContractSource {
	NPC,            # От NPC
	PLAYER,         # От игрока
	GUILD,          # От гильдии
	BOARD           # Доска объявлений
}

class Contract:
	var contract_id: String
	var contract_type: ContractType
	var source: ContractSource
	var issuer_id: String  # ID того, кто выдал контракт
	var issuer_name: String
	var title: String
	var description: String
	var status: ContractStatus = ContractStatus.AVAILABLE
	var reward: Dictionary = {}
	var requirements: Dictionary = {}
	var deadline: int = 0  # Unix timestamp
	var accepted_by: String = ""
	var accepted_at: int = 0
	var progress: Dictionary = {}
	var difficulty: int = 1  # 1-5
	
	func _init(_id: String, _type: ContractType, _source: ContractSource):
		contract_id = _id
		contract_type = _type
		source = _source
		deadline = Time.get_unix_time_from_system() + 86400  # 24 часа по умолчанию

var available_contracts: Dictionary = {}  # contract_id -> Contract
var active_contracts: Dictionary = {}     # contract_id -> Contract
var completed_contracts: Array[String] = []

signal contract_created(contract: Contract)
signal contract_accepted(contract_id: String)
signal contract_completed(contract_id: String, rewards: Dictionary)
signal contract_failed(contract_id: String)
signal contract_expired(contract_id: String)

func _ready() -> void:
	_generate_contracts()

func _process(delta: float) -> void:
	_check_contract_expiration()

func _generate_contracts() -> void:
	# Генерируем начальные контракты
	_create_npc_contract("deliver_fish", ContractType.DELIVERY, "Доставить рыбу", "Доставить 50 рыб в порт", {"item": "fish", "quantity": 50}, {"shells": 200})
	_create_npc_contract("hunt_shark", ContractType.HUNT, "Охота на акулу", "Убить 3 больших акул", {"monster": "giant_shark", "quantity": 3}, {"shells": 500, "gold": 10})

func _create_npc_contract(contract_id: String, contract_type: ContractType, title: String, description: String, requirements: Dictionary, reward: Dictionary) -> void:
	var contract = Contract.new(contract_id, contract_type, ContractSource.NPC)
	contract.issuer_id = "npc_trader_1"
	contract.issuer_name = "Торговец"
	contract.title = title
	contract.description = description
	contract.requirements = requirements
	contract.reward = reward
	
	available_contracts[contract_id] = contract
	contract_created.emit(contract)

func create_player_contract(player_id: String, player_name: String, contract_type: ContractType, title: String, description: String, requirements: Dictionary, reward: Dictionary, deadline_hours: int = 24) -> String:
	var contract_id = "contract_%s_%d" % [player_id, Time.get_ticks_msec()]
	var contract = Contract.new(contract_id, contract_type, ContractSource.PLAYER)
	contract.issuer_id = player_id
	contract.issuer_name = player_name
	contract.title = title
	contract.description = description
	contract.requirements = requirements
	contract.reward = reward
	contract.deadline = Time.get_unix_time_from_system() + (deadline_hours * 3600)
	
	available_contracts[contract_id] = contract
	contract_created.emit(contract)
	
	return contract_id

func accept_contract(contract_id: String, player_id: String) -> bool:
	if not available_contracts.has(contract_id):
		return false
	
	var contract = available_contracts[contract_id]
	
	if contract.status != ContractStatus.AVAILABLE:
		return false
	
	# Проверяем, не истёк ли контракт
	if Time.get_unix_time_from_system() >= contract.deadline:
		contract.status = ContractStatus.EXPIRED
		available_contracts.erase(contract_id)
		return false
	
	contract.status = ContractStatus.ACCEPTED
	contract.accepted_by = player_id
	contract.accepted_at = Time.get_unix_time_from_system()
	
	# Инициализируем прогресс
	contract.progress = _initialize_progress(contract)
	
	active_contracts[contract_id] = contract
	available_contracts.erase(contract_id)
	
	contract_accepted.emit(contract_id)
	return true

func _initialize_progress(contract: Contract) -> Dictionary:
	match contract.contract_type:
		ContractType.DELIVERY:
			return {"delivered": 0, "required": contract.requirements.get("quantity", 0)}
		ContractType.HUNT:
			return {"killed": 0, "required": contract.requirements.get("quantity", 0)}
		ContractType.COLLECT:
			return {"collected": 0, "required": contract.requirements.get("quantity", 0)}
		_:
			return {}

func update_contract_progress(contract_id: String, progress_data: Dictionary) -> void:
	if not active_contracts.has(contract_id):
		return
	
	var contract = active_contracts[contract_id]
	
	match contract.contract_type:
		ContractType.DELIVERY:
			contract.progress["delivered"] = progress_data.get("delivered", contract.progress.get("delivered", 0))
		ContractType.HUNT:
			contract.progress["killed"] = progress_data.get("killed", contract.progress.get("killed", 0))
		ContractType.COLLECT:
			contract.progress["collected"] = progress_data.get("collected", contract.progress.get("collected", 0))
	
	# Проверяем выполнение
	if _check_contract_completion(contract):
		complete_contract(contract_id)

func _check_contract_completion(contract: Contract) -> bool:
	match contract.contract_type:
		ContractType.DELIVERY:
			return contract.progress.get("delivered", 0) >= contract.progress.get("required", 0)
		ContractType.HUNT:
			return contract.progress.get("killed", 0) >= contract.progress.get("required", 0)
		ContractType.COLLECT:
			return contract.progress.get("collected", 0) >= contract.progress.get("required", 0)
		_:
			return false

func complete_contract(contract_id: String) -> void:
	if not active_contracts.has(contract_id):
		return
	
	var contract = active_contracts[contract_id]
	contract.status = ContractStatus.COMPLETED
	
	# Выдаём награды
	_give_contract_rewards(contract)
	
	completed_contracts.append(contract_id)
	active_contracts.erase(contract_id)
	
	contract_completed.emit(contract_id, contract.reward)

func _give_contract_rewards(contract: Contract) -> void:
	var world = get_tree().current_scene
	if world:
		# Валюта
		if contract.reward.has("shells"):
			var currency_system = world.find_child("CurrencySystem", true, false)
			if currency_system:
				currency_system.add_currency(CurrencySystem.CurrencyType.SHELLS, contract.reward["shells"])
		
		# Опыт
		if contract.reward.has("experience"):
			# TODO: Выдать опыт
			pass
		
		# Предметы
		if contract.reward.has("items"):
			var inventory = world.find_child("Inventory", true, false)
			if inventory:
				for item in contract.reward["items"]:
					inventory.add_item(item["item_id"], item.get("quantity", 1))

func fail_contract(contract_id: String) -> void:
	if not active_contracts.has(contract_id):
		return
	
	var contract = active_contracts[contract_id]
	contract.status = ContractStatus.FAILED
	
	active_contracts.erase(contract_id)
	contract_failed.emit(contract_id)

func _check_contract_expiration() -> void:
	var current_time = Time.get_unix_time_from_system()
	var expired: Array[String] = []
	
	for contract_id in active_contracts.keys():
		var contract = active_contracts[contract_id]
		if current_time >= contract.deadline:
			expired.append(contract_id)
	
	for contract_id in expired:
		var contract = active_contracts[contract_id]
		contract.status = ContractStatus.EXPIRED
		active_contracts.erase(contract_id)
		contract_expired.emit(contract_id)

func get_available_contracts() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for contract_id in available_contracts.keys():
		var contract = available_contracts[contract_id]
		result.append(_contract_to_dict(contract))
	
	return result

func get_active_contracts() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for contract_id in active_contracts.keys():
		var contract = active_contracts[contract_id]
		result.append(_contract_to_dict(contract))
	
	return result

func _contract_to_dict(contract: Contract) -> Dictionary:
	var time_remaining = max(0, contract.deadline - Time.get_unix_time_from_system())
	
	return {
		"id": contract.contract_id,
		"type": contract.contract_type,
		"source": contract.source,
		"title": contract.title,
		"description": contract.description,
		"status": contract.status,
		"reward": contract.reward.duplicate(),
		"requirements": contract.requirements.duplicate(),
		"time_remaining": time_remaining,
		"progress": contract.progress.duplicate(),
		"difficulty": contract.difficulty,
		"issuer": contract.issuer_name
	}

