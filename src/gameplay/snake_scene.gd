class_name SnakesSnakeScene
extends Node3D
## Isolated snake blueprint: open scenes/snake/Snake.tscn to preview one
## flexible snake on its own. Girth slims/fattens the body, length winds or
## straightens the coils — one snake per size on the board just reuses this
## with different knobs. Mirrors the Ladder.tscn thin shell.

## Slim (<1) / fatten (>1) the body.
@export_range(0.4, 2.5, 0.05) var girth: float = 1.0
## Shorten (<1) / lengthen (>1) the winding coils.
@export_range(0.3, 2.5, 0.05) var snake_length: float = 1.0
## Head-to-tail span of the preview in metres.
@export_range(1.0, 10.0, 0.1) var preview_span: float = 3.0
## Coil pattern variant (same palettes as the board snakes).
@export var variant_seed: int = 87

var snake: SnakesFlexSnake = null


func _ready() -> void:
	rebuild()


## Rebuild the preview (frees the previous rig first).
func rebuild() -> void:
	if snake != null and is_instance_valid(snake):
		snake.queue_free()
	snake = SnakesFlexSnake.new()
	snake.girth_scale = girth
	snake.length_scale = snake_length
	add_child(snake)
	snake.setup(Vector3.ZERO, Vector3(0, 0.5, preview_span), variant_seed)


## Adjust knobs at runtime and rebuild (different snake sizes).
func set_knobs(p_girth: float, p_length: float) -> void:
	girth = p_girth
	snake_length = p_length
	if is_inside_tree():
		rebuild()
