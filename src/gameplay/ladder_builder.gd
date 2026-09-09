class_name SnakesLadderBuilder
extends RefCounted
## Straight wooden ladder blueprint (mesh level; texturing comes later).
## Replaces the old arched ladder: rails run straight foot -> top and the
## rung count is proportional to ladder length, so short and tall portals
## each get evenly spaced steps and any height stays adjustable.
##
## Solid-step physics: every rung carries a BoxShape3D on layer 1 / mask 0
## (world-solid, raycast-neutral). A token climbing the ladder meets a real
## step surface at each rung instead of falling through the gaps.
## Tokens themselves are tween-driven visuals, so these bodies also document
## the "no fall-through" contract for future physics movers.
##
## Usage (board portals):
##   SnakesLadderBuilder.build_straight_ladder(root, foot_pos, top_pos)
## Usage (isolated blueprint / different heights):
##   SnakesLadderBuilder.build_preview(root, height)

# Rail separation (full gauge) and rail/rung radii in metres.
const GAUGE := 0.56
const RAIL_RADIUS := 0.09
const RUNG_RADIUS := 0.06
# Target spacing between rungs; the count scales with ladder length.
const RUNG_SPACING := 0.45
# Rail extension past foot/top so rails land on the tiles, not mid-air.
const RAIL_EXT := 0.30
# Step collider thickness (y) and depth (z, along the climb).
const STEP_THICK := 0.10
const STEP_DEPTH := 0.26


## Rung count for a ladder of `length` metres (always >= 2).
static func rung_count_for_height(length: float, rung_spacing: float = RUNG_SPACING) -> int:
	return maxi(2, int(floor(maxf(length, 0.0) / maxf(rung_spacing, 0.05))))


## Straight ladder between two tile-top points. Returns the ladder root.
## `foot_pos` / `top_pos` need not share a height (terraced boards).
static func build_straight_ladder(parent: Node3D, foot_pos: Vector3, top_pos: Vector3,
		gauge: float = GAUGE, rung_spacing: float = RUNG_SPACING) -> Node3D:
	var root := Node3D.new()
	root.name = "Ladder"
	parent.add_child(root)
	var span_vec: Vector3 = top_pos - foot_pos
	var length: float = span_vec.length()
	if length < 0.01:
		return root
	var rail_dir: Vector3 = span_vec / length
	var side := Vector3.UP.cross(rail_dir)
	if side.length() < 0.01:
		# Near-vertical ladder: pick any horizontal axis.
		side = Vector3.RIGHT
	side = side.normalized()
	_build_rails(root, foot_pos, top_pos, rail_dir, side, gauge)
	var count := rung_count_for_height(length, rung_spacing)
	# Rungs sit on the foot->top segment (inside the rail extensions).
	for i in range(count):
		var t: float = float(i + 1) / float(count + 1)
		var center: Vector3 = foot_pos.lerp(top_pos, t)
		_build_rung(root, center, rail_dir, side, gauge, i)
	_build_step_body(root, foot_pos, top_pos, rail_dir, side, gauge, count)
	return root


## Isolated vertical preview ladder `height` metres tall (foot at origin).
## Height knob for the blueprint: raise/lower to preview any ladder size.
static func build_preview(parent: Node3D, height: float,
		gauge: float = GAUGE, rung_spacing: float = RUNG_SPACING) -> Node3D:
	return build_straight_ladder(parent, Vector3.ZERO,
		Vector3(0, maxf(height, 0.5), 0), gauge, rung_spacing)


static func _rail_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("7a5a38")
	m.roughness = 0.45
	m.metallic_specular = 0.5
	return m


static func _rung_mat(idx: int) -> StandardMaterial3D:
	var base := Color("8d6e4a")
	var dark := Color("6d4c41")
	var m := StandardMaterial3D.new()
	m.albedo_color = base.lerp(dark, fmod(float(idx) * 0.37, 1.0) * 0.55)
	m.roughness = 0.5
	m.metallic_specular = 0.5
	return m


static func _build_rails(root: Node3D, foot_pos: Vector3, top_pos: Vector3,
		rail_dir: Vector3, side: Vector3, gauge: float) -> void:
	var mat := _rail_mat()
	var half := gauge * 0.5
	for s in [-1.0, 1.0]:
		var off: Vector3 = side * (half * s)
		_tube(root, foot_pos - rail_dir * RAIL_EXT + off,
			top_pos + rail_dir * RAIL_EXT + off, RAIL_RADIUS, mat)
		for end_pos in [foot_pos - rail_dir * RAIL_EXT, top_pos + rail_dir * RAIL_EXT]:
			var cap := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = RAIL_RADIUS * 1.05
			sm.height = RAIL_RADIUS * 2.1
			sm.radial_segments = 16
			sm.rings = 8
			cap.mesh = sm
			cap.position = end_pos + off
			cap.material_override = mat
			root.add_child(cap)


static func _build_rung(root: Node3D, center: Vector3, rail_dir: Vector3,
		side: Vector3, gauge: float, idx: int) -> void:
	_tube(root, center - side * gauge * 0.5, center + side * gauge * 0.5,
		RUNG_RADIUS, _rung_mat(idx))


## One StaticBody3D holding a solid box per rung: nothing passes through
## the steps. Layer 1 / mask 0 keeps it out of token picking raycasts.
static func _build_step_body(root: Node3D, foot_pos: Vector3, top_pos: Vector3,
		rail_dir: Vector3, side: Vector3, gauge: float, count: int) -> void:
	var body := StaticBody3D.new()
	body.name = "StepsBody"
	body.collision_layer = 1
	body.collision_mask = 0
	root.add_child(body)
	# Rung frame: X across (side), Y along the climb, Z facing out.
	var normal: Vector3 = rail_dir.cross(side).normalized()
	if normal.length() < 0.5:
		normal = Vector3.FORWARD
	var basis := Basis(side, rail_dir, normal).orthonormalized()
	for i in range(count):
		var t: float = float(i + 1) / float(count + 1)
		var center: Vector3 = foot_pos.lerp(top_pos, t)
		var shape_node := CollisionShape3D.new()
		shape_node.name = "Step_%d" % i
		var box := BoxShape3D.new()
		# Slightly wider than the visual rung so edges are sealed too.
		box.size = Vector3(gauge + 0.12, STEP_THICK, STEP_DEPTH)
		shape_node.shape = box
		body.add_child(shape_node)
		shape_node.transform = Transform3D(basis, center)


static func _tube(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material) -> void:
	var dir: Vector3 = b - a
	var length: float = dir.length()
	if length < 0.001:
		return
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = length
	cyl.radial_segments = 16
	mi.mesh = cyl
	mi.material_override = mat
	parent.add_child(mi)
	mi.position = (a + b) * 0.5
	var up := Vector3.UP
	var axis: Vector3 = up.cross(dir.normalized())
	if axis.length() < 0.001:
		if dir.normalized().y < 0.0:
			mi.rotation_degrees = Vector3(180, 0, 0)
	else:
		mi.rotation = axis.normalized() * up.angle_to(dir.normalized())
