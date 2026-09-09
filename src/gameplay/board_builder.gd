class_name SnakesBoardBuilder
extends RefCounted
## Procedural premium 3D S&L board. Thin-tscn + RefCounted builder.
## Builds: walnut table + felt inlay, wood slab, 100 bevel tiles with corner
## accents + crisp numbers, wood frame with gold trim, curved snakes with
## heads/eyes/tongues, arched wooden ladders, staging pads, dice tray.

const FIELD_HALF := 8.0
const BASE_SIZE := 1.48
const BASE_H := 0.10
const BASE_Y := 0.05
const PLATE_SIZE := 1.32
const PLATE_H := 0.04
const PLATE_Y := 0.115
const PLATE_TOP := 0.135

var tile_nodes: Dictionary = {}
var snake_nodes: Array[Node3D] = []
var ladder_nodes: Array[Node3D] = []
## Head cell -> SnakesFlexSnake rig (for strike/digest presentation).
var snake_rigs: Dictionary = {}
var tile_mats: Array[StandardMaterial3D] = []
var tray_center := SnakesDiceTray.TRAY_POS

# Step-farm terrace knobs (mesh blueprint level; texturing comes later).
# terrace_step: rise between adjacent 10-cell bands. terrace_master: the
# master control knob (0 = flat classic board, 1 = full terraces).
var terrace_step: float = SnakesBoardStyle.TERRACE_STEP
var terrace_master: float = SnakesBoardStyle.TERRACE_MASTER


## Set both terrace knobs; publishes to SnakesBoardStyle actives so
## token_anchor / PathData.anchor_for agree with the built geometry.
func set_terrace(step: float, master: float) -> void:
	terrace_step = maxf(step, 0.0)
	terrace_master = clampf(master, 0.0, 2.0)
	SnakesBoardStyle.set_active_terrace(terrace_step, terrace_master)


func effective_terrace_step() -> float:
	return terrace_step * terrace_master


func terrace_y_for_cell(cell: int) -> float:
	return SnakesBoardStyle.terrace_y_for_cell(cell, terrace_step, terrace_master)


func tile_top_for_cell(cell: int) -> Vector3:
	var g := SnakesPathData.cell_to_grid(cell)
	var w := SnakesPathData.grid_to_world(g.x, g.y)
	w.y = SnakesBoardStyle.TILE_TOP + terrace_y_for_cell(cell)
	return w


static func glow_mat(c: Color, energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = energy > 0.0
	m.emission = c
	m.emission_energy_multiplier = energy
	m.roughness = 0.85
	return m


static func flat_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m


static func prem_mat(c: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	if mat != null:
		mi.material_override = mat
	parent.add_child(mi)
	return mi


func build_atmosphere(root: Node3D) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("2b3450")
	sm.sky_horizon_color = Color("e8c9a0")
	sm.sky_curve = 0.12
	sm.sky_energy_multiplier = 0.9
	sm.ground_bottom_color = Color("1a1210")
	sm.ground_horizon_color = Color("5a4636")
	sm.ground_curve = 0.12
	sm.ground_energy_multiplier = 0.6
	sky.sky_material = sm
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.55
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 1.05
	e.glow_enabled = true
	e.glow_intensity = 0.35
	e.glow_strength = 0.85
	e.glow_bloom = 0.05
	e.glow_hdr_threshold = 1.1
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	e.ssao_enabled = true
	e.ssao_radius = 0.6
	e.ssao_intensity = 0.35
	e.ssao_power = 0.9
	e.ssao_detail = 0.6
	e.ssao_horizon = 0.06
	e.ssao_sharpness = 0.98
	e.ssao_light_affect = 0.35
	e.fog_enabled = true
	e.fog_mode = Environment.FOG_MODE_DEPTH
	e.fog_light_color = Color("d9c2a3")
	e.fog_density = 0.008
	e.fog_depth_begin = 30.0
	e.fog_depth_end = 90.0
	e.fog_sky_affect = 0.3
	env.environment = e
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -32, 0)
	sun.light_color = Color("fff0da")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 45.0
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 0.9
	sun.shadow_reverse_cull_face = true
	sun.shadow_blur = 1.5
	sun.shadow_opacity = 0.38
	root.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-28, 148, 0)
	fill.light_color = Color("bfd4ff")
	fill.light_energy = 0.32
	fill.shadow_enabled = false
	root.add_child(fill)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-18, -145, 0)
	rim.light_color = Color("ffd9b0")
	rim.light_energy = 0.18
	rim.shadow_enabled = false
	root.add_child(rim)


