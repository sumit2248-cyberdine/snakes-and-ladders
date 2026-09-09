class_name SnakesEvent
extends RefCounted
## Notification vocabulary. Views consume the ordered stream; never mutate.
## Mirrors Ludo's MatchEvent with typed accessors (no stringly-typed payloads).

enum Type {
	STATE_CHANGED,
	DICE_ROLLED,
	TOKEN_MOVED,
	SNAKE_HIT,
	LADDER_CLIMBED,
	TURN_ENDED,
	GAME_OVER,
}

const KEYS := {
	Type.STATE_CHANGED: ["from", "to"],
	Type.DICE_ROLLED: ["die", "player"],
	Type.TOKEN_MOVED: ["player", "from_pos", "to_pos", "die"],
	Type.SNAKE_HIT: ["player", "from_pos", "to_pos"],
	Type.LADDER_CLIMBED: ["player", "from_pos", "to_pos"],
	Type.TURN_ENDED: ["player", "extra_turn", "reason"],
	Type.GAME_OVER: ["winner", "finish_order"],
}

var type: int = Type.STATE_CHANGED
var payload: Dictionary = {}


static func _make(t: int, p: Dictionary) -> SnakesEvent:
	var e := SnakesEvent.new()
	e.type = t
	e.payload = p
	return e


static func state_changed(from_id: String, to_id: String) -> SnakesEvent:
	return _make(Type.STATE_CHANGED, {"from": from_id, "to": to_id})


static func dice_rolled(player: int, die: int) -> SnakesEvent:
	return _make(Type.DICE_ROLLED, {"player": player, "die": die})


static func token_moved(player: int, from_pos: int, to_pos: int, die: int) -> SnakesEvent:
	return _make(Type.TOKEN_MOVED, {"player": player, "from_pos": from_pos, "to_pos": to_pos, "die": die})


static func snake_hit(player: int, from_pos: int, to_pos: int) -> SnakesEvent:
	return _make(Type.SNAKE_HIT, {"player": player, "from_pos": from_pos, "to_pos": to_pos})


static func ladder_climbed(player: int, from_pos: int, to_pos: int) -> SnakesEvent:
	return _make(Type.LADDER_CLIMBED, {"player": player, "from_pos": from_pos, "to_pos": to_pos})


static func turn_ended(player: int, extra_turn: bool, reason: String) -> SnakesEvent:
	return _make(Type.TURN_ENDED, {"player": player, "extra_turn": extra_turn, "reason": reason})


static func game_over(winner: int, finish_order: Array[int]) -> SnakesEvent:
	return _make(Type.GAME_OVER, {"winner": winner, "finish_order": finish_order.duplicate()})


func player() -> int:
	return int(payload.get("player", -1))


func die() -> int:
	return int(payload.get("die", 0))


func from_pos() -> int:
	return int(payload.get("from_pos", 0))


func to_pos() -> int:
	return int(payload.get("to_pos", 0))


func extra_turn() -> bool:
	return bool(payload.get("extra_turn", false))


func reason() -> String:
	return str(payload.get("reason", ""))


func reason_id() -> int:
	return SnakesTurnEndReason.id_of(reason())


func winner() -> int:
	return int(payload.get("winner", -1))


func finish_order() -> Array[int]:
	var out: Array[int] = []
	for v in payload.get("finish_order", []):
		out.append(int(v))
	return out


func state_from() -> String:
	return str(payload.get("from", ""))


func state_to() -> String:
	return str(payload.get("to", ""))
