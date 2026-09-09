class_name SnakesDice
extends Node3D
## Kinematic fake die with real inset pips. Standard layout, opposites sum
## to 7 (1-6, 2-5, 3-4). Clickable via child StaticBody3D meta (layer 4).
## Roll presentation mirrors Ludo's dice (suspended tumble easing onto the
## exact face); the top_face() read-back verification is ported from
## LudoDice so the shown number can never contradict the engine result.

const SIZE := 0.7
const HALF := 0.35
const PIP_R := 0.055
const PIP_INSET := 0.02
const GRID := 0.16
const FACE_NORMALS := {
	1: Vector3(0, 1, 0), 6: Vector3(0, -1, 0),
	2: Vector3(0, 0, -1), 5: Vector3(0, 0, 1),
	3: Vector3(1, 0, 0), 4: Vector3(-1, 0, 0),
}

static func face_basis(face: int) -> Basis:
	match face:
		1:
			return Basis.IDENTITY
		6:
			return Basis(Vector3(1, 0, 0), PI)
		2:
			return Basis(Vector3(1, 0, 0), PI * 0.5)
		5:
			return Basis(Vector3(1, 0, 0), -PI * 0.5)
		3:
			return Basis(Vector3(0, 0, 1), PI * 0.5)
		4:
			return Basis(Vector3(0, 0, 1), -PI * 0.5)
	return Basis.IDENTITY


static func pip_grid(face: int) -> Array:
	var g := GRID
	match face:
		1:
			return [Vector2(0, 0)]
		2:
			return [Vector2(-g, g), Vector2(g, -g)]
		3:
			return [Vector2(-g, g), Vector2(0, 0), Vector2(g, -g)]
		4:
			return [Vector2(-g, -g), Vector2(-g, g), Vector2(g, -g), Vector2(g, g)]
		5:
			return [Vector2(-g, -g), Vector2(-g, g), Vector2(0, 0), Vector2(g, -g), Vector2(g, g)]
		6:
			return [Vector2(-g, -g), Vector2(-g, 0), Vector2(-g, g),
				Vector2(g, -g), Vector2(g, 0), Vector2(g, g)]
	return []

var value: int = 1
var _rolling := false
var _gen := 0
var _tween: Tween = null
var _tray := SnakesDiceTray.TRAY_POS
var _rest_y := SnakesDiceTray.REST_Y
var _free := 0.62


func _ready() -> void:
	_build()
	snap_to_face(1 + randi() % 6, randf() * TAU)


func set_tray(center: Vector3, rest_y: float, free_half: float = 0.62) -> void:
	_tray = center
	_rest_y = rest_y
	_free = free_half


func _pip_pos(face: int, uv: Vector2) -> Vector3:
	var h := HALF - PIP_INSET
	match face:
		1: # +Y viewed from above: right=+X, up=-Z
			return Vector3(uv.x, h, -uv.y)
		6: # -Y viewed from below: right=+X, up=+Z
			return Vector3(uv.x, -h, uv.y)
		2: # -Z
			return Vector3(uv.x, uv.y, -h)
		5: # +Z
			return Vector3(uv.x, uv.y, h)
		3: # +X viewed from +X: right=-Z, up=+Y
			return Vector3(h, uv.y, -uv.x)
		4: # -X viewed from -X: right=+Z, up=+Y
			return Vector3(-h, uv.y, uv.x)
	return Vector3.ZERO


func _build() -> void:
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(0.96, 0.95, 0.92)
	white.metallic_specular = 0.6
	white.roughness = 0.28
	white.clearcoat_enabled = true
	white.clearcoat = 0.6
	white.clearcoat_roughness = 0.25
	var box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(SIZE, SIZE, SIZE)
	box.mesh = bm
	box.material_override = white
	add_child(box)
	var pip_mesh := SphereMesh.new()
	pip_mesh.radius = PIP_R
	pip_mesh.height = PIP_R * 2.0
	pip_mesh.radial_segments = 16
	pip_mesh.rings = 8
	var black := StandardMaterial3D.new()
	black.albedo_color = Color(0.05, 0.05, 0.06)
	black.roughness = 0.5
	for face in range(1, 7):
		for uv in pip_grid(face):
			var p := MeshInstance3D.new()
			p.mesh = pip_mesh
			p.material_override = black
			p.position = _pip_pos(face, uv)
			var n: Vector3 = FACE_NORMALS[face]
			if absf(n.y) > 0.5:
				p.scale = Vector3(1, 0.45, 1)
			elif absf(n.z) > 0.5:
				p.scale = Vector3(1, 1, 0.45)
			else:
				p.scale = Vector3(0.45, 1, 1)
			p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(p)
	var pick := StaticBody3D.new()
	pick.collision_layer = 4
	pick.collision_mask = 0
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.7, 0.7, 0.7)
	col.shape = shape
	pick.add_child(col)
	pick.set_meta("dice_ref", self)
	add_child(pick)


