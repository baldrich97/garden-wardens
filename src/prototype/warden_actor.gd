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

var _bar: ColorRect
var _bar_back: ColorRect


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 2


## Builds the portrait. A null texture becomes the Dew Dropper placeholder.
func setup(p_kind: UnitCatalog.Warden, p_column: int, p_row: int, p_id: int, texture: Texture2D) -> void:
	kind = p_kind
	column = p_column
	row = p_row
	grid_id = p_id
	max_hp = UnitCatalog.WARDEN_HP[kind]
	hp = max_hp
	if texture == null:
		var placeholder := Panel.new()
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		placeholder.add_theme_stylebox_override("panel", FlatStyle.panel(FlatStyle.PLACEHOLDER, FlatStyle.INK, 12, 3))
		add_child(placeholder)
		placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
		var label := Label.new()
		label.text = "No sprite"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.add_theme_color_override("font_color", FlatStyle.INK)
		label.add_theme_font_size_override("font_size", 14)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		placeholder.add_child(label)
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
	else:
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
	_bar.color = Color("7dce4a")
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bar)


## Returns "shot", "water", or "" for what happened this step.
func tick(delta: float, can_shoot: bool) -> String:
	if kind == UnitCatalog.Warden.NEEDLE:
		fire_wait = maxf(0.0, fire_wait - delta)
		if can_shoot and fire_wait <= 0.0:
			fire_wait = UnitCatalog.NEEDLE_INTERVAL
			return "shot"
	elif kind == UnitCatalog.Warden.DEW:
		produce_wait -= delta
		if produce_wait <= 0.0:
			produce_wait += UnitCatalog.DEW_INTERVAL
			return "water"
	return ""


## Returns true when this Warden is destroyed.
func take_damage(amount: float) -> bool:
	hp -= int(ceil(amount))
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
	_bar.color = FlatStyle.CLAY if fraction < 0.35 else Color("7dce4a")
