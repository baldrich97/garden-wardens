## A needle traveling right along a row. [member column_pos] is in cell units.
class_name ShotActor
extends Control

var row: int
var column_pos: float
var damage: int


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 4
	var pea := Panel.new()
	pea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pea.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("7dce4a")
	style.border_color = FlatStyle.INK
	style.set_border_width_all(2)
	style.set_corner_radius_all(20)
	pea.add_theme_stylebox_override("panel", style)
	add_child(pea)
