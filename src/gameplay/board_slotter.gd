class_name SnakesSlotter
extends RefCounted
## Pure layout: stacking discs when seats share a cell. Mirrors Ludo's BoardSlotter.

const DISC_R := 0.22
const TILE_HALF := 0.74


## N occupants arranged on a circle (n=1 centered).
static func disc_offsets(n: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if n <= 1:
		out.append(Vector2.ZERO)
		return out
	var radius: float = clampf(DISC_R / sin(PI / float(n)), 0.26, TILE_HALF - DISC_R)
	for i in n:
		var a: float = TAU * float(i) / float(n) - PI * 0.5
		out.append(Vector2(cos(a), sin(a)) * radius)
	return out


static func disc_offset(slot: int, total: int) -> Vector2:
	return disc_offsets(total)[clampi(slot, 0, maxi(0, total - 1))]


## Seats sharing `cell`, stable seat order.
static func find_cell_occupants(rules: SnakesRules, cell: int) -> Array[int]:
	var out: Array[int] = []
	for seat in range(4):
		if rules.positions[seat] == cell and cell != SnakesRules.POS_OFF:
			out.append(seat)
	return out


static func token_anchor_for(rules: SnakesRules, seat: int) -> Vector3:
	var cell: int = rules.positions[seat]
	if cell == SnakesRules.POS_OFF:
		return offboard_anchor(seat)
	var occupants := find_cell_occupants(rules, cell)
	var slot: int = occupants.find(seat)
	return SnakesBoardBuilder.token_anchor(cell, maxi(slot, 0), occupants.size())


## Off-board staging row below the board.
static func offboard_anchor(seat: int) -> Vector3:
	return Vector3((float(seat) - 1.5) * 1.6, SnakesBoardStyle.TILE_TOP, 9.9)
