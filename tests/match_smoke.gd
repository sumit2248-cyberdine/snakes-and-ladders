extends SceneTree
## Boots the real Main scene headlessly, verifies the world builds and a
## scripted match starts. Usage:
##   godot --headless --path . --script res://tests/match_smoke.gd

var _frames := 0
var _match: SnakesMatch
var _failures := 0


func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	_match = packed.instantiate()
	root.add_child(_match)


func _check(cond: bool, name: String) -> void:
	if cond:
		print("  ok: ", name)
	else:
		_failures += 1
		printerr("  FAIL: ", name)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 5:
		_check(_match != null, "match node exists")
		_check(_match.board != null and _match.board.get_child_count() > 5, "board built (>5 nodes)")
		_check(_match.dice != null, "dice exists")
		_check(_match.cam != null and _match.cam.camera != null, "camera exists")
		_check(_match.hud != null and _match.hud.visible == false, "hud hidden pre-start")
		_check(_match.setup_screen.visible, "setup visible on boot")
		# Start an all-AI match through the real UI seam.
		_match.setup_screen.configure_for_test(2, "classic")
		_match.setup_screen.press_play()
	if _frames == 10:
		_check(_match.in_match, "match started via setup seam")
		_check(_match.tokens.size() == 4, "4 tokens built")
		_check(_match.session.fsm.current_id != "", "FSM running")
	if _frames == 12:
		print("=== match_smoke: %s ===" % ("PASS" if _failures == 0 else "FAIL"))
		quit(0 if _failures == 0 else 1)
		return true
	return false