func build_dressing(root: Node3D) -> void:
	# Infinite walnut table.
	var table := MeshInstance3D.new()
	var t := CylinderMesh.new()
	t.top_radius = 34.0
	t.bottom_radius = 34.0
	t.height = 0.1
	t.radial_segments = 64
	table.mesh = t
	table.position = Vector3(2.0, -0.58, 1.0)
	var tm := prem_mat(Color("4a3423"), 0.72)
	table.material_override = tm
	root.add_child(table)
	# Teal felt inlay under board + tray + staging.
	var felt := MeshInstance3D.new()
	var f := CylinderMesh.new()
	f.top_radius = 14.5
	f.bottom_radius = 14.8
	f.height = 0.12
	f.radial_segments = 64
	felt.mesh = f
	felt.position = Vector3(2.0, -0.48, 1.0)
	felt.scale = Vector3(1.15, 1.0, 0.92)
	var fm := prem_mat(Color("2e6b5e"), 1.0)
	felt.material_override = fm
	root.add_child(felt)


func _plate_mats() -> Dictionary:
	return {
		"light": prem_mat(Color("f6eed6"), 0.55),
		"dark": prem_mat(Color("dec795"), 0.62),
		"light_base": prem_mat(Color("b39a68"), 0.75),
		"dark_base": prem_mat(Color("a08454"), 0.75),
		"start": prem_mat(Color("1f8a4c"), 0.5),
		"start_base": prem_mat(Color("14532b"), 0.7),
		"finish": prem_mat(Color("d4af37"), 0.32, 0.65),
		"finish_base": prem_mat(Color("7a5c14"), 0.6),
		"snake": prem_mat(Color("c0392b"), 0.6),
		"ladder": prem_mat(Color("27ae60"), 0.6),
	}


func build_board(root: Node3D, snakes: Dictionary, ladders: Dictionary) -> void:
	# Publish knobs first so every anchor below agrees with the geometry.
	SnakesBoardStyle.set_active_terrace(terrace_step, terrace_master)
	# Single wood slab, top just below tile bottoms (no floating gap, no overlap).
	_box(root, Vector3(19.6, 0.7, 19.6), Vector3(0, -0.355, 0), prem_mat(Color("5d4037"), 0.7))
	_build_terrace_bodies(root)
	var mats := _plate_mats()
	tile_mats = [mats["light"], mats["dark"]]
	for cell in range(1, 101):
		var g := SnakesPathData.cell_to_grid(cell)
		var w := SnakesPathData.grid_to_world(g.x, g.y)
		var lift := terrace_y_for_cell(cell)
		var is_light: bool = (g.x + g.y) % 2 == 0
		var is_start: bool = cell == 1
		var is_finish: bool = cell == 100
		var plate_mat: Material = mats["light"] if is_light else mats["dark"]
		var base_mat: Material = mats["light_base"] if is_light else mats["dark_base"]
		if is_start:
			plate_mat = mats["start"]
			base_mat = mats["start_base"]
		elif is_finish:
			plate_mat = mats["finish"]
			base_mat = mats["finish_base"]
		_box(root, Vector3(BASE_SIZE, BASE_H, BASE_SIZE), Vector3(w.x, BASE_Y + lift, w.z), base_mat)
		var plate := _box(root, Vector3(PLATE_SIZE, PLATE_H, PLATE_SIZE), Vector3(w.x, PLATE_Y + lift, w.z), plate_mat)
		tile_nodes[cell] = plate
		var top := Vector3(w.x, PLATE_TOP + lift, w.z)
		if snakes.has(cell) and not is_start and not is_finish:
			_corner_wedge(root, top, 0, mats["snake"])
		if ladders.has(cell) and not is_start and not is_finish:
			_corner_wedge(root, top, 2, mats["ladder"])
		if is_start:
			_start_ring(root, top)
		if is_finish:
			_finish_checker(root, top)
		_tile_number(root, cell, top, is_start or is_finish)
	_build_frame(root)
	_build_staging_pads(root)
	_build_snakes(root, snakes)
	_build_ladders(root, ladders)
	SnakesDiceTray.build(root, tray_center)


# Step-farm bodies: one soil retaining box per raised row-band so no tile
# floats. Band k == board row (terrace 0 = cells 1-10 at the front, terrace
# 9 = cells 91-100 at the back). Mesh-only pass; texturing comes later.
func _build_terrace_bodies(root: Node3D) -> void:
	var eff := effective_terrace_step()
	if eff < 0.01:
		return
	var soil_a := prem_mat(Color("6b5a3e"), 0.85)
	var soil_b := prem_mat(Color("5d4f36"), 0.85)
	# Grass rim: each step edge reads as a farmed terrace lip.
	var lip := prem_mat(Color("4d7a35"), 0.9)
	for band in range(1, SnakesBoardStyle.TERRACE_COUNT):
		var lift: float = float(band) * eff
		var row_from_top: int = 9 - band
		var z: float = (float(row_from_top) - 4.5) * SnakesPathData.CELL
		var soil: Material = soil_a if band % 2 == 0 else soil_b
		# Retaining wall: top meets the tile-base bottoms, foot sunk in slab.
		_box(root, Vector3(16.0, lift + 0.1, SnakesPathData.CELL),
			Vector3(0, (lift - 0.1) * 0.5, z), soil)
		# Thin lip at the riser top edge so each step reads at a glance.
		_box(root, Vector3(16.0, 0.06, 0.12),
			Vector3(0, lift - 0.01, z + SnakesPathData.CELL * 0.5 - 0.06), lip)


