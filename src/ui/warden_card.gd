## One Warden card (GW-AA pass 5): the seed packet art fills the whole card.
## The Warden's NAME sits on the packet's top lip, the printed Warden art is
## the middle, and the water COST sits on the blank cream price tag next to
## the blue drop. A cooldown dims the packet with a sweep that drains from
## the top and shows the seconds left on the tag. Selected packets get a gold
## outline; unaffordable ones dim with a clay price.
class_name WardenCard
extends PanelContainer

## Packet art aspect (seed_packet_*.png are 325x412).
const PACKET_ASPECT := 325.0 / 412.0
## Card sizes: bottom tray (compact) and vertical side bar (large).
const COMPACT_SIZE := Vector2(84, 106)
const LARGE_SIZE := Vector2(124, 157)
## Where the labels sit on the packet, as fractions of the card rect.
## The lip is the folded top band; the tag is the blank cream price tag
## (x 122..311, y 300..379 of the 325x412 packet).
const LIP_RECT := Rect2(0.04, 0.0, 0.92, 0.13)
const TAG_RECT := Rect2(122.0 / 325.0, 300.0 / 412.0, 189.0 / 325.0, 79.0 / 412.0)
## Font sizes as a share of the card height, and the floor they shrink to.
const NAME_FONT_SHARE := 0.105
const COST_FONT_SHARE := 0.15
const MIN_FONT := 8
const NAME_COLOR := Color(1.0, 0.97, 0.88)
const NAME_OUTLINE := Color(0.2, 0.12, 0.06)
const COST_COLOR := Color(0.16, 0.22, 0.34)
const COST_POOR_COLOR := Color(0.72, 0.2, 0.14)
const COOLDOWN_COLOR := Color(0.2, 0.18, 0.16)
## The cooldown dim over the part of the packet still recharging.
const SHADE_COLOR := Color(0.05, 0.04, 0.03, 0.5)
const SHADE_EDGE := Color(1.0, 0.95, 0.75, 0.85)

@onready var _face: Control = %Face
@onready var _portrait: TextureRect = %Portrait
@onready var _placeholder: Label = %Placeholder
@onready var _shade: Control = %Shade
@onready var _name_label: Label = %NameLabel
@onready var _cost_label: Label = %CostLabel

signal pointer_down

var kind := -1
var _base_cost := 0
var _cooldown_left := 0.0
var _cooldown_total := 0.0
var _selected := false
var _unaffordable := false
## Tray cards (horizontal HUD) are compact; side bar cards are bigger.
var _large := false


func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_apply_size()
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_pass_clicks_to_self(self)
	gui_input.connect(_on_gui_input)
	_face.resized.connect(_layout_face)
	_shade.draw.connect(_draw_shade)
	_refresh()


