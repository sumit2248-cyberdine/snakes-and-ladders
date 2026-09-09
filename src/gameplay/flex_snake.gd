class_name SnakesFlexSnake
extends Node3D
## Flexible snake rig (mesh blueprint level; texturing comes later).
## Same tube/head recipe as SnakesSnakeBuilder, but rebuildable every frame:
## the body mesh is re-emitted from the centerline whenever a knob moves, so
## the snake can slim/fatten, grow/shrink, lunge at a token, and push a
## digest lump neck -> tail without tearing UVs or breaking ring shape.
##
## Knobs (all adjustable per snake; the board carries several sizes):
##   girth_scale  — <1 slim, >1 fat.
##   length_scale — <1 short/straight, >1 long winding coils.
## Animation state (driven by play_strike / play_digest, or set directly):
##   lunge_offset — head displacement from its rest pose (strike attack).
##   digest_pos   — bulge param t, travels 1 (neck) -> 0 (tail).
##   digest_size  — bulge radius in metres, 0 hides the lump.
## NOTE: this rig animates only itself. Token shrink/attach stays with the
## choreographer when the elements are combined into the game.

## Slim (<1) / fatten (>1) the body.
@export_range(0.4, 2.5, 0.05) var girth_scale: float = 1.0
## Shorten (<1) / lengthen (>1) the winding coils.
@export_range(0.3, 2.5, 0.05) var length_scale: float = 1.0
## Furthest the head may lunge from rest during a strike.
@export var max_strike_range: float = 3.0

var tail_base := Vector3.ZERO
var head_base := Vector3(0, 0.5, 2.5)
var variant_seed: int = 1
## Board head cell this rig belongs to (-1 = standalone preview).
var head_cell: int = -1
var lunge_offset := Vector3.ZERO
var digest_pos: float = -1.0
var digest_size: float = 0.0

var _body: MeshInstance3D = null
var _head: Node3D = null
var _points: Array[Vector3] = []
var _rest_segs := 32
var _rest_band := 7
var _segs := 0
var _live_tweens: Array[Tween] = []
var _gen := 0


func setup(p_tail: Vector3, p_head: Vector3, p_seed: int) -> SnakesFlexSnake:
	tail_base = p_tail
	head_base = p_head
	variant_seed = p_seed
	# Freeze tessellation + banding from the rest pose: every later rebuild
	# (lunge, digest, knobs) re-emits the same vertex/UV layout, so nothing
	# pops or re-tiles mid-animation.
	var rest_dist: float = maxf(p_tail.distance_to(p_head), 0.5)
	_rest_segs = clampi(int(rest_dist * 6.0) + 20, 24, 44)
	_rest_band = clampi(int(rest_dist * 0.9), 5, 9)
	rebuild()
	return self


## Re-emit the tube + head frame from the current knobs. Cheap enough
## (~600 verts) to call every tween tick during strike/digest.
func rebuild() -> void:
	var rng := SnakesSnakeBuilder.rng_for_seed(variant_seed)
	var pal := SnakesSnakeBuilder._palette_for(variant_seed)
	var head_now: Vector3 = head_base + lunge_offset
	_points = SnakesSnakeBuilder._sample_centerline(
		tail_base, head_now, rng, length_scale, girth_scale, _rest_segs)
	_segs = _points.size() - 1
	var frames := SnakesSnakeBuilder._compute_frames(_points)
	var mesh := SnakesSnakeBuilder.body_mesh_for(
		_points, frames[0], frames[1], _rest_band, _segs, pal,
		girth_scale, digest_pos, digest_size)
	if _body == null or not is_instance_valid(_body):
		_body = MeshInstance3D.new()
		_body.name = "FlexBody"
		_body.material_override = SnakesSnakeBuilder._body_mat()
		add_child(_body)
	_body.mesh = mesh
	var arrival: Vector3 = frames[2][frames[2].size() - 1]
	if _head == null or not is_instance_valid(_head):
		SnakesSnakeBuilder._build_head(self, head_now, arrival, pal)
		_head = get_node_or_null("Head")
	else:
		_head.transform = SnakesSnakeBuilder.head_transform_for(head_now, arrival)


## Current head world position (rest pose + lunge).
func head_now() -> Vector3:
	return head_base + lunge_offset


## Polyline length of the live centerline (grows with length_scale).
func centerline_length() -> float:
	var total := 0.0
	for i in range(1, _points.size()):
		total += _points[i].distance_to(_points[i - 1])
	return total


func body_mesh() -> ArrayMesh:
	return _body.mesh as ArrayMesh if _body != null else null


func set_girth(g: float) -> void:
	girth_scale = clampf(g, 0.4, 2.5)
	rebuild()


func set_length(l: float) -> void:
	length_scale = clampf(l, 0.3, 2.5)
	rebuild()


func set_lunge(offset: Vector3) -> void:
	lunge_offset = offset
	rebuild()


func set_digest(t01: float, size: float) -> void:
	digest_pos = clampf(t01, 0.0, 1.0)
	digest_size = maxf(size, 0.0)
	rebuild()


func clear_digest() -> void:
	digest_pos = -1.0
	digest_size = 0.0
	rebuild()


## Strike attack: head lunges toward `target` (clamped to range) and back.
## The body stretches with the head because every tick rebuilds the tube.
func play_strike(target: Vector3, out_dur: float = 0.18, back_dur: float = 0.35) -> void:
	# Outward lunge, clamped so the neck never over-extends.
	var want: Vector3 = target - head_now()
	if want.length() > max_strike_range:
		want = want.normalized() * max_strike_range
	kill_anims()
	var fwd_from := lunge_offset
	var fwd_to := lunge_offset + want
	var tw := create_tween()
	_track(tw)
	tw.tween_method(_apply_lunge.bind(fwd_from, fwd_to), 0.0, 1.0, out_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_method(_apply_lunge.bind(fwd_to, fwd_from), 0.0, 1.0, back_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


## Digest: a lump travels neck (t=1) -> tail (t=0), then clears. The token
## shrink/attach itself stays with the choreographer; this is the body wave.
func play_digest(duration: float = 1.4, size: float = 0.22) -> void:
	kill_anims()
	digest_size = size
	var tw := create_tween()
	_track(tw)
	tw.tween_method(_apply_digest, 1.0, 0.0, duration).set_trans(Tween.TRANS_LINEAR)
	tw.tween_callback(clear_digest)


## Drop pending strike/digest tweens (restart-safe; mirrors choreographer).
func kill_anims() -> void:
	_gen += 1
	for tw in _live_tweens:
		if is_instance_valid(tw):
			tw.kill()
	_live_tweens.clear()


func _track(tw: Tween) -> void:
	_live_tweens.append(tw)


func _apply_lunge(u: float, from_off: Vector3, to_off: Vector3) -> void:
	lunge_offset = from_off.lerp(to_off, u)
	rebuild()


func _apply_digest(t01: float) -> void:
	digest_pos = t01
	rebuild()
