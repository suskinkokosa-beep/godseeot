extends Node
class_name MarketSystem

## Система рынка для Isleborn Online
## Согласно GDD: глобальный аукцион, локальные торговые посты, динамические цены

enum MarketType {
	GLOBAL,         # Глобальный аукцион
	LOCAL,          # Локальный торговый пост
	NPC,            # NPC-торговец
	GUILD,          # Гильдейский рынок
	BLACK_MARKET    # Чёрный рынок
}

enum ListingType {
	BUY,            # Покупка
	SELL,           # Продажа
	AUCTION         # Аукцион
}

class MarketListing:
	var listing_id: String
	var owner_id: String
	var item_id: String
	var quantity: int
	var price_per_unit: float
	var listing_type: ListingType
	var market_type: MarketType
	var created_at: int
	var expires_at: int
	var status: String = "active"  # active, completed, cancelled
	
	func _init(_id: String, _owner: String, _item: String, _qty: int, _price: float, _type: ListingType, _market: MarketType):
		listing_id = _id
		owner_id = _owner
		item_id = _item
		quantity = _qty
		price_per_unit = _price
		listing_type = _type
		market_type = _market
		created_at = Time.get_unix_time_from_system()
		expires_at = created_at + 86400  # 24 часа по умолчанию

class MarketPrice:
	var item_id: String
	var base_price: float
	var current_price: float
	var supply: int = 0  # Предложение
	var demand: int = 0  # Спрос
	var price_history: Array[Dictionary] = []
	
	func _init(_item_id: String, _base_price: float):
		item_id = _item_id
		base_price = _base_price
		current_price = _base_price

var market_listings: Dictionary = {}  # listing_id -> MarketListing
var market_prices: Dictionary = {}  # item_id -> MarketPrice
var trade_posts: Dictionary = {}  # post_id -> {position, market_type, listings}

signal listing_created(listing_id: String, item_id: String, quantity: int, price: float)
signal listing_purchased(listing_id: String, buyer_id: String)
signal price_updated(item_id: String, old_price: float, new_price: float)

func _ready() -> void:
	_initialize_base_prices()

func _process(delta: float) -> void:
	_update_market_prices()
	_expire_listings()

func _initialize_base_prices() -> void:
	# Устанавливаем базовые цены для всех предметов
	var base_prices = {
		"palm_wood": 5.0,
		"stone": 3.0,
		"fish": 2.0,
		"water": 1.0,
		"metal": 15.0,
		"crystal": 50.0,
		"essence": 30.0
	}
	
	for item_id in base_prices.keys():
		market_prices[item_id] = MarketPrice.new(item_id, base_prices[item_id])

func create_listing(owner_id: String, item_id: String, quantity: int, price_per_unit: float, listing_type: ListingType, market_type: MarketType) -> String:
	var listing_id = "listing_%d" % Time.get_ticks_msec()
	var listing = MarketListing.new(listing_id, owner_id, item_id, quantity, price_per_unit, listing_type, market_type)
	
	market_listings[listing_id] = listing
	listing_created.emit(listing_id, item_id, quantity, price_per_unit)
	
	return listing_id

func purchase_listing(listing_id: String, buyer_id: String, quantity: int = -1) -> Dictionary:
	if not market_listings.has(listing_id):
		return {"success": false, "error": "Listing not found"}
	
	var listing = market_listings[listing_id]
	
	if listing.status != "active":
		return {"success": false, "error": "Listing not active"}
	
	if listing.owner_id == buyer_id:
		return {"success": false, "error": "Cannot purchase your own listing"}
	
	# Если quantity = -1, покупаем всё
	var purchase_quantity = quantity if quantity > 0 else listing.quantity
	if purchase_quantity > listing.quantity:
		purchase_quantity = listing.quantity
	
	var total_price = purchase_quantity * listing.price_per_unit
	
	# TODO: Проверка баланса покупателя
	# TODO: Проверка наличия предметов у продавца
	# TODO: Передача предметов и валюты
	
	# Обновляем листинг
	listing.quantity -= purchase_quantity
	if listing.quantity <= 0:
		listing.status = "completed"
		listing.quantity = 0
	
	# Обновляем цены на рынке
	_update_item_demand(listing.item_id, purchase_quantity)
	_update_item_supply(listing.item_id, -purchase_quantity)
	
	listing_purchased.emit(listing_id, buyer_id)
	
	return {
		"success": true,
		"quantity": purchase_quantity,
		"total_price": total_price
	}

