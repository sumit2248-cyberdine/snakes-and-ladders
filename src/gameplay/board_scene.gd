class_name SnakesBoardScene
extends Node3D
## World construction order wrapper. Mirrors Ludo's BoardScene._ready order.

var builder := SnakesBoardBuilder.new()
var snakes: Dictionary = {}
var ladders: Dictionary = {}

# Terrace knobs, tweakable in the editor when Board.tscn is instanced.
# step_height: rise between adjacent 10-cell bands (1-10, 11-20, ...).
# master_scale: MASTER control knob (0 = flat classic board, 1 = terraces).
@export var terrace_step_height: float = SnakesBoardStyle.TERRACE_STEP
@export_range(0.0, 2.0, 0.05) var terrace_master_scale: float = SnakesBoardStyle.TERRACE_MASTER
# Optional blueprint resource; when set (non-null) it wins over the floats.
@export var terrace_settings: SnakesTerraceSettings = null


func setup(p_snakes: Dictionary, p_ladders: Dictionary, p_terrace: SnakesTerraceSettings = null) -> void:
	snakes = p_snakes.duplicate()
	ladders = p_ladders.duplicate()
	if p_terrace != null:
		terrace_settings = p_terrace
		terrace_step_height = p_terrace.step_height
		terrace_master_scale = p_terrace.master_scale


func _ready() -> void:
	if snakes.is_empty():
		snakes = SnakesPathData.snakes_for("classic_mb")
	if ladders.is_empty():
		ladders = SnakesPathData.ladders_for("classic_mb")
	if terrace_settings != null:
		terrace_step_height = terrace_settings.step_height
		terrace_master_scale = terrace_settings.master_scale
	builder.set_terrace(terrace_step_height, terrace_master_scale)
	builder.build_atmosphere(self)
	builder.build_dressing(self)
	builder.build_board(self, snakes, ladders)


func dice_rest() -> Vector3:
	return SnakesDiceTray.rest_pos(builder.tray_center)
