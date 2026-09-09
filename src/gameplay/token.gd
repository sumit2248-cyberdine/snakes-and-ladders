class_name SnakesToken
extends Node3D
## Premium lathe pawn: base disc -> concave stem -> collar -> ball head.
## Only SnakesChoreographer (+ this script) animate token nodes.

const SEGS := 24
const HEAD_R := 0.19
const HEAD_Y := 0.90
# Lathe profile (r, y) bottom-to-top. Tops at 0.73; head ball tops at ~1.09.
const PROFILE := [
	Vector2(0.00, 0.00), Vector2(0.28, 0.00),
	Vector2(0.32, 0.02), Vector2(0.32, 0.05),
	Vector2(0.28, 0.09), Vector2(0.22, 0.13),
	Vector2(0.15, 0.18), Vector2(0.115, 0.28),
	Vector2(0.10, 0.38), Vector2(0.115, 0.48),
	Vector2(0.15, 0.56), Vector2(0.19, 0.60),
	Vector2(0.20, 0.63), Vector2(0.17, 0.67),
	Vector2(0.115, 0.70), Vector2(0.11, 0.73),
]

static var _blob_tex: Texture2D = null

var player: int = 0
var cell: int = 0
var ground_y: float = 0.14
var anim_lock: bool = false

var _head: MeshInstance3D
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _halo_energy: float = 0.0
var _halo_target: float = 0.0
var _bob_t: float = 0.0


func setup(p_player: int) -> void:
	player = p_player
	_build()


