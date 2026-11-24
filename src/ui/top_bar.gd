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

var _logo: TextureRect


func _ready() -> void:
	var panel := FlatStyle.panel(FlatStyle.PANEL, FlatStyle.INK, 16, 4)
	panel.content_margin_top = 5
	panel.content_margin_bottom = 5
	add_theme_stylebox_override("panel", panel)
	var logo := TextureRect.new()
	_logo = logo
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
	set_compact(true)


## The slim Option B bar (about 60 px tall at 1280x720): smaller logo, icon,
## text, and 46 px buttons. The stretch scale enlarges it on big windows.
func set_compact(compact: bool) -> void:
	var button_h := 46.0 if compact else 64.0
	custom_minimum_size = Vector2(0, 0 if compact else 80)
	_logo.custom_minimum_size = Vector2(44, 44) if compact else Vector2(56, 56)
	_water_icon.custom_minimum_size = Vector2(32, 32) if compact else Vector2(40, 40)
	_preview_button.custom_minimum_size = Vector2(96, button_h)
	_speed_button.custom_minimum_size = Vector2(112, button_h)
	_pause_button.custom_minimum_size = Vector2(112, button_h)
	for button in [_preview_button, _speed_button, _pause_button]:
		(button as Button).add_theme_font_size_override("font_size", 18 if compact else 20)
	($Row/Title as Label).add_theme_font_size_override("font_size", 22 if compact else 26)
	_water_label.add_theme_font_size_override("font_size", 20 if compact else 22)
	_wave_label.add_theme_font_size_override("font_size", 18 if compact else 20)
	_remaining_label.add_theme_font_size_override("font_size", 18 if compact else 20)


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


## Presses or releases Pause as if clicked (Space uses this, so the button
## and the board never disagree).
func set_paused(paused: bool) -> void:
	_pause_button.button_pressed = paused


func pause_shown() -> bool:
	return _pause_button.button_pressed


func _on_pause_toggled(pressed: bool) -> void:
	_pause_button.text = "Paused" if pressed else "Pause"
	pause_toggled.emit(pressed)
