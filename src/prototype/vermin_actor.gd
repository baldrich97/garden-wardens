## One Vermin walking left along a row. [member column_pos] is in cell units.
class_name VerminActor
extends Control

var kind: UnitCatalog.Vermin
var row: int
var column_pos: float
var hp: int
var max_hp: int

var _bar: ColorRect
var _bar_back: ColorRect


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 3


func setup(p_kind: UnitCatalog.Vermin, p_row: int, p_column_pos: float, texture: Texture2D) -> void:
	kind = p_kind
	row = p_row
	column_pos = p_column_pos
	max_hp = UnitCatalog.VERMIN_HP[kind]
	hp = max_hp
	var sprite := TextureRect.new()
	sprite.texture = texture
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(sprite)
	sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bar_back = ColorRect.new()
	_bar_back.color = Color(0.08, 0.1, 0.08, 0.85)
	_bar_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bar_back)
	_bar = ColorRect.new()
	_bar.color = Color("e0704a")
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bar)


func speed() -> float:
	return UnitCatalog.VERMIN_SPEED[kind]


func chew_damage() -> float:
	return UnitCatalog.VERMIN_CHEW[kind]


## Returns true when this Vermin is destroyed.
func take_damage(amount: int) -> bool:
	hp -= amount
	refresh_bar()
	return hp <= 0


func refresh_bar() -> void:
	if _bar == null:
		return
	var width := size.x
	var height := maxf(5.0, size.y * 0.08)
	_bar_back.position = Vector2(0.0, size.y - height)
	_bar_back.size = Vector2(width, height)
	var fraction := 0.0 if max_hp <= 0 else clampf(float(hp) / float(max_hp), 0.0, 1.0)
	_bar.position = _bar_back.position
	_bar.size = Vector2(width * fraction, height)
