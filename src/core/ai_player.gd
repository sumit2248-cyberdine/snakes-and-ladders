class_name SnakesAIPlayer
extends RefCounted
## Trivial facade: S&L has no move choice (one token, 0-1 legal moves).
## Kept as a seam mirroring Ludo's AIPlayer so personalities can hook in later.


static func choose_move(moves: Array[SnakesMoveOption]) -> SnakesMoveOption:
	if moves.is_empty():
		return null
	return moves[0]
