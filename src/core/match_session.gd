class_name SnakesSession
extends RefCounted
## Authoritative coordinator. dispatch_action is the ONLY gameplay entry point.
## Fully synchronous: never awaits presentation. Mirrors Ludo's MatchSession.

signal event_emitted(event: SnakesEvent)

var rules := SnakesRules.new()
var dice := SnakesDiceEngine.new()
var settings := SnakesMatchSettings.new()
var rule_set := SnakesRuleSet.classic()
var fsm: SnakesFSM

var current: int = 0
var die_value: int = 0
var six_streak: int = 0
var winner: int = -1
var legal_now: Array[SnakesMoveOption] = []
var turn_count: int = 0


func _init() -> void:
	fsm = SnakesFSM.new(self)


func begin() -> void:
	rules.setup(rule_set.portal_preset)
	rules.reset()
	current = _first_seat()
	die_value = 0
	six_streak = 0
	winner = -1
	legal_now = []
	turn_count = 1
	fsm.start()


func _first_seat() -> int:
	var active := settings.active_seats()
	if active.is_empty():
		return 0
	return active[0]


func dispatch_action(action: SnakesAction) -> void:
	if fsm.current_id == SnakesFSM.GAME_OVER and action.type != SnakesAction.Type.RESTART_MATCH:
		return
	if action.type == SnakesAction.Type.RESTART_MATCH:
		begin()
		return
	fsm.process_action(action)


func advance_turn() -> void:
	var active := settings.active_seats()
	if active.is_empty():
		return
	var idx: int = active.find(current)
	if idx == -1:
		current = active[0]
		turn_count += 1
		legal_now = []
		return
	for step in range(1, active.size() + 1):
		var cand: int = active[(idx + step) % active.size()]
		if not rules.is_finished(cand):
			current = cand
			turn_count += 1
			legal_now = []
			return
	# Everyone finished (should have been GAME_OVER already).
	legal_now = []


func match_decided() -> bool:
	return rules.game_decided(settings.active_count())


func emit_event(event: SnakesEvent) -> void:
	event_emitted.emit(event)
