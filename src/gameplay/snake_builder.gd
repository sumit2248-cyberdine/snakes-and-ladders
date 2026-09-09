class_name SnakesSnakeBuilder
extends RefCounted
## Premium procedural snake: tapered S-curved tube + elongated head with
## eyes + forked tongue. Pure GDScript, no assets. <2k tris per snake.
## Usage: SnakesSnakeBuilder.build_snake(root, head_pos, tail_pos, head_cell_id)

const SIDES := 12
const MIN_Y := 0.22


static func build_snake(parent: Node3D, head_pos: Vector3, tail_pos: Vector3, variant_seed: int) -> Node3D:
	var rng := rng_for_seed(variant_seed)
	var pal := _palette_for(variant_seed)

	var root := Node3D.new()
	root.name = "Snake_%d" % variant_seed
	parent.add_child(root)

	var points := _sample_centerline(tail_pos, head_pos, rng)
	var segs: int = points.size() - 1
	var frames := _compute_frames(points)
	# Wide bands read at gameplay distance; thin stripes turn to noise.
	var band_count: int = clampi(int(tail_pos.distance_to(head_pos) * 0.9), 5, 9)

	_build_body(root, points, frames[0], frames[1], band_count, segs, pal)
	_build_head(root, head_pos, frames[2][frames[2].size() - 1], pal)
	return root


