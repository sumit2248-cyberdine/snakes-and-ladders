class_name SnakesRulesPanel
extends CanvasLayer
## Reference card explaining the active preset. Mirrors Ludo's RulesPanel.


func _ready() -> void:
	layer = 22
	visible = false


func open(rule_set: SnakesRuleSet) -> void:
	for c in get_children():
		c.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev: InputEvent) -> void: if ev is InputEventMouseButton: close())
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var card := PanelContainer.new()
	card.theme = SnakesUITheme.build()
	card.custom_minimum_size = Vector2(480, 0)
	center.add_child(card)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	card.add_child(vb)
	vb.add_child(SnakesUITheme.make_label("HOW TO PLAY", 32, Color("1b5e20")))
	vb.add_child(SnakesUITheme.make_label("Roll the die, advance that many squares. Land exactly on a ladder foot to climb; land on a snake head to slide. First to 100 wins.", 18, Color("3e2723")))
	var finish_word := "exact roll"
	match rule_set.finish_rule:
		SnakesRuleSet.FinishRule.EXACT_BOUNCE:
			finish_word = "exact roll (overshoot bounces back)"
		SnakesRuleSet.FinishRule.OVERFLOW_WIN:
			finish_word = "reach or pass 100"
	vb.add_child(SnakesUITheme.make_label("House rules (%s): finish needs %s; six grants bonus: %s; ladder grants bonus: %s." % [rule_set.rule_name, finish_word, "yes" if rule_set.extra_roll_on_six else "no", "yes" if rule_set.extra_roll_on_ladder else "no"], 16, Color("5d4037")))
	var close_b := Button.new()
	close_b.text = "CLOSE"
	close_b.pressed.connect(close)
	vb.add_child(close_b)
	visible = true


func close() -> void:
	visible = false
	for c in get_children():
		c.queue_free()
