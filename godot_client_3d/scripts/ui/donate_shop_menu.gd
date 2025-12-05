extends Control
class_name DonateShopMenu

## Донат магазин Isleborn Online
## Fair To Play - только косметика и удобства

@onready var pearls_label: Label = $MainPanel/VBox/CurrencyDisplay/PearlsLabel
@onready var buy_pearls_button: Button = $MainPanel/VBox/CurrencyDisplay/BuyPearlsButton
@onready var close_button: Button = $MainPanel/VBox/Header/CloseButton
@onready var category_tabs: TabContainer = $MainPanel/VBox/CategoryTabs

@onready var cosmetic_grid: GridContainer = $MainPanel/VBox/CategoryTabs/Косметика/CosmeticGrid
@onready var pet_grid: GridContainer = $MainPanel/VBox/CategoryTabs/Питомцы/PetGrid
@onready var emotion_grid: GridContainer = $MainPanel/VBox/CategoryTabs/Эмоции/EmotionGrid
@onready var aura_grid: GridContainer = $MainPanel/VBox/CategoryTabs/Ауры/AuraGrid
@onready var premium_grid: VBoxContainer = $MainPanel/VBox/CategoryTabs/Премиум/PremiumGrid

var monetization_system: MonetizationSystem = null
var currency_system: CurrencySystem = null

func _ready() -> void:
	UIThemeManager.apply_theme_to_control(self)
	
	close_button.pressed.connect(_on_close_pressed)
	buy_pearls_button.pressed.connect(_on_buy_pearls_pressed)
	
	# Получаем системы
	var world = get_tree().current_scene
	if world:
		monetization_system = world.find_child("MonetizationSystem", true, false)
		currency_system = world.find_child("CurrencySystem", true, false)
	
	if currency_system:
		currency_system.currency_changed.connect(_on_currency_changed)
	
	if monetization_system:
		monetization_system.item_purchased.connect(_on_item_purchased)
	
	_update_display()
	_populate_items()

func _update_display() -> void:
	if currency_system:
		var pearls = currency_system.get_currency(CurrencySystem.CurrencyType.PEARLS)
		pearls_label.text = "💎 Жемчужины: %d" % pearls

func _populate_items() -> void:
	if not monetization_system:
		return
	
	# Очищаем все сетки
	_clear_grid(cosmetic_grid)
	_clear_grid(pet_grid)
	_clear_grid(emotion_grid)
	_clear_grid(aura_grid)
	_clear_grid(premium_grid)
	
	# Заполняем косметику
	var cosmetics = monetization_system.get_shop_items_by_type(MonetizationSystem.ShopItemType.COSMETIC_CHARACTER)
	cosmetics.append_array(monetization_system.get_shop_items_by_type(MonetizationSystem.ShopItemType.COSMETIC_SHIP))
	cosmetics.append_array(monetization_system.get_shop_items_by_type(MonetizationSystem.ShopItemType.COSMETIC_ISLAND))
	for item in cosmetics:
		_create_item_card(item, cosmetic_grid)
	
	# Заполняем питомцев
	var pets = monetization_system.get_shop_items_by_type(MonetizationSystem.ShopItemType.PET)
	for item in pets:
		_create_item_card(item, pet_grid)
	
	# Заполняем эмоции
	var emotions = monetization_system.get_shop_items_by_type(MonetizationSystem.ShopItemType.EMOTION)
	for item in emotions:
		_create_item_card(item, emotion_grid)
	
	# Заполняем ауры
	var auras = monetization_system.get_shop_items_by_type(MonetizationSystem.ShopItemType.AURA)
	for item in auras:
		_create_item_card(item, aura_grid)
	
	# Заполняем премиум
	var premium_items = monetization_system.get_shop_items_by_type(MonetizationSystem.ShopItemType.PREMIUM_ACCOUNT)
	premium_items.append_array(monetization_system.get_shop_items_by_type(MonetizationSystem.ShopItemType.SEASON_PASS))
	for item in premium_items:
		_create_premium_card(item, premium_grid)

