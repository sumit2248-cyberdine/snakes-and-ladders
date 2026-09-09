class_name SnakesPathData
extends RefCounted
## Pure static data describing the 10x10 Snakes & Ladders board.
## Cells are 1..100, numbered boustrophedon (ox-plow):
## 1 = bottom-left, 10 = bottom-right, 11 = above 10, ..., 100 = top-left.
## Grid coords are Vector2i(col, row), col 0..9 left->right, row 0..9 top->bottom.
## World mapping: x = (col - 4.5) * CELL, z = (row - 4.5) * CELL.

const GRID := 10
const CELL := 1.6
const CELL_COUNT := 100
const POS_OFF := 0
const POS_WIN := 100

const PLAYER_COUNT := 4
const PLAYER_RED := 0
const PLAYER_GREEN := 1
const PLAYER_YELLOW := 2
const PLAYER_BLUE := 3

const PLAYER_NAMES: Array[String] = ["Red", "Green", "Yellow", "Blue"]

const PLAYER_COLORS: Array[Color] = [
	Color("e53935"),
	Color("43a047"),
	Color("fdd835"),
	Color("1e88e5"),
]

const PLAYER_COLORS_SOFT: Array[Color] = [
	Color("ee8f8f"),
	Color("93d193"),
	Color("ffdf70"),
	Color("82bcf0"),
]

const PLAYER_COLORS_DARK: Array[Color] = [
	Color("b71c1c"),
	Color("1b5e20"),
	Color("c79100"),
	Color("0d47a1"),
]

# Milton Bradley 1998/2013 canonical portals (9 ladders + 10 snakes).
const CLASSIC_LADDERS := {
	1: 38,
	4: 14,
	9: 31,
	21: 42,
	28: 84,
	36: 44,
	51: 67,
	71: 91,
	80: 100,
}

const CLASSIC_SNAKES := {
	16: 6,
	47: 26,
	49: 11,
	56: 53,
	62: 19,
	64: 60,
	87: 24,
	93: 73,
	95: 75,
	98: 78,
}

# Quick preset for testing / short mobile sessions.
const QUICK_LADDERS := {
	3: 22,
	8: 30,
	20: 41,
	36: 77,
	62: 100,
}

const QUICK_SNAKES := {
	17: 4,
	32: 12,
	55: 34,
	79: 58,
	96: 76,
}


## Cell (1..100) -> grid coords. Cell 0 (off-board) maps to below-board staging.
static func cell_to_grid(cell: int) -> Vector2i:
	if cell < 1 or cell > CELL_COUNT:
		return Vector2i(-1, -1)
	var r_from_bottom: int = (cell - 1) / GRID
	var c_in_row: int = (cell - 1) % GRID
	var col: int = c_in_row if r_from_bottom % 2 == 0 else GRID - 1 - c_in_row
	var row_from_top: int = (GRID - 1) - r_from_bottom
	return Vector2i(col, row_from_top)


static func grid_to_world(col: int, row: int) -> Vector3:
	return Vector3((float(col) - 4.5) * CELL, 0.0, (float(row) - 4.5) * CELL)


static func anchor_for(cell: int) -> Vector3:
	if cell < 1 or cell > CELL_COUNT:
		# Off-board staging: line up tokens below the board by seat order.
		return Vector3(0.0, 0.0, 5.5 * CELL)
	var g := cell_to_grid(cell)
	var w := grid_to_world(g.x, g.y)
	w.y = SnakesBoardStyle.tile_top_for_cell(cell)
	return w


## Explicit-knob variant so the board director can honour a
## SnakesTerraceSettings resource (step height + master scale).
## anchor_for(cell) above uses the BoardStyle defaults.
static func anchor_for_terraced(cell: int, step: float, master: float) -> Vector3:
	if cell < 1 or cell > CELL_COUNT:
		return Vector3(0.0, 0.0, 5.5 * CELL)
	var g := cell_to_grid(cell)
	var w := grid_to_world(g.x, g.y)
	w.y = SnakesBoardStyle.tile_top_for_cell(cell, step, master)
	return w


## Terrace band 0..9 for a cell (1-10 -> 0, ... 91-100 -> 9), -1 off-board.
static func terrace_index_for_cell(cell: int) -> int:
	return SnakesBoardStyle.terrace_index_for_cell(cell)


static func ladders_for(preset_id: String) -> Dictionary:
	if preset_id == "quick":
		return QUICK_LADDERS.duplicate()
	return CLASSIC_LADDERS.duplicate()


static func snakes_for(preset_id: String) -> Dictionary:
	if preset_id == "quick":
		return QUICK_SNAKES.duplicate()
	return CLASSIC_SNAKES.duplicate()


static func portals_for(preset_id: String) -> Dictionary:
	var out := {}
	for k in ladders_for(preset_id):
		out[k] = ladders_for(preset_id)[k]
	for k in snakes_for(preset_id):
		out[k] = snakes_for(preset_id)[k]
	return out


static func is_ladder_foot(cell: int, ladders: Dictionary) -> bool:
	return ladders.has(cell)


static func is_snake_head(cell: int, snakes: Dictionary) -> bool:
	return snakes.has(cell)


## Single portal lookup, no chaining (landing exactly only).
static func apply_portal(cell: int, portals: Dictionary) -> int:
	return int(portals.get(cell, cell))


static func validate_portals(snakes: Dictionary, ladders: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var seen := {}
	for foot in ladders:
		var top: int = int(ladders[foot])
		if foot < 1 or foot > 100 or top < 1 or top > 100:
			errors.append("ladder %d->%d out of range" % [foot, top])
		if top <= int(foot):
			errors.append("ladder %d->%d must climb" % [foot, top])
		if seen.has(foot):
			errors.append("duplicate portal start %d" % foot)
		seen[foot] = true
	for head in snakes:
		var tail: int = int(snakes[head])
		if head < 1 or head > 100 or tail < 1 or tail > 100:
			errors.append("snake %d->%d out of range" % [head, tail])
		if tail >= int(head):
			errors.append("snake %d->%d must slide down" % [head, tail])
		if seen.has(head):
			errors.append("duplicate portal start %d" % head)
		seen[head] = true
	return errors


static func progress_for(pos: int) -> int:
	return clampi(pos, 0, 100)
