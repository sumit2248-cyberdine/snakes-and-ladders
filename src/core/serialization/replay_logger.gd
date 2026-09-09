class_name SnakesReplayLogger
extends RefCounted
## Seeded action-log replays. Mirrors Ludo's ReplayLogger.

const LAST_PATH := "user://snakes_last_replay.json"

var actions: Array = []
var dice_seed: int = 0
var has_dice_seed: bool = false


func start_recording() -> void:
	actions = []


func log_action(action: SnakesAction) -> void:
	actions.append({"type": action.type, "player": action.player})


func dispatch(session: SnakesSession, action: SnakesAction) -> void:
	log_action(action)
	session.dispatch_action(action)


func to_dict() -> Dictionary:
	return {
		"version": 1,
		"dice_seed": dice_seed,
		"has_dice_seed": has_dice_seed,
		"actions": actions.duplicate(),
	}


func from_dict(d: Dictionary) -> void:
	dice_seed = int(d.get("dice_seed", 0))
	has_dice_seed = bool(d.get("has_dice_seed", false))
	actions = (d.get("actions", []) as Array).duplicate()


## Replays into a fresh session with identical settings/rules. Returns the session.
func play_into(settings: SnakesMatchSettings, rule_set: SnakesRuleSet) -> SnakesSession:
	var s := SnakesSession.new()
	s.settings = settings
	s.rule_set = rule_set
	if has_dice_seed:
		s.dice.seed_with(dice_seed)
	s.begin()
	for a in actions:
		var act := SnakesAction.new()
		act.type = int(a.get("type", 0))
		act.player = int(a.get("player", -1))
		s.dispatch_action(act)
	return s


func save_last() -> bool:
	var f := FileAccess.open(LAST_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(to_dict()))
	f.close()
	return true


static func load_last() -> SnakesReplayLogger:
	if not FileAccess.file_exists(LAST_PATH):
		return null
	var f := FileAccess.open(LAST_PATH, FileAccess.READ)
	if f == null:
		return null
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		return null
	var r := SnakesReplayLogger.new()
	r.from_dict(parsed)
	return r
