## The level's Warden cards, plus ability, remove, and the backdrop cycle.
## Horizontal: the bottom tray (GW-AA pass 3, Option B). Vertical: a side bar
## with bigger cards in two columns, for small windows.
class_name BottomBar
extends PanelContainer

const CARD_SCENE := preload("res://src/ui/warden_card.tscn")

signal remove_toggled(active: bool)
signal backdrop_requested

@onready var _row: BoxContainer = $Row
@onready var _cards_row: GridContainer = %CardRow
@onready var _buttons: GridContainer = %Buttons
@onready var _ability: Button = %AbilityButton
@onready var _remove: Button = %RemoveButton
@onready var _backdrop: Button = %BackdropButton

var _cards: Array[WardenCard] = []
var _vertical := false


func _ready() -> void:
	var box := FlatStyle.panel(FlatStyle.PANEL, FlatStyle.INK, 16, 4)
	box.content_margin_top = 5
	box.content_margin_bottom = 5
	add_theme_stylebox_override("panel", box)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_row.add_theme_constant_override("separation", 8)
	_fit_button(_ability, Vector2(84, 64))
	_fit_button(_remove, Vector2(88, 64))
	_fit_button(_backdrop, Vector2(120, 64))
	_backdrop.clip_text = true
	_backdrop.autowrap_mode = TextServer.AUTOWRAP_WORD
	_ability.disabled = true
	_remove.toggled.connect(_on_remove_toggled)
	_backdrop.pressed.connect(func() -> void: backdrop_requested.emit())


## Rebuilds the card row for this level, in bar order.
func show_roster(kinds: Array[int]) -> void:
	for card in _cards:
		card.queue_free()
	_cards.clear()
	for kind in kinds:
		var card := CARD_SCENE.instantiate() as WardenCard
		card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_cards_row.add_child(card)
		_cards.append(card)
	set_vertical(_vertical)


## The cards currently on the bar.
func cards() -> Array[WardenCard]:
	return _cards


## Bottom tray (false) or side bar (true). The tray is one row of compact
## cards and buttons; the side bar stacks two columns of large cards over a
## two-column button block, filling the height of the window's left edge.
func set_vertical(vertical: bool) -> void:
	_vertical = vertical
	if not is_node_ready():
		return
	_row.vertical = vertical
	_row.alignment = BoxContainer.ALIGNMENT_BEGIN if vertical else BoxContainer.ALIGNMENT_CENTER
	size_flags_horizontal = Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_FILL
	_cards_row.columns = 2 if vertical else maxi(1, _cards.size())
	_buttons.columns = 2 if vertical else 3
	for card in _cards:
		card.set_large(vertical)
	var button_h := 52.0 if vertical else 64.0
	_ability.custom_minimum_size = Vector2(124 if vertical else 84, button_h)
	_remove.custom_minimum_size = Vector2(124 if vertical else 88, button_h)
	_backdrop.custom_minimum_size = Vector2(124 if vertical else 120, button_h)
	for button in [_ability, _remove, _backdrop]:
		(button as Button).add_theme_font_size_override("font_size", 17)


func is_vertical() -> bool:
	return _vertical


func _on_remove_toggled(pressed: bool) -> void:
	_remove.text = "Removing" if pressed else "Remove"
	remove_toggled.emit(pressed)


## Keeps the button matched to the board without emitting another toggle.
func set_backdrop_name(backdrop_name: String) -> void:
	_backdrop.text = backdrop_name


func set_removing(active: bool) -> void:
	_remove.set_pressed_no_signal(active)
	_remove.text = "Removing" if active else "Remove"


func _fit_button(button: Button, minimum: Vector2) -> void:
	FlatStyle.apply_button(button)
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = minimum
