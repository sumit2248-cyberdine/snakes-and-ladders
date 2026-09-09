class_name SnakesMoveResult
extends RefCounted
## Outcome of SnakesRules.apply_move: landing + optional portal + win/extra flags.

var player: int = -1
var from_pos: int = 0
var landed_pos: int = 0
var final_pos: int = 0
var die: int = 0
var hit_snake: bool = false
var hit_ladder: bool = false
var entered_win: bool = false
var grants_extra_turn: bool = false


static func make(p_player: int, p_from: int, p_landed: int, p_final: int, p_die: int) -> SnakesMoveResult:
	var r := SnakesMoveResult.new()
	r.player = p_player
	r.from_pos = p_from
	r.landed_pos = p_landed
	r.final_pos = p_final
	r.die = p_die
	return r
