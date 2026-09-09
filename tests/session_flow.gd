extends SceneTree
## Driver: pure dispatch_action matches. Usage:
##   godot --headless --path . --script res://tests/session_flow.gd [-- ai=10]

func _init() -> void:
	var kv := _parse_cli()
	var ai: int = int(kv.get("ai", 10))
	var ok: bool = SnakesSessionSuite.run(ai)
	print("=== session_flow: %s ===" % ("PASS" if ok else "FAIL"))
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
