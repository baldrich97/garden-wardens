## Bottom row of Warden cards plus the ability and remove buttons.
class_name BottomBar
extends PanelContainer

@onready var _dew: WardenCard = %DewDropper
@onready var _needle: WardenCard = %NeedleSpitter
@onready var _bark: WardenCard = %BarkBlock
@onready var _ability: Button = %AbilityButton
@onready var _remove: Button = %RemoveButton


func _ready() -> void:
	add_theme_stylebox_override("panel", FlatStyle.panel(FlatStyle.PANEL, FlatStyle.INK, 18, 4))
	FlatStyle.apply_button(_ability)
	FlatStyle.apply_button(_remove)
	_ability.focus_mode = Control.FOCUS_NONE
	_remove.focus_mode = Control.FOCUS_NONE
	_ability.disabled = true
	_remove.toggled.connect(_on_remove_toggled)


## Returns the three cards in bar order: Dew Dropper, Needle Spitter, Bark Block.
func cards() -> Array[WardenCard]:
	return [_dew, _needle, _bark]


func _on_remove_toggled(pressed: bool) -> void:
	# Visual only. Nothing is removed from the lawn.
	_remove.text = "Removing" if pressed else "Remove"
