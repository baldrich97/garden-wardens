## One Vermin walking left along a row. [member column_pos] is in cell units.
class_name VerminActor
extends Control

var kind: UnitCatalog.Vermin
var row: int
var column_pos: float
var hp: int
var max_hp: int
var bee_column: int
var bee_since_forward: int
var bee_since_backward: int = 5
var bee_wait: float = UnitCatalog.BEE_STEP

var _clip: ClipView
var _bar: ColorRect
var _bar_back: ColorRect


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 3


func setup(p_kind: UnitCatalog.Vermin, p_row: int, p_column_pos: float) -> void:
	kind = p_kind
	row = p_row
	column_pos = p_column_pos
	max_hp = UnitCatalog.VERMIN_HP[kind]
	hp = max_hp
	if kind == UnitCatalog.Vermin.BEE:
		bee_column = maxi(0, int(floor(p_column_pos)))
		column_pos = float(bee_column) + 0.5
		bee_since_forward = 0
		bee_since_backward = 5
		bee_wait = UnitCatalog.BEE_STEP
	_clip = ClipView.new()
	_clip.setup(UnitClips.vermin(kind))
	_clip.play("walk")
	add_child(_clip)
	_bar_back = ColorRect.new()
	_bar_back.color = Color(0.08, 0.1, 0.08, 0.85)
	_bar_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_back.z_index = 1
	add_child(_bar_back)
	_bar = ColorRect.new()
	_bar.color = Color("e0704a")
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.z_index = 1
	add_child(_bar)


func speed() -> float:
	return UnitCatalog.VERMIN_SPEED[kind]


func chew_damage() -> float:
	return UnitCatalog.VERMIN_CHEW[kind]


func play(anim_name: String) -> void:
	if _clip != null:
		_clip.play(anim_name)


func tick_visual(delta: float) -> void:
	if _clip != null:
		_clip.tick(delta, size)


## Returns true when this Vermin is destroyed.
func take_damage(amount: int) -> bool:
	hp -= amount
	play("hurt")
	if _clip != null:
		_clip.flash()
	refresh_bar()
	return hp <= 0


func refresh_bar() -> void:
	if _clip != null:
		_clip.tick(0.0, size)
	if _bar == null:
		return
	var width := size.x
	var height := maxf(5.0, size.y * 0.08)
	_bar_back.position = Vector2(0.0, size.y - height)
	_bar_back.size = Vector2(width, height)
	var fraction := 0.0 if max_hp <= 0 else clampf(float(hp) / float(max_hp), 0.0, 1.0)
	_bar.position = _bar_back.position
	_bar.size = Vector2(width * fraction, height)
