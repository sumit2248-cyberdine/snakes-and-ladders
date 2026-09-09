class_name SnakesMatch
extends Node3D
## Match director: UI wiring, input, AI pacing, save/resume + replay driving.
## Delegates rules to SnakesSession and animation to SnakesChoreographer.
## Mirrors Ludo's Match (main.gd) layering. Presentation mirrors of session
## state (state, current, die_value) exist for HUD/tests; session is truth.

var session := SnakesSession.new()
var board: SnakesBoardScene
var dice: SnakesDice
var cam: SnakesCameraDirector
var fx: SnakesFX
var audio: SnakesSynthAudio
var choreographer: SnakesChoreographer
var hud: SnakesHUD
var setup_screen: SnakesSetupScreen
var pause_menu: SnakesPauseMenu
var rules_panel: SnakesRulesPanel

var tokens: Dictionary = {}

# Presentation mirrors (session remains the single source of truth).
var state: String = ""
var current: int = 0
var die_value: int = 0

var in_match: bool = false
var watching_replay: bool = false
var replay: SnakesReplayLogger
var _ai_scheduling := false
var _gen := 0

const SAVE_EVERY_TURNS := 1


func _ready() -> void:
	_build_world()
	_build_ui()
	session.event_emitted.connect(_on_event)
	_show_setup()


func _build_world() -> void:
	board = SnakesBoardScene.new()
	add_child(board)
	fx = SnakesFX.new()
	add_child(fx)
	audio = SnakesSynthAudio.new()
	add_child(audio)
	dice = SnakesDice.new()
	add_child(dice)
	# _ready() runs on add; now place on the felt and bind tray bounds.
	dice.set_tray(board.builder.tray_center, SnakesDiceTray.REST_Y)
	dice.position = board.dice_rest()
	cam = SnakesCameraDirector.new()
	add_child(cam)
	choreographer = SnakesChoreographer.new()
	add_child(choreographer)


func _build_ui() -> void:
	hud = SnakesHUD.new()
	add_child(hud)
	hud.roll_pressed.connect(_on_roll_pressed)
	hud.pause_pressed.connect(_on_pause)
	hud.restart_pressed.connect(_on_restart)
	hud.view_toggled.connect(_on_view_toggled)
	hud.rematch_pressed.connect(_on_restart)
	hud.menu_pressed.connect(_to_menu)
	setup_screen = SnakesSetupScreen.new()
	add_child(setup_screen)
	setup_screen.start_game.connect(_on_start_game)
	setup_screen.continue_game.connect(_on_continue)
	setup_screen.watch_replay.connect(_on_watch_replay)
	pause_menu = SnakesPauseMenu.new()
	add_child(pause_menu)
	pause_menu.resume_pressed.connect(_on_resume)
	pause_menu.restart_pressed.connect(_on_restart)
	pause_menu.save_menu_pressed.connect(_on_save_menu)
	pause_menu.quit_pressed.connect(_to_menu)
	rules_panel = SnakesRulesPanel.new()
	add_child(rules_panel)


func _show_setup() -> void:
	in_match = false
	setup_screen.visible = true
	hud.visible = false


func _on_start_game(player_count: int, all_ai: bool, ruleset_id: String, seed_text: String) -> void:
	var settings := SnakesMatchSettings.with_players(player_count, all_ai)
	settings.portal_preset = "quick" if ruleset_id == "quick" else "classic_mb"
	_start_with(settings, SnakesRuleSet.load_preset(ruleset_id), seed_text)


func _start_with(settings: SnakesMatchSettings, rule_set: SnakesRuleSet, seed_text: String) -> void:
	_gen += 1
	_rebuild_tokens()
	session.settings = settings
	session.rule_set = rule_set
	session.dice = SnakesDiceEngine.new()
	var seed_int := 0
	if seed_text.strip_edges() != "":
		seed_int = abs(seed_text.hash())
		session.dice.seed_with(seed_int)
	replay = SnakesReplayLogger.new()
	replay.start_recording()
	replay.dice_seed = seed_int
	replay.has_dice_seed = seed_text.strip_edges() != ""
	# Re-point board portals for quick preset.
	_ensure_board_portals()
	choreographer.reset()
	choreographer.setup(session, tokens, dice, cam, fx, audio)
	setup_screen.visible = false
	hud.visible = true
	hud.hide_finale()
	watching_replay = false
	in_match = true
	session.begin()
	_sync_mirrors()
	_refresh_hud()
	choreographer.snap_all_visuals()
	_maybe_schedule_ai()


func _ensure_board_portals() -> void:
	var preset: String = session.settings.portal_preset
	var snakes := SnakesPathData.snakes_for(preset)
	var ladders := SnakesPathData.ladders_for(preset)
	# Rebuild the board group for the preset (cheap, asset-free).
	board.queue_free()
	board = SnakesBoardScene.new()
	board.setup(snakes, ladders)
	add_child(board)
	move_child(board, 0)


