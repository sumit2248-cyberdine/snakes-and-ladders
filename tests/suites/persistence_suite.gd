class_name SnakesPersistenceSuite
extends RefCounted
## Serializer + replay determinism. Mirrors Ludo's persistence_flow.

static var failures: int = 0


static func check(cond: bool, name: String) -> void:
	if cond:
		print("  ok: ", name)
	else:
		failures += 1
		printerr("  FAIL: ", name)


static func run() -> bool:
	failures = 0
	print("[persistence] serializer round-trip")
	var s := SnakesSession.new()
	s.settings = SnakesMatchSettings.with_players(3, false)
	s.rule_set = SnakesRuleSet.blitz()
	s.dice.seed_with(555)
	s.begin()
	for i in 12:
		if s.fsm.current_id == SnakesFSM.AWAIT_ROLL:
			s.dispatch_action(SnakesAction.roll(s.current))
	var d := SnakesSerializer.serialize_match(s)
	var s2 := SnakesSerializer.deserialize_match(d)
	check(s2 != null, "deserializes")
	check(s2.rules.positions == s.rules.positions, "positions survive")
	check(s2.current == s.current, "current survives")
	check(s2.rule_set.flag_dict() == s.rule_set.flag_dict(), "rule flags survive")
	# JSON float round-trip.
	var txt := JSON.stringify(d)
	var back = JSON.parse_string(txt)
	check(back is Dictionary, "json round-trip")
	var s3 := SnakesSerializer.deserialize_match(back)
	check(s3 != null and s3.rules.positions == s.rules.positions, "json positions survive")

	print("[persistence] bad input degrades to null")
	check(SnakesSerializer.deserialize_match({}) == null, "empty dict -> null")
	check(SnakesSerializer.deserialize_match({"version": 999}) == null, "bad version -> null")

	print("[persistence] replay determinism")
	var logger := SnakesReplayLogger.new()
	logger.start_recording()
	var a := SnakesSession.new()
	a.settings = SnakesMatchSettings.with_players(2, true)
	a.rule_set = SnakesRuleSet.classic()
	a.dice.seed_with(2024)
	logger.dice_seed = 2024
	logger.has_dice_seed = true
	a.begin()
	var guard := 0
	while a.fsm.current_id != SnakesFSM.GAME_OVER and guard < 3000:
		guard += 1
		if a.fsm.current_id == SnakesFSM.AWAIT_ROLL:
			logger.dispatch(a, SnakesAction.roll(a.current))
	check(a.fsm.current_id == SnakesFSM.GAME_OVER, "recorded match finishes")
	var settings := SnakesMatchSettings.with_players(2, true)
	var b := logger.play_into(settings, SnakesRuleSet.classic())
	check(b.rules.positions == a.rules.positions, "replay reproduces positions")
	check(b.winner == a.winner, "replay reproduces winner")
	print("[persistence] failures: %d" % failures)
	return failures == 0
