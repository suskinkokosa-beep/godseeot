extends AcceptDialog

## Диалог подтверждения выброса предмета

@onready var item_label: Label = $VBox/ItemLabel

var item_id: String = ""
var confirmed: bool = false

signal item_discard_confirmed(item_id: String)

func _ready() -> void:
	confirmed = false
	confirmed.connect(_on_confirmed)
	canceled.connect(_on_canceled)

func setup(item_id: String, item_name: String) -> void:
	self.item_id = item_id
	item_label.text = "Предмет: %s" % item_name
	dialog_text = "Вы уверены, что хотите выбросить '%s'?\n\nВНИМАНИЕ: Предмет будет удалён без возможности восстановления!" % item_name

func _on_confirmed() -> void:
	confirmed = true
	item_discard_confirmed.emit(item_id)
	queue_free()

func _on_canceled() -> void:
	confirmed = false
	queue_free()