## Deterministic RNG per snake so the same seed always winds the same coils.
static func rng_for_seed(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(seed_value) * 100003 + 17
	return rng


static func _palette_for(seed_value: int) -> Dictionary:
	# Deep jewel-tone bodies: horizontal flanks eat ~0.5 warm horizon ambient,
	# so backs need one LOW channel to survive. Heads/brows unchanged (proven).
	match absi(seed_value) % 4:
		0: # emerald cobra
			return {"back": Color("0a5c2a"), "alt": Color("03170b"),
				"belly": Color("ccd9a8"), "head": Color("189a4a"), "brow": Color("0a3d22")}
		1: # golden python
			return {"back": Color("8a5f0e"), "alt": Color("2a1c04"),
				"belly": Color("e3cfa0"), "head": Color("b8891f"), "brow": Color("4a3208")}
		2: # crimson viper
			return {"back": Color("7d121c"), "alt": Color("200508"),
				"belly": Color("dba897"), "head": Color("9c1b26"), "brow": Color("33080d")}
		_: # azure constrictor
			return {"back": Color("1d4696"), "alt": Color("081426"),
				"belly": Color("b3c2dd"), "head": Color("3360b8"), "brow": Color("12233f")}
	return {}


## Base tube radius at centerline param t (0 = tail tip, 1 = neck).
## `girth` slims (<1) or fattens (>1) the whole body for snake variety.
## `bulge_t`/`bulge_size` add a digest lump travelling neck -> tail; the
## rings stay circular and UVs untouched, so texture/shape never break.
static func _radius_at(t: float, girth: float = 1.0, bulge_t: float = -1.0, bulge_size: float = 0.0) -> float:
	var grow: float = smoothstep(0.0, 0.35, t)
	var shrink: float = 1.0 - 0.35 * smoothstep(0.55, 1.0, t)
	var r: float = (0.04 + 0.24 * grow) * shrink * maxf(girth, 0.1)
	if bulge_size > 0.0 and bulge_t >= 0.0 and bulge_t <= 1.0:
		var d: float = (t - bulge_t) / 0.08
		r += bulge_size * exp(-d * d)
	return r


## `length_scale` winds the S-coils wider/taller: 1.0 is the classic
## portal snake, >1 a longer winding body between the same endpoints
## (for bigger snakes on the board), <1 a shorter, straighter one.
## `girth` is threaded through only for the ground-clearance clamp.
## `force_segs` freezes tessellation across rebuilds (the flex rig sets it
## once from the rest pose so lunges never pop the vertex count).
static func _sample_centerline(tail_pos: Vector3, head_pos: Vector3, rng: RandomNumberGenerator,
		length_scale: float = 1.0, girth: float = 1.0, force_segs: int = -1) -> Array[Vector3]:
	var dist: float = maxf(tail_pos.distance_to(head_pos), 0.5)
	var segs: int = force_segs if force_segs > 0 else clampi(int(dist * 6.0) + 20, 24, 44)
	var straight: Vector3 = (head_pos - tail_pos) / maxf(tail_pos.distance_to(head_pos), 0.001)
	var perp := Vector3(-straight.z, 0.0, straight.x)
	if perp.length() < 0.01:
		perp = Vector3.RIGHT
	else:
		perp = perp.normalized()
	var coils: float = 1.5 + rng.randf() * 1.0
	var phase: float = rng.randf() * TAU
	var phase2: float = rng.randf() * TAU
	var wind: float = maxf(length_scale, 0.2)
	var amp: float = clampf(dist * 0.09, 0.20, 0.50) * wind
	var amp2: float = amp * 0.35
	var arch: float = clampf(dist * 0.14, 0.45, 1.2) * lerpf(1.0, wind, 0.5)
	var pts: Array[Vector3] = []
	for i in range(segs + 1):
		var t: float = float(i) / float(segs)
		var envelope: float = sin(t * PI)
		var lateral: float = (sin(t * TAU * coils + phase) * amp \
			+ sin(t * TAU * coils * 2.3 + phase2) * amp2) * envelope
		var base: Vector3 = tail_pos.lerp(head_pos, t)
		var h: float = sin(t * PI) * arch \
			+ smoothstep(0.75, 1.0, t) * 0.35 \
			+ sin(t * TAU * coils + phase) * 0.06 * envelope
		var p: Vector3 = base + perp * lateral
		p.y = maxf(base.y + h, MIN_Y + _radius_at(t, girth))
		pts.append(p)
	return pts


static func _compute_frames(points: Array[Vector3]) -> Array:
	# Parallel-transport frames: no Frenet twist flips on near-straight spans.
	var n: int = points.size()
	var tangents: Array[Vector3] = []
	for i in range(n):
		if i == 0:
			tangents.append((points[1] - points[0]).normalized())
		elif i == n - 1:
			tangents.append((points[n - 1] - points[n - 2]).normalized())
		else:
			tangents.append((points[i + 1] - points[i - 1]).normalized())
	var ref := Vector3.UP
	if absf(tangents[0].dot(Vector3.UP)) > 0.9:
		ref = Vector3.RIGHT
	var n0: Vector3 = (ref - tangents[0] * ref.dot(tangents[0])).normalized()
	var normals: Array[Vector3] = [n0]
	var binormals: Array[Vector3] = [tangents[0].cross(n0).normalized()]
	for i in range(1, n):
		var t: Vector3 = tangents[i]
		var prev: Vector3 = normals[i - 1]
		var nn: Vector3 = prev - t * prev.dot(t)
		if nn.length() < 0.00001:
			var r := Vector3.UP
			if absf(t.dot(Vector3.UP)) > 0.9:
				r = Vector3.RIGHT
			nn = r - t * r.dot(t)
		nn = nn.normalized()
		normals.append(nn)
		binormals.append(t.cross(nn).normalized())
	return [normals, binormals, tangents]


static func _body_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	# Vertex colors are authored as sRGB hexes; without this flag the renderer
	# reads them as linear (much brighter) and mid-tone snakes wash to white.
	# (Pure primaries survive either way, which made this maddening to find.)
	m.vertex_color_is_srgb = true
	m.albedo_color = Color("ffffff")
	m.roughness = 0.38
	m.metallic = 0.0
	m.metallic_specular = 0.55
	m.rim_enabled = true
	m.rim = 0.15
	m.rim_tint = 0.6
	return m


static func _flat_mat(c: Color, rough: float = 0.6, emission: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emission
	return m


static func _build_body(root: Node3D, points: Array[Vector3], normals: Array,
		binormals: Array, band_count: int, segs: int, pal: Dictionary) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = body_mesh_for(points, normals, binormals, band_count, segs, pal)
	mi.material_override = _body_mat()
	root.add_child(mi)


## Tube mesh for the given centerline. Rebuild-safe: identical inputs give
## an identical mesh, and girth/bulge only change ring radii — vertex
## COLOR/UV layout is untouched, so digest/strike rebuilds never tear the
## pattern or the silhouette into non-circular rings.
static func body_mesh_for(points: Array[Vector3], normals: Array,
		binormals: Array, band_count: int, segs: int, pal: Dictionary,
		girth: float = 1.0, bulge_t: float = -1.0, bulge_size: float = 0.0) -> ArrayMesh:
	var back: Color = pal["back"]
	var alt: Color = pal["alt"]
	var belly: Color = pal["belly"]
	# Raw arrays (NOT SurfaceTool): this path provably renders vertex colors.
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var uvs := PackedVector2Array()
	for i in range(segs + 1):
		var t: float = float(i) / float(segs)
		var r: float = _radius_at(t, girth, bulge_t, bulge_size)
		for j in range(SIDES):
			var theta: float = TAU * float(j) / float(SIDES)
			var ring_dir: Vector3 = normals[i] * cos(theta) + binormals[i] * sin(theta)
			verts.append(points[i] + ring_dir * r)
			norms.append(ring_dir)
			uvs.append(Vector2(t * band_count, float(j) / float(SIDES)))
			var diag: float = fposmod(t * band_count + float(j) / float(SIDES), 2.0)
			var pattern: Color = back if diag < 1.0 else alt
			# Pattern covers top AND flanks (what the 3/4 camera sees);
			# pale belly shows only underneath.
			var back_w: float = smoothstep(-0.55, 0.05, ring_dir.dot(Vector3.UP))
			cols.append(belly.lerp(pattern, back_w))
	var idx := PackedInt32Array()
	for i in range(segs):
		for j in range(SIDES):
			var a: int = i * SIDES + j
			var b: int = i * SIDES + (j + 1) % SIDES
			var c: int = (i + 1) * SIDES + j
			var d: int = (i + 1) * SIDES + (j + 1) % SIDES
			idx.append_array([a, b, c, b, d, c])
	# End caps (tail tip is sub-pixel; neck cap hides inside the cranium).
	var tail_tan: Vector3 = (points[1] - points[0]).normalized()
	var neck_tan: Vector3 = (points[points.size() - 1] - points[points.size() - 2]).normalized()
	var tail_idx: int = verts.size()
	verts.append(points[0] - tail_tan * 0.03)
	norms.append(-tail_tan)
	cols.append(belly.darkened(0.1))
	uvs.append(Vector2.ZERO)
	var neck_idx: int = verts.size()
	verts.append(points[points.size() - 1] + neck_tan * 0.02)
	norms.append(neck_tan)
	cols.append(belly.darkened(0.05))
	uvs.append(Vector2.ONE)
	for j in range(SIDES):
		var a0: int = j
		var b0: int = (j + 1) % SIDES
		idx.append_array([tail_idx, b0, a0])
		var a1: int = segs * SIDES + j
		var b1: int = segs * SIDES + (j + 1) % SIDES
		idx.append_array([neck_idx, a1, b1])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _sphere(parent: Node3D, radius: float, height: float, pos: Vector3,
		scl: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = height
	sm.radial_segments = 16
	sm.rings = 8
	mi.mesh = sm
	mi.position = pos
	mi.scale = scl
	if mat != null:
		mi.material_override = mat
	parent.add_child(mi)
	return mi


## Head frame for a head position + arrival tangent. The rig re-applies
## this every rebuild so the skull tracks lunges without rebuilding geometry.
static func head_transform_for(head_pos: Vector3, arrival: Vector3) -> Transform3D:
	# Face outward from board centre, blended with arrival tangent, tilted up.
	var outward := Vector3(head_pos.x, 0.0, head_pos.z)
	if outward.length() < 0.05:
		outward = Vector3(0.0, 0.0, -1.0)
	else:
		outward = outward.normalized()
	var flat := Vector3(arrival.x, 0.0, arrival.z)
	if flat.length() < 0.01:
		flat = outward
	else:
		flat = flat.normalized()
	var fwd: Vector3 = (outward * 0.65 + flat * 0.35 + Vector3.UP * 0.30).normalized()
	var z_axis: Vector3 = -fwd
	var x_axis: Vector3 = Vector3.UP.cross(z_axis)
	if x_axis.length() < 0.01:
		x_axis = Vector3.RIGHT
	x_axis = x_axis.normalized()
	var y_axis: Vector3 = z_axis.cross(x_axis).normalized()
	return Transform3D(Basis(x_axis, y_axis, z_axis),
		head_pos + fwd * 0.22 + Vector3.UP * 0.16)


static func _build_head(root: Node3D, head_pos: Vector3, arrival: Vector3, pal: Dictionary) -> void:
	var head_node := Node3D.new()
	head_node.name = "Head"
	root.add_child(head_node)
	head_node.transform = head_transform_for(head_pos, arrival)

	var head_mat := _flat_mat(pal["head"], 0.35)
	var brow_mat := _flat_mat(pal["brow"], 0.6)
	# Cranium elongated along local Z + tapered snout overlapping it.
	_sphere(head_node, 0.24, 0.48, Vector3.ZERO, Vector3(1.0, 0.82, 1.35), head_mat)
	_sphere(head_node, 0.15, 0.30, Vector3(0.0, -0.02, -0.28),
		Vector3(0.85, 0.65, 1.2), head_mat)
	# Brow ridges just above the eyes.
	_sphere(head_node, 0.08, 0.16, Vector3(-0.15, 0.21, -0.13),
		Vector3(1.3, 0.45, 1.1), brow_mat)
	_sphere(head_node, 0.08, 0.16, Vector3(0.15, 0.21, -0.13),
		Vector3(1.3, 0.45, 1.1), brow_mat)
	# Eyes proud of the skull surface; pupils on the eyeball surface.
	var white := _flat_mat(Color.WHITE, 0.2)
	var black := _flat_mat(Color("0a0a0a"), 0.15)
	for side in [-1.0, 1.0]:
		var eye_pos := Vector3(side * 0.15, 0.13, -0.16)
		_sphere(head_node, 0.07, 0.14, eye_pos, Vector3.ONE, white)
		_sphere(head_node, 0.032, 0.064,
			eye_pos + Vector3(side * 0.035, 0.015, -0.045), Vector3.ONE, black)
	# Forked tongue: base + two prongs yawed ±14°.
	var tongue := _flat_mat(Color("c02020"), 0.4, 0.3)
	var base := MeshInstance3D.new()
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(0.05, 0.015, 0.18)
	base.mesh = base_mesh
	base.position = Vector3(0.0, -0.04, -0.48)
	base.material_override = tongue
	head_node.add_child(base)
	for side in [-1.0, 1.0]:
		var prong := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.022, 0.012, 0.20)
		prong.mesh = pm
		prong.position = Vector3(side * 0.028, -0.045, -0.63)
		prong.rotation.y = side * deg_to_rad(14.0)
		prong.rotation.x = deg_to_rad(4.0)
		prong.material_override = tongue
		head_node.add_child(prong)
