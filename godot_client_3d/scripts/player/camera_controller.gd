extends Node3D

## Simple third-person camera rig:
## - RMB + mouse move: вращение вокруг персонажа
## - колесо мыши: зум

@export var target_path: NodePath
@export var distance: float = 8.0
@export var min_distance: float = 3.0
@export var max_distance: float = 20.0
@export var mouse_sensitivity: float = 0.01

@onready var target: Node3D = get_node_or_null(target_path)
@onready var cam: Camera3D = $Camera3D

var _yaw: float = 0.0
var _pitch: float = -0.4 # немного сверху


func _ready() -> void:
	if cam:
		cam.current = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch = clamp(_pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-80.0), deg_to_rad(10.0))

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clamp(distance - 1.0, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clamp(distance + 1.0, min_distance, max_distance)


func _process(delta: float) -> void:
	if not target:
		target = get_node_or_null(target_path)
	if not target or not cam:
		return

	# Риг центрируется на цели
	global_transform.origin = target.global_transform.origin

	# Вычисляем позицию камеры в сферических координатах
	var offset := Vector3(
		cos(_yaw) * cos(_pitch),
		sin(_pitch),
		sin(_yaw) * cos(_pitch)
	) * distance

	cam.global_transform.origin = global_transform.origin + offset
	cam.look_at(global_transform.origin, Vector3.UP)


