class_name SnakesBoardStyle
extends RefCounted
## Shared geometry constants so rules (PathData) and builders agree.
## Mirrors Ludo's TILE_TOP / TILE_SIZE convention.

const TILE_TOP := 0.14
const TILE_SIZE := 1.48
const TILE_PITCH := 1.6
const TOKEN_HOVER := 0.0

# Step-farm terraces: bands of 10 cells (1-10, 11-20, ... 91-100).
# Keep the single source of default knobs here so headless paths
# (PathData.anchor_for, token_anchor) agree without needing a Resource.
const TERRACE_STEP := 0.35
const TERRACE_MASTER := 1.0
const TERRACE_COUNT := 10

# Live knobs (visual-only mirror, NOT session state). The last built board
# wins; headless paths that never build a board see the defaults.
# Set via set_active_terrace() — the board director owns this, and the
# choreographer/tokens read it through tile_top_for_cell().
static var active_step: float = TERRACE_STEP
static var active_master: float = TERRACE_MASTER


static func set_active_terrace(step: float, master: float) -> void:
	active_step = maxf(step, 0.0)
	active_master = clampf(master, 0.0, 2.0)


static func reset_active_terrace() -> void:
	active_step = TERRACE_STEP
	active_master = TERRACE_MASTER


## 1..100 -> terrace band 0..9. Off-board / out-of-range -> -1.
static func terrace_index_for_cell(cell: int) -> int:
	if cell < 1 or cell > 100:
		return -1
	return int((cell - 1) / 10)


## Terrace lift for a cell. Omit knobs (negative) to use the live
## active_step/active_master set by the last built board.
static func terrace_y_for_cell(cell: int, step: float = -1.0, master: float = -1.0) -> float:
	var s: float = active_step if step < 0.0 else step
	var m: float = active_master if master < 0.0 else master
	var idx := terrace_index_for_cell(cell)
	if idx < 0:
		return 0.0
	return float(idx) * s * m


## Tile-top world Y for a cell under explicit knobs.
static func tile_top_for_cell(cell: int, step: float = -1.0, master: float = -1.0) -> float:
	return TILE_TOP + terrace_y_for_cell(cell, step, master)
