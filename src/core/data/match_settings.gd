class_name SnakesMatchSettings
extends RefCounted
## Who sits at each seat. Mirrors Ludo's MatchSettings, trimmed to 1 token/seat.

enum SeatType { HUMAN, AI, OFF }

var seat_types: Array = [SeatType.HUMAN, SeatType.AI, SeatType.OFF, SeatType.OFF]
var portal_preset: String = "classic_mb"


func active_seats() -> Array[int]:
	var out: Array[int] = []
	for i in seat_types.size():
		if int(seat_types[i]) != SeatType.OFF:
			out.append(i)
	return out


func active_count() -> int:
	return active_seats().size()


## Seat layout for N players: 2P diagonal (Red/Yellow), 3P first three, 4P all.
static func seat_layout_for(player_count: int) -> Array[int]:
	match player_count:
		2:
			return [0, 2]
		3:
			return [0, 1, 2]
		_:
			return [0, 1, 2, 3]


static func with_players(player_count: int, all_ai: bool = false) -> SnakesMatchSettings:
	var s := SnakesMatchSettings.new()
	var seats: Array = [SeatType.OFF, SeatType.OFF, SeatType.OFF, SeatType.OFF]
	var layout := seat_layout_for(player_count)
	for i in layout.size():
		var seat: int = layout[i]
		if all_ai:
			seats[seat] = SeatType.AI
		else:
			seats[seat] = SeatType.HUMAN if i == 0 else SeatType.AI
	s.seat_types = seats
	return s
