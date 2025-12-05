extends Node
class_name MonetizationSystem

## Система монетизации Isleborn Online
## Принцип "Fair To Play" - только косметика и удобства, без P2W

enum CurrencyType {
	SHELLS,      # Обычная валюта (игровая)
	GOLD,        # Дополнительная валюта
	PEARLS,      # Премиум-валюта (за реальные деньги)
	GUILD_COINS  # Валюту гильдии
}

enum ShopItemType {
	COSMETIC_CHARACTER,    # Косметика персонажа
	COSMETIC_SHIP,         # Косметика корабля
	COSMETIC_ISLAND,       # Косметика острова
	PET,                   # Питомец
	EMOTION,               # Эмоция
	AURA,                  # Аура
	PREMIUM_ACCOUNT,       # Премиум-аккаунт
	SEASON_PASS,           # Сезонный пропуск
	GUILD_PLUS,            # Guild Plus подписка
	BOOSTER                # Ускоритель прогресса
}

class ShopItem:
	var id: String
	var name: String
	var type: ShopItemType
	var price_pearls: int = 0
	var price_shells: int = 0
	var description: String
	var icon_path: String
	var rarity: String = "common"  # common, rare, epic, legendary, mythical
	var is_premium: bool = false
	var season_id: String = ""  # Для сезонных предметов
	var category: String = ""
	
	func _init(_id: String, _name: String, _type: ShopItemType):
		id = _id
		name = _name
		type = _type

class PremiumAccount:
	var is_active: bool = false
	var expires_at: int = 0  # Unix timestamp
	var bonuses: Dictionary = {
		"exp_bonus": 0.15,        # +15% к опыту персонажа
		"island_exp_bonus": 0.15,  # +15% к опыту острова
		"ship_speed_bonus": 0.10,  # +10% скорость лодки
		"craft_queue_extra": 1,    # +1 очередь на крафт
		"daily_teleport": true     # Бесплатный телепорт раз в день
	}

class SeasonPass:
	var season_id: String
	var is_premium: bool = false
	var level: int = 0
	var experience: int = 0
	var expires_at: int = 0
	var rewards_free: Array = []
	var rewards_premium: Array = []

var shop_items: Dictionary = {}
var premium_account: PremiumAccount = PremiumAccount.new()
var current_season_pass: SeasonPass = null
var owned_items: Dictionary = {}  # item_id -> true
var owned_pets: Array = []
var owned_emotions: Array = []
var owned_auras: Array = []

signal item_purchased(item_id: String, currency_type: CurrencyType)
signal premium_account_activated(expires_at: int)
signal season_pass_activated(season_id: String, is_premium: bool)
signal pearls_changed(new_amount: int)

func _ready() -> void:
	_register_all_shop_items()
	load_player_data()

