class_name SnakesMovingState
extends SnakesState
## Applies the staged move, bursts the event fan-out, then ends the turn.

var pending: SnakesMoveOption


func id() -> String:
	return SnakesFSM.MOVING


func enter() -> void:
	var s := session
	if pending == null:
		push_error("SnakesMovingState: no pending move; skipping turn")
		s.emit_event(SnakesEvent.turn_ended(s.current, false, "no_moves"))
		s.advance_turn()
		s.fsm.goto(SnakesFSM.AWAIT_ROLL)
		return
	# Re-validate (rules may have changed under a restored save).
	var fresh := s.rules.legal_moves(pending.player, s.die_value, s.rule_set)
	var ok := false
	for m in fresh:
		if m.to_pos == pending.to_pos:
			ok = true
	if not ok:
		s.emit_event(SnakesEvent.turn_ended(s.current, false, "no_moves"))
		s.advance_turn()
		s.fsm.goto(SnakesFSM.AWAIT_ROLL)
		return
	var res: SnakesMoveResult = s.rules.apply_move(pending.player, s.die_value, s.rule_set)
	s.emit_event(SnakesEvent.token_moved(res.player, res.from_pos, res.landed_pos, res.die))
	if res.hit_snake:
		s.emit_event(SnakesEvent.snake_hit(res.player, res.landed_pos, res.final_pos))
	elif res.hit_ladder:
		s.emit_event(SnakesEvent.ladder_climbed(res.player, res.landed_pos, res.final_pos))
	if res.entered_win:
		var rank: int = s.rules.finish_order.size()
		s.emit_event(SnakesEvent.turn_ended(res.player, false, SnakesTurnEndReason.format_finished_rank(rank)))
		var active := s.settings.active_seats()
		if s.rules.game_decided(active.size()):
			s.winner = s.rules.finish_order[0] if not s.rules.finish_order.is_empty() else res.player
			s.emit_event(SnakesEvent.game_over(s.winner, s.rules.finish_order))
			s.fsm.goto(SnakesFSM.GAME_OVER)
		else:
			s.advance_turn()
			s.fsm.goto(SnakesFSM.AWAIT_ROLL)
		return
	if res.grants_extra_turn:
		s.emit_event(SnakesEvent.turn_ended(res.player, true, ""))
		s.fsm.goto(SnakesFSM.AWAIT_ROLL)
	else:
		# Six streak already maintained by RollingState.enter.
		s.emit_event(SnakesEvent.turn_ended(res.player, false, ""))
		s.advance_turn()
		s.fsm.goto(SnakesFSM.AWAIT_ROLL)


func exit() -> void:
	pending = null
