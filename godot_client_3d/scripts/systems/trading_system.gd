extends Node
class_name TradingSystem

## Система торговли Isleborn Online
## Поддерживает торговлю с NPC и между игроками

enum TradeType {
	NPC_BUY,       # Покупка у NPC
	NPC_SELL,      # Продажа NPC
	PLAYER_TRADE   # Торговля с игроком
}

## Предложение торговли
class TradeOffer:
	var item_id: String
	var quantity: int
	var price_per_unit: int
	var currency_type: CurrencySystem.CurrencyType
	var seller_id: String
	var seller_name: String
	
	func get_total_price() -> int:
		return price_per_unit * quantity

var active_trades: Dictionary = {}  # trade_id -> TradeOffer
var npc_shops: Dictionary = {}      # npc_id -> shop_data

signal trade_started(trade_id: String, offer: TradeOffer)
signal trade_completed(trade_id: String)
signal trade_cancelled(trade_id: String)

func _ready() -> void:
	_initialize_npc_shops()

## Инициализация магазинов NPC
func _initialize_npc_shops() -> void:
	# Магазин торговца
	npc_shops["trader_npc"] = {
		"name": "Торговец",
		"buy_items": {
			"palm_wood": {"price": 2, "quantity": -1},  # -1 = неограничено
			"stone": {"price": 1, "quantity": -1},
			"fabric": {"price": 10, "quantity": 50},
			"metal_ingot": {"price": 50, "quantity": 20}
		},
		"sell_items": {
			"stone_knife": {"price": 15, "quantity": 5},
			"wooden_sword": {"price": 35, "quantity": 3},
			"healing_herb": {"price": 8, "quantity": 10}
		},
		"currency_type": CurrencySystem.CurrencyType.SHELLS
	}
	
	# Магазин оружейника
	npc_shops["weaponsmith_npc"] = {
		"name": "Оружейник",
		"buy_items": {},
		"sell_items": {
			"iron_sword": {"price": 200, "quantity": 2},
			"wooden_bow": {"price": 50, "quantity": 3},
			"crossbow": {"price": 250, "quantity": 1}
		},
		"currency_type": CurrencySystem.CurrencyType.SHELLS
	}

## Купить предмет у NPC
func buy_from_npc(npc_id: String, item_id: String, quantity: int, inventory: Node, currency_system: CurrencySystem) -> bool:
	if not npc_shops.has(npc_id):
		return false
	
	var shop = npc_shops[npc_id]
	var sell_items = shop.get("sell_items", {})
	
	if not sell_items.has(item_id):
		return false
	
	var item_data = sell_items[item_id]
	var available = item_data.get("quantity", 0)
	
	# Проверяем наличие товара
	if available != -1 and available < quantity:
		return false
	
	var price_per_unit = item_data.get("price", 0)
	var total_price = price_per_unit * quantity
	var currency_type = shop.get("currency_type", CurrencySystem.CurrencyType.SHELLS)
	
	# Проверяем валюту
	if not currency_system.has_currency(currency_type, total_price):
		return false
	
	# Покупаем
	if not currency_system.spend_currency(currency_type, total_price):
		return false
	
	# Добавляем в инвентарь
	if inventory and inventory.has_method("add_item"):
		inventory.add_item(item_id, quantity)
	
	# Обновляем количество в магазине
	if available != -1:
		item_data["quantity"] = available - quantity
		sell_items[item_id] = item_data
		shop["sell_items"] = sell_items
		npc_shops[npc_id] = shop
	
	return true

## Продать предмет NPC
func sell_to_npc(npc_id: String, item_id: String, quantity: int, inventory: Node, currency_system: CurrencySystem) -> int:
	if not npc_shops.has(npc_id):
		return 0
	
	var shop = npc_shops[npc_id]
	var buy_items = shop.get("buy_items", {})
	
	if not buy_items.has(item_id):
		return 0
	
	var item_data = buy_items[item_id]
	var price_per_unit = item_data.get("price", 0)
	var total_price = price_per_unit * quantity
	var currency_type = shop.get("currency_type", CurrencySystem.CurrencyType.SHELLS)
	
	# Проверяем наличие предметов в инвентаре
	if inventory and inventory.has_method("remove_item"):
		if not inventory.remove_item(item_id, quantity):
			return 0
	
	# Добавляем валюту
	if currency_system:
		currency_system.add_currency(currency_type, total_price)
	
	return total_price

## Получить цену продажи предмета NPC
func get_sell_price(npc_id: String, item_id: String) -> int:
	if not npc_shops.has(npc_id):
		return 0
	
	var shop = npc_shops[npc_id]
	var buy_items = shop.get("buy_items", {})
	
	if not buy_items.has(item_id):
		return 0
	
	return buy_items[item_id].get("price", 0)

## Получить цену покупки предмета у NPC
func get_buy_price(npc_id: String, item_id: String) -> int:
	if not npc_shops.has(npc_id):
		return 0
	
	var shop = npc_shops[npc_id]
	var sell_items = shop.get("sell_items", {})
	
	if not sell_items.has(item_id):
		return 0
	
	return sell_items[item_id].get("price", 0)

## Получить магазин NPC
func get_npc_shop(npc_id: String) -> Dictionary:
	return npc_shops.get(npc_id, {})