func _register_all_shop_items() -> void:
	# === КОСМЕТИКА ПЕРСОНАЖЕЙ ===
	_register_cosmetic("skin_sea_wanderer", "Морской бродяга", ShopItemType.COSMETIC_CHARACTER, 150, "Одежда моряка-бродяги", "rare")
	_register_cosmetic("skin_empire_navigator", "Навигатор империи", ShopItemType.COSMETIC_CHARACTER, 300, "Роскошный мундир", "epic")
	_register_cosmetic("skin_kraken_captain", "Капитан-кракен", ShopItemType.COSMETIC_CHARACTER, 500, "Одежда из щупалец", "legendary")
	_register_cosmetic("skin_sandy_wanderer", "Песчаный странник", ShopItemType.COSMETIC_CHARACTER, 200, "Пустынный сет", "rare")
	_register_cosmetic("skin_ice_fisher", "Ледяной рыболов", ShopItemType.COSMETIC_CHARACTER, 250, "Меховая отделка", "rare")
	
	# Маски
	_register_cosmetic("mask_seagull", "Маска чайки", ShopItemType.COSMETIC_CHARACTER, 50, "Маска в виде чайки", "common")
	_register_cosmetic("mask_shark", "Маска акулы", ShopItemType.COSMETIC_CHARACTER, 100, "Устрашающая маска", "rare")
	_register_cosmetic("mask_pirate_skull", "Череп пирата", ShopItemType.COSMETIC_CHARACTER, 150, "Легендарный череп", "epic")
	_register_cosmetic("mask_depths", "Маска глубин", ShopItemType.COSMETIC_CHARACTER, 200, "С зелёным свечением", "epic")
	
	# Аксессуары
	_register_cosmetic("cloak_sea_pattern", "Плащ с морским узором", ShopItemType.COSMETIC_CHARACTER, 75, "Красивый плащ", "common")
	_register_cosmetic("shoulders_shells", "Наплечники-раковины", ShopItemType.COSMETIC_CHARACTER, 100, "Уникальные наплечники", "rare")
	_register_cosmetic("coral_bracelets", "Браслеты из кораллов", ShopItemType.COSMETIC_CHARACTER, 50, "Красивые браслеты", "common")
	
	# === КОСМЕТИКА КОРАБЛЕЙ ===
	_register_cosmetic("ship_fire_boat", "Огненная ладья", ShopItemType.COSMETIC_SHIP, 400, "Пылающие борта", "epic")
	_register_cosmetic("ship_ghost_bark", "Призрачный баркас", ShopItemType.COSMETIC_SHIP, 350, "Полупрозрачный", "rare")
	_register_cosmetic("ship_golden_trimaran", "Золотой тримаран", ShopItemType.COSMETIC_SHIP, 600, "Роскошный корабль", "legendary")
	_register_cosmetic("ship_kraken_ship", "Корабль-кракен", ShopItemType.COSMETIC_SHIP, 500, "Украшения в виде щупалец", "epic")
	_register_cosmetic("ship_pirate_vessel", "Пиратская посудина", ShopItemType.COSMETIC_SHIP, 300, "Флаги и черепа", "rare")
	
	# === КОСМЕТИКА ОСТРОВОВ ===
	_register_cosmetic("island_japanese_garden", "Японский сад", ShopItemType.COSMETIC_ISLAND, 500, "Мини-тории и фонари", "epic")
	_register_cosmetic("island_viking", "Викинг", ShopItemType.COSMETIC_ISLAND, 400, "Деревянные столбы", "rare")
	_register_cosmetic("island_tropical_paradise", "Тропический рай", ShopItemType.COSMETIC_ISLAND, 350, "Пальмы и фрукты", "rare")
	_register_cosmetic("island_ice_island", "Ледяной остров", ShopItemType.COSMETIC_ISLAND, 450, "Голубые текстуры", "epic")
	_register_cosmetic("island_ancient_ruins", "Древние руины", ShopItemType.COSMETIC_ISLAND, 600, "Колонны и статуи", "legendary")
	
	# === ПИТОМЦЫ ===
	_register_pet("pet_mini_dolphin", "Мини-дельфин", 150)
	_register_pet("pet_kraken_baby", "Кракенчик", 300)
	_register_pet("pet_penguin", "Пингвин", 200)
	_register_pet("pet_flying_fish", "Летучая рыба", 100)
	_register_pet("pet_parrot", "Попугай", 250)
	_register_pet("pet_jellyfish", "Медузёнок", 180)
	_register_pet("pet_mini_yeti", "Мини-йети", 400)
	
	# === ЭМОЦИИ ===
	_register_emotion("emotion_dancing_pirate", "Пляшущий пират", 50)
	_register_emotion("emotion_raise_mug", "Поднять кружку", 30)
	_register_emotion("emotion_wave_jump", "Прыжок через волну", 40)
	_register_emotion("emotion_seagull_dance", "Танец чаек", 35)
	_register_emotion("emotion_ahoy", "Ахой!", 25)
	_register_emotion("emotion_drowning", "Я тону!", 30)
	_register_emotion("emotion_kraken_challenge", "Вызов кракена", 100)
	
	# === АУРЫ ===
	_register_aura("aura_bubble_trail", "След из пузырей", 200)
	_register_aura("aura_fire_trail", "Пылающий след", 250)
	_register_aura("aura_ice_crystals", "Ледяные кристаллы", 300)
	_register_aura("aura_ghost_trail", "Призрачный след", 220)
	_register_aura("aura_rainbow_splash", "Радужные брызги", 350)
	
	# === ПРЕМИУМ-АККАУНТ ===
	var premium_item = ShopItem.new("premium_account_30", "Премиум-аккаунт (30 дней)", ShopItemType.PREMIUM_ACCOUNT)
	premium_item.price_pearls = 500
	premium_item.description = "Все бонусы премиум-аккаунта на 30 дней"
	premium_item.rarity = "epic"
	shop_items[premium_item.id] = premium_item
	
	# === СЕЗОННЫЙ ПРОПУСК ===
	var season_pass_item = ShopItem.new("season_pass_1", "Сезонный пропуск - Пробуждение глубин", ShopItemType.SEASON_PASS)
	season_pass_item.price_pearls = 1000
	season_pass_item.description = "Все награды сезона + премиум награды"
	season_pass_item.rarity = "legendary"
	season_pass_item.season_id = "season_1"
	shop_items[season_pass_item.id] = season_pass_item

