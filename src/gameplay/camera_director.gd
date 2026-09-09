class_name SnakesCameraDirector
extends Node3D
## Lightweight orbit camera (no PhantomCamera dependency).
## Damped target (no focus jumps), tuned default framing, subtle idle drift.

var camera: Camera3D
var yaw: float = deg_to_rad(30.0)
var pitch: float = deg_to_rad(-52.0)
var dist: float = 27.5
var target := Vector3(2.2, 0.0, 1.0)
var top_down := false
var _desired := Vector3(2.2, 0.0, 1.0)
var _drag_offset := Vector2.ZERO
var _shake: float = 0.0
var _idle_t := 0.0
var _idle_hold := 0.0

const HOME := Vector3(2.2, 0.0, 1.0)
const MIN_DIST := 14.0
const MAX_DIST := 38.0


func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 40.0
	camera.near = 0.15
	camera.far = 150.0
	add_child(camera)
	_apply()


func _process(delta: float) -> void:
	_idle_t += delta
	if _drag_offset.length() > 0.01:
		_drag_offset = _drag_offset.lerp(Vector2.ZERO, 1.0 - exp(-2.0 * delta))
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 2.0)
	# Damped follow: focus requests glide instead of jumping.
	target = target.lerp(_desired, 1.0 - exp(-3.0 * delta))
	# Subtle idle sway (yaw only — raycasts stay stable).
	if _idle_hold > 0.0:
		_idle_hold -= delta
	elif not top_down and _drag_offset.length() < 0.5 and _shake <= 0.0:
		yaw += deg_to_rad(1.4) * delta * sin(_idle_t * TAU / 14.0)
	_apply()


func _apply() -> void:
	var y: float = yaw + _drag_offset.x * 0.003
	var p: float = pitch
	if top_down:
		p = deg_to_rad(-89.0)
	var dir := Vector3(cos(p) * sin(y), -sin(p), cos(p) * cos(y))
	var shake_off := Vector3.ZERO
	if _shake > 0.0:
		shake_off = Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake * 0.35
	camera.position = target + dir * dist + shake_off
	camera.look_at(target + shake_off * 0.5)


func apply_drag(delta_px: Vector2) -> void:
	_drag_offset += delta_px
	_idle_hold = 6.0


func apply_zoom(factor: float) -> void:
	dist = clampf(dist * factor, MIN_DIST, MAX_DIST)
	_idle_hold = 6.0


func set_top_down(on: bool) -> void:
	top_down = on


func focus_on(point: Vector3) -> void:
	_desired = point


func home() -> void:
	_desired = HOME


func reset_framing() -> void:
	_desired = HOME
	target = HOME
	_drag_offset = Vector2.ZERO
	yaw = deg_to_rad(30.0)
	pitch = deg_to_rad(-52.0)
	dist = 27.5
	top_down = false


func shake(amount: float = 0.5) -> void:
	_shake = maxf(_shake, amount)
