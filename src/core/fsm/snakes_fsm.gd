class_name SnakesFSM
extends RefCounted
## State Pattern router. Mirrors Ludo's MatchFSM: goto() emits STATE_CHANGED.

const AWAIT_ROLL := "await_roll"
const ROLLING := "rolling"
const MOVING := "moving"
const GAME_OVER := "game_over"

var session: SnakesSession
var states: Dictionary = {}
var current_id: String = ""
var _depth := 0
var _pending: String = ""


func _init(p_session: SnakesSession) -> void:
	session = p_session
	states[AWAIT_ROLL] = SnakesAwaitRollState.new(p_session)
	states[ROLLING] = SnakesRollingState.new(p_session)
	states[MOVING] = SnakesMovingState.new(p_session)
	states[GAME_OVER] = SnakesGameOverState.new(p_session)


func start() -> void:
	goto(AWAIT_ROLL)


func current() -> SnakesState:
	return states.get(current_id, null)


func goto(to_id: String) -> void:
	if not states.has(to_id):
		push_error("SnakesFSM: unknown state %s" % to_id)
		return
	# States chain goto() from inside enter() (roll -> resolve -> move);
	# queue nested requests and drain them outermost-first instead of dropping.
	if _depth > 0:
		_pending = to_id
		return
	_depth = 1
	var target: String = to_id
	while target != "":
		var from_id: String = current_id
		if from_id != "" and states.has(from_id):
			(states[from_id] as SnakesState).exit()
		current_id = target
		target = ""
		session.emit_event(SnakesEvent.state_changed(from_id, current_id))
		(states[current_id] as SnakesState).enter()
		# enter() may have queued the next hop.
		target = _pending
		_pending = ""
	_depth = 0


func process_action(action: SnakesAction) -> bool:
	var st := current()
	if st == null:
		return false
	return st.process_action(action)


func begin_move(mv: SnakesMoveOption) -> void:
	var moving := states[MOVING] as SnakesMovingState
	moving.pending = mv
	goto(MOVING)