func _register_cosmetic(id: String, name: String, type: ShopItemType, price: int, description: String, rarity: String = "common"):
	var item = ShopItem.new(id, name, type)
	item.price_pearls = price
	item.description = description
	item.rarity = rarity
	item.is_premium = true
	shop_items[id] = item

func _register_pet(id: String, name: String, price: int):
	var item = ShopItem.new(id, name, ShopItemType.PET)
	item.price_pearls = price
	item.description = "Питомец-компаньон (без бонусов к статам)"
	item.rarity = "rare"
	item.is_premium = true
	shop_items[id] = item

func _register_emotion(id: String, name: String, price: int):
	var item = ShopItem.new(id, name, ShopItemType.EMOTION)
	item.price_pearls = price
	item.description = "Эмоция для персонажа"
	item.rarity = "common"
	item.is_premium = true
	shop_items[id] = item

func _register_aura(id: String, name: String, price: int):
	var item = ShopItem.new(id, name, ShopItemType.AURA)
	item.price_pearls = price
	item.description = "Визуальный эффект ауры"
	item.rarity = "epic"
	item.is_premium = true
	shop_items[id] = item

func purchase_item(item_id: String, currency_type: CurrencyType = CurrencyType.PEARLS) -> bool:
	if not shop_items.has(item_id):
		push_error("Shop item not found: %s" % item_id)
		return false
	
	var item = shop_items[item_id]
	var currency_system = get_node_or_null("/root/World/CurrencySystem")
	if not currency_system:
		push_error("CurrencySystem not found!")
		return false
	
	# Проверяем, есть ли уже этот предмет
	if owned_items.has(item_id):
		push_warning("Item already owned: %s" % item_id)
		return false
	
	var price = item.price_pearls if currency_type == CurrencyType.PEARLS else item.price_shells
	var currency_enum = CurrencySystem.CurrencyType.PEARLS if currency_type == CurrencyType.PEARLS else CurrencySystem.CurrencyType.SHELLS
	
	# Проверяем баланс
	if not currency_system.has_currency(currency_enum, price):
		push_error("Not enough currency!")
		return false
	
	# Списываем валюту
	currency_system.spend_currency(currency_enum, price)
	
	# Добавляем предмет в собственность
	owned_items[item_id] = true
	
	# Добавляем в соответствующую категорию
	match item.type:
		ShopItemType.PET:
			if not item_id in owned_pets:
				owned_pets.append(item_id)
		ShopItemType.EMOTION:
			if not item_id in owned_emotions:
				owned_emotions.append(item_id)
		ShopItemType.AURA:
			if not item_id in owned_auras:
				owned_auras.append(item_id)
		ShopItemType.PREMIUM_ACCOUNT:
			activate_premium_account(30)  # 30 дней
		ShopItemType.SEASON_PASS:
			activate_season_pass(item.season_id, true)
	
	item_purchased.emit(item_id, currency_type)
	save_player_data()
	
	return true

