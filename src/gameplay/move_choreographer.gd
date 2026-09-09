class_name SnakesChoreographer
extends Node3D
## Sole consumer of SnakesEvent that touches the 3D world. Serial queue-drain.
## Mirrors Ludo's MoveChoreographer3D: busy flag, drained signal, gen-guarded reset.

signal drained
signal roll_settled

const MOVE_SPEED := 3.4
const HOP_HEIGHT := 0.55

var session: SnakesSession
var token_nodes: Dictionary = {}
var dice: SnakesDice
var cam: SnakesCameraDirector
var fx: Node
var audio: Node

var busy: bool = false
var progress_token: int = 0
var _queue: Array[SnakesEvent] = []
var _gen: int = 0
var _live_tweens: Array[Tween] = []


func setup(p_session: SnakesSession, p_tokens: Dictionary, p_dice: SnakesDice, p_cam: SnakesCameraDirector, p_fx: Node = null, p_audio: Node = null) -> void:
	session = p_session
	token_nodes = p_tokens
	dice = p_dice
	cam = p_cam
	fx = p_fx
	audio = p_audio
	session.event_emitted.connect(_enqueue)


func reset() -> void:
	_gen += 1
	_queue.clear()
	for tw in _live_tweens:
		if is_instance_valid(tw):
			tw.kill()
	_live_tweens.clear()
	busy = false


func _enqueue(event: SnakesEvent) -> void:
	_queue.append(event)
	if not busy:
		_drain()


func _drain() -> void:
	if busy:
		return
	busy = true
	var my_gen: int = _gen
	while not _queue.is_empty() and my_gen == _gen:
		var ev: SnakesEvent = _queue.pop_front()
		progress_token += 1
		await _present(ev, my_gen)
		if my_gen != _gen:
			break
	busy = false
	drained.emit()


func _track(tw: Tween) -> Tween:
	_live_tweens.append(tw)
	return tw


func _present(ev: SnakesEvent, my_gen: int) -> void:
	match ev.type:
		SnakesEvent.Type.DICE_ROLLED:
			await _present_roll(ev.player(), ev.die(), my_gen)
		SnakesEvent.Type.TOKEN_MOVED:
			await _present_token_moved(ev.player(), ev.from_pos(), ev.to_pos(), my_gen)
		SnakesEvent.Type.SNAKE_HIT:
			await _present_slide(ev.player(), ev.from_pos(), ev.to_pos(), true, my_gen)
		SnakesEvent.Type.LADDER_CLIMBED:
			await _present_slide(ev.player(), ev.from_pos(), ev.to_pos(), false, my_gen)
		SnakesEvent.Type.TURN_ENDED:
			_refresh_anchors()
			_tidy_halos()
			if cam != null:
				cam.home()
		SnakesEvent.Type.GAME_OVER:
			await _victory_ceremony(ev.winner(), my_gen)
		SnakesEvent.Type.STATE_CHANGED:
			_refresh_anchors()
			_tidy_halos()


func _present_roll(player: int, die: int, my_gen: int) -> void:
	if audio != null and audio.has_method("play_dice"):
		audio.play_dice()
	if dice != null and is_instance_valid(dice):
		await dice.roll(die, 1.0)
		if my_gen != _gen:
			return
	roll_settled.emit()


func _token(seat: int) -> SnakesToken:
	return token_nodes.get(seat, null)


func _present_token_moved(player: int, from_pos: int, to_pos: int, my_gen: int) -> void:
	var t := _token(player)
	if t == null:
		return
	t.anim_lock = true
	t.set_selected(true)
	# Step cell-by-cell from from+1..to (off-board 0 starts at 1).
	var start_cell: int = maxi(from_pos + 1, 1)
	if to_pos < start_cell:
		t.anim_lock = false
		return
	for cell in range(start_cell, to_pos + 1):
		if my_gen != _gen:
			return
		var anchor := SnakesBoardBuilder.token_anchor(cell)
		t.face_towards(anchor)
		t.squash()
		await _hop_to(t, anchor, my_gen)
		if my_gen != _gen:
			return
		t.stretch_pop()
		t.cell = cell
		if fx != null and fx.has_method("dust"):
			fx.dust(anchor)
		# Gentle camera follow: nudge every 3rd hop, damped by the director.
		if cam != null and (cell - start_cell) % 3 == 2:
			cam.focus_on(anchor * 0.15 + Vector3(2.2, 0, 1.0) * 0.85)
		if audio != null and audio.has_method("play_hop"):
			audio.play_hop()
	t.anim_lock = false
	_refresh_anchors()
	_tidy_halos()


