## The top status row. Pause freezes the match. Speed runs it at double time.
class_name TopBar
extends PanelContainer

## The game logo shown left of the title (GW-AW-7 UI wiring).
const LOGO_TEXTURE: Texture2D = preload("res://assets/art/ui/logo.png")

signal pause_toggled(paused: bool)
signal speed_toggled(fast: bool)
signal preview_requested

@onready var _row: HBoxContainer = $Row
@onready var _water_icon: TextureRect = %WaterIcon
@onready var _water_label: Label = %WaterLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _remaining_label: Label = %RemainingLabel
@onready var _speed_button: Button = %SpeedButton
@onready var _pause_button: Button = %PauseButton
@onready var _preview_button: Button = %PreviewButton


func _ready() -> void:
	add_theme_stylebox_override("panel", FlatStyle.panel(FlatStyle.PANEL, FlatStyle.INK, 18, 4))
	var logo := TextureRect.new()
	logo.name = "Logo"
	logo.texture = LOGO_TEXTURE
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.custom_minimum_size = Vector2(56, 56)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_row.add_child(logo)
	_row.move_child(logo, 0)
	FlatStyle.apply_button(_speed_button)
	FlatStyle.apply_button(_pause_button)
	FlatStyle.apply_button(_preview_button)
	_speed_button.focus_mode = Control.FOCUS_NONE
	_pause_button.focus_mode = Control.FOCUS_NONE
	_preview_button.focus_mode = Control.FOCUS_NONE
	_speed_button.toggled.connect(_on_speed_toggled)
	_pause_button.toggled.connect(_on_pause_toggled)
	_preview_button.pressed.connect(func() -> void: preview_requested.emit())


## Shows water, the level number, and how many Vermin are still to come.
func show_status(water: int, level_number: int, remaining: int) -> void:
	_water_label.text = str(water)
	_wave_label.text = "Level %d" % level_number
	_remaining_label.text = "Vermin %d" % remaining


func set_water_icon(texture: Texture2D) -> void:
	_water_icon.texture = texture


func _on_speed_toggled(pressed: bool) -> void:
	_speed_button.text = "Speed x2" if pressed else "Speed"
	speed_toggled.emit(pressed)


func _on_pause_toggled(pressed: bool) -> void:
	_pause_button.text = "Paused" if pressed else "Pause"
	pause_toggled.emit(pressed)
