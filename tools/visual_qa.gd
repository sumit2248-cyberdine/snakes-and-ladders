extends SceneTree
## Visual QA capture: boots Main, stages shots, saves PNGs to qa_shots/.
## Usage: godot --path . --script res://tools/visual_qa.gd
## (NOT headless — needs the window to render. Quits itself.)

const OUT_DIR := "qa_shots"
const W := 1280
const H := 720

var _frames := 0
var _match = null
var _done := false
var _mock_from := 0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var packed: PackedScene = load("res://scenes/Main.tscn")
	_match = packed.instantiate()
	root.add_child(_match)
	root.size = Vector2i(W, H)


func _cam(yaw_deg: float, pitch_deg: float, dist: float, target: Vector3) -> void:
	var cam = _match.cam
	cam.yaw = deg_to_rad(yaw_deg)
	cam.pitch = deg_to_rad(pitch_deg)
	cam.dist = dist
	cam.target = target
	cam._desired = target
	cam.top_down = false


func _anchor(cell: int) -> Vector3:
	return SnakesBoardBuilder.token_anchor(cell)


func _shot(name: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [OUT_DIR, name]
	img.save_png(path)
	print("saved ", path)


func _teleport(seat: int, cell: int) -> void:
	var t = _match.tokens[seat]
	var a := _anchor(cell)
	t.position = a
	t.ground_y = a.y
	t.cell = cell


## Restore token visuals to the live session state after mock staging.
func _resnap_live() -> void:
	var rules = _match.session.rules
	for seat in _match.tokens:
		var t = _match.tokens[seat]
		var pos: int = rules.positions[int(seat)]
		var a := SnakesSlotter.offboard_anchor(int(seat)) if pos == 0 else _anchor(pos)
		t.position = a
		t.ground_y = a.y
		t.cell = pos


func _process(_delta: float) -> bool:
	_frames += 1
	match _frames:
		5:
			_match.setup_screen.configure_for_test(2, "classic")
			_match.setup_screen._all_ai = true
			_match.setup_screen.press_play()
		14:
			# Isolation burst at board center (no panel) to verify particles.
			_match.fx.confetti(Vector3(0, 0, 2.0))
		20:
			_cam(30, -52, 27.5, Vector3(2.2, 0, 1.0))
		26:
			_shot("01_board_overview")
			_cam(35, -50, 7.5, _anchor(87))
		32:
			_shot("02_snake87_head")
			_cam(215, -48, 7.5, _anchor(28))
		38:
			_shot("03_ladder28_foot")
			_cam(90, -55, 6.0, Vector3(11.5, 0.3, 0.0))
		44:
			_shot("04_dice_tray")
			_cam(30, -55, 7.0, Vector3(-2.4, 0.0, 9.9))
		50:
			_shot("05_staging_row")
			_teleport(0, 28)
			_teleport(1, 87)
			_teleport(2, 4)
			_teleport(3, 55)
			_cam(30, -52, 20.0, Vector3(0, 0, 2.0))
		56:
			_shot("06_tokens_on_board")
			# Mock a win on top of the live session: pin BOTH logic and visual
			# so the running AI match cannot steal token 0 back mid-mock.
			_mock_from = _match.session.rules.positions[0]
			_match.session.rules.positions[0] = 100
			_teleport(0, 100)
			_match.tokens[0].anim_lock = true
			_match.hud.show_finale("Red")
			_match.fx.confetti(_match.tokens[0].position)
			_cam(30, -40, 14.0, _anchor(100) + Vector3(-3.0, 0, 5.0))
		76:
			_shot("07_finale")
			# Return to the live match: hide mock finale, restore + re-snap.
			_match.hud.hide_finale()
			_match.tokens[0].anim_lock = false
			_match.session.rules.positions[0] = _mock_from
			_resnap_live()
			_cam(30, -52, 27.5, Vector3(2.2, 0, 1.0))
		92:
			_shot("08_ai_autoplay")
			_cam(30, -60, 5.0, SnakesPathData.anchor_for(50))
		98:
			_shot("09_tile_detail")
		108:
			if not _done:
				_done = true
				print("=== visual_qa done ===")
				quit(0)
			return true
	return false
