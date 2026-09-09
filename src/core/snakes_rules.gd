class_name SnakesRules
extends RefCounted
## Pure S&L engine: one token per seat on cells 0..100. No scene dependencies.
## Mirrors LudoRules layering: positions + legal_moves + apply_move + win query.

const POS_OFF := 0
const POS_WIN := 100

var positions: Array[int] = [0, 0, 0, 0]
var finish_order: Array[int] = []
var snakes: Dictionary = {}
var ladders: Dictionary = {}
var portals: Dictionary = {}


func setup(preset_id: String = "classic_mb") -> void:
	snakes = SnakesPathData.snakes_for(preset_id)
	ladders = SnakesPathData.ladders_for(preset_id)
	portals = SnakesPathData.portals_for(preset_id)


func reset() -> void:
	positions = [0, 0, 0, 0]
	finish_order = []


func token_pos(player: int) -> int:
	return positions[player]


## 0 or 1 legal moves. Empty when EXACT_STAY overshoot would pass 100.
func legal_moves(player: int, die: int, rule_set: SnakesRuleSet) -> Array[SnakesMoveOption]:
	var out: Array[SnakesMoveOption] = []
	var from: int = positions[player]
	if is_finished(player):
		return out
	var target: int = from + die
	match rule_set.finish_rule:
		SnakesRuleSet.FinishRule.EXACT_STAY:
			if target > POS_WIN:
				return out
		SnakesRuleSet.FinishRule.EXACT_BOUNCE:
			if target > POS_WIN:
				target = POS_WIN - (target - POS_WIN)
		SnakesRuleSet.FinishRule.OVERFLOW_WIN:
			if target >= POS_WIN:
				target = POS_WIN
			# else target stays from + die
	if target < 1:
		target = 1
	out.append(SnakesMoveOption.make(player, from, target, die))
	return out


## Applies one move (landing + single portal lookup + win). Returns rich result.
func apply_move(player: int, die: int, rule_set: SnakesRuleSet) -> SnakesMoveResult:
	var from: int = positions[player]
	var moves := legal_moves(player, die, rule_set)
	# No-move (overshoot under EXACT_STAY) is a pass-through result.
	if moves.is_empty():
		var stay := SnakesMoveResult.make(player, from, from, from, die)
		stay.grants_extra_turn = false
		return stay
	var landed: int = moves[0].to_pos
	var final_pos: int = landed
	var hit_snake := false
	var hit_ladder := false
	# Portal triggers on landing exactly. Bounce landing portals only if enabled.
	var is_bounced: bool = rule_set.finish_rule == SnakesRuleSet.FinishRule.EXACT_BOUNCE and (from + die) > POS_WIN
	var may_trigger: bool = (not is_bounced) or rule_set.bounce_triggers_portal
	if may_trigger and portals.has(landed):
		final_pos = int(portals[landed])
		if snakes.has(landed):
			hit_snake = true
		elif ladders.has(landed):
			hit_ladder = true
	# Overflow clamp: any landing at/past 100 wins.
	if rule_set.finish_rule == SnakesRuleSet.FinishRule.OVERFLOW_WIN and (from + die) >= POS_WIN:
		final_pos = POS_WIN
	positions[player] = final_pos
	var res := SnakesMoveResult.make(player, from, landed, final_pos, die)
	res.hit_snake = hit_snake
	res.hit_ladder = hit_ladder
	res.entered_win = final_pos == POS_WIN
	res.grants_extra_turn = move_grants_extra(die, res, rule_set)
	if res.entered_win:
		record_finish(player)
	return res


static func move_grants_extra(die: int, result: SnakesMoveResult, rule_set: SnakesRuleSet) -> bool:
	if result.entered_win:
		return false
	if rule_set.extra_roll_on_six and die == 6:
		return true
	if rule_set.extra_roll_on_ladder and result.hit_ladder:
		return true
	return false


func is_finished(player: int) -> bool:
	return finish_order.has(player)


func check_win(player: int) -> bool:
	return positions[player] == POS_WIN


func record_finish(player: int) -> void:
	if not finish_order.has(player):
		finish_order.append(player)


func game_decided(active_count: int) -> bool:
	return finish_order.size() >= maxi(1, active_count - 1)


func all_finished(active_seats: Array[int]) -> bool:
	for s in active_seats:
		if not finish_order.has(s):
			return false
	return true


func standings(active_seats: Array[int]) -> Array[int]:
	var out: Array[int] = finish_order.duplicate()
	for s in active_seats:
		if not out.has(s):
			out.append(s)
	# Rank unfinished seats by progress, descending.
	var tail: Array[int] = []
	for s in out:
		if not finish_order.has(s):
			tail.append(s)
	tail.sort_custom(func(a: int, b: int) -> bool: return positions[a] > positions[b])
	var ranked: Array[int] = []
	for s in finish_order:
		ranked.append(s)
	for s in tail:
		ranked.append(s)
	return ranked


func total_progress(player: int) -> int:
	return positions[player]
