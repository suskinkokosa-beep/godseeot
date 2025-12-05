extends Node
class_name PlayerControllerVisualUpdate

## Обновляет визуализацию персонажа в PlayerController

static func update_player_visual(player_controller: Node, gender: String, variant: String = "default") -> void:
	var local_player = player_controller.get_node_or_null("LocalPlayer")
	if not local_player:
		return
	
	# Находим или создаём PlayerVisual
	var player_visual = local_player.get_node_or_null("PlayerVisual")
	if not player_visual:
		player_visual = PlayerVisual.new()
		player_visual.name = "PlayerVisual"
		local_player.add_child(player_visual)
	
	player_visual.set_gender(gender)
	player_visual.set_character_variant(variant)

