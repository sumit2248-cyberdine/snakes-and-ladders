extends SceneTree
## Lane runner — ONE boot per lane (mirrors Ludo's run_all.gd).
##   godot --headless --path . --script res://tests/run_all.gd -- fast
##   godot --headless --path . --script res://tests/run_all.gd -- full

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var lane := "fast"
	for a in args:
		if a == "fast" or a == "full" or a == "soak":
			lane = a
	var failures := 0
	print("=== lane: %s ===" % lane)
	if lane == "fast":
		if not SnakesRulesSuite.run(150):
			failures += 1
		if not SnakesTerraceSuite.run():
			failures += 1
		if not SnakesLadderSuite.run():
			failures += 1
		if not SnakesSnakeSuite.run():
			failures += 1
		if not SnakesDiceSuite.run():
			failures += 1
		if not SnakesSessionSuite.run(6):
			failures += 1
		if not SnakesPersistenceSuite.run():
			failures += 1
		if not SnakesArchSuite.run():
			failures += 1
	else:
		if not SnakesRulesSuite.run(1500):
			failures += 1
		if not SnakesTerraceSuite.run():
			failures += 1
		if not SnakesLadderSuite.run():
			failures += 1
		if not SnakesSnakeSuite.run():
			failures += 1
		if not SnakesDiceSuite.run():
			failures += 1
		if not SnakesSessionSuite.run(20):
			failures += 1
		if not SnakesPersistenceSuite.run():
			failures += 1
		if not SnakesArchSuite.run():
			failures += 1
	print("=== lane %s: %d failures ===" % [lane, failures])
	quit(0 if failures == 0 else 1)
