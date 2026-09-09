class_name SnakesAction
extends RefCounted
## Command vocabulary. Only SnakesSession.dispatch_action mutates match state.
## Mirrors Ludo's MatchAction.

enum Type { ROLL_DICE, RESTART_MATCH }

var type: int = Type.ROLL_DICE
var player: int = -1


static func roll(p_player: int) -> SnakesAction:
	var a := SnakesAction.new()
	a.type = Type.ROLL_DICE
	a.player = p_player
	return a


static func restart() -> SnakesAction:
	var a := SnakesAction.new()
	a.type = Type.RESTART_MATCH
	a.player = -1
	return a
