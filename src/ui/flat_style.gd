## Shared colors and flat panels for the prototype UI.
##
## The values are sampled from Kenney's New Platformer Pack: dark outlines,
## garden green, cream highlights, and the gold used for a selected card.
class_name FlatStyle
extends RefCounted

const INK := Color("243028")
const CREAM := Color("fff6df")
const PANEL := Color("1e4a30")
const PANEL_DIM := Color("163324")
const LEAF := Color("2f7d46")
const LEAF_BRIGHT := Color("3d9958")
const GOLD := Color("f2c14e")
const CLAY := Color("e0704a")
const SKY := Color("e7f4fb")
const PLACEHOLDER := Color("d7eef8")

static func panel(background: Color, border: Color, radius: int, thickness: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(thickness)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box


## Gives a button the garden panel look, including hover, pressed, and disabled.
static func apply_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", panel(LEAF, INK, 14, 3))
	button.add_theme_stylebox_override("hover", panel(LEAF_BRIGHT, INK, 14, 3))
	button.add_theme_stylebox_override("pressed", panel(PANEL, GOLD, 14, 4))
	button.add_theme_stylebox_override("focus", panel(LEAF_BRIGHT, GOLD, 14, 3))
	button.add_theme_stylebox_override("disabled", panel(PANEL_DIM, Color(INK, 0.35), 14, 3))
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", CREAM)
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_color_override("font_focus_color", CREAM)
	button.add_theme_color_override("font_disabled_color", Color(CREAM, 0.72))
	button.add_theme_font_size_override("font_size", 20)
