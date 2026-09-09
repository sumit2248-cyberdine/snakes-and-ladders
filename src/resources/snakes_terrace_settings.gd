class_name SnakesTerraceSettings
extends Resource
## Blueprint for the step-farmed board: rows 1-10 on terrace 0, 11-20 on
## terrace 1, ... 91-100 on terrace 9. Each terrace rises by `step_height`.
## `master_scale` is the master control knob: 0 = flat classic board,
## 1 = full terraced look. Texturing/colors come later; this is mesh-level data.
##
## Pure data (no scene tree) so headless tests can drive terrace math.

## Per-terrace rise in metres. Adjustable per project / per preset.
@export var step_height: float = 0.35
## Master control knob. Multiplies every terrace offset (0 = flat).
@export_range(0.0, 2.0, 0.05) var master_scale: float = 1.0


## Effective rise applied between two adjacent terraces.
func effective_step() -> float:
	return step_height * master_scale


## 1..100 -> terrace band 0..9. Off-board (0) and out-of-range -> -1.
static func terrace_index_for_cell(cell: int) -> int:
	if cell < 1 or cell > SnakesPathData.CELL_COUNT:
		return -1
	return int((cell - 1) / 10)


## World Y offset for a cell given an explicit step + master knob.
static func terrace_y_for(cell: int, step: float, master: float) -> float:
	var idx := terrace_index_for_cell(cell)
	if idx < 0:
		return 0.0
	return float(idx) * step * master


## World Y offset for a cell under this resource's knobs.
func terrace_y_for_cell(cell: int) -> float:
	return terrace_y_for(cell, step_height, master_scale)


## Tile-top world Y (base plate top + terrace lift).
func tile_top_for_cell(cell: int) -> float:
	return SnakesBoardStyle.TILE_TOP + terrace_y_for_cell(cell)


static func flat() -> SnakesTerraceSettings:
	var s := SnakesTerraceSettings.new()
	s.step_height = 0.35
	s.master_scale = 0.0
	return s


static func default() -> SnakesTerraceSettings:
	return SnakesTerraceSettings.new()
