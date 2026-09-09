class_name SnakesFX
extends Node3D
## Juice: landing dust puffs + win confetti. Called by the choreographer only.
## Particles free themselves via the `finished` signal (no orphan timers).

static var _pass_mesh: BoxMesh = null
static var _pass_mat: StandardMaterial3D = null


static func pass_mesh() -> BoxMesh:
	if _pass_mesh == null:
		_pass_mesh = BoxMesh.new()
		_pass_mesh.size = Vector3(0.09, 0.09, 0.02)
		_pass_mat = StandardMaterial3D.new()
		_pass_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_pass_mat.albedo_color = Color.WHITE
		_pass_mesh.surface_set_material(0, _pass_mat)
	return _pass_mesh


func dust(at: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.amount = 16
	p.lifetime = 0.7
	p.one_shot = true
	p.explosiveness = 0.72
	p.direction = Vector3.UP
	p.spread = 42.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.2
	p.gravity = Vector3(0, -1.2, 0)
	p.damping_min = 1.0
	p.damping_max = 2.0
	p.scale_amount_min = 0.3
	p.scale_amount_max = 0.6
	var g := Gradient.new()
	g.set_color(0, Color(1, 0.96, 0.86, 0.85))
	g.add_point(1.0, Color(1, 0.96, 0.86, 0.0))
	p.color_ramp = g
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.35
	p.visibility_aabb = AABB(Vector3(-4, -1, -4), Vector3(8, 6, 8))
	p.mesh = pass_mesh()
	add_child(p)
	p.position = at + Vector3(0, 0.18, 0)
	p.emitting = true
	p.finished.connect(p.queue_free)


func confetti(center: Vector3 = Vector3.ZERO) -> void:
	var cols := [Color("e53935"), Color("43a047"), Color("fdd835"), Color("1e88e5")]
	for i in 4:
		var p := CPUParticles3D.new()
		p.amount = 55
		p.lifetime = 1.9
		p.one_shot = true
		p.explosiveness = 0.8
		p.direction = Vector3.UP
		p.spread = 42.0
		p.initial_velocity_min = 3.5
		p.initial_velocity_max = 6.0
		p.gravity = Vector3(0, -7.5, 0)
		p.damping_min = 0.6
		p.damping_max = 1.4
		p.angle_min = -180.0
		p.angle_max = 180.0
		p.scale_amount_min = 0.5
		p.scale_amount_max = 1.0
		p.visibility_aabb = AABB(Vector3(-8, -1, -8), Vector3(16, 14, 16))
		# Per-emitter tinted mesh: particle COLOR does not reliably tint a
		# shared pass mesh, so each burst gets its own colored material.
		var quad := BoxMesh.new()
		quad.size = Vector3(0.09, 0.09, 0.02)
		var qm := StandardMaterial3D.new()
		qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		qm.albedo_color = cols[i % cols.size()]
		quad.surface_set_material(0, qm)
		p.mesh = quad
		add_child(p)
		p.position = center + Vector3(float(i) * 0.8 - 1.2, 2.2, 0)
		p.emitting = true
		p.finished.connect(p.queue_free)