func _rebuild_tokens() -> void:
	for s in tokens:
		(tokens[s] as SnakesToken).queue_free()
	tokens = {}
	for seat in 4:
		var t := SnakesToken.new()
		t.setup(seat)
		add_child(t)
		t.position = SnakesSlotter.offboard_anchor(seat)
		t.ground_y = t.position.y
		tokens[seat] = t


# --- continue / replay -----------------------------------------------------

func _on_continue() -> void:
	var s := SnakesSerializer.load_from_file()
	if s == null:
		return
	_gen += 1
	_rebuild_tokens()
	session = s
	choreographer.reset()
	choreographer.setup(session, tokens, dice, cam, fx, audio)
	_ensure_board_portals()
	replay = SnakesReplayLogger.new()
	replay.start_recording()
	setup_screen.visible = false
	hud.visible = true
	hud.hide_finale()
	in_match = true
	_sync_mirrors()
	_refresh_hud()
	choreographer.snap_all_visuals()
	_maybe_schedule_ai()


func _on_watch_replay() -> void:
	var r := SnakesReplayLogger.load_last()
	if r == null:
		return
	# Replay through the live scene with pacing.
	watching_replay = true
	_gen += 1
	_rebuild_tokens()
	var settings := SnakesMatchSettings.with_players(2, true)
	var rule_set := SnakesRuleSet.classic()
	session = SnakesSession.new()
	session.settings = settings
	session.rule_set = rule_set
	if r.has_dice_seed:
		session.dice.seed_with(r.dice_seed)
	choreographer.reset()
	choreographer.setup(session, tokens, dice, cam, fx, audio)
	setup_screen.visible = false
	hud.visible = true
	hud.hide_finale()
	in_match = true
	session.begin()
	_replay_drive(r)


func _replay_drive(r: SnakesReplayLogger) -> void:
	var my_gen: int = _gen
	for a in r.actions:
		if my_gen != _gen:
			return
		await _wait_idle()
		if my_gen != _gen:
			return
		var act := SnakesAction.new()
		act.type = int(a.get("type", 0))
		act.player = int(a.get("player", -1))
		session.dispatch_action(act)


func _wait_idle() -> void:
	while choreographer.busy:
		await get_tree().process_frame


