class_name SnakesDiceEngine
extends RefCounted
## Fair d6 with seeded stream (PCG) or entropy chain. Mirrors Ludo DiceEngine API.

var _rng := RandomNumberGenerator.new()
var _seed: int = 0
var _has_seed: bool = false


func _init() -> void:
	_rng.randomize()


func roll() -> int:
	return _rng.randi_range(1, 6)


func roll_for() -> int:
	return roll()


func seed_with(s: int) -> void:
	_seed = s
	_has_seed = true
	_rng.seed = s


func get_seed() -> int:
	return _seed


func has_seed() -> bool:
	return _has_seed


func stream_state() -> Dictionary:
	return {"seed": _seed, "has_seed": _has_seed, "rng_state": _rng.state}


func restore_stream(st: Dictionary) -> void:
	_seed = int(st.get("seed", 0))
	_has_seed = bool(st.get("has_seed", false))
	if _has_seed:
		_rng.seed = _seed
		_rng.state = int(st.get("rng_state", _rng.state))
