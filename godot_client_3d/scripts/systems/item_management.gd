extends Node
class_name ItemManagement

## Система управления предметами
## Продажа NPC, другим игрокам, выброс

enum SellTarget {
	NPC,        # Продажа NPC
	PLAYER,     # Продажа другому игроку
	DISCARD     # Выброс
}

signal item_sold(item_id: String, target: SellTarget, price: float)
signal item_discarded(item_id: String)

func _ready() -> void:
	pass

## Продать предмет NPC
func sell_to_npc(item_id: String, npc_id: String, inventory_system: Node) -> bool:
	var item_data = ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		return false
	
	# Вычисляем цену продажи (обычно 50% от базовой цены)
	var base_price = item_data.get("sell_price", 0.0)
	var sell_price = base_price * 0.5
	
	# Учитываем заточку (каждый уровень +10% к цене)
	var enhancement_level = item_data.get("enhancement_level", 0)
	if enhancement_level > 0:
		sell_price *= (1.0 + enhancement_level * 0.1)
	
	# Удаляем из инвентаря
	if inventory_system and inventory_system.has_method("remove_item"):
		if not inventory_system.remove_item(item_id, 1):
			return false
	
	# TODO: Добавить валюту игроку
	item_sold.emit(item_id, SellTarget.NPC, sell_price)
	return true

## Продать предмет другому игроку
func sell_to_player(item_id: String, buyer_id: String, price: float, inventory_system: Node) -> bool:
	var item_data = ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		return false
	
	# Проверяем наличие предмета
	if inventory_system and inventory_system.has_method("has_items"):
		if not inventory_system.has_items(item_id, 1):
			return false
	
	# TODO: Реализовать торговлю между игроками через сервер
	# Пока просто эмитируем сигнал
	item_sold.emit(item_id, SellTarget.PLAYER, price)
	return true

## Выбросить предмет (с подтверждением)
func discard_item(item_id: String, inventory_system: Node, confirmed: bool = false) -> bool:
	if not confirmed:
		# Запрашиваем подтверждение через UI
		# TODO: Показать диалог подтверждения
		return false
	
	var item_data = ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		return false
	
	# Удаляем из инвентаря
	if inventory_system and inventory_system.has_method("remove_item"):
		if not inventory_system.remove_item(item_id, 1):
			return false
	
	item_discarded.emit(item_id)
	return true

## Получить цену продажи NPC
static func get_npc_sell_price(item_id: String) -> float:
	var item_data = ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		return 0.0
	
	var base_price = item_data.get("sell_price", 0.0)
	var sell_price = base_price * 0.5
	
	var enhancement_level = item_data.get("enhancement_level", 0)
	if enhancement_level > 0:
		sell_price *= (1.0 + enhancement_level * 0.1)
	
	return sell_price

