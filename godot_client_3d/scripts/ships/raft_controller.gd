extends Node3D

## Very simple local raft prototype.
## For now moves independently with IJKL keys; later will sync to server and use ShipDatabase.

@export var move_speed: float = 3.0

func _process(delta: float) -> void:
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_I):
		dir.z -= 1.0
	if Input.is_key_pressed(KEY_K):
		dir.z += 1.0
	if Input.is_key_pressed(KEY_J):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_L):
		dir.x += 1.0
	if dir != Vector3.ZERO:
		dir = dir.normalized()
		translation += dir * move_speed * delta


