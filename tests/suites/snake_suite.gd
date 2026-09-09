class_name SnakesSnakeSuite
extends RefCounted
## Flex-snake blueprint tests: girth/length knobs, strike lunge, digest
## travel — all without breaking UVs or ring topology. Headless-safe:
## rigs are built under no tree, tweens are never played.

static var failures: int = 0


static func check(cond: bool, name: String) -> void:
	if cond:
		print("  ok: ", name)
	else:
		failures += 1
		printerr("  FAIL: ", name)


static func _make(seed: int, girth: float, length: float) -> SnakesFlexSnake:
	var s := SnakesFlexSnake.new()
	s.girth_scale = girth
	s.length_scale = length
	s.setup(Vector3(0, 0.3, 0), Vector3(0, 0.5, 3.0), seed)
	return s


static func _arrays(s: SnakesFlexSnake) -> Array:
	return s.body_mesh().surface_get_arrays(0)


static func run() -> bool:
	failures = 0
	print("[snake] girth knob slims/fattens, topology preserved")
	var slim := _make(87, 0.5, 1.0)
	var fat := _make(87, 2.0, 1.0)
	var slim_box := slim.body_mesh().get_aabb()
	var fat_box := fat.body_mesh().get_aabb()
	check(fat_box.size.x > slim_box.size.x * 1.5, "fat body wider than slim")
	check(fat_box.size.y > slim_box.size.y * 1.2, "fat body taller than slim")
	var sa := _arrays(slim)
	var fa := _arrays(fat)
	check((sa[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() == (fa[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), "girth keeps vertex count")
	check((sa[Mesh.ARRAY_INDEX] as PackedInt32Array).size() == (fa[Mesh.ARRAY_INDEX] as PackedInt32Array).size(), "girth keeps index count")
	check((sa[Mesh.ARRAY_TEX_UV] as PackedVector2Array) == (fa[Mesh.ARRAY_TEX_UV] as PackedVector2Array), "girth keeps UVs (texture unbroken)")
	slim.free()
	fat.free()

	print("[snake] length knob winds/unwinds the coils")
	var short := _make(87, 1.0, 0.4)
	var long := _make(87, 1.0, 2.0)
	check(long.centerline_length() > short.centerline_length() * 1.1, "long coils measure longer")
	var la := _arrays(long)
	var ha := _arrays(short)
	check((la[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() == (ha[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), "length keeps vertex count")
	check((la[Mesh.ARRAY_TEX_UV] as PackedVector2Array) == (ha[Mesh.ARRAY_TEX_UV] as PackedVector2Array), "length keeps UVs")
	short.free()
	long.free()

	print("[snake] strike lunge stretches the body")
	var striker := _make(16, 1.0, 1.0)
	var rest_uv: PackedVector2Array = _arrays(striker)[Mesh.ARRAY_TEX_UV]
	var rest_count: int = (_arrays(striker)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var rest_head: Vector3 = striker.head_now()
	striker.set_lunge(Vector3(0, 0.2, 1.5))
	check(striker.head_now().is_equal_approx(rest_head + Vector3(0, 0.2, 1.5)), "head follows the lunge")
	check((_arrays(striker)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() == rest_count, "lunge keeps vertex count")
	check((_arrays(striker)[Mesh.ARRAY_TEX_UV] as PackedVector2Array) == rest_uv, "lunge keeps UVs (no texture tear)")
	var head_node := striker.get_node_or_null("Head") as Node3D
	check(head_node != null and head_node.position.distance_to(rest_head) > 0.5, "skull tracks the lunge")
	striker.free()

	print("[snake] digest lump travels neck -> tail")
	var base_r: float = SnakesSnakeBuilder._radius_at(0.9)
	var neck_r: float = SnakesSnakeBuilder._radius_at(0.9, 1.0, 0.9, 0.22)
	check(neck_r > base_r + 0.1, "lump swells the neck")
	var here: float = SnakesSnakeBuilder._radius_at(0.3, 1.0, 0.3, 0.22)
	var gone: float = SnakesSnakeBuilder._radius_at(0.3, 1.0, 0.9, 0.22)
	check(here > gone + 0.1, "lump peak follows its position")
	var eater := _make(49, 1.0, 1.0)
	var plain_verts: PackedVector3Array = _arrays(eater)[Mesh.ARRAY_VERTEX]
	var plain_count: int = plain_verts.size()
	var plain_uv: PackedVector2Array = _arrays(eater)[Mesh.ARRAY_TEX_UV]
	eater.set_digest(1.0, 0.22)
	var swollen_verts: PackedVector3Array = _arrays(eater)[Mesh.ARRAY_VERTEX]
	check(swollen_verts.size() == plain_count, "digest keeps vertex count")
	check((_arrays(eater)[Mesh.ARRAY_TEX_UV] as PackedVector2Array) == plain_uv, "digest keeps UVs")
	check(swollen_verts != plain_verts, "lump visibly swells the tube")
	eater.clear_digest()
	check((_arrays(eater)[Mesh.ARRAY_VERTEX] as PackedVector3Array) == plain_verts, "clearing digest restores the body exactly")
	eater.free()

	print("[snake] determinism + legacy board path")
	var a := _make(62, 1.3, 1.6)
	var b := _make(62, 1.3, 1.6)
	check((_arrays(a)[Mesh.ARRAY_VERTEX] as PackedVector3Array) == (_arrays(b)[Mesh.ARRAY_VERTEX] as PackedVector3Array), "same knobs rebuild identically")
	a.free()
	b.free()
	var host := Node3D.new()
	var legacy := SnakesSnakeBuilder.build_snake(host, Vector3(0, 0.5, 3.0), Vector3.ZERO, 16)
	check((legacy.get_node_or_null("Head") as Node3D) != null, "legacy portal snake keeps its head")
	host.free()

	print("[snake] board portals use sized rigs")
	var bhost := Node3D.new()
	var builder := SnakesBoardBuilder.new()
	builder.set_terrace(SnakesBoardStyle.TERRACE_STEP, SnakesBoardStyle.TERRACE_MASTER)
	var classic := SnakesPathData.snakes_for("classic_mb")
	builder._build_snakes(bhost, classic)
	check(builder.snake_rigs.size() == classic.size(), "one rig per snake head")
	var all_rigs := true
	var girths: Array[float] = []
	var lengths: Array[float] = []
	for head in classic:
		var rig: Variant = builder.snake_rigs.get(int(head), null)
		if not (rig is SnakesFlexSnake) or (rig as SnakesFlexSnake).head_cell != int(head):
			all_rigs = false
		else:
			girths.append((rig as SnakesFlexSnake).girth_scale)
			lengths.append((rig as SnakesFlexSnake).length_scale)
	check(all_rigs, "rigs carry their head cells")
	check(girths.min() < girths.max(), "bigger drops get fatter snakes")
	check(lengths.min() < lengths.max(), "bigger drops get longer snakes")
	builder._build_ladders(bhost, SnakesPathData.ladders_for("classic_mb"))
	check(builder.ladder_nodes.size() == 9, "classic ladders still build")
	bhost.free()

	print("[snake] failures: %d" % failures)
	return failures == 0
