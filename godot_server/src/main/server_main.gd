extends Node3D

## Thin wrapper that delegates to legacy server.gd logic.
## This lets us evolve structure under src/ without breaking existing behaviour.

@onready var legacy_server := preload("res://server.gd")

var _server_instance: Node = null

func _ready() -> void:
	_spawn_legacy_server()


func _process(delta: float) -> void:
	# Ensure legacy server keeps running even if we later add more nodes here.
	if _server_instance == null:
		_spawn_legacy_server()


func _spawn_legacy_server() -> void:
	if _server_instance != null:
		return
	_server_instance = legacy_server.new()
	add_child(_server_instance)


