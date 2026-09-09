class_name SnakesHUD
extends CanvasLayer
## In-game HUD. Emits intent signals; the director translates to SnakesActions.
## Mirrors Ludo's HUD layering (layer 10) with plates + top bar + ROLL + finale.

signal roll_pressed
signal pause_pressed
signal restart_pressed
signal view_toggled(top_down: bool)
signal rematch_pressed
signal menu_pressed

var _plates: Dictionary = {}
var _dice_pill: Label
var _roll_btn: Button
var _banner: Label
var _toast: Label
var _toast_tw: Tween = null
var _finale: PanelContainer
var _finale_title: Label
var _top_down := false


func _ready() -> void:
	layer = 10
	var theme := SnakesUITheme.build()
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = theme
	add_child(root)
	_build_plates(root)
	_build_topbar(root)
	_build_bottom(root)
	_build_finale(root)


func _build_plates(root: Control) -> void:
	var corners := [Control.PRESET_TOP_LEFT, Control.PRESET_TOP_RIGHT, Control.PRESET_BOTTOM_LEFT, Control.PRESET_BOTTOM_RIGHT]
	for seat in 4:
		var panel := PanelContainer.new()
		panel.set_anchors_preset(corners[seat])
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.position += Vector2(12, 12) if seat % 2 == 0 else Vector2(-192, 12)
		if seat >= 2:
			panel.position.y = 500
		panel.custom_minimum_size = Vector2(180, 56)
		panel.pivot_offset = Vector2(90, 28)
		var vb := VBoxContainer.new()
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(vb)
		var name_l := SnakesUITheme.make_label(SnakesPathData.PLAYER_NAMES[seat], 20, SnakesPathData.PLAYER_COLORS_DARK[seat])
		name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(name_l)
		var prog := Label.new()
		prog.name = "Progress"
		prog.text = "0"
		prog.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(prog)
		root.add_child(panel)
		_plates[seat] = panel


func _build_topbar(root: Control) -> void:
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	bar.position = Vector2(-190, 10)
	bar.add_theme_constant_override("separation", 8)
	root.add_child(bar)
	var pause_b := Button.new()
	pause_b.text = "II"
	pause_b.focus_mode = Control.FOCUS_ALL
	pause_b.pressed.connect(func() -> void: pause_pressed.emit())
	bar.add_child(pause_b)
	_dice_pill = Label.new()
	_dice_pill.text = "🎲 -"
	_dice_pill.add_theme_font_size_override("font_size", 26)
	bar.add_child(_dice_pill)
	var restart_b := Button.new()
	restart_b.text = "↺"
	restart_b.pressed.connect(func() -> void: restart_pressed.emit())
	bar.add_child(restart_b)
	var view_b := Button.new()
	view_b.text = "3D/2D"
	view_b.pressed.connect(_on_view)
	bar.add_child(view_b)


func _build_bottom(root: Control) -> void:
	_banner = Label.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_banner.position = Vector2(-220, -175)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_theme_font_size_override("font_size", 24)
	_banner.add_theme_color_override("font_color", Color.WHITE)
	_banner.add_theme_color_override("font_shadow_color", Color("2b1d12"))
	_banner.add_theme_constant_override("shadow_offset_x", 2)
	_banner.add_theme_constant_override("shadow_offset_y", 2)
	_banner.add_theme_constant_override("outline_size", 6)
	_banner.add_theme_color_override("font_outline_color", Color("2b1d12"))
	root.add_child(_banner)
	_roll_btn = Button.new()
	_roll_btn.text = "ROLL"
	_roll_btn.custom_minimum_size = Vector2(150, 54)
	_roll_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_roll_btn.position = Vector2(-75, -80)
	_roll_btn.pressed.connect(func() -> void: roll_pressed.emit())
	root.add_child(_roll_btn)
	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.position = Vector2(-220, -145)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.add_theme_font_size_override("font_size", 20)
	_toast.add_theme_color_override("font_color", Color.WHITE)
	_toast.add_theme_color_override("font_shadow_color", Color("2b1d12"))
	_toast.add_theme_constant_override("shadow_offset_x", 2)
	_toast.add_theme_constant_override("shadow_offset_y", 2)
	_toast.add_theme_constant_override("outline_size", 6)
	_toast.add_theme_color_override("font_outline_color", Color("2b1d12"))
	root.add_child(_toast)


func _build_finale(root: Control) -> void:
	_finale = PanelContainer.new()
	_finale.set_anchors_preset(Control.PRESET_CENTER)
	_finale.position = Vector2(-180, -120)
	_finale.custom_minimum_size = Vector2(360, 240)
	_finale.visible = false
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	_finale.add_child(vb)
	_finale_title = SnakesUITheme.make_label("RED WINS!", 40, Color("3e2723"))
	vb.add_child(_finale_title)
	var rematch := Button.new()
	rematch.text = "REMATCH"
	rematch.pressed.connect(func() -> void: rematch_pressed.emit())
	vb.add_child(rematch)
	var menu := Button.new()
	menu.text = "MAIN MENU"
	menu.pressed.connect(func() -> void: menu_pressed.emit())
	vb.add_child(menu)
	root.add_child(_finale)


func _on_view() -> void:
	_top_down = not _top_down
	view_toggled.emit(_top_down)


func set_active(seat: int, can_roll: bool) -> void:
	for s in _plates:
		var panel: PanelContainer = _plates[s]
		panel.scale = Vector2(1.05, 1.05) if s == seat else Vector2.ONE
		panel.modulate = Color(1, 1, 1, 1) if s == seat else Color(1, 1, 1, 0.75)
	_roll_btn.disabled = not can_roll
	_roll_btn.text = "ROLL (%s)" % SnakesPathData.PLAYER_NAMES[seat] if can_roll else "WAIT..."


func set_die(v: int) -> void:
	_dice_pill.text = "🎲 %d" % v if v > 0 else "🎲 -"


func clear_die() -> void:
	_dice_pill.text = "🎲 -"


func update_progress(rules: SnakesRules) -> void:
	for seat in _plates:
		var panel: PanelContainer = _plates[seat]
		var prog := _find_progress(panel)
		if prog != null:
			prog.text = "%d / 100" % rules.positions[int(seat)]


func _find_progress(n: Node) -> Label:
	if n.name == "Progress" and n is Label:
		return n
	for c in n.get_children():
		var r := _find_progress(c)
		if r != null:
			return r
	return null


func banner(text: String) -> void:
	_banner.text = text


func toast(text: String) -> void:
	_toast.text = text
	if _toast_tw != null and _toast_tw.is_valid():
		_toast_tw.kill()
	_toast_tw = create_tween()
	_toast_tw.tween_interval(1.6)
	_toast_tw.tween_callback(func() -> void: _toast.text = "")


func show_finale(winner_name: String) -> void:
	_finale_title.text = "%s WINS!" % winner_name.to_upper()
	_finale.visible = true


func hide_finale() -> void:
	_finale.visible = false


func finale_visible() -> bool:
	return _finale.visible


func press_roll() -> void:
	_roll_btn.pressed.emit()
