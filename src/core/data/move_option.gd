class_name SnakesMoveOption
extends RefCounted
## One legal move: advance `steps` from `from_pos` to `to_pos` (pre-portal).
## S&L has one token per seat, so a turn offers 0 or 1 options.

var player: int = -1
var from_pos: int = 0
var to_pos: int = 0
var die: int = 0


static func make(p_player: int, p_from: int, p_to: int, p_die: int) -> SnakesMoveOption:
	var m := SnakesMoveOption.new()
	m.player = p_player
	m.from_pos = p_from
	m.to_pos = p_to
	m.die = p_die
	return m