func snap_to_face(result: int, yaw: float = 0.0) -> void:
	quaternion = (Quaternion(Basis(Vector3.UP, yaw) * face_basis(result))).normalized()
	value = result


## Read-back: which face currently points up (ported from LudoDice).
func top_face() -> int:
	var best := 1
	var best_dot := -2.0
	for face in FACE_NORMALS:
		var d: float = (quaternion.normalized() * FACE_NORMALS[face]).dot(Vector3.UP)
		if d > best_dot:
			best_dot = d
			best = face
	return best


## Tumble ~0.8s (two hops, drift clamped to the tray) then settle result-up.
func roll(result: int, speed: float = 1.0) -> void:
	_gen += 1
	var g := _gen
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_rolling = true
	value = result
	var dur: float = 0.8 / clampf(speed, 0.4, 2.0)
	var q0 := quaternion.normalized()
	var yaw := randf() * TAU
	var q_target := Quaternion(Basis(Vector3.UP, yaw) * face_basis(result)).normalized()
	var axis := Vector3(1, 0, 0).rotated(Vector3.UP, randf() * TAU) \
		+ Vector3.UP * randf_range(-0.3, 0.3)
	axis = axis.normalized()
	var q_spin := (Quaternion(axis, randf_range(TAU * 2.0, TAU * 3.0)) * q0).normalized()
	var p0 := position
	var p1 := Vector3(
		clampf(p0.x + randf_range(-0.35, 0.35), _tray.x - _free, _tray.x + _free),
		_rest_y,
		clampf(p0.z + randf_range(-0.35, 0.35), _tray.z - _free, _tray.z + _free))
	_tween = create_tween()
	_tween.tween_method(_apply_roll.bind(q0, q_spin, q_target, p0, p1), 0.0, 1.0, dur)
	await _tween.finished
	if g != _gen:
		return
	quaternion = q_target
	position = p1
	# Blend guarantee (LudoDice parity): the shown face must be the result.
	if top_face() != result:
		quaternion = q_target
	value = result
	_rolling = false
	var st := create_tween()
	st.tween_property(self, "scale", Vector3(1.15, 0.8, 1.15), 0.07)
	st.tween_property(self, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _apply_roll(t: float, q0: Quaternion, qs: Quaternion, qt: Quaternion,
		p0: Vector3, p1: Vector3) -> void:
	var q: Quaternion
	if t < 0.6:
		var u := 1.0 - pow(1.0 - t / 0.6, 2.0)
		q = q0.slerp(qs, u)
	else:
		var u := (t - 0.6) / 0.4
		u = u * u * (3.0 - 2.0 * u)
		q = qs.slerp(qt, u)
	quaternion = q.normalized()
	var ease := 1.0 - pow(1.0 - t, 2.0)
	var px := lerpf(p0.x, p1.x, ease)
	var pz := lerpf(p0.z, p1.z, ease)
	var base_y := lerpf(p0.y, p1.y, t)
	var hop := 0.0
	if t < 0.55:
		var u := t / 0.55
		hop = 0.9 * 4.0 * u * (1.0 - u)
	elif t < 0.8:
		var u := (t - 0.55) / 0.25
		hop = 0.35 * 4.0 * u * (1.0 - u)
	position = Vector3(px, base_y + hop, pz)


func rest_at(pos: Vector3) -> void:
	_gen += 1
	var g := _gen
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var tw := create_tween()
	tw.tween_property(self, "position", pos, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await tw.finished
	if g != _gen:
		return


func is_rolling() -> bool:
	return _rolling