static func plastic(col: Color, rough: float, metallic: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = metallic
	m.metallic_specular = 0.6
	m.roughness = rough
	m.clearcoat_enabled = true
	m.clearcoat = 1.0
	m.clearcoat_roughness = 0.15
	return m


static func blob_texture() -> Texture2D:
	if _blob_tex != null:
		return _blob_tex
	var s := 128
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var c := Vector2(s, s) * 0.5
	for y in range(s):
		for x in range(s):
			var d := Vector2(x, y).distance_to(c) / (float(s) * 0.5)
			var a := clampf(1.0 - d * d, 0.0, 1.0)
			a = pow(a, 1.6) * 0.22
			img.set_pixel(x, y, Color(0, 0, 0, a))
	_blob_tex = ImageTexture.create_from_image(img)
	return _blob_tex


func _lathe_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := PROFILE.size()
	var pn: Array[Vector2] = []
	pn.resize(n)
	for i in range(n):
		var pa: Vector2 = PROFILE[maxi(i - 1, 0)]
		var pb: Vector2 = PROFILE[mini(i + 1, n - 1)]
		var t := pb - pa
		if t.length() < 0.00001:
			t = Vector2(0, 1)
		t = t.normalized()
		pn[i] = Vector2(t.y, -t.x)
	for i in range(n - 1):
		var r0: float = PROFILE[i].x
		var y0: float = PROFILE[i].y
		var r1: float = PROFILE[i + 1].x
		var y1: float = PROFILE[i + 1].y
		for s in range(SEGS):
			var a0 := TAU * float(s) / float(SEGS)
			var a1 := TAU * float(s + 1) / float(SEGS)
			var v00 := Vector3(r0 * cos(a0), y0, r0 * sin(a0))
			var v01 := Vector3(r0 * cos(a1), y0, r0 * sin(a1))
			var v10 := Vector3(r1 * cos(a0), y1, r1 * sin(a0))
			var v11 := Vector3(r1 * cos(a1), y1, r1 * sin(a1))
			var nv00 := Vector3(pn[i].x * cos(a0), pn[i].y, pn[i].x * sin(a0))
			var nv01 := Vector3(pn[i].x * cos(a1), pn[i].y, pn[i].x * sin(a1))
			var nv10 := Vector3(pn[i + 1].x * cos(a0), pn[i + 1].y, pn[i + 1].x * sin(a0))
			var nv11 := Vector3(pn[i + 1].x * cos(a1), pn[i + 1].y, pn[i + 1].x * sin(a1))
			var u0 := float(s) / float(SEGS)
			var u1 := float(s + 1) / float(SEGS)
			st.set_normal(nv00); st.set_uv(Vector2(u0, y0)); st.add_vertex(v00)
			st.set_normal(nv10); st.set_uv(Vector2(u0, y1)); st.add_vertex(v10)
			st.set_normal(nv11); st.set_uv(Vector2(u1, y1)); st.add_vertex(v11)
			st.set_normal(nv00); st.set_uv(Vector2(u0, y0)); st.add_vertex(v00)
			st.set_normal(nv11); st.set_uv(Vector2(u1, y1)); st.add_vertex(v11)
			st.set_normal(nv01); st.set_uv(Vector2(u1, y0)); st.add_vertex(v01)
	# Bottom cap fan (normal -Y), wound to face down.
	var rb: float = PROFILE[1].x
	var center := Vector3(0, 0, 0)
	for s in range(SEGS):
		var a0 := TAU * float(s) / float(SEGS)
		var a1 := TAU * float(s + 1) / float(SEGS)
		var v0 := Vector3(rb * cos(a0), 0, rb * sin(a0))
		var v1 := Vector3(rb * cos(a1), 0, rb * sin(a1))
		st.set_normal(Vector3.DOWN); st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(center)
		st.set_normal(Vector3.DOWN); st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(v1)
		st.set_normal(Vector3.DOWN); st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(v0)
	return st.commit()


func _build() -> void:
	var col: Color = SnakesPathData.PLAYER_COLORS[player]
	var body_mat := plastic(col, 0.3, 0.0)
	var body := MeshInstance3D.new()
	body.mesh = _lathe_mesh()
	body.material_override = body_mat
	add_child(body)
	_head = MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = HEAD_R
	hm.height = HEAD_R * 2.0
	hm.radial_segments = 32
	hm.rings = 16
	_head.mesh = hm
	_head.position = Vector3(0, HEAD_Y, 0)
	_head.material_override = body_mat
	add_child(_head)
	# White collar accent hugging the stem.
	var collar := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.13
	tm.outer_radius = 0.20
	tm.rings = 32
	tm.ring_segments = 16
	collar.mesh = tm
	collar.position = Vector3(0, 0.615, 0)
	collar.material_override = plastic(Color(0.95, 0.95, 0.97), 0.2, 0.0)
	add_child(collar)
	# Soft blob shadow just above the tile (no z-fight).
	var shadow := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.9, 0.9)
	shadow.mesh = quad
	shadow.rotation_degrees = Vector3(-90, 0, 0)
	shadow.position = Vector3(0, 0.035, 0)
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.albedo_color = Color(1, 1, 1, 1)
	smat.albedo_texture = blob_texture()
	smat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	smat.cull_mode = BaseMaterial3D.CULL_DISABLED
	smat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	smat.disable_fog = true
	shadow.material_override = smat
	add_child(shadow)
	# Selection ring: animate energy + scale only.
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_mat.albedo_color = Color(1, 1, 1, 0.9)
	_ring_mat.emission_enabled = true
	_ring_mat.emission = Color(1, 1, 1)
	_ring_mat.emission_energy_multiplier = 0.0
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.36
	torus.outer_radius = 0.46
	torus.rings = 40
	torus.ring_segments = 12
	_ring.mesh = torus
	_ring.position = Vector3(0, 0.10, 0)
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.material_override = _ring_mat
	add_child(_ring)
	# Pickable collider (layer 2, like Ludo).
	var pick := StaticBody3D.new()
	pick.collision_layer = 2
	pick.collision_mask = 0
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.42
	cap.height = 1.2
	shape.shape = cap
	shape.position = Vector3(0, 0.6, 0)
	pick.add_child(shape)
	pick.set_meta("token_ref", self)
	add_child(pick)


func _process(delta: float) -> void:
	_bob_t += delta
	_halo_energy = lerpf(_halo_energy, _halo_target, 1.0 - exp(-5.0 * delta))
	if _ring_mat != null:
		_ring_mat.emission_energy_multiplier = _halo_energy
	if _ring != null:
		if _halo_target > 0.05:
			var s := 1.0 + 0.05 * sin(_bob_t * 4.0)
			_ring.scale = Vector3(s, 1.0, s)
		else:
			_ring.scale = Vector3.ONE


func set_selectable(on: bool) -> void:
	_halo_target = 1.2 if on else 0.0


func set_selected(on: bool) -> void:
	_halo_target = 2.2 if on else 0.0


func set_halo_target(e: float) -> void:
	_halo_target = e


func snap_to(pos: Vector3) -> void:
	position = pos
	ground_y = pos.y


func face_towards(target: Vector3) -> void:
	var d: Vector3 = target - position
	d.y = 0.0
	if d.length() < 0.01:
		return
	rotation.y = atan2(d.x, d.z)


func squash() -> void:
	scale = Vector3(1.15, 0.8, 1.15)


func stretch_pop() -> void:
	scale = Vector3.ONE


func cheer() -> void:
	var tw := create_tween()
	tw.tween_property(self, "position:y", position.y + 0.5, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", ground_y, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
