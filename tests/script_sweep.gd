extends SceneTree
## Compile-check every script (mirrors Ludo's script_sweep).

func _init() -> void:
	var files: Array[String] = []
	_walk("res://src", files)
	_walk("res://tests", files)
	var failures := 0
	for f in files:
		var res = load(f)
		if res == null:
			printerr("  FAIL compile: ", f)
			failures += 1
		else:
			print("  ok: ", f)
	print("=== script_sweep: %d files, %d failures ===" % [files.size(), failures])
	quit(0 if failures == 0 else 1)


func _walk(dir: String, out: Array[String]) -> void:
	var da := DirAccess.open(dir)
	if da == null:
		return
	for f in da.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for d in da.get_directories():
		_walk(dir + "/" + d, out)
