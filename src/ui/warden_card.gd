## One Warden card: preview, name, water cost, and selected or unaffordable state.
class_name WardenCard
extends PanelContainer

@onready var _portrait: TextureRect = %Portrait
@onready var _placeholder: Label = %Placeholder
@onready var _name_label: Label = %NameLabel
@onready var _cost_label: Label = %CostLabel

signal chosen

var _base_cost := 0
var _cooldown_left := 0.0
var _selected := false
var _unaffordable := false


func _ready() -> void:
	custom_minimum_size = Vector2(200, 128)
	focus_mode = Control.FOCUS_NONE
	gui_input.connect(_on_gui_input)
	_refresh()


## Fills the card. A null portrait shows [param gap] instead of a sprite.
func present(
	warden_name: String,
	water_cost: int,
	portrait: Texture2D,
	selected: bool,
	unaffordable: bool,
	gap: String,
) -> void:
	_base_cost = water_cost
	_name_label.text = warden_name
	_portrait.texture = portrait
	_portrait.visible = portrait != null
	_placeholder.visible = portrait == null
	_placeholder.text = gap
	set_state(selected, unaffordable, 0.0)


## Updates the border, the price color, and an optional cooldown.
func set_state(selected: bool, unaffordable: bool, cooldown_left: float) -> void:
	_selected = selected
	_unaffordable = unaffordable
	_cooldown_left = cooldown_left
	_refresh()


func is_selected() -> bool:
	return _selected


func is_unaffordable() -> bool:
	return _unaffordable


func _refresh() -> void:
	if not is_node_ready():
		return
	var border := FlatStyle.GOLD if _selected else FlatStyle.INK
	var background := FlatStyle.PANEL_DIM if _unaffordable or _cooldown_left > 0.0 else FlatStyle.PANEL
	add_theme_stylebox_override("panel", FlatStyle.panel(background, border, 16, 5 if _selected else 3))
	_name_label.add_theme_color_override("font_color", FlatStyle.GOLD if _selected else FlatStyle.CREAM)
	if _cooldown_left > 0.0:
		_cost_label.text = "%.1fs" % _cooldown_left
		_cost_label.add_theme_color_override("font_color", FlatStyle.CREAM)
	else:
		_cost_label.text = "%d water" % _base_cost
		_cost_label.add_theme_color_override("font_color", FlatStyle.CLAY if _unaffordable else FlatStyle.CREAM)
	_placeholder.add_theme_color_override("font_color", FlatStyle.CREAM)
	modulate = Color(1, 1, 1, 0.78) if _unaffordable or _cooldown_left > 0.0 else Color.WHITE


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		chosen.emit()
		accept_event()