func cancel_listing(listing_id: String, owner_id: String) -> bool:
	if not market_listings.has(listing_id):
		return false
	
	var listing = market_listings[listing_id]
	if listing.owner_id != owner_id:
		return false
	
	if listing.status != "active":
		return false
	
	listing.status = "cancelled"
	
	# Возвращаем предметы продавцу (TODO)
	# Возвращаем предложение
	_update_item_supply(listing.item_id, -listing.quantity)
	
	return true

func search_listings(item_id: String = "", market_type: MarketType = MarketType.GLOBAL, max_price: float = -1.0, min_price: float = -1.0) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	
	for listing_id in market_listings.keys():
		var listing = market_listings[listing_id]
		
		if listing.status != "active":
			continue
		
		if item_id != "" and listing.item_id != item_id:
			continue
		
		if market_type != MarketType.GLOBAL and listing.market_type != market_type:
			continue
		
		if max_price > 0.0 and listing.price_per_unit > max_price:
			continue
		
		if min_price > 0.0 and listing.price_per_unit < min_price:
			continue
		
		results.append({
			"listing_id": listing.listing_id,
			"owner_id": listing.owner_id,
			"item_id": listing.item_id,
			"quantity": listing.quantity,
			"price": listing.price_per_unit,
			"type": listing.listing_type,
			"market": listing.market_type
		})
	
	# Сортируем по цене
	results.sort_custom(func(a, b): return a["price"] < b["price"])
	
	return results

func get_market_price(item_id: String) -> float:
	if not market_prices.has(item_id):
		return 0.0
	
	return market_prices[item_id].current_price

func create_trade_post(position: Vector3, market_type: MarketType) -> String:
	var post_id = "post_%d" % Time.get_ticks_msec()
	trade_posts[post_id] = {
		"position": position,
		"market_type": market_type,
		"listings": []
	}
	return post_id

func add_listing_to_trade_post(post_id: String, listing_id: String) -> bool:
	if not trade_posts.has(post_id) or not market_listings.has(listing_id):
		return false
	
	trade_posts[post_id]["listings"].append(listing_id)
	return true

func _update_item_demand(item_id: String, amount: int) -> void:
	if not market_prices.has(item_id):
		return
	
	var price = market_prices[item_id]
	price.demand += amount
	_update_price(item_id)

func _update_item_supply(item_id: String, amount: int) -> void:
	if not market_prices.has(item_id):
		return
	
	var price = market_prices[item_id]
	price.supply += amount
	_update_price(item_id)

func _update_price(item_id: String) -> void:
	if not market_prices.has(item_id):
		return
	
	var price = market_prices[item_id]
	var old_price = price.current_price
	
	# Формула динамической цены: NewPrice = OldPrice * (Demand / Supply)^0.32
	if price.supply > 0:
		var ratio = float(price.demand) / float(price.supply)
		var price_multiplier = pow(ratio, 0.32)
		price.current_price = price.base_price * price_multiplier
	else:
		# Если предложения нет, цена растёт
		price.current_price = price.base_price * (1.0 + float(price.demand) / 100.0)
	
	# Ограничиваем цену разумными пределами (0.1x - 10x от базовой)
	price.current_price = clamp(price.current_price, price.base_price * 0.1, price.base_price * 10.0)
	
	if abs(old_price - price.current_price) > 0.01:
		price_updated.emit(item_id, old_price, price.current_price)
		
		# Сохраняем историю цен
		price.price_history.append({
			"time": Time.get_unix_time_from_system(),
			"price": price.current_price,
			"supply": price.supply,
			"demand": price.demand
		})
		
		# Ограничиваем историю последними 100 записями
		if price.price_history.size() > 100:
			price.price_history.remove_at(0)

func _update_market_prices() -> void:
	# Цены обновляются автоматически при изменении спроса/предложения
	# Можно добавить периодическое обновление
	pass

func _expire_listings() -> void:
	var current_time = Time.get_unix_time_from_system()
	var expired: Array[String] = []
	
	for listing_id in market_listings.keys():
		var listing = market_listings[listing_id]
		if listing.status == "active" and current_time >= listing.expires_at:
			listing.status = "expired"
			expired.append(listing_id)
	
	# TODO: Возврат предметов владельцам истёкших листингов
	for listing_id in expired:
		var listing = market_listings[listing_id]
		_update_item_supply(listing.item_id, -listing.quantity)

func get_price_history(item_id: String, hours: int = 24) -> Array[Dictionary]:
	if not market_prices.has(item_id):
		return []
	
	var price = market_prices[item_id]
	var cutoff_time = Time.get_unix_time_from_system() - (hours * 3600)
	var history: Array[Dictionary] = []
	
	for entry in price.price_history:
		if entry["time"] >= cutoff_time:
			history.append(entry)
	
	return history

