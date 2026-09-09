class_name SnakesDiceTray
extends RefCounted
## Felt-lined wooden dice tray. Clearance math: outer 2.6, walls 0.3 thick ->
## interior half 1.0; die half 0.35 + max drift 0.5 = 0.85 < 1.0. Never clips.

const TRAY_POS := Vector3(11.5, 0.0, 0.0)
const OUTER := 2.6
const WALL_T := 0.3
const WALL_H := 0.5
const FLOOR_T := 0.12
const FELT_T := 0.04
# Felt top surface Y (tray origin at y=0).
const FELT_TOP := 0.16
# Dice rest Y: felt top + die half (0.35) + 0.01 clearance.
const REST_Y := 0.51


static func wood_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("4a2e18")
	m.roughness = 0.7
	return m


static func felt_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("1f5c46")
	m.roughness = 1.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


static func build(parent: Node3D, center: Vector3 = TRAY_POS) -> Node3D:
	var root := Node3D.new()
	root.name = "DiceTray"
	root.position = center
	parent.add_child(root)
	var wood := wood_mat()
	var felt := felt_mat()
	var inner: float = OUTER - WALL_T * 2.0
	_add_box(root, Vector3(OUTER, FLOOR_T, OUTER), Vector3(0, FLOOR_T * 0.5, 0), wood)
	_add_box(root, Vector3(inner, FELT_T, inner), Vector3(0, FLOOR_T + FELT_T * 0.5, 0), felt)
	var wy: float = FLOOR_T + WALL_H * 0.5
	var off: float = OUTER * 0.5 - WALL_T * 0.5
	_add_box(root, Vector3(OUTER, WALL_H, WALL_T), Vector3(0, wy, -off), wood)
	_add_box(root, Vector3(OUTER, WALL_H, WALL_T), Vector3(0, wy, off), wood)
	_add_box(root, Vector3(WALL_T, WALL_H, inner), Vector3(-off, wy, 0), wood)
	_add_box(root, Vector3(WALL_T, WALL_H, inner), Vector3(off, wy, 0), wood)
	return root


static func _add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


static func rest_pos(center: Vector3 = TRAY_POS) -> Vector3:
	return center + Vector3(0, REST_Y, 0)