func _clear_grid(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()

func _create_item_card(item: MonetizationSystem.ShopItem, parent: Container) -> void:
	var card = Panel.new()
	card.custom_minimum_size = Vector2(200, 250)
	
	var vbox = VBoxContainer.new()
	card.add_child(vbox)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 10
	vbox.offset_top = 10
	vbox.offset_right = -10
	vbox.offset_bottom = -10
	
	# Иконка (placeholder)
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(180, 120)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(icon)
	
	# Название
	var name_label = Label.new()
	name_label.text = item.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	# Описание
	var desc_label = Label.new()
	desc_label.text = item.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(desc_label)
	
	# Цена
	var price_label = Label.new()
	var rarity_color = _get_rarity_color(item.rarity)
	price_label.text = "💎 %d" % item.price_pearls
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(price_label)
	
	# Кнопка покупки
	var buy_button = Button.new()
	buy_button.text = "Купить"
	if monetization_system.is_item_owned(item.id):
		buy_button.text = "✓ Куплено"
		buy_button.disabled = true
	buy_button.pressed.connect(func(): _on_buy_item_pressed(item.id))
	vbox.add_child(buy_button)
	
	parent.add_child(card)

func _create_premium_card(item: MonetizationSystem.ShopItem, parent: Container) -> void:
	var card = Panel.new()
	card.custom_minimum_size = Vector2(600, 200)
	
	var hbox = HBoxContainer.new()
	card.add_child(hbox)
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 20
	hbox.offset_top = 20
	hbox.offset_right = -20
	hbox.offset_bottom = -20
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	
	# Название
	var name_label = Label.new()
	name_label.text = item.name
	name_label.theme_override_font_sizes["font_size"] = 24
	vbox.add_child(name_label)
	
	# Описание
	var desc_label = Label.new()
	desc_label.text = item.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	# Цена и кнопка справа
	var right_vbox = VBoxContainer.new()
	hbox.add_child(right_vbox)
	
	var price_label = Label.new()
	price_label.text = "💎 %d" % item.price_pearls
	price_label.theme_override_font_sizes["font_size"] = 28
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_vbox.add_child(price_label)
	
	var buy_button = Button.new()
	buy_button.custom_minimum_size = Vector2(150, 50)
	buy_button.text = "Купить"
	if item.type == MonetizationSystem.ShopItemType.PREMIUM_ACCOUNT and monetization_system.is_premium_active():
		buy_button.text = "Активен"
		buy_button.disabled = true
	buy_button.pressed.connect(func(): _on_buy_item_pressed(item.id))
	right_vbox.add_child(buy_button)
	
	parent.add_child(card)

func _get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common":
			return Color(0.7, 0.7, 0.7)
		"rare":
			return Color(0.2, 0.6, 1.0)
		"epic":
			return Color(0.8, 0.2, 0.8)
		"legendary":
			return Color(1.0, 0.6, 0.0)
		"mythical":
			return Color(1.0, 0.0, 0.5)
		_:
			return Color.WHITE

func _on_buy_item_pressed(item_id: String) -> void:
	if not monetization_system:
		return
	
	if monetization_system.is_item_owned(item_id):
		return
	
	var success = monetization_system.purchase_item(item_id, MonetizationSystem.CurrencyType.PEARLS)
	if success:
		print("Item purchased: %s" % item_id)
		_populate_items()
		_update_display()
	else:
		print("Failed to purchase item: %s" % item_id)
		# TODO: Показать сообщение об ошибке

func _on_buy_pearls_pressed() -> void:
	# Открываем браузер для покупки Pearls
	var payment_url = "http://localhost:8080/payment?user_id=%s" % "user123"  # TODO: Получить реальный user_id
	OS.shell_open(payment_url)

func _on_close_pressed() -> void:
	queue_free()

func _on_currency_changed(currency_type: CurrencySystem.CurrencyType, new_amount: int) -> void:
	if currency_type == CurrencySystem.CurrencyType.PEARLS:
		_update_display()

func _on_item_purchased(item_id: String, currency_type: MonetizationSystem.CurrencyType) -> void:
	_populate_items()
	_update_display()