## Children would otherwise eat the click, so only the card itself handles it.
func _pass_clicks_to_self(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pass_clicks_to_self(child)


## Fills the card. A null portrait shows [param gap] instead of the packet.
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
	_cooldown_total = UnitCatalog.WARDEN_COOLDOWN[kind_id] if kind_id >= 0 and kind_id < UnitCatalog.WARDEN_COOLDOWN.size() else 0.0
	_name_label.text = warden_name
	_portrait.texture = portrait
	_portrait.visible = portrait != null
	_placeholder.visible = portrait == null
	_placeholder.text = gap
	_apply_size()
	set_state(selected, unaffordable, 0.0)


## Large cards for the vertical side bar (small windows); compact cards for
## the bottom tray, which the stretch scale enlarges on big windows.
func set_large(large: bool) -> void:
	_large = large
	_apply_size()


func is_large() -> bool:
	return _large


func _apply_size() -> void:
	if not is_node_ready():
		return
	custom_minimum_size = LARGE_SIZE if _large else COMPACT_SIZE
	_layout_face()


## Updates the outline, the price color, and an optional cooldown.
func set_state(selected: bool, unaffordable: bool, cooldown_left: float) -> void:
	_selected = selected
	_unaffordable = unaffordable
	_cooldown_left = maxf(cooldown_left, 0.0)
	if _cooldown_left > _cooldown_total:
		_cooldown_total = _cooldown_left
	_refresh()


func is_selected() -> bool:
	return _selected


func is_unaffordable() -> bool:
	return _unaffordable


## The text on the price tag right now (cost, or seconds left).
func tag_text() -> String:
	return _cost_label.text if _cost_label != null else ""


## The name on the lip.
func lip_text() -> String:
	return _name_label.text if _name_label != null else ""


## How much of the packet the cooldown still covers, 0..1.
func cooldown_share() -> float:
	if _cooldown_left <= 0.0 or _cooldown_total <= 0.0:
		return 0.0
	return clampf(_cooldown_left / _cooldown_total, 0.0, 1.0)


## The two label rects in card-local pixels (for tests and captures).
func label_rects() -> Dictionary:
	return {"name": _name_label.get_rect(), "cost": _cost_label.get_rect(), "face": _face.get_rect()}


func _refresh() -> void:
	if not is_node_ready():
		return
	var cooling := _cooldown_left > 0.0
	if cooling:
		_cost_label.text = "%.1fs" % _cooldown_left
		_cost_label.add_theme_color_override("font_color", COOLDOWN_COLOR)
	else:
		_cost_label.text = "%d" % _base_cost
		_cost_label.add_theme_color_override("font_color", COST_POOR_COLOR if _unaffordable else COST_COLOR)
	_name_label.add_theme_color_override("font_color", FlatStyle.GOLD if _selected else NAME_COLOR)
	_placeholder.add_theme_color_override("font_color", FlatStyle.CREAM)
	_portrait.self_modulate = Color(0.72, 0.72, 0.72) if _unaffordable and not cooling else Color.WHITE
	_fit_labels()
	_shade.queue_redraw()


func _layout_face() -> void:
	if not is_node_ready():
		return
	var area := _face.size
	if area.x <= 0.0 or area.y <= 0.0:
		area = custom_minimum_size
	_name_label.position = Vector2(LIP_RECT.position.x * area.x, LIP_RECT.position.y * area.y)
	_name_label.size = Vector2(LIP_RECT.size.x * area.x, LIP_RECT.size.y * area.y)
	_cost_label.position = Vector2(TAG_RECT.position.x * area.x, TAG_RECT.position.y * area.y)
	_cost_label.size = Vector2(TAG_RECT.size.x * area.x, TAG_RECT.size.y * area.y)
	_fit_labels()
	_shade.queue_redraw()


## Sizes both labels to the card, shrinking a long name until it fits the lip.
func _fit_labels() -> void:
	var area := _face.size
	if area.y <= 0.0:
		area = custom_minimum_size
	var font := _name_label.get_theme_font("font")
	var name_size := maxi(MIN_FONT, int(round(area.y * NAME_FONT_SHARE)))
	var room := LIP_RECT.size.x * area.x - 4.0
	while name_size > MIN_FONT and font != null and font.get_string_size(_name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x > room:
		name_size -= 1
	_name_label.add_theme_font_size_override("font_size", name_size)
	_name_label.add_theme_color_override("font_outline_color", NAME_OUTLINE)
	_name_label.add_theme_constant_override("outline_size", maxi(3, int(round(name_size * 0.36))))
	var cost_size := maxi(MIN_FONT, int(round(area.y * COST_FONT_SHARE)))
	var tag_room := TAG_RECT.size.x * area.x - 4.0
	while cost_size > MIN_FONT and font != null and font.get_string_size(_cost_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, cost_size).x > tag_room:
		cost_size -= 1
	_cost_label.add_theme_font_size_override("font_size", cost_size)


## The cooldown dim and its draining edge, and the selection outline.
func _draw_shade() -> void:
	var area := _shade.size
	var share := cooldown_share()
	if share > 0.0:
		var h := area.y * share
		_shade.draw_rect(Rect2(0.0, 0.0, area.x, h), SHADE_COLOR)
		_shade.draw_line(Vector2(0.0, h), Vector2(area.x, h), SHADE_EDGE, 2.0)
	elif _unaffordable:
		_shade.draw_rect(Rect2(Vector2.ZERO, area), Color(0.05, 0.04, 0.03, 0.18))
	if _selected:
		_shade.draw_rect(Rect2(Vector2(2.0, 2.0), area - Vector2(4.0, 4.0)), FlatStyle.GOLD, false, 4.0)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pointer_down.emit()
		accept_event()
