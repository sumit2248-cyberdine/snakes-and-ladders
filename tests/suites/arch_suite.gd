class_name SnakesArchSuite
extends RefCounted
## Layering lint. Mirrors Ludo's arch_lint: core purity + doc drift + scene refs.

static var failures: int = 0


static func check(cond: bool, name: String) -> void:
	if cond:
		print("  ok: ", name)
	else:
		failures += 1
		printerr("  FAIL: ", name)


static func _walk(dir: String, out: Array[String]) -> void:
	var da := DirAccess.open(dir)
	if da == null:
		return
	for f in da.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for d in da.get_directories():
		if d == ".godot" or d == ".git":
			continue
		_walk(dir + "/" + d, out)


static func run() -> bool:
	failures = 0
	print("[arch] core purity (no scene tree in src/core)")
	var files: Array[String] = []
	_walk("res://src/core", files)
	var banned := ["Node3D", "Node2D", "create_tween", "add_child", "get_tree", "Input.", "preload(\"res://scenes", "CanvasLayer"]
	for f in files:
		var text := FileAccess.get_file_as_string(f)
		for b in banned:
			check(not text.contains(b), "%s has no %s" % [f.get_file(), b])
	print("[arch] event consumers: choreographer (3D) + director (HUD/AI) only")
	var gameplay: Array[String] = []
	_walk("res://src/gameplay", gameplay)
	var presenters := 0
	for f in gameplay:
		var text := FileAccess.get_file_as_string(f)
		if text.contains("event_emitted.connect"):
			presenters += 1
			var base := f.get_file()
			check(base == "move_choreographer.gd" or base == "main.gd", "known consumer only (%s)" % base)
	check(presenters == 2, "exactly director + choreographer consume events")
	print("[arch] failures: %d" % failures)
	return failures == 0
