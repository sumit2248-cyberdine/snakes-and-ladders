class_name SnakesAwaitRollState
extends SnakesState


func id() -> String:
	return SnakesFSM.AWAIT_ROLL


func process_action(action: SnakesAction) -> bool:
	if action.type != SnakesAction.Type.ROLL_DICE:
		return false
	if action.player != session.current:
		return false
	var die: int = session.dice.roll_for()
	session.die_value = die
	session.emit_event(SnakesEvent.dice_rolled(session.current, die))
	session.fsm.goto(SnakesFSM.ROLLING)
	return true
