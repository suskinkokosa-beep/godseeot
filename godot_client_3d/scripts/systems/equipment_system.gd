extends Node
class_name EquipmentSystem

## Система экипировки персонажа Isleborn Online
## Управляет броней, оружием и их визуализацией
## Поддерживает уровни предметов и редкость

enum EquipmentSlot {
	WEAPON_MAIN,      # Основное оружие
	WEAPON_OFFHAND,   # Дополнительное оружие/щит
	HELMET,           # Шлем
	CHEST,            # Нагрудник
	LEGS,             # Поножи
	BOOTS,            # Сапоги
	GLOVES,           # Перчатки
	ACCESSORY_1,      # Аксессуар 1
	ACCESSORY_2,      # Аксессуар 2
	ACCESSORY_3       # Аксессуар 3
}

## Данные экипированного предмета
class EquippedItem:
	var item_id: String
	var item_data: Dictionary
	var enhancement_level: int = 0  # Уровень заточки (0-12)
	var visual_style: String = ""    # Стиль визуализации
	
	func get_total_stats() -> Dictionary:
		# Используем систему редкости для вычисления статов
		return ItemRaritySystem.calculate_total_item_stats(item_data, enhancement_level)

var equipped_items: Dictionary = {}  # slot -> EquippedItem
var show_equipment_visual: bool = true  # Показывать броню/оружие или стиль

signal item_equipped(slot: EquipmentSlot, item_id: String)
signal item_unequipped(slot: EquipmentSlot, item_id: String)
signal visual_mode_changed(show_equipment: bool)

func _ready() -> void:
	# Инициализируем все слоты как пустые
	for slot in EquipmentSlot.values():
		equipped_items[slot] = null

## Экипировать предмет
func equip_item(item_id: String, slot: EquipmentSlot, inventory_system: Node = null, player_level: int = 1) -> bool:
	# Проверяем, что предмет существует
	var item_data = ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		return false
	
	# Проверяем уровень предмета
	var required_level = item_data.get("required_level", 1)
	if player_level < required_level:
		return false
	
	# Проверяем, что предмет может быть экипирован в этот слот
	if not _can_equip_in_slot(item_data, slot):
		return false
	
	# Если в слоте уже есть предмет, снимаем его
	if equipped_items[slot] != null:
		unequip_item(slot, inventory_system)
	
	# Создаём запись экипированного предмета
	var equipped = EquippedItem.new()
	equipped.item_id = item_id
	equipped.item_data = item_data
	equipped.enhancement_level = item_data.get("enhancement_level", 0)
	
	equipped_items[slot] = equipped
	
	# Удаляем из инвентаря
	if inventory_system and inventory_system.has_method("remove_item"):
		inventory_system.remove_item(item_id, 1)
	
	item_equipped.emit(slot, item_id)
	return true

## Снять предмет
func unequip_item(slot: EquipmentSlot, inventory_system: Node = null) -> bool:
	if equipped_items[slot] == null:
		return false
	
	var equipped = equipped_items[slot]
	var item_id = equipped.item_id
	
	# Возвращаем в инвентарь
	if inventory_system and inventory_system.has_method("add_item"):
		inventory_system.add_item(item_id, 1)
	
	equipped_items[slot] = null
	item_unequipped.emit(slot, item_id)
	return true

## Проверить, можно ли экипировать предмет в слот
func _can_equip_in_slot(item_data: Dictionary, slot: EquipmentSlot) -> bool:
	var item_type = item_data.get("type", "")
	var item_slot = item_data.get("equipment_slot", "")
	
	match slot:
		EquipmentSlot.WEAPON_MAIN:
			return item_type == "weapon" and item_slot == "main_hand"
		EquipmentSlot.WEAPON_OFFHAND:
			return item_type == "weapon" and item_slot == "offhand" or item_type == "shield"
		EquipmentSlot.HELMET:
			return item_type == "armor" and item_slot == "helmet"
		EquipmentSlot.CHEST:
			return item_type == "armor" and item_slot == "chest"
		EquipmentSlot.LEGS:
			return item_type == "armor" and item_slot == "legs"
		EquipmentSlot.BOOTS:
			return item_type == "armor" and item_slot == "boots"
		EquipmentSlot.GLOVES:
			return item_type == "armor" and item_slot == "gloves"
		EquipmentSlot.ACCESSORY_1, EquipmentSlot.ACCESSORY_2, EquipmentSlot.ACCESSORY_3:
			return item_type == "accessory"
		_:
			return false

## Получить все статы от экипировки
func get_total_equipment_stats() -> Dictionary:
	var total_stats: Dictionary = {}
	
	for slot in equipped_items.keys():
		var equipped = equipped_items[slot]
		if equipped != null:
			var item_stats = equipped.get_total_stats()
			for stat in item_stats.keys():
				if not total_stats.has(stat):
					total_stats[stat] = 0.0
				total_stats[stat] += item_stats[stat]
	
	return total_stats

## Получить экипированный предмет в слоте
func get_equipped_item(slot: EquipmentSlot) -> EquippedItem:
	return equipped_items.get(slot, null)

## Переключить режим визуализации
func toggle_visual_mode() -> void:
	show_equipment_visual = not show_equipment_visual
	visual_mode_changed.emit(show_equipment_visual)

## Установить режим визуализации
func set_visual_mode(show_equipment: bool) -> void:
	show_equipment_visual = show_equipment
	visual_mode_changed.emit(show_equipment_visual)

## Получить текущий режим визуализации
func is_showing_equipment() -> bool:
	return show_equipment_visual

## Проверить, можно ли экипировать предмет по уровню
func can_equip_by_level(item_id: String, player_level: int) -> bool:
	var item_data = ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		return false
	
	var required_level = item_data.get("required_level", 1)
	return player_level >= required_level
