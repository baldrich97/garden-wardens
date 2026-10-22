## The top status row. Pause freezes the match. Speed does not change the clock.
class_name TopBar
extends PanelContainer

signal pause_toggled(paused: bool)

@onready var _water_icon: TextureRect = %WaterIcon
@onready var _water_label: Label = %WaterLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _remaining_label: Label = %RemainingLabel
@onready var _speed_button: Button = %SpeedButton
@onready var _pause_button: Button = %PauseButton


func _ready() -> void:
	add_theme_stylebox_override("panel", FlatStyle.panel(FlatStyle.PANEL, FlatStyle.INK, 18, 4))
	FlatStyle.apply_button(_speed_button)
	FlatStyle.apply_button(_pause_button)
	_speed_button.focus_mode = Control.FOCUS_NONE
	_pause_button.focus_mode = Control.FOCUS_NONE
	_speed_button.toggled.connect(_on_speed_toggled)
	_pause_button.toggled.connect(_on_pause_toggled)


## Shows the mock water, wave, and remaining Vermin counts.
func show_status(water: int, wave: int, remaining: int) -> void:
	_water_label.text = str(water)
	_wave_label.text = "Wave %d" % wave
	_remaining_label.text = "Vermin %d" % remaining


func set_water_icon(texture: Texture2D) -> void:
	_water_icon.texture = texture


func _on_speed_toggled(pressed: bool) -> void:
	# Visual only. This does not change the process speed.
	_speed_button.text = "Speed x2" if pressed else "Speed"


func _on_pause_toggled(pressed: bool) -> void:
	_pause_button.text = "Paused" if pressed else "Pause"
	pause_toggled.emit(pressed)
