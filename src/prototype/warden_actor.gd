## One planted Warden. The match decides when it shoots or produces water.
class_name WardenActor
extends Control

var kind: UnitCatalog.Warden
var column: int
var row: int
var grid_id: int
var hp: int
var max_hp: int
var fire_wait: float = 0.35
var produce_wait: float = UnitCatalog.DEW_INTERVAL

var _clip: ClipView
var _bar: ColorRect
var _bar_back: ColorRect


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 2


func setup(p_kind: UnitCatalog.Warden, p_column: int, p_row: int, p_id: int) -> void:
	kind = p_kind
	column = p_column
	row = p_row
	grid_id = p_id
	max_hp = UnitCatalog.WARDEN_HP[kind]
	hp = max_hp
	_clip = ClipView.new()
	_clip.setup(UnitClips.warden(kind))
	add_child(_clip)
	_bar_back = ColorRect.new()
	_bar_back.color = Color(0.08, 0.1, 0.08, 0.85)
	_bar_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_back.z_index = 1
	add_child(_bar_back)
	_bar = ColorRect.new()
	_bar.color = Color("7dce4a")
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.z_index = 1
	add_child(_bar)
	if UnitClips.needs_label(kind):
		var label := Label.new()
		label.text = UnitCatalog.WARDEN_SHORT[kind]
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.add_theme_color_override("font_color", FlatStyle.INK)
		label.add_theme_font_size_override("font_size", 14)
		label.z_index = 2
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(label)


## Returns "shot", "lob", "water", or "" for what happened this step.
func tick(delta: float, can_shoot: bool) -> String:
	var action := ""
	if kind == UnitCatalog.Warden.NEEDLE:
		fire_wait = maxf(0.0, fire_wait - delta)
		if can_shoot and fire_wait <= 0.0:
			fire_wait = UnitCatalog.NEEDLE_INTERVAL
			action = "shot"
	elif kind == UnitCatalog.Warden.DEW:
		produce_wait -= delta
		if produce_wait <= 0.0:
			produce_wait += UnitCatalog.DEW_INTERVAL
			action = "water"
	elif kind == UnitCatalog.Warden.SEED:
		fire_wait = maxf(0.0, fire_wait - delta)
		if can_shoot and fire_wait <= 0.0:
			fire_wait = UnitCatalog.LOB_INTERVAL
			action = "lob"
	if action == "shot" or action == "lob":
		play("attack")
		_clip.pulse()
	elif action == "water":
		play("produce")
		_clip.pulse()
	else:
		play("idle")
	_clip.tick(delta, size)
	return action


func play(anim_name: String) -> void:
	if _clip != null:
		_clip.play(anim_name)


## Returns true when this Warden is destroyed.
func take_damage(amount: float) -> bool:
	hp -= int(ceil(amount))
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
	_bar.color = FlatStyle.CLAY if fraction < 0.35 else Color("7dce4a")
