class_name SnakesRollingState
extends SnakesState
## Resolves the rolled die: three-sixes forfeit, no-move pass, else stage a move.


func id() -> String:
	return SnakesFSM.ROLLING


func enter() -> void:
	var s := session
	# Track consecutive sixes for the three-sixes forfeit.
	if s.die_value == 6:
		s.six_streak += 1
	else:
		s.six_streak = 0
	if s.rule_set.cancel_on_three_sixes and s.six_streak >= 3:
		s.six_streak = 0
		s.emit_event(SnakesEvent.turn_ended(s.current, false, "three_sixes"))
		s.advance_turn()
		s.fsm.goto(SnakesFSM.AWAIT_ROLL)
		return
	var moves := s.rules.legal_moves(s.current, s.die_value, s.rule_set)
	if moves.is_empty():
		s.emit_event(SnakesEvent.turn_ended(s.current, false, "no_moves"))
		s.advance_turn()
		s.fsm.goto(SnakesFSM.AWAIT_ROLL)
		return
	s.legal_now = moves
	# S&L offers no choice (single token): stage immediately into MOVING.
	s.fsm.begin_move(moves[0])
