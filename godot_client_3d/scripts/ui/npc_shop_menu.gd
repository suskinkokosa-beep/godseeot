extends Control

## Меню торговли с NPC

@onready var npc_name_label: Label = $VBox/NPCName
@onready var shells_label: Label = $VBox/CurrencyDisplay/ShellsLabel
@onready var buy_list: VBoxContainer = $VBox/TabContainer/Buy/BuyItems/BuyList
@onready var sell_list: VBoxContainer = $VBox/TabContainer/Sell/SellItems/SellList
@onready var close_button: Button = $VBox/CloseButton

var npc_id: String = ""
var trading_system: TradingSystem = null
var currency_system: CurrencySystem = null
var inventory: Node = null

func _ready() -> void:
	UIThemeManager.apply_theme_to_control(self)
	_setup_background()
	
	close_button.pressed.connect(_on_close_pressed)
	
	# Получаем ссылки на системы
	var world = get_tree().current_scene
	if world:
		trading_system = world.find_child("TradingSystem", true, false)
		currency_system = world.find_child("CurrencySystem", true, false)
		inventory = world.find_child("Inventory", true, false)
	
	if currency_system:
		currency_system.currency_changed.connect(_on_currency_changed)
	
	_update_display()

func setup(npc_id_param: String) -> void:
	npc_id = npc_id_param
	_update_display()

func _setup_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.1, 0.15, 1.0)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

func _update_display() -> void:
	if not trading_system or npc_id.is_empty():
		return
	
	var shop = trading_system.get_npc_shop(npc_id)
	if shop.is_empty():
		return
	
	npc_name_label.text = shop.get("name", "Торговец")
	
	_update_currency_display()
	_update_buy_list(shop)
	_update_sell_list()

func _update_currency_display() -> void:
	if currency_system:
		var shells = currency_system.get_currency(CurrencySystem.CurrencyType.SHELLS)
		shells_label.text = "Ракушки: %d" % shells

func _update_buy_list(shop: Dictionary) -> void:
	# Очищаем список
	for child in buy_list.get_children():
		child.queue_free()
	
	var sell_items = shop.get("sell_items", {})
	for item_id in sell_items.keys():
		var item_data = sell_items[item_id]
		var widget = _create_buy_widget(item_id, item_data)
		buy_list.add_child(widget)

func _create_buy_widget(item_id: String, item_data: Dictionary) -> Control:
	var container := HBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 50)
	
	var item_db = ItemDatabase.get_item(item_id)
	var item_name = item_db.get("name", item_id)
	var price = item_data.get("price", 0)
	var quantity = item_data.get("quantity", 0)
	
	var name_label := Label.new()
	name_label.text = item_name
	name_label.custom_minimum_size = Vector2(200, 0)
	
	var price_label := Label.new()
	price_label.text = "%d ракушек" % price
	price_label.custom_minimum_size = Vector2(150, 0)
	
	var qty_label := Label.new()
	if quantity == -1:
		qty_label.text = "∞"
	else:
		qty_label.text = "Осталось: %d" % quantity
	qty_label.custom_minimum_size = Vector2(150, 0)
	
	var buy_button := Button.new()
	buy_button.text = "Купить"
	buy_button.pressed.connect(func(): _on_buy_pressed(item_id, 1))
	
	container.add_child(name_label)
	container.add_child(price_label)
	container.add_child(qty_label)
	container.add_child(buy_button)
	
	return container

func _update_sell_list() -> void:
	# Очищаем список
	for child in sell_list.get_children():
		child.queue_free()
	
	if not inventory or not trading_system:
		return
	
	var slots = inventory.slots if inventory.has("slots") else {}
	for item_id in slots.keys():
		var quantity = slots[item_id]
		if quantity <= 0:
			continue
		
		var sell_price = trading_system.get_sell_price(npc_id, item_id)
		if sell_price <= 0:
			continue
		
		var widget = _create_sell_widget(item_id, quantity, sell_price)
		sell_list.add_child(widget)

func _create_sell_widget(item_id: String, quantity: int, price_per_unit: int) -> Control:
	var container := HBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 50)
	
	var item_db = ItemDatabase.get_item(item_id)
	var item_name = item_db.get("name", item_id)
	
	var name_label := Label.new()
	name_label.text = item_name
	name_label.custom_minimum_size = Vector2(200, 0)
	
	var qty_label := Label.new()
	qty_label.text = "x%d" % quantity
	qty_label.custom_minimum_size = Vector2(100, 0)
	
	var price_label := Label.new()
	price_label.text = "%d ракушек" % price_per_unit
	price_label.custom_minimum_size = Vector2(150, 0)
	
	var sell_button := Button.new()
	sell_button.text = "Продать"
	sell_button.pressed.connect(func(): _on_sell_pressed(item_id, 1))
	
	container.add_child(name_label)
	container.add_child(qty_label)
	container.add_child(price_label)
	container.add_child(sell_button)
	
	return container

func _on_buy_pressed(item_id: String, quantity: int) -> void:
	if trading_system and inventory and currency_system:
		if trading_system.buy_from_npc(npc_id, item_id, quantity, inventory, currency_system):
			_update_display()

func _on_sell_pressed(item_id: String, quantity: int) -> void:
	if trading_system and inventory and currency_system:
		trading_system.sell_to_npc(npc_id, item_id, quantity, inventory, currency_system)
		_update_display()

func _on_currency_changed(_currency_type: CurrencySystem.CurrencyType, _amount: int) -> void:
	_update_currency_display()

func _on_close_pressed() -> void:
	queue_free()

