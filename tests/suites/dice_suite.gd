class_name SnakesDiceSuite
extends RefCounted
## Dice face math: basis layout, pip grids, and the Ludo-ported top_face()
## read-back. Headless-safe: no tree, no tweens, no awaits.

static var failures: int = 0


static func check(cond: bool, name: String) -> void:
	if cond:
		print("  ok: ", name)
	else:
		failures += 1
		printerr("  FAIL: ", name)


static func run() -> bool:
	failures = 0
	print("[dice] standard layout, opposites sum to 7")
	var normals: Dictionary = SnakesDice.FACE_NORMALS
	check((normals[1] + normals[6]).length() < 0.001, "1 opposite 6")
	check((normals[2] + normals[5]).length() < 0.001, "2 opposite 5")
	check((normals[3] + normals[4]).length() < 0.001, "3 opposite 4")

	print("[dice] face bases carry their face up")
	for face in range(1, 7):
		var up: Vector3 = SnakesDice.face_basis(face) * normals[face]
		check(up.distance_to(Vector3.UP) < 0.001, "face %d basis points up" % face)

	print("[dice] pip counts match faces")
	for face in range(1, 7):
		check((SnakesDice.pip_grid(face) as Array).size() == face, "face %d has %d pips" % [face, face])

	print("[dice] top_face read-back (Ludo port)")
	var die := SnakesDice.new()
	for face in range(1, 7):
		die.snap_to_face(face, 0.0)
		check(die.top_face() == face, "face %d reads back" % face)
		die.snap_to_face(face, 1.37)
		check(die.top_face() == face, "face %d reads back under yaw" % face)
		check(die.value == face, "value tracks face %d" % face)
	die.free()

	print("[dice] failures: %d" % failures)
	return failures == 0
