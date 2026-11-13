## A simple needle. It travels right along one row until it hits a vermin.
class_name ShotActor
extends Control

var row: int
var column_pos: float
var damage: int


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 5
	var tail := Panel.new()
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tail.set_anchors_preset(Control.PRESET_FULL_RECT)
	tail.offset_right = -18.0
	tail.add_theme_stylebox_override("panel", _pill(Color("3d9958"), 8))
	add_child(tail)
	var head := Panel.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.set_anchors_preset(Control.PRESET_FULL_RECT)
	head.offset_left = 14.0
	head.add_theme_stylebox_override("panel", _pill(Color("d6ff6b"), 16))
	add_child(head)


func _pill(fill: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = FlatStyle.INK
	style.set_border_width_all(3)
	style.set_corner_radius_all(radius)
	return style
