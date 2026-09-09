class_name SnakesLadderScene
extends Node3D
## Isolated ladder blueprint: open scenes/ladder/Ladder.tscn to preview one
## straight ladder on its own. Height knob raises/lowers the ladder; the rung
## count stays proportional automatically. Mirrors the Board.tscn thin shell.

## Ladder height in metres (foot at origin, rails rise straight up).
@export_range(0.5, 12.0, 0.1) var ladder_height: float = 3.0
## Target spacing between rungs; smaller values add more steps.
@export_range(0.2, 1.0, 0.05) var rung_spacing: float = SnakesLadderBuilder.RUNG_SPACING
## Rail separation in metres.
@export_range(0.3, 1.0, 0.02) var gauge: float = SnakesLadderBuilder.GAUGE

var ladder: Node3D = null


func _ready() -> void:
	rebuild()


## Rebuild the preview (frees the previous ladder first).
func rebuild() -> void:
	if ladder != null and is_instance_valid(ladder):
		ladder.queue_free()
	ladder = SnakesLadderBuilder.build_preview(self, ladder_height, gauge, rung_spacing)


## Adjust the height knob at runtime and rebuild (different ladder sizes).
func set_height(h: float) -> void:
	ladder_height = maxf(h, 0.5)
	if is_inside_tree():
		rebuild()
