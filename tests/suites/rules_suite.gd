class_name SnakesRulesSuite
extends RefCounted
## Pure-logic unit + fuzz tests for SnakesRules / PathData / Dice.
## Static run() so both run_tests.gd and run_all.gd share it. No tree needed.

static var failures: int = 0


static func check(cond: bool, name: String) -> void:
	if cond:
		print("  ok: ", name)
	else:
		failures += 1
		printerr("  FAIL: ", name)


static func run(games: int = 400) -> bool:
	failures = 0
	print("[rules] boustrophedon numbering")
	check(SnakesPathData.cell_to_grid(1) == Vector2i(0, 9), "cell 1 bottom-left")
	check(SnakesPathData.cell_to_grid(10) == Vector2i(9, 9), "cell 10 bottom-right")
	check(SnakesPathData.cell_to_grid(11) == Vector2i(9, 8), "cell 11 above 10")
	check(SnakesPathData.cell_to_grid(20) == Vector2i(0, 8), "cell 20 above 1")
	check(SnakesPathData.cell_to_grid(100) == Vector2i(0, 0), "cell 100 top-left")
	check(SnakesPathData.cell_to_grid(28) == Vector2i(7, 7), "cell 28 spot-check")

	print("[rules] classic portals")
	var ladders := SnakesPathData.ladders_for("classic_mb")
	var snakes := SnakesPathData.snakes_for("classic_mb")
	check(ladders.get(28) == 84, "mega ladder 28->84")
	check(ladders.get(80) == 100, "win ladder 80->100")
	check(snakes.get(87) == 24, "long chute 87->24")
	check(SnakesPathData.validate_portals(snakes, ladders).is_empty(), "classic portals validate")

	print("[rules] movement + portals (no chaining)")
	var rules := SnakesRules.new()
	rules.setup("classic_mb")
	var rs := SnakesRuleSet.classic()
	rules.reset()
	check(rules.token_pos(0) == 0, "start off-board")
	var r1 := rules.apply_move(0, 4, rs)
	check(r1.landed_pos == 4 and r1.final_pos == 14 and r1.hit_ladder, "4 lands ladder 4->14")
	check(not r1.entered_win, "no early win")
	# Single application: ladder 28->84 must not chain even if 84 were a head (it is not).
	rules.positions[1] = 27
	var r2 := rules.apply_move(1, 1, rs)
	check(r2.landed_pos == 28 and r2.final_pos == 84, "ladder resolves once")
	rules.positions[2] = 86
	var r3 := rules.apply_move(2, 1, rs)
	check(r3.landed_pos == 87 and r3.final_pos == 24 and r3.hit_snake, "snake 87->24")

	print("[rules] finish variants")
	var stay := SnakesRuleSet.classic()
	rules.reset()
	rules.positions[0] = 97
	check(rules.legal_moves(0, 5, stay).is_empty(), "EXACT_STAY overshoot has no moves")
	var bounce := SnakesRuleSet.classic()
	bounce.finish_rule = SnakesRuleSet.FinishRule.EXACT_BOUNCE
	var bm := rules.legal_moves(0, 5, bounce)
	check(bm.size() == 1 and bm[0].to_pos == 98, "EXACT_BOUNCE 97+5 -> 98")
	var over := SnakesRuleSet.classic()
	over.finish_rule = SnakesRuleSet.FinishRule.OVERFLOW_WIN
	rules.positions[0] = 97
	var ov := rules.apply_move(0, 5, over)
	check(ov.final_pos == 100 and ov.entered_win, "OVERFLOW_WIN 97+5 wins")

	print("[rules] extra turns")
	rules.reset()
	rules.setup("classic_mb")
	var e1 := rules.apply_move(0, 6, stay)
	check(e1.grants_extra_turn, "six grants extra (classic)")
	var nladder := SnakesRuleSet.classic()
	nladder.extra_roll_on_ladder = false
	rules.reset()
	var e2 := rules.apply_move(0, 4, nladder)
	check(not e2.grants_extra_turn, "ladder alone grants no extra by default")
	var yladder := SnakesRuleSet.classic()
	yladder.extra_roll_on_ladder = true
	rules.reset()
	var e3 := rules.apply_move(0, 4, yladder)
	check(e3.grants_extra_turn, "ladder grants extra when enabled")

	print("[rules] dice streams")
	var d := SnakesDiceEngine.new()
	d.seed_with(1234)
	var a := d.roll()
	d.seed_with(1234)
	check(d.roll() == a, "seeded dice deterministic")
	var seen := {}
	for i in 600:
		seen[d.roll()] = true
	check(seen.size() == 6, "die covers 1..6")

	print("[rules] fuzz %d games (invariants)" % games)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var unfinished := 0
	for g in games:
		var fr := SnakesRules.new()
		fr.setup("classic_mb")
		fr.reset()
		var turns := 0
		var ended := false
		while turns < 2000 and not ended:
			turns += 1
			var die: int = rng.randi_range(1, 6)
			var seat: int = turns % 2
			var res: SnakesMoveResult = fr.apply_move(seat, die, stay)
			check(res.final_pos >= 0 and res.final_pos <= 100, "pos in range")
			if res.final_pos == 100:
				ended = true
		if not ended:
			unfinished += 1
	check(unfinished == 0, "all fuzz games terminate")
	print("[rules] failures: %d" % failures)
	return failures == 0
