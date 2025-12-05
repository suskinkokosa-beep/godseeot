extends Node
class_name CurrencySystem

## Система валют Isleborn Online
## Управляет различными валютами: ракушки, золото, жемчужины

enum CurrencyType {
	SHELLS,        # Ракушки - основная валюта
	GOLD,          # Золото - редкая валюта
	PEARLS,        # Жемчужины - премиум валюта
	GUILD_COINS    # Монеты гильдии
}

var currencies: Dictionary = {
	CurrencyType.SHELLS: 0,
	CurrencyType.GOLD: 0,
	CurrencyType.PEARLS: 0,
	CurrencyType.GUILD_COINS: 0
}

signal currency_changed(currency_type: CurrencyType, new_amount: int)
signal currency_insufficient(currency_type: CurrencyType, required: int, have: int)

## Добавить валюту
func add_currency(currency_type: CurrencyType, amount: int) -> void:
	if amount <= 0:
		return
	
	var current = currencies.get(currency_type, 0)
	currencies[currency_type] = current + amount
	currency_changed.emit(currency_type, currencies[currency_type])

## Потратить валюту
func spend_currency(currency_type: CurrencyType, amount: int) -> bool:
	if amount <= 0:
		return false
	
	var current = currencies.get(currency_type, 0)
	if current < amount:
		currency_insufficient.emit(currency_type, amount, current)
		return false
	
	currencies[currency_type] = current - amount
	currency_changed.emit(currency_type, currencies[currency_type])
	return true

## Проверить, достаточно ли валюты
func has_currency(currency_type: CurrencyType, amount: int) -> bool:
	return currencies.get(currency_type, 0) >= amount

## Получить количество валюты
func get_currency(currency_type: CurrencyType) -> int:
	return currencies.get(currency_type, 0)

## Получить баланс валюты (алиас для get_currency)
func get_currency_balance(currency_type: CurrencyType) -> int:
	return get_currency(currency_type)

## Получить название валюты
static func get_currency_name(currency_type: CurrencyType) -> String:
	match currency_type:
		CurrencyType.SHELLS:
			return "Ракушки"
		CurrencyType.GOLD:
			return "Золото"
		CurrencyType.PEARLS:
			return "Жемчужины"
		CurrencyType.GUILD_COINS:
			return "Монеты гильдии"
		_:
			return "Неизвестно"

## Обменять валюту (если нужно)
func exchange_currency(from_type: CurrencyType, to_type: CurrencyType, from_amount: int, exchange_rate: float) -> bool:
	if not has_currency(from_type, from_amount):
		return false
	
	var to_amount = int(from_amount * exchange_rate)
	if to_amount <= 0:
		return false
	
	if not spend_currency(from_type, from_amount):
		return false
	
	add_currency(to_type, to_amount)
	return true

