class_name SnakesPauseMenu
extends CanvasLayer
## Right-docked pause card. Mirrors Ludo's PauseMenu.

signal resume_pressed
signal restart_pressed
signal save_menu_pressed
signal quit_pressed


func _ready() -> void:
	layer = 25
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.08, 0.06, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.theme = SnakesUITheme.build()
	card.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	card.position = Vector2(-300, -200)
	card.custom_minimum_size = Vector2(280, 0)
	add_child(card)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)
	vb.add_child(SnakesUITheme.make_label("PAUSED", 36, Color("3e2723")))
	vb.add_child(SnakesUITheme.make_label("Take a breather.", 16, Color("5d4037")))
	var resume := Button.new()
	resume.text = "RESUME"
	resume.pressed.connect(func() -> void: resume_pressed.emit())
	vb.add_child(resume)
	var restart := Button.new()
	restart.text = "RESTART MATCH"
	restart.pressed.connect(func() -> void: restart_pressed.emit())
	vb.add_child(restart)
	var save := Button.new()
	save.text = "SAVE & MAIN MENU"
	save.pressed.connect(func() -> void: save_menu_pressed.emit())
	vb.add_child(save)
	var quit := Button.new()
	quit.text = "QUIT WITHOUT SAVING"
	quit.pressed.connect(func() -> void: quit_pressed.emit())
	vb.add_child(quit)


func open() -> void:
	visible = true


func close() -> void:
	visible = false
