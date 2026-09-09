class_name SnakesState
extends RefCounted
## FSM base. Mirrors Ludo's MatchState: enter/exit hooks + action gate.

var session: SnakesSession


func _init(p_session: SnakesSession = null) -> void:
	session = p_session


func id() -> String:
	return "base"


func enter() -> void:
	pass


func exit() -> void:
	pass


## Returns true when the action was consumed.
func process_action(_action: SnakesAction) -> bool:
	return false
