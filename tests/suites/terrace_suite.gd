class_name SnakesTerraceSuite
extends RefCounted
## Terrace math: 10 bands of 10 cells rising like step-farmed mountains.
## Headless-safe (no nodes): drives SnakesBoardStyle + SnakesTerraceSettings
## + SnakesPathData anchors only. Static run() shared by run_all lanes.

static var failures: int = 0


static func check(cond: bool, name: String) -> void:
	if cond:
		print("  ok: ", name)
	else:
		failures += 1
		printerr("  FAIL: ", name)


static func run() -> bool:
	failures = 0
	print("[terrace] band mapping")
	check(SnakesBoardStyle.terrace_index_for_cell(1) == 0, "cell 1 band 0")
	check(SnakesBoardStyle.terrace_index_for_cell(10) == 0, "cell 10 band 0")
	check(SnakesBoardStyle.terrace_index_for_cell(11) == 1, "cell 11 band 1")
	check(SnakesBoardStyle.terrace_index_for_cell(20) == 1, "cell 20 band 1")
	check(SnakesBoardStyle.terrace_index_for_cell(30) == 2, "cell 30 band 2")
	check(SnakesBoardStyle.terrace_index_for_cell(91) == 9, "cell 91 band 9")
	check(SnakesBoardStyle.terrace_index_for_cell(100) == 9, "cell 100 band 9")
	check(SnakesBoardStyle.terrace_index_for_cell(0) == -1, "off-board has no band")
	check(SnakesPathData.terrace_index_for_cell(55) == 5, "path data agrees")

	print("[terrace] step + master knobs")
	var step := SnakesBoardStyle.TERRACE_STEP
	check(is_equal_approx(SnakesBoardStyle.terrace_y_for_cell(1, step, 1.0), 0.0), "band 0 sits at base")
	check(is_equal_approx(SnakesBoardStyle.terrace_y_for_cell(11, step, 1.0), step), "band 1 rises one step")
	check(is_equal_approx(SnakesBoardStyle.terrace_y_for_cell(100, step, 1.0), 9.0 * step), "band 9 rises nine steps")
	check(is_equal_approx(SnakesBoardStyle.terrace_y_for_cell(100, step, 0.0), 0.0), "master 0 flattens board")
	check(is_equal_approx(SnakesBoardStyle.terrace_y_for_cell(50, 0.5, 1.0), 4.0 * 0.5), "custom step honored")
	check(is_equal_approx(SnakesBoardStyle.terrace_y_for_cell(50, step, 0.5), 4.0 * step * 0.5), "master scales lift")

	print("[terrace] resource blueprint")
	var res := SnakesTerraceSettings.new()
	res.step_height = 0.4
	res.master_scale = 1.0
	check(is_equal_approx(res.effective_step(), 0.4), "effective step = height * master")
	check(is_equal_approx(res.terrace_y_for_cell(21), 0.8), "resource lifts band 2 twice")
	res.master_scale = 0.0
	check(is_equal_approx(res.terrace_y_for_cell(100), 0.0), "resource master 0 flattens")
	check(is_equal_approx(res.tile_top_for_cell(1), SnakesBoardStyle.TILE_TOP), "band 0 top is base top")

	print("[terrace] anchors climb monotonically")
	SnakesBoardStyle.reset_active_terrace()
	var prev_y := -1.0
	var mono := true
	for cell in [1, 11, 21, 31, 41, 51, 61, 71, 81, 91, 100]:
		var y: float = SnakesPathData.anchor_for(cell).y
		if y < prev_y - 0.0001:
			mono = false
		prev_y = y
	check(mono, "anchors rise 1 -> 100")
	var a1 := SnakesPathData.anchor_for(5)
	var a2 := SnakesPathData.anchor_for_terraced(5, 0.5, 1.0)
	check(is_equal_approx(a1.y, SnakesBoardStyle.TILE_TOP), "band 0 anchor at base top")
	check(is_equal_approx(a2.y, SnakesBoardStyle.TILE_TOP), "explicit knobs agree on band 0")
	var b1 := SnakesPathData.anchor_for(95)
	var b2 := SnakesPathData.anchor_for_terraced(95, 0.5, 1.0)
	check(is_equal_approx(b2.y, SnakesBoardStyle.TILE_TOP + 9.0 * 0.5), "explicit knobs lift band 9")
	check(b1.y > b2.y or is_equal_approx(b1.y, SnakesBoardStyle.TILE_TOP + 9.0 * SnakesBoardStyle.TERRACE_STEP), "default anchor uses default step")

	print("[terrace] builder + token anchors agree")
	var builder := SnakesBoardBuilder.new()
	builder.set_terrace(0.5, 1.0)
	check(is_equal_approx(builder.effective_terrace_step(), 0.5), "builder effective step")
	check(is_equal_approx(builder.terrace_y_for_cell(31), 3.0 * 0.5), "builder lifts band 3")
	var tok := SnakesBoardBuilder.token_anchor(31)
	var anc := SnakesPathData.anchor_for(31)
	check(tok.is_equal_approx(anc), "token anchor matches cell anchor (live knobs)")
	var flat_tok := SnakesBoardBuilder.token_anchor_terraced(31, 0, 1, 0.5, 0.0)
	check(is_equal_approx(flat_tok.y, SnakesBoardStyle.TILE_TOP), "explicit flat token anchor")
	SnakesBoardStyle.reset_active_terrace()

	print("[terrace] failures: %d" % failures)
	return failures == 0