# --- input -----------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("game_pause") and in_match:
		if pause_menu.visible:
			_on_resume()
		else:
			_on_pause()
		return
	if event.is_action_pressed("game_toggle_camera") and in_match:
		_on_view_toggled(not cam.top_down)
		return
	if event.is_action_pressed("game_zoom_in") and in_match:
		cam.apply_zoom(0.92)
		return
	if event.is_action_pressed("game_zoom_out") and in_match:
		cam.apply_zoom(1.08)
		return
	if event is InputEventMouseMotion and in_match:
		var mm := event as InputEventMouseMotion
		if (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			cam.apply_drag(mm.relative)
		return
	if event is InputEventMouseButton and in_match:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			cam.apply_zoom(0.92)
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			cam.apply_zoom(1.08)
			return
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_handle_click(mb.position)


func _handle_click(pos: Vector2) -> void:
	if not in_match or choreographer.busy:
		return
	if session.fsm.current_id != SnakesFSM.AWAIT_ROLL:
		return
	var hit = _raycast_meta(pos, "dice_ref")
	if hit != null:
		_on_roll_pressed()


func _raycast_meta(pos: Vector2, key: String) -> Variant:
	var space := get_world_3d().direct_space_state
	var from: Vector3 = cam.camera.project_ray_origin(pos)
	var to: Vector3 = from + cam.camera.project_ray_normal(pos) * 200.0
	var q := PhysicsRayQueryParameters3D.create(from, to, 4)
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return null
	var collider: Object = hit.get("collider", null)
	if collider is Object and (collider as Object).has_meta(key):
		return (collider as Object).get_meta(key)
	return null


# --- turn flow --------------------------------------------------------------

func _on_roll_pressed() -> void:
	if not in_match or watching_replay:
		return
	if choreographer.busy:
		return
	if session.fsm.current_id != SnakesFSM.AWAIT_ROLL:
		return
	if not _is_human_turn():
		return
	_submit_roll(session.current)


func _is_human_turn() -> bool:
	var t: int = int(session.settings.seat_types[session.current])
	return t == SnakesMatchSettings.SeatType.HUMAN


func _submit_roll(player: int) -> void:
	var act := SnakesAction.roll(player)
	if replay != null and not watching_replay:
		replay.dispatch(session, act)
	else:
		session.dispatch_action(act)


func _on_event(ev: SnakesEvent) -> void:
	match ev.type:
		SnakesEvent.Type.STATE_CHANGED:
			state = ev.state_to()
		SnakesEvent.Type.DICE_ROLLED:
			die_value = ev.die()
			hud.set_die(ev.die())
		SnakesEvent.Type.TOKEN_MOVED:
			hud.banner("%s moves to %d" % [SnakesPathData.PLAYER_NAMES[ev.player()], ev.to_pos()])
		SnakesEvent.Type.SNAKE_HIT:
			hud.toast("🐍 Snake! %d → %d" % [ev.from_pos(), ev.to_pos()])
		SnakesEvent.Type.LADDER_CLIMBED:
			hud.toast("🪜 Ladder! %d → %d" % [ev.from_pos(), ev.to_pos()])
		SnakesEvent.Type.TURN_ENDED:
			_sync_mirrors()
			_refresh_hud()
			if not ev.extra_turn():
				hud.clear_die()
			if ev.reason() == "three_sixes":
				hud.toast("Three sixes — turn forfeited")
			elif ev.reason() == "no_moves":
				hud.toast("No move — need exact roll")
			_autosave()
			_maybe_schedule_ai()
		SnakesEvent.Type.GAME_OVER:
			_sync_mirrors()
			_refresh_hud()
			hud.banner("")
			hud.show_finale(SnakesPathData.PLAYER_NAMES[ev.winner()])
			_autosave()
			if replay != null:
				replay.save_last()
			SnakesSerializer.clear_autosave()


func _sync_mirrors() -> void:
	state = session.fsm.current_id
	current = session.current
	die_value = session.die_value


func _refresh_hud() -> void:
	hud.update_progress(session.rules)
	var can_roll: bool = in_match and not watching_replay and not choreographer.busy and session.fsm.current_id == SnakesFSM.AWAIT_ROLL and _is_human_turn()
	hud.set_active(session.current, can_roll)
	if session.fsm.current_id == SnakesFSM.GAME_OVER:
		hud.set_active(session.current, false)
	elif can_roll:
		hud.banner("%s's turn — tap ROLL" % SnakesPathData.PLAYER_NAMES[session.current])
	else:
		hud.banner("%s is thinking…" % SnakesPathData.PLAYER_NAMES[session.current])


func _maybe_schedule_ai() -> void:
	if not in_match or watching_replay:
		return
	if session.fsm.current_id == SnakesFSM.GAME_OVER:
		return
	if _is_human_turn():
		_refresh_hud()
		return
	if _ai_scheduling:
		return
	_ai_scheduling = true
	_ai_drive()


func _ai_drive() -> void:
	var my_gen: int = _gen
	await get_tree().create_timer(0.7).timeout
	while in_match and not watching_replay and my_gen == _gen:
		if session.fsm.current_id == SnakesFSM.GAME_OVER:
			break
		if _is_human_turn():
			break
		if session.fsm.current_id != SnakesFSM.AWAIT_ROLL:
			await get_tree().process_frame
			continue
		if choreographer.busy:
			await choreographer.drained
			continue
		_submit_roll(session.current)
		await get_tree().process_frame
		# Wait for the turn to resolve before looping (extra turns stay on AI).
		await _wait_idle()
		await get_tree().create_timer(0.4).timeout
	_ai_scheduling = false
	_refresh_hud()


func _autosave() -> void:
	if not in_match or watching_replay:
		return
	if session.fsm.current_id == SnakesFSM.GAME_OVER:
		return
	SnakesSerializer.save_to_file(session)


# --- pause / restart / menu --------------------------------------------------

func _on_pause() -> void:
	get_tree().paused = true
	pause_menu.open()


func _on_resume() -> void:
	pause_menu.close()
	get_tree().paused = false


func _on_restart() -> void:
	get_tree().paused = false
	pause_menu.close()
	session.dispatch_action(SnakesAction.restart())
	_gen += 1
	_ai_scheduling = false
	hud.hide_finale()
	SnakesSerializer.clear_autosave()
	_sync_mirrors()
	_refresh_hud()
	choreographer.snap_all_visuals()
	_maybe_schedule_ai()


func _on_save_menu() -> void:
	_autosave()
	get_tree().paused = false
	_to_menu()


func _on_view_toggled(top_down: bool) -> void:
	cam.set_top_down(top_down)


func _to_menu() -> void:
	_gen += 1
	get_tree().paused = false
	pause_menu.close()
	in_match = false
	watching_replay = false
	_ai_scheduling = false
	_show_setup()


## TEST SEAM: drive a headless match without the 3D presentation.
func configure_for_headless(settings: SnakesMatchSettings, rule_set: SnakesRuleSet) -> void:
	session.settings = settings
	session.rule_set = rule_set
