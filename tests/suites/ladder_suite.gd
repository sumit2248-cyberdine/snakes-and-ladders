class_name SnakesLadderSuite
extends RefCounted
## Straight-ladder blueprint tests: proportional rungs, adjustable height,
## solid-step colliders (no fall-through). Headless-safe: builds real nodes
## under throwaway parents, never added to the tree.

static var failures: int = 0


static func check(cond: bool, name: String) -> void:
	if cond:
		print("  ok: ", name)
	else:
		failures += 1
		printerr("  FAIL: ", name)


static func _step_centers(ladder: Node3D) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var body := ladder.get_node_or_null("StepsBody") as StaticBody3D
	if body == null:
		return out
	for child in body.get_children():
		if child is CollisionShape3D:
			out.append((child as CollisionShape3D).position)
	return out


static func run() -> bool:
	failures = 0
	print("[ladder] proportional rung counts")
	check(SnakesLadderBuilder.rung_count_for_height(0.0) == 2, "degenerate still gets 2 rungs")
	check(SnakesLadderBuilder.rung_count_for_height(0.4) == 2, "short ladder floors at 2")
	var short_c := SnakesLadderBuilder.rung_count_for_height(1.0)
	var tall_c := SnakesLadderBuilder.rung_count_for_height(8.0)
	check(tall_c > short_c, "taller ladder gets more rungs")
	check(short_c == maxi(2, int(floor(1.0 / SnakesLadderBuilder.RUNG_SPACING))), "count follows spacing")
	check(SnakesLadderBuilder.rung_count_for_height(2.0, 0.25) > SnakesLadderBuilder.rung_count_for_height(2.0, 0.5), "tighter spacing adds rungs")

	print("[ladder] straight portal build + solid steps")
	var host := Node3D.new()
	var foot := Vector3(0, 0.14, 7.2)
	var top := Vector3(3.2, 1.2, -4.8)
	var ladder := SnakesLadderBuilder.build_straight_ladder(host, foot, top)
	check(ladder.get_parent() == host, "ladder parented to host")
	var body := ladder.get_node_or_null("StepsBody") as StaticBody3D
	check(body != null, "StepsBody exists")
	check(body.collision_layer == 1 and body.collision_mask == 0, "steps world-solid, raycast-neutral")
	var want := SnakesLadderBuilder.rung_count_for_height(foot.distance_to(top))
	check(body.get_child_count() == want, "one collider per rung")
	var sealed := true
	for child in body.get_children():
		if not (child is CollisionShape3D and (child as CollisionShape3D).shape is BoxShape3D):
			sealed = false
	check(sealed, "every step is a box collider")
	# Steps must tile the climb with no gaps a token could fall through:
	# consecutive step gap stays under the target spacing.
	var centers := _step_centers(ladder)
	var span: Vector3 = top - foot
	var rail_dir: Vector3 = span.normalized()
	var prev: float = 0.0
	var no_gaps := true
	for c in centers:
		var along: float = (c - foot).dot(rail_dir)
		if along - prev > SnakesLadderBuilder.RUNG_SPACING + 0.001:
			no_gaps = false
		prev = along
	if (top - centers[centers.size() - 1]).dot(rail_dir) > SnakesLadderBuilder.RUNG_SPACING + 0.001:
		no_gaps = false
	check(no_gaps, "no fall-through gaps along the climb")
	# Straightness: every step center sits on the foot->top segment.
	var straight := true
	for c in centers:
		var t: float = clampf((c - foot).dot(rail_dir) / foot.distance_to(top), 0.0, 1.0)
		if c.distance_to(foot.lerp(top, t)) > 0.01:
			straight = false
	check(straight, "rungs sit on the straight foot->top line")
	host.free()

	print("[ladder] height knob scales the blueprint")
	var h1 := Node3D.new()
	var l1 := SnakesLadderBuilder.build_preview(h1, 1.0)
	var h2 := Node3D.new()
	var l2 := SnakesLadderBuilder.build_preview(h2, 6.0)
	var c1 := _step_centers(l1).size()
	var c2 := _step_centers(l2).size()
	check(c2 > c1, "raising height adds rungs (%d -> %d)" % [c1, c2])
	var top_step: float = 0.0
	for c in _step_centers(l2):
		top_step = maxf(top_step, c.y)
	check(top_step > 4.0 and top_step < 6.0, "tall ladder climbs with its height")
	h1.free()
	h2.free()

	print("[ladder] degenerate + wrapper paths")
	var hd := Node3D.new()
	var ld := SnakesLadderBuilder.build_straight_ladder(hd, Vector3.ZERO, Vector3.ZERO)
	check(ld.get_child_count() == 0, "zero-length ladder builds nothing, no crash")
	hd.free()
	var hw := Node3D.new()
	var lw := SnakesBoardBuilder.build_ladder(hw, Vector3(0, 0.14, 0), Vector3(0, 0.5, -3.2))
	check((lw.get_node_or_null("StepsBody") as StaticBody3D) != null, "board wrapper keeps solid steps")
	hw.free()

	print("[ladder] failures: %d" % failures)
	return failures == 0
