extends Node
class_name InventorySystem

## Very simple local inventory prototype.
## Not authoritative (server will own real state later),
## but good enough for UI and client-side logic.

var slots: Dictionary = {} # item_id -> quantity
var max_slots: int = 32

func add_item(item_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	var current := slots.get(item_id, 0)
	slots[item_id] = current + amount


func remove_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	var current := slots.get(item_id, 0)
	if current < amount:
		return false
	current -= amount
	if current <= 0:
		slots.erase(item_id)
	else:
		slots[item_id] = current
	return true


func has_items(requirements: Array) -> bool:
	for entry in requirements:
		var id := entry.get("item_id", "")
		var need := int(entry.get("amount", 0))
		if need <= 0:
			continue
		if slots.get(id, 0) < need:
			return false
	return true


func apply_requirements(requirements: Array) -> bool:
	if not has_items(requirements):
		return false
	for entry in requirements:
		var id := entry.get("item_id", "")
		var need := int(entry.get("amount", 0))
		if need > 0:
			remove_item(id, need)
	return true