# Thin triangular corner decal: 3-sided cylinder, bottom embedded in plate.
func _corner_wedge(parent: Node3D, tile_top: Vector3, corner_idx: int, mat: Material) -> void:
	var leg := 0.42
	var cyl := CylinderMesh.new()
	cyl.top_radius = leg
	cyl.bottom_radius = leg
	cyl.height = 0.014
	cyl.radial_segments = 3
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	# idx: 0 NE(+x,-z) 1 NW(-x,-z) 2 SW(-x,+z) 3 SE(+x,+z)
	var ix := 0.38
	var iz := 0.38
	var ox: float = ix if corner_idx == 0 or corner_idx == 3 else -ix
	var oz: float = -iz if corner_idx == 0 or corner_idx == 1 else iz
	mi.position = tile_top + Vector3(ox, 0.009, oz)
	mi.rotation_degrees = Vector3(0, 45.0 + float(corner_idx) * 90.0, 0)
	mi.material_override = mat
	parent.add_child(mi)


func _start_ring(parent: Node3D, tile_top: Vector3) -> void:
	var t := TorusMesh.new()
	t.inner_radius = 0.44
	t.outer_radius = 0.52
	t.rings = 48
	t.ring_segments = 12
	var mi := MeshInstance3D.new()
	mi.mesh = t
	mi.position = tile_top + Vector3(0, 0.008, 0)
	mi.material_override = prem_mat(Color("d4af37"), 0.3, 0.8)
	parent.add_child(mi)


func _finish_checker(parent: Node3D, tile_top: Vector3) -> void:
	var black := prem_mat(Color("1b1b1b"), 0.5)
	var white := prem_mat(Color("fafafa"), 0.5)
	var s := 0.16
	for j in range(2):
		for i in range(8):
			var m: Material = black if (i + j) % 2 == 0 else white
			var px: float = tile_top.x - 0.6125 + float(i) * 0.175
			var pz: float = tile_top.z - 0.50 + float(j) * 0.16
			_box(parent, Vector3(s, 0.008, s), Vector3(px, tile_top.y + 0.006, pz), m)


func _tile_number(parent: Node3D, cell: int, tile_top: Vector3, light_text: bool) -> void:
	var label := Label3D.new()
	label.text = str(cell)
	label.font_size = 96
	label.pixel_size = 0.0025
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.shaded = false
	label.double_sided = true
	label.no_depth_test = false
	label.fixed_size = false
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if light_text:
		label.modulate = Color("ffffff")
		label.outline_size = 24
		label.outline_modulate = Color("3a2a12")
	else:
		label.modulate = Color("4a3220")
		label.outline_size = 12
		label.outline_modulate = Color("f6eed6")
	label.position = tile_top + Vector3(-0.60, 0.012, 0.52)
	label.rotation_degrees = Vector3(-90, 0, 0)
	parent.add_child(label)


func _build_frame(root: Node3D) -> void:
	var wood := prem_mat(Color("6b4a2f"), 0.6)
	var post_m := prem_mat(Color("4e342e"), 0.65)
	var gold := prem_mat(Color("d4af37"), 0.3, 0.8)
	var rail_w := 0.9
	var rail_h := 0.36
	var rail_y := 0.08
	var rc: float = FIELD_HALF + rail_w * 0.5
	var long_len: float = FIELD_HALF * 2.0 + rail_w * 2.0
	var short_len: float = FIELD_HALF * 2.0
	_box(root, Vector3(long_len, rail_h, rail_w), Vector3(0, rail_y, -rc), wood)
	_box(root, Vector3(long_len, rail_h, rail_w), Vector3(0, rail_y, rc), wood)
	_box(root, Vector3(rail_w, rail_h, short_len), Vector3(-rc, rail_y, 0), wood)
	_box(root, Vector3(rail_w, rail_h, short_len), Vector3(rc, rail_y, 0), wood)
	var trim_w := 0.14
	var trim_y := 0.17
	var tc: float = FIELD_HALF + trim_w * 0.5 + 0.02
	var tl: float = FIELD_HALF * 2.0 + 0.04
	_box(root, Vector3(tl, 0.06, trim_w), Vector3(0, trim_y, -tc), gold)
	_box(root, Vector3(tl, 0.06, trim_w), Vector3(0, trim_y, tc), gold)
	_box(root, Vector3(trim_w, 0.06, tl), Vector3(-tc, trim_y, 0), gold)
	_box(root, Vector3(trim_w, 0.06, tl), Vector3(tc, trim_y, 0), gold)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(root, Vector3(0.7, 0.7, 0.7), Vector3(sx * rc, 0.15, sz * rc), post_m)
			var ball := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.28
			sm.height = 0.56
			sm.radial_segments = 24
			sm.rings = 16
			ball.mesh = sm
			ball.position = Vector3(sx * rc, 0.72, sz * rc)
			ball.material_override = gold
			root.add_child(ball)


