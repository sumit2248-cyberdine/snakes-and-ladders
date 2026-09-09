class_name SnakesGameOverState
extends SnakesState


func id() -> String:
	return SnakesFSM.GAME_OVER


func process_action(action: SnakesAction) -> bool:
	if action.type == SnakesAction.Type.RESTART_MATCH:
		session.begin()
		return true
	return false
