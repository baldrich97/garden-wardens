## Shared "standing on a rail" bits for Wardens and Vermin (GW-AA pass 3):
## the soft contact shadow under the feet, and a slim health bar laid on the
## ground just under the foot point. The board tells each actor where its foot
## is (actor-local pixels) and how wide a cell is on its rail.
class_name RailStand
extends RefCounted

## GW-AA pass 4: Brandon asked for no health bars under units. HP still
## drives the damage-state art (100 / 66 / 33); flip this to bring bars back.
const SHOW_HEALTH_BARS := false
const BAR_WIDTH_CELLS := 0.6
const BAR_HEIGHT_CELLS := 0.07
const BAR_GAP_PX := 3.0

static var _shadow_texture: GradientTexture2D


## A soft dark ellipse; one texture shared by every actor.
static func shadow_texture() -> GradientTexture2D:
	if _shadow_texture == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(0.06, 0.12, 0.03, 0.55))
		gradient.set_color(1, Color(0.06, 0.12, 0.03, 0.0))
		gradient.add_point(0.55, Color(0.06, 0.12, 0.03, 0.32))
		_shadow_texture = GradientTexture2D.new()
		_shadow_texture.gradient = gradient
		_shadow_texture.fill = GradientTexture2D.FILL_RADIAL
		_shadow_texture.fill_from = Vector2(0.5, 0.5)
		_shadow_texture.fill_to = Vector2(1.0, 0.5)
		_shadow_texture.width = 64
		_shadow_texture.height = 64
	return _shadow_texture


static func make_shadow() -> TextureRect:
	var shadow := TextureRect.new()
	shadow.name = "ContactShadow"
	shadow.texture = shadow_texture()
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.stretch_mode = TextureRect.STRETCH_SCALE
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return shadow


## Bars draw with their unit (same rail z), so a front-rail unit covers a
## back-rail unit's bar the same way it covers its feet, as on a real stage.
static func style_bar(rect: ColorRect) -> void:
	rect.z_as_relative = true
	rect.z_index = 0
	rect.visible = SHOW_HEALTH_BARS


## Places the shadow (centered on the foot, flattened to the ground) and the
## bar (just under the foot). [param flying] units get a lighter, smaller shadow.
static func layout(shadow: TextureRect, bar_back: ColorRect, bar: ColorRect, foot: Vector2,
		cell_w: float, flying: bool, fraction: float) -> void:
	if shadow != null:
		var w := cell_w * (0.5 if flying else 0.72)
		var h := cell_w * (0.13 if flying else 0.2)
		shadow.size = Vector2(w, h)
		shadow.position = foot - Vector2(w * 0.5, h * 0.5)
		shadow.modulate = Color(1, 1, 1, 0.6 if flying else 1.0)
	if bar_back == null or bar == null:
		return
	var width := cell_w * BAR_WIDTH_CELLS
	var height := maxf(4.0, cell_w * BAR_HEIGHT_CELLS)
	bar_back.position = foot + Vector2(-width * 0.5, BAR_GAP_PX)
	bar_back.size = Vector2(width, height)
	bar.position = bar_back.position
	bar.size = Vector2(width * clampf(fraction, 0.0, 1.0), height)