func _build_staging_pads(root: Node3D) -> void:
	var pad_mat := prem_mat(Color("6b4a2f"), 0.6)
	var trim := prem_mat(Color("d4af37"), 0.35, 0.7)
	for seat in range(4):
		var a := SnakesSlotter.offboard_anchor(seat)
		var pad := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.55
		cyl.bottom_radius = 0.6
		cyl.height = 0.14
		cyl.radial_segments = 32
		pad.mesh = cyl
		pad.position = Vector3(a.x, 0.065, a.z)
		pad.material_override = pad_mat
		root.add_child(pad)
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.5
		tm.outer_radius = 0.58
		tm.rings = 40
		tm.ring_segments = 10
		ring.mesh = tm
		ring.position = Vector3(a.x, 0.135, a.z)
		ring.material_override = trim
		root.add_child(ring)


func _tube_between(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material) -> void:
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


func _build_snakes(root: Node3D, snakes: Dictionary) -> void:
	snake_rigs.clear()
	for head in snakes:
		var head_id: int = int(head)
		var tail: int = int(snakes[head])
		var a := SnakesPathData.anchor_for_terraced(head_id, terrace_step, terrace_master) + Vector3(0, 0.15, 0)
		var b := SnakesPathData.anchor_for_terraced(tail, terrace_step, terrace_master) + Vector3(0, 0.10, 0)
		# Bigger drops get bigger snakes: girth 0.8..1.6, length 0.7..1.7.
		var frac := clampf(float(head_id - tail) / 60.0, 0.0, 1.0)
		var rig := SnakesFlexSnake.new()
		rig.girth_scale = 0.8 + 0.8 * frac
		rig.length_scale = 0.7 + 1.0 * frac
		rig.head_cell = head_id
		root.add_child(rig)
		rig.setup(b, a, head_id)
		if root.is_inside_tree():
			rig.add_to_group("snakes_flex")
		snake_nodes.append(rig)
		snake_rigs[head_id] = rig


func _build_ladders(root: Node3D, ladders: Dictionary) -> void:
	for foot in ladders:
		var node := build_ladder(root,
			SnakesPathData.anchor_for_terraced(int(foot), terrace_step, terrace_master),
			SnakesPathData.anchor_for_terraced(int(ladders[foot]), terrace_step, terrace_master))
		ladder_nodes.append(node)


## Straight portal ladder between two tile-top points. Thin wrapper over
## SnakesLadderBuilder (the element blueprint); kept so existing callers
## keep working while the mesh/physics contract lives in one place.
static func build_ladder(parent: Node3D, foot_pos: Vector3, top_pos: Vector3) -> Node3D:
	return SnakesLadderBuilder.build_straight_ladder(parent, foot_pos, top_pos)


## Single source of world positions for tokens (mirrors Ludo's anchor_for).
## Reads the live terrace knobs (see set_terrace / BoardStyle actives) so
## tokens sit on the lifted plates of the last built board.
static func token_anchor(cell: int, slot: int = 0, slots_total: int = 1) -> Vector3:
	var base := SnakesPathData.anchor_for(cell)
	if slots_total <= 1:
		return base
	var off := SnakesSlotter.disc_offset(slot, slots_total)
	return base + Vector3(off.x, 0.0, off.y)


## Explicit-knob variant for previews / tests that must not touch the actives.
static func token_anchor_terraced(cell: int, slot: int = 0, slots_total: int = 1, step: float = -1.0, master: float = -1.0) -> Vector3:
	var base := SnakesPathData.anchor_for_terraced(cell,
		SnakesBoardStyle.active_step if step < 0.0 else step,
		SnakesBoardStyle.active_master if master < 0.0 else master)
	if slots_total <= 1:
		return base
	var off := SnakesSlotter.disc_offset(slot, slots_total)
	return base + Vector3(off.x, 0.0, off.y)
