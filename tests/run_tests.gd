extends SceneTree
## Driver: rules/AI/dice fuzz + slotter. Usage:
##   godot --headless --path . --script res://tests/run_tests.gd [-- games=400]

func _init() -> void:
	var kv := _parse_cli()
	var games: int = int(kv.get("games", 150))
	var ok: bool = SnakesRulesSuite.run(games)
	# Slotter sanity (headless, no nodes).
	var rules := SnakesRules.new()
	rules.setup("classic_mb")
	rules.reset()
	rules.positions[0] = 4
	rules.positions[1] = 4
	var occ := SnakesSlotter.find_cell_occupants(rules, 4)
	if occ != [0, 1]:
		printerr("  FAIL: slotter shares cell")
		ok = false
	else:
		print("  ok: slotter shares cell")
	print("=== run_tests: %s ===" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)


func _parse_cli() -> Dictionary:
	var out := {}
	for a in OS.get_cmdline_user_args():
		if a.contains("="):
			var parts := a.split("=", true, 1)
			out[parts[0]] = parts[1]
		else:
			out[a] = true
	return out
