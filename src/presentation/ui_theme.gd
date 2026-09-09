class_name SnakesUITheme
extends RefCounted
## Shared theme factory. Mirrors Ludo's UITheme: code-built Theme, no assets.


static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 20
	# Buttons.
	var btn_primary := StyleBoxFlat.new()
	btn_primary.bg_color = Color("43a047")
	btn_primary.set_corner_radius_all(12)
	btn_primary.content_margin_left = 20
	btn_primary.content_margin_right = 20
	btn_primary.content_margin_top = 12
	btn_primary.content_margin_bottom = 12
	theme.set_stylebox("normal", "Button", btn_primary)
	var btn_hover := btn_primary.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color("4caf50")
	theme.set_stylebox("hover", "Button", btn_hover)
	var btn_pressed := btn_primary.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = Color("2e7d32")
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_color("font_color", "Button", Color.WHITE)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	# Cards / plates.
	var card := StyleBoxFlat.new()
	card.bg_color = Color("fff8e1")
	card.set_corner_radius_all(20)
	card.shadow_size = 12
	card.shadow_color = Color(0, 0, 0, 0.25)
	card.content_margin_left = 24
	card.content_margin_right = 24
	card.content_margin_top = 20
	card.content_margin_bottom = 20
	theme.set_stylebox("panel", "PanelContainer", card)
	return theme


static func make_label(text: String, size: int = 20, color: Color = Color("3e2723"), bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_constant_override("line_spacing", 0)
	return l


static func make_dot(col: Color, d: float = 22.0) -> ColorRect:
	var r := ColorRect.new()
	r.color = col
	r.custom_minimum_size = Vector2(d, d)
	return r
