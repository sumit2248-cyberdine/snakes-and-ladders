class_name SnakesSessionSuite
extends RefCounted
## Full matches via dispatch_action only. Mirrors Ludo's session_flow.

static var failures: int = 0


static func check(cond: bool, name: String) -> void:
	if cond:
		print("  ok: ", name)
	else:
		failures += 1
		printerr("  FAIL: ", name)


static func _play_all_ai(seed: int, ai_games_note: String = "") -> SnakesSession:
	var s := SnakesSession.new()
	s.settings = SnakesMatchSettings.with_players(2, true)
	s.rule_set = SnakesRuleSet.classic()
	s.dice.seed_with(seed)
	s.begin()
	var events: Array[SnakesEvent] = []
	s.event_emitted.connect(func(ev: SnakesEvent) -> void: events.append(ev))
	var guard := 0
	while s.fsm.current_id != SnakesFSM.GAME_OVER and guard < 5000:
		guard += 1
		if s.fsm.current_id == SnakesFSM.AWAIT_ROLL:
			s.dispatch_action(SnakesAction.roll(s.current))
	return s


static func run(ai_games: int = 10) -> bool:
	failures = 0
	print("[session] all-AI matches x%d" % ai_games)
	var winners := {}
	for i in ai_games:
		var s := _play_all_ai(1000 + i)
		check(s.fsm.current_id == SnakesFSM.GAME_OVER, "game %d reaches GAME_OVER" % i)
		check(s.winner >= 0, "game %d has winner" % i)
		check(s.rules.positions[s.winner] == 100, "winner at 100")
		winners[s.winner] = true
	print("  info: winners across seats: ", winners.keys())

	print("[session] out-of-turn roll ignored")
	var s2 := SnakesSession.new()
	s2.settings = SnakesMatchSettings.with_players(2, false)
	s2.rule_set = SnakesRuleSet.classic()
	s2.dice.seed_with(7)
	s2.begin()
	var first: int = s2.current
	var other: int = 1 if first == 0 else 0
	# Find an active seat that is not current.
	var active := s2.settings.active_seats()
	other = active[(active.find(first) + 1) % active.size()]
	s2.dispatch_action(SnakesAction.roll(other))
	check(s2.die_value == 0, "out-of-turn roll rejected")

	print("[session] three sixes forfeit")
	var s3 := SnakesSession.new()
	s3.settings = SnakesMatchSettings.with_players(2, true)
	s3.rule_set = SnakesRuleSet.classic()
	s3.dice.seed_with(1)
	s3.begin()
	# Force dice by direct manipulation: easier to test streak logic via rolling state.
	# Simulate: set six_streak=2 then roll a 6 through a stubbed die.
	s3.six_streak = 2
	s3.die_value = 6
	s3.fsm.goto(SnakesFSM.ROLLING)
	check(s3.six_streak == 0, "three-sixes resets streak")

	print("[session] restart from game over")
	var s4 := _play_all_ai(4242)
	check(s4.fsm.current_id == SnakesFSM.GAME_OVER, "finished before restart")
	s4.dispatch_action(SnakesAction.restart())
	check(s4.fsm.current_id == SnakesFSM.AWAIT_ROLL, "restart returns to await_roll")
	check(s4.rules.positions == [0, 0, 0, 0], "restart clears positions")

	print("[session] failures: %d" % failures)
	return failures == 0
