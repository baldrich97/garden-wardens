## A small panel that follows the pointer. It does not block clicks.
class_name GameTooltip
extends PanelContainer

var _label: Label
var _shown := false
## When set (board pixels), the tip's bottom edge sits on this line instead of
## under the pointer: lawn tips ride in the sky just above the board's far
## edge, so they never cover the tiles being aimed at.
var _bottom_line := NAN


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Over the HUD (z 60) and the drag ghost (z 110).
	z_index = 120
	visible = false
	add_theme_stylebox_override("panel", FlatStyle.panel(FlatStyle.PANEL, FlatStyle.INK, 10, 3))
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_color_override("font_color", FlatStyle.CREAM)
	_label.add_theme_font_size_override("font_size", 16)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.custom_minimum_size = Vector2(220, 0)
	add_child(_label)


func _process(_delta: float) -> void:
	if not _shown:
		return
	var tip_size := size
	if tip_size.x < 4.0:
		reset_size()
		tip_size = get_combined_minimum_size()
	var viewport := get_viewport_rect().size
	var mouse := get_global_mouse_position()
	var pos := mouse + Vector2(16, 22)
	if not is_nan(_bottom_line):
		pos = Vector2(mouse.x - tip_size.x * 0.5, _bottom_line - tip_size.y)
	elif pos.y + tip_size.y > viewport.y - 8.0:
		# Near the bottom (the card tray): flip above the pointer instead of
		# clamping down over the cards.
		pos.y = mouse.y - tip_size.y - 14.0
	pos.x = clampf(pos.x, 8.0, maxf(8.0, viewport.x - tip_size.x - 8.0))
	pos.y = clampf(pos.y, 8.0, maxf(8.0, viewport.y - tip_size.y - 8.0))
	global_position = pos


func show_text(text: String, bottom_line: float = NAN) -> void:
	_bottom_line = bottom_line
	_label.text = text
	_shown = true
	visible = true
	reset_size()


func hide_tip() -> void:
	_shown = false
	visible = false


## Shows [param text] while the pointer is over [param control].
static func attach(control: Control, text: String, tip: GameTooltip) -> void:
	control.mouse_entered.connect(func() -> void: tip.show_text(text))
	control.mouse_exited.connect(func() -> void: tip.hide_tip())