func _present_slide(player: int, from_pos: int, to_pos: int, is_snake: bool, my_gen: int) -> void:
	var t := _token(player)
	if t == null:
		return
	if is_snake:
		await _present_snake_hit(t, from_pos, to_pos, my_gen)
	else:
		await _present_ladder_climb(t, from_pos, to_pos, my_gen)


## Flex-rig lookup for strike/digest. Rigs register in "snakes_flex" with
## head_cell set by the board builder; board rebuilds refresh the group.
func _snake_rig_for(head_cell: int) -> Node:
	if not is_inside_tree():
		return null
	for n in get_tree().get_nodes_in_group("snakes_flex"):
		var rig_cell: int = int(n.get("head_cell"))
		if is_instance_valid(n) and rig_cell == head_cell and n.has_method("play_strike"):
			return n
	return null


## Snake hit: rig strikes at the token, gulps it at the head, digests
## neck -> tail while the token travels hidden, then pops it out at the tail.
## Falls back to the plain arc slide when no rig owns the head cell.
func _present_snake_hit(t: SnakesToken, head_cell: int, tail_cell: int, my_gen: int) -> void:
	var exit_anchor := SnakesBoardBuilder.token_anchor(tail_cell)
	var rig := _snake_rig_for(head_cell)
	if rig == null:
		await _arc_slide(t, exit_anchor, true, my_gen)
		if my_gen != _gen:
			return
		_land_token(t, exit_anchor, tail_cell)
		return
	t.anim_lock = true
	t.face_towards(rig.head_now())
	if audio != null and audio.has_method("play_slide"):
		audio.play_slide()
	if cam != null:
		cam.shake(0.6)
	# 1. Strike: head lunges out to the token and back (~0.53 s).
	rig.play_strike(t.position)
	await get_tree().create_timer(0.55).timeout
	if my_gen != _gen:
		return
	# 2. Gulp: token shrinks into the mouth.
	t.face_towards(rig.head_now())
	t.squash()
	var mouth: Vector3 = rig.head_now() + Vector3(0, 0.1, 0)
	var gulp := create_tween()
	_track(gulp)
	gulp.set_parallel(true)
	gulp.tween_property(t, "position", mouth, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	gulp.tween_property(t, "scale", Vector3.ONE * 0.05, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await gulp.finished
	if my_gen != _gen:
		return
	# 3. Hidden ride + digest wave neck -> tail.
	t.visible = false
	t.position = exit_anchor
	t.ground_y = exit_anchor.y
	t.cell = tail_cell
	rig.play_digest(1.1)
	await get_tree().create_timer(1.15).timeout
	if my_gen != _gen:
		return
	# 4. Pop out at the tail.
	t.visible = true
	var pop := create_tween()
	_track(pop)
	pop.tween_property(t, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await pop.finished
	if my_gen != _gen:
		return
	t.anim_lock = false
	t.stretch_pop()
	if fx != null and fx.has_method("dust"):
		fx.dust(exit_anchor)
	_refresh_anchors()
	_tidy_halos()


## Ladder climb: rung-to-rung hops along the straight foot -> top segment
## instead of one arc, so the token reads as climbing the solid steps.
func _present_ladder_climb(t: SnakesToken, foot_cell: int, top_cell: int, my_gen: int) -> void:
	var exit_anchor := SnakesBoardBuilder.token_anchor(top_cell)
	var start: Vector3 = t.position
	t.anim_lock = true
	t.set_selected(true)
	t.face_towards(exit_anchor)
	if audio != null and audio.has_method("play_climb"):
		audio.play_climb()
	if cam != null:
		cam.shake(0.3)
	var hops: int = clampi(int(start.distance_to(exit_anchor) / 1.2), 3, 6)
	for i in range(1, hops + 1):
		if my_gen != _gen:
			return
		var step_pos: Vector3 = start.lerp(exit_anchor, float(i) / float(hops))
		t.squash()
		await _hop_to(t, step_pos, my_gen)
		if my_gen != _gen:
			return
		t.stretch_pop()
		t.cell = top_cell if i == hops else foot_cell
	_land_token(t, exit_anchor, top_cell)


## Legacy arc slide (no-rig fallback) + shared landing bookkeeping.
func _arc_slide(t: SnakesToken, b: Vector3, is_snake: bool, my_gen: int) -> void:
	var start: Vector3 = t.position
	t.face_towards(b)
	if audio != null:
		if is_snake and audio.has_method("play_slide"):
			audio.play_slide()
		elif not is_snake and audio.has_method("play_climb"):
			audio.play_climb()
	if cam != null:
		cam.shake(0.6 if is_snake else 0.3)
	var dist: float = start.distance_to(b)
	var peak: Vector3 = (start + b) * 0.5 + Vector3(0, minf(2.2, 0.6 + dist * 0.12), 0)
	var dur: float = clampf(dist * 0.09, 0.5, 1.4)
	t.anim_lock = true
	var tw := create_tween()
	_track(tw)
	tw.tween_method(_slide_step.bind(t, start, peak, b), 0.0, 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished


func _land_token(t: SnakesToken, anchor: Vector3, cell: int) -> void:
	t.position = anchor
	t.ground_y = anchor.y
	t.cell = cell
	t.anim_lock = false
	t.stretch_pop()
	if fx != null and fx.has_method("dust"):
		fx.dust(anchor)
	_refresh_anchors()
	_tidy_halos()


func _slide_step(t: float, token: SnakesToken, a: Vector3, peak: Vector3, b: Vector3) -> void:
	if not is_instance_valid(token):
		return
	var p1: Vector3 = a.lerp(peak, t)
	var p2: Vector3 = peak.lerp(b, t)
	token.position = p1.lerp(p2, t)


func _hop_to(t: SnakesToken, anchor: Vector3, my_gen: int) -> void:
	var from: Vector3 = t.position
	var dist: float = from.distance_to(anchor)
	var dur: float = clampf(dist / MOVE_SPEED, 0.12, 0.45)
	var tw := create_tween()
	_track(tw)
	tw.set_parallel(true)
	tw.tween_property(t, "position:x", anchor.x, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(t, "position:z", anchor.z, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_method(_hop_arc.bind(t, from.y, anchor.y), 0.0, 1.0, dur)
	await tw.finished
	if my_gen != _gen:
		return
	t.position = anchor
	t.ground_y = anchor.y


func _hop_arc(u: float, token: SnakesToken, y0: float, y1: float) -> void:
	if not is_instance_valid(token):
		return
	token.position.y = lerpf(y0, y1, u) + HOP_HEIGHT * 4.0 * u * (1.0 - u)


func _refresh_anchors() -> void:
	if session == null:
		return
	# Stack occupants sharing a cell.
	var by_cell := {}
	for seat in token_nodes:
		var pos: int = session.rules.positions[int(seat)]
		if pos == SnakesRules.POS_OFF:
			var tok := _token(int(seat))
			if tok != null:
				tok.position = SnakesSlotter.offboard_anchor(int(seat))
				tok.ground_y = tok.position.y
			continue
		if not by_cell.has(pos):
			by_cell[pos] = []
		(by_cell[pos] as Array).append(int(seat))
	for cell in by_cell:
		var seats: Array = by_cell[cell]
		for i in seats.size():
			var tok := _token(int(seats[i]))
			if tok != null and not tok.anim_lock:
				var anchor := SnakesBoardBuilder.token_anchor(int(cell), i, seats.size())
				tok.position = anchor
				tok.ground_y = anchor.y
				# Cancelled strike/digest presentations may leave these dirty.
				tok.scale = Vector3.ONE
				tok.visible = true


func _tidy_halos() -> void:
	if session == null:
		return
	for seat in token_nodes:
		var tok := _token(int(seat))
		if tok == null:
			continue
		var active: bool = int(seat) == session.current and session.fsm.current_id == SnakesFSM.AWAIT_ROLL
		tok.set_selectable(active)


func _victory_ceremony(winner: int, my_gen: int) -> void:
	var t := _token(winner)
	if t != null:
		t.set_selected(true)
		t.cheer()
		if fx != null and fx.has_method("confetti"):
			fx.confetti(t.position)
	if audio != null and audio.has_method("play_win"):
		audio.play_win()
	if cam != null:
		cam.shake(0.4)
		if t != null:
			cam.focus_on(t.position * 0.3 + Vector3(2.2, 0, 1.0) * 0.7)
	# Let the celebration breathe before releasing the drain.
	var timer := get_tree().create_timer(1.2)
	await timer.timeout


func snap_all_visuals() -> void:
	_refresh_anchors()
	_tidy_halos()


func force_unwedge() -> void:
	# Stall watchdog escape: drop the queue, release input.
	_queue.clear()
	busy = false
	drained.emit()
