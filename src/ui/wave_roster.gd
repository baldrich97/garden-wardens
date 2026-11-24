## One card per vermin type in this wave, shown before Start.
class_name WaveRoster
extends PanelContainer

## The flag shown above the roster title (GW-AW-7 UI wiring).
const WAVE_FLAG_TEXTURE: Texture2D = preload("res://assets/art/ui/wave_flag.png")

## The pre-wave panel is a slim horizontal strip (GW-AA pass 3): flag and
## title, one portrait per vermin type in a single row, then Start. It sits in
## the sky's top-right corner so it never covers the lawn.
const PORTRAIT_SIZE := Vector2(54, 50)

signal start_requested

var _clips: Array[ClipView] = []
var _cards: Array[Control] = []
var _hosts: Array[Control] = []
var _list: GridContainer
var _wave: Array[Vector3] = []


func _ready() -> void:
	name = "WaveRoster"
	mouse_filter = Control.MOUSE_FILTER_STOP
	var panel := FlatStyle.panel(FlatStyle.PANEL, FlatStyle.INK, 14, 3)
	panel.content_margin_top = 6
	panel.content_margin_bottom = 6
	add_theme_stylebox_override("panel", panel)
	var row := HBoxContainer.new()
	row.name = "RosterRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	var head := VBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_theme_constant_override("separation", 0)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(head)
	var flag := TextureRect.new()
	flag.name = "WaveFlag"
	flag.texture = WAVE_FLAG_TEXTURE
	flag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flag.custom_minimum_size = Vector2(40, 40)
	flag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	head.add_child(flag)
	var title := Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = "This wave"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", FlatStyle.CREAM)
	title.add_theme_font_size_override("font_size", 14)
	head.add_child(title)
	_list = GridContainer.new()
	_list.name = "RosterGrid"
	_list.columns = 1
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_list.add_theme_constant_override("h_separation", 6)
	_list.add_theme_constant_override("v_separation", 6)
	row.add_child(_list)
	var start := Button.new()
	start.name = "StartButton"
	start.text = "Start"
	start.focus_mode = Control.FOCUS_NONE
	start.custom_minimum_size = Vector2(96, 64)
	start.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	start.add_theme_font_size_override("font_size", 20)
	FlatStyle.apply_button(start)
	start.pressed.connect(func() -> void: start_requested.emit())
	row.add_child(start)


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
	_list.columns = maxi(1, _kinds().size())
	for kind in _kinds():
		var card := PanelContainer.new()
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.clip_contents = true
		card.custom_minimum_size = PORTRAIT_SIZE + Vector2(8, 8)
		var box := FlatStyle.panel(FlatStyle.PANEL_DIM, FlatStyle.INK, 10, 3)
		box.content_margin_left = 4
		box.content_margin_right = 4
		box.content_margin_top = 4
		box.content_margin_bottom = 4
		card.add_theme_stylebox_override("panel", box)
		var host := Control.new()
		host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.custom_minimum_size = PORTRAIT_SIZE
		host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		host.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var clip := ClipView.new()
		clip.setup(UnitClips.vermin(kind))
		clip.set_idle_bob(true)
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
