## One Warden card: preview, name, water cost, and selected or unaffordable state.
class_name WardenCard
extends PanelContainer

@onready var _portrait: TextureRect = %Portrait
@onready var _placeholder: Label = %Placeholder
@onready var _name_label: Label = %NameLabel
@onready var _cost_label: Label = %CostLabel

signal pointer_down

var kind := -1
var _base_cost := 0
var _cooldown_left := 0.0
var _selected := false
var _unaffordable := false


func _ready() -> void:
	custom_minimum_size = Vector2(112, 108)
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_pass_clicks_to_self(self)
	gui_input.connect(_on_gui_input)
	_refresh()


## Children would otherwise eat the click, so only the card itself handles it.
func _pass_clicks_to_self(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pass_clicks_to_self(child)


## Fills the card. A null portrait shows [param gap] instead of a sprite.
func present(
	kind_id: int,
	warden_name: String,
	water_cost: int,
	portrait: Texture2D,
	selected: bool,
	unaffordable: bool,
	gap: String,
) -> void:
	kind = kind_id
	_base_cost = water_cost
	_name_label.text = warden_name
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_name_label.add_theme_font_size_override("font_size", 14)
	_name_label.custom_minimum_size = Vector2(96, 34)
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
	var box := FlatStyle.panel(background, border, 12, 5 if _selected else 3)
	box.content_margin_left = 6
	box.content_margin_right = 6
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	add_theme_stylebox_override("panel", box)
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
		pointer_down.emit()
		accept_event()
