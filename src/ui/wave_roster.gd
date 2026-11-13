## One card per vermin type in this wave, shown before Start.
class_name WaveRoster
extends PanelContainer

## Wide enough for two portrait columns, the title, and Start.
const WIDTH := 188.0

signal start_requested

var _clips: Array[ClipView] = []
var _cards: Array[Control] = []
var _hosts: Array[Control] = []
var _list: GridContainer
var _wave: Array[Vector3] = []


func _ready() -> void:
	name = "WaveRoster"
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(WIDTH, 0)
	add_theme_stylebox_override("panel", FlatStyle.panel(FlatStyle.PANEL, FlatStyle.INK, 14, 3))
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 8)
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(column)
	var title := Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = "This wave"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", FlatStyle.CREAM)
	title.add_theme_font_size_override("font_size", 16)
	column.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	column.add_child(scroll)
	_list = GridContainer.new()
	_list.name = "RosterGrid"
	_list.columns = 2
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("h_separation", 6)
	_list.add_theme_constant_override("v_separation", 6)
	scroll.add_child(_list)
	var start := Button.new()
	start.name = "StartButton"
	start.text = "Start"
	start.focus_mode = Control.FOCUS_NONE
	start.custom_minimum_size = Vector2(0, 64)
	FlatStyle.apply_button(start)
	start.pressed.connect(func() -> void: start_requested.emit())
	column.add_child(start)


func card_count() -> int:
	return _cards.size()


func waiting_count() -> int:
	var waiting := 0
	for card in _cards:
		if card.visible:
			waiting += 1
	return waiting


## One idling card per vermin type, in the order they first appear.
func fill(tip: GameTooltip, wave: Array[Vector3]) -> void:
	_wave = wave
	for kind in _kinds():
		var card := PanelContainer.new()
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.clip_contents = true
		card.custom_minimum_size = Vector2(0, 58)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var box := FlatStyle.panel(FlatStyle.PANEL_DIM, FlatStyle.INK, 10, 3)
		box.content_margin_left = 4
		box.content_margin_right = 4
		box.content_margin_top = 4
		box.content_margin_bottom = 4
		card.add_theme_stylebox_override("panel", box)
		var host := Control.new()
		host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.custom_minimum_size = Vector2(52, 50)
		host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		host.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var clip := ClipView.new()
		clip.setup(UnitClips.vermin(kind))
		clip.play("idle")
		host.add_child(clip)
		card.add_child(host)
		_list.add_child(card)
		_clips.append(clip)
		_cards.append(card)
		_hosts.append(host)
		GameTooltip.attach(card, UnitCatalog.vermin_blurb(kind), tip)


func _kinds() -> Array[int]:
	var kinds: Array[int] = []
	for entry in _wave:
		var kind := int(entry.y)
		if not kinds.has(kind):
			kinds.append(kind)
	return kinds


## Keeps the idle bob moving. A paused match passes a delta of 0.
func tick(delta: float) -> void:
	for index in _clips.size():
		_clips[index].tick(delta, _hosts[index].size)