func activate_premium_account(days: int) -> void:
	var current_time = Time.get_unix_time_from_system()
	if premium_account.is_active and premium_account.expires_at > current_time:
		# Продлеваем существующий
		premium_account.expires_at += days * 86400  # 86400 секунд в дне
	else:
		# Создаём новый
		premium_account.is_active = true
		premium_account.expires_at = current_time + (days * 86400)
	
	premium_account_activated.emit(premium_account.expires_at)
	save_player_data()

func activate_season_pass(season_id: String, is_premium: bool) -> void:
	if current_season_pass == null or current_season_pass.season_id != season_id:
		current_season_pass = SeasonPass.new()
		current_season_pass.season_id = season_id
		current_season_pass.is_premium = is_premium
		current_season_pass.level = 0
		current_season_pass.experience = 0
		# Сезон длится 60 дней
		current_season_pass.expires_at = Time.get_unix_time_from_system() + (60 * 86400)
	else:
		current_season_pass.is_premium = is_premium
	
	season_pass_activated.emit(season_id, is_premium)
	save_player_data()

func is_item_owned(item_id: String) -> bool:
	return owned_items.has(item_id)

func is_premium_active() -> bool:
	if not premium_account.is_active:
		return false
	
	var current_time = Time.get_unix_time_from_system()
	if premium_account.expires_at <= current_time:
		premium_account.is_active = false
		return false
	
	return true

func get_premium_bonuses() -> Dictionary:
	if not is_premium_active():
		return {}
	return premium_account.bonuses

func get_shop_items_by_category(category: String) -> Array:
	var result = []
	for item_id in shop_items.keys():
		var item = shop_items[item_id]
		if item.category == category or category == "":
			result.append(item)
	return result

func get_shop_items_by_type(type: ShopItemType) -> Array:
	var result = []
	for item_id in shop_items.keys():
		var item = shop_items[item_id]
		if item.type == type:
			result.append(item)
	return result

func load_player_data() -> void:
	# Загружаем из сохранения
	var config = ConfigFile.new()
	var err = config.load("user://monetization_data.cfg")
	if err != OK:
		return
	
	# Загружаем владение предметами
	var items = config.get_value("ownership", "items", {})
	owned_items = items
	
	# Загружаем премиум-аккаунт
	var premium_expires = config.get_value("premium", "expires_at", 0)
	var current_time = Time.get_unix_time_from_system()
	if premium_expires > current_time:
		premium_account.is_active = true
		premium_account.expires_at = premium_expires
	
	# Загружаем сезонный пропуск
	var season_id = config.get_value("season_pass", "season_id", "")
	if season_id != "":
		current_season_pass = SeasonPass.new()
		current_season_pass.season_id = season_id
		current_season_pass.is_premium = config.get_value("season_pass", "is_premium", false)
		current_season_pass.level = config.get_value("season_pass", "level", 0)
		current_season_pass.experience = config.get_value("season_pass", "experience", 0)
		current_season_pass.expires_at = config.get_value("season_pass", "expires_at", 0)

func save_player_data() -> void:
	var config = ConfigFile.new()
	
	# Сохраняем владение предметами
	config.set_value("ownership", "items", owned_items)
	
	# Сохраняем премиум-аккаунт
	if premium_account.is_active:
		config.set_value("premium", "expires_at", premium_account.expires_at)
	
	# Сохраняем сезонный пропуск
	if current_season_pass:
		config.set_value("season_pass", "season_id", current_season_pass.season_id)
		config.set_value("season_pass", "is_premium", current_season_pass.is_premium)
		config.set_value("season_pass", "level", current_season_pass.level)
		config.set_value("season_pass", "experience", current_season_pass.experience)
		config.set_value("season_pass", "expires_at", current_season_pass.expires_at)
	
	config.save("user://monetization_data.cfg")

## Добавить Pearls (после покупки за реальные деньги через веб-API)
func add_pearls(amount: int, source: String = "purchase") -> void:
	var currency_system = get_node_or_null("/root/World/CurrencySystem")
	if currency_system:
		currency_system.add_currency(CurrencySystem.CurrencyType.PEARLS, amount)
		pearls_changed.emit(currency_system.get_currency_balance(CurrencySystem.CurrencyType.PEARLS))

