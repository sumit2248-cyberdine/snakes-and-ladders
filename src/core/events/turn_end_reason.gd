class_name SnakesTurnEndReason
extends RefCounted
## TURN_ENDED vocabulary. Mirrors Ludo's TurnEndReason.

enum Id { NONE, THREE_SIXES, NO_MOVES, FINISHED_RANK }

static func format_finished_rank(rank: int) -> String:
	return "finished_rank_%d" % rank


static func id_of(s: String) -> int:
	if s == "three_sixes":
		return Id.THREE_SIXES
	if s == "no_moves":
		return Id.NO_MOVES
	if s.begins_with("finished_rank"):
		return Id.FINISHED_RANK
	return Id.NONE
