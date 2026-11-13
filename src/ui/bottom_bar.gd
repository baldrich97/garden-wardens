## Bottom row of the level's Warden cards, plus ability, remove, and the backdrop cycle.
class_name BottomBar
extends PanelContainer

const CARD_SCENE := preload("res://src/ui/warden_card.tscn")

signal remove_toggled(active: bool)
signal backdrop_requested

@onready var _row: HBoxContainer = $Row
@onready var _cards_row: HBoxContainer = %CardRow
@onready var _ability: Button = %AbilityButton
@onready var _remove: Button = %RemoveButton
@onready var _backdrop: Button = %BackdropButton

var _cards: Array[WardenCard] = []


func _ready() -> void:
	add_theme_stylebox_override("panel", FlatStyle.panel(FlatStyle.PANEL, FlatStyle.INK, 18, 4))
	_row.add_theme_constant_override("separation", 8)
	_fit_button(_ability, Vector2(84, 64))
	_fit_button(_remove, Vector2(88, 64))
	_fit_button(_backdrop, Vector2(120, 64))
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


## The cards currently on the bar.
func cards() -> Array[WardenCard]:
	return _cards


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
