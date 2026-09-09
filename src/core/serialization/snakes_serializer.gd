class_name SnakesSerializer
extends RefCounted
## JSON save v1. Mirrors Ludo's MatchSerializer (null on bad version/missing keys).

const VERSION := 1
const AUTOSAVE_PATH := "user://snakes_save.json"


static func serialize_match(session: SnakesSession, meta: Dictionary = {}) -> Dictionary:
	return {
		"version": VERSION,
		"positions": session.rules.positions.duplicate(),
		"finish_order": session.rules.finish_order.duplicate(),
		"current": session.current,
		"die_value": session.die_value,
		"six_streak": session.six_streak,
		"winner": session.winner,
		"turn_count": session.turn_count,
		"seats": session.settings.seat_types.duplicate(),
		"portal_preset": session.settings.portal_preset,
		"rule_flags": session.rule_set.flag_dict(),
		"dice": session.dice.stream_state(),
		"meta": meta,
	}


static func deserialize_match(data: Dictionary) -> SnakesSession:
	if int(data.get("version", -1)) != VERSION:
		return null
	if not data.has("positions") or not data.has("current") or not data.has("seats"):
		return null
	var s := SnakesSession.new()
	s.rule_set = SnakesRuleSet.classic()
	if data.has("rule_flags") and data["rule_flags"] is Dictionary:
		s.rule_set.apply_flag_dict(data["rule_flags"])
	var preset: String = str(data.get("portal_preset", "classic_mb"))
	s.settings = SnakesMatchSettings.new()
	s.settings.portal_preset = preset
	var seats: Array = []
	for v in data["seats"]:
		seats.append(int(v))
	while seats.size() < 4:
		seats.append(SnakesMatchSettings.SeatType.OFF)
	s.settings.seat_types = seats
	s.rules.setup(preset)
	var pos: Array[int] = []
	for v in data["positions"]:
		pos.append(clampi(int(v), 0, 100))
	while pos.size() < 4:
		pos.append(0)
	s.rules.positions = pos
	var fo: Array[int] = []
	for v in data.get("finish_order", []):
		fo.append(int(v))
	s.rules.finish_order = fo
	s.current = int(data["current"])
	s.die_value = int(data.get("die_value", 0))
	s.six_streak = int(data.get("six_streak", 0))
	s.winner = int(data.get("winner", -1))
	s.turn_count = int(data.get("turn_count", 1))
	if data.has("dice") and data["dice"] is Dictionary:
		s.dice.restore_stream(data["dice"])
	return s


static func save_to_file(session: SnakesSession, path: String = AUTOSAVE_PATH) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("SnakesSerializer: cannot write %s" % path)
		return false
	f.store_string(JSON.stringify(serialize_match(session)))
	f.close()
	return true


static func load_from_file(path: String = AUTOSAVE_PATH) -> SnakesSession:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		return null
	return deserialize_match(parsed)


static func has_autosave(path: String = AUTOSAVE_PATH) -> bool:
	return FileAccess.file_exists(path)


static func clear_autosave(path: String = AUTOSAVE_PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
