class_name SnakesSetupScreen
extends CanvasLayer
## Title + seat config + rules preset. Mirrors Ludo's SetupScreen signal surface.

signal start_game(player_count: int, all_ai: bool, ruleset_id: String, seed_text: String)
signal continue_game
signal watch_replay

var _player_count := 2
var _all_ai := false
var _ruleset := "classic"
var _count_label: Label
var _resume_box: VBoxContainer


func _ready() -> void:
	layer = 20
	var theme := SnakesUITheme.build()
	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.2, 0.14, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var card := PanelContainer.new()
	card.theme = theme
	card.custom_minimum_size = Vector2(460, 0)
	center.add_child(card)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	card.add_child(vb)
	vb.add_child(SnakesUITheme.make_label("SNAKES & LADDERS", 44, Color("1b5e20")))
	vb.add_child(SnakesUITheme.make_label("Climb fast. Slide happens.", 18, Color("5d4037")))
	_resume_box = VBoxContainer.new()
	vb.add_child(_resume_box)
	_refresh_resume()
	vb.add_child(SnakesUITheme.make_label("Players", 22, Color("3e2723")))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vb.add_child(row)
	for n in [2, 3, 4]:
		var b := Button.new()
		b.text = str(n)
		b.pressed.connect(_on_count.bind(n))
		row.add_child(b)
	_count_label = SnakesUITheme.make_label("2 players (You + AI)", 18, Color("3e2723"))
	vb.add_child(_count_label)
	var ai_toggle := CheckButton.new()
	ai_toggle.text = "All-AI demo match"
	ai_toggle.toggled.connect(func(on: bool) -> void: _all_ai = on)
	vb.add_child(ai_toggle)
	vb.add_child(SnakesUITheme.make_label("Rules", 22, Color("3e2723")))
	var rules := HBoxContainer.new()
	rules.add_theme_constant_override("separation", 8)
	vb.add_child(rules)
	for id in ["classic", "blitz", "quick"]:
		var b := Button.new()
		b.text = id.capitalize()
		b.pressed.connect(_on_rules.bind(id))
		rules.add_child(b)
	var seed_row := HBoxContainer.new()
	vb.add_child(seed_row)
	seed_row.add_child(SnakesUITheme.make_label("Seed (blank = random):", 16, Color("3e2723")))
	var seed := LineEdit.new()
	seed.name = "Seed"
	seed.placeholder_text = "e.g. 1234"
	seed.custom_minimum_size = Vector2(140, 36)
	seed_row.add_child(seed)
	var play := Button.new()
	play.text = "PLAY"
	play.custom_minimum_size = Vector2(220, 58)
	play.pressed.connect(_on_play)
	vb.add_child(play)


func _refresh_resume() -> void:
	for c in _resume_box.get_children():
		c.queue_free()
	if SnakesSerializer.has_autosave():
		var b := Button.new()
		b.text = "CONTINUE MATCH"
		b.pressed.connect(func() -> void: continue_game.emit())
		_resume_box.add_child(b)
	if FileAccess.file_exists(SnakesReplayLogger.LAST_PATH):
		var w := Button.new()
		w.text = "WATCH LAST MATCH"
		w.pressed.connect(func() -> void: watch_replay.emit())
		_resume_box.add_child(w)


func _on_count(n: int) -> void:
	_player_count = n
	_count_label.text = "%d players (%s)" % [n, "demo" if _all_ai else "You + AI"]


func _on_rules(id: String) -> void:
	_ruleset = id


func _on_play() -> void:
	var seed_text := ""
	var seed_node := find_child("Seed", true, false)
	if seed_node is LineEdit:
		seed_text = (seed_node as LineEdit).text.strip_edges()
	start_game.emit(_player_count, _all_ai, _ruleset, seed_text)


## TEST SEAM: headless-friendly quick start.
func configure_for_test(player_count: int, ruleset: String = "classic") -> void:
	_player_count = player_count
	_ruleset = ruleset


func press_play() -> void:
	_on_play()
