## The flat paper sticker a new Warden is placed as (GW-AA pass 5).
##
## Draws one still frame of the Warden as a deformable paper decal, cut into
## horizontal strips: it comes down standing, then an invisible hand presses
## it onto the felt from its bottom edge up. The pressed part lies flat on the
## tile (foreshortened), the next stretch bends over a paper roll (each strip
## lit by its bend angle so it reads as a curl, not a scale), and the rest
## still stands. Then it shrinks and sinks into the tile. PaperPop.placement
## drives every pose; the actor hides its live clip while this shows.
class_name StickerDecal
extends Node2D

## Strips the sticker is cut into (more = a rounder curl).
const SLICES := 32
## Brightness by bend: flat on the felt, the roll's lit shoulder, standing.
const FLAT_LIGHT := 1.0
const CURL_LIGHT := 1.16
const STAND_LIGHT := 0.94
## How much narrower the far edge of a flat sticker looks (perspective).
const FAR_NARROW := 0.1
## The sink darkens it toward the felt and fades it out at the very end.
const SINK_DARK := 0.4
const SHADOW_COLOR := Color(0.05, 0.1, 0.04, 0.28)

var _texture: Texture2D
## Ground point (feet) in texture pixels, and texture px -> actor px.
var _ground_px := Vector2.ZERO
var _px_scale := 1.0
## Ground point in actor-local pixels.
var _foot := Vector2.ZERO
var _beat: Dictionary = {}
## First opaque row of the frame (texture px): the curl runs over the drawn
## art only, not the frame's empty headroom.
var _top_px := 0.0
## Opaque top per frame texture, measured once.
static var _tops: Dictionary = {}


## Which frame to draw, where its feet are in the frame, where they stand in
## the actor, and the frame's on-screen scale.
func configure(texture: Texture2D, ground_px: Vector2, foot: Vector2, px_scale: float) -> void:
	_texture = texture
	_ground_px = ground_px
	_foot = foot
	_px_scale = px_scale
	_top_px = minf(_opaque_top(texture), maxf(ground_px.y - 1.0, 0.0))
	queue_redraw()


## The first row with any opaque pixel (0 when it cannot be read).
static func _opaque_top(texture: Texture2D) -> float:
	if texture == null:
		return 0.0
	var key := texture.get_rid()
	if not _tops.has(key):
		var image := texture.get_image()
		var top := 0.0
		if image != null and not image.is_empty():
			if image.is_compressed():
				image.decompress()
			top = float(image.get_used_rect().position.y)
		_tops[key] = top
	return float(_tops[key])


func set_beat(beat: Dictionary) -> void:
	_beat = beat
	queue_redraw()


func has_texture() -> bool:
	return _texture != null


## The decal's on-screen height right now (actor px), for tests and captures:
## standing it is the sticker's full height, flat it is foreshortened.
func shown_height() -> float:
	var pts := _outline()
	if pts.is_empty():
		return 0.0
	var top := INF
	var bottom := -INF
	for p in pts:
		top = minf(top, p.y)
		bottom = maxf(bottom, p.y)
	return bottom - top


func _draw() -> void:
	if _texture == null or _beat.is_empty() or not bool(_beat.get("decal", false)):
		return
	var size_px := _texture.get_size()
	var height := (_ground_px.y - _top_px) * _px_scale
	if height <= 1.0:
		return
	var geo := _geometry()
	var points: Array = geo["points"]
	var lights: Array = geo["lights"]
	var shade := float(_beat.get("shade", 0.0))
	var dark := 1.0 - SINK_DARK * shade
	var alpha := 1.0 - maxf(0.0, shade - 0.7) / 0.3 * 0.85
	# A soft contact shadow that firms up as the sticker nears the felt.
	var lift := float(_beat.get("lift", 0.0))
	var sink := float(_beat.get("sink", 1.0))
	var shadow_w := size_px.x * _px_scale * 0.42 * sink
	var shadow_a := SHADOW_COLOR.a * (1.0 - clampf(lift / PaperPop.DESCEND_LIFT, 0.0, 1.0) * 0.7)
	_draw_ellipse(_foot + Vector2(0.0, 2.0), Vector2(shadow_w, shadow_w * 0.22), Color(SHADOW_COLOR, shadow_a * alpha))
	var uv_rect := _uv_rect()
	var draw_texture := _texture
	if _texture is AtlasTexture:
		draw_texture = (_texture as AtlasTexture).atlas
	for i in SLICES:
		var v0 := 1.0 - float(i) / SLICES
		var v1 := 1.0 - float(i + 1) / SLICES
		var a: Array = points[i]
		var b: Array = points[i + 1]
		var l0 := float(lights[i]) * dark
		var l1 := float(lights[i + 1]) * dark
		var quad := PackedVector2Array([a[0], a[1], b[1], b[0]])
		var colors := PackedColorArray([
			Color(l0, l0, l0, alpha), Color(l0, l0, l0, alpha),
			Color(l1, l1, l1, alpha), Color(l1, l1, l1, alpha),
		])
		var u0 := uv_rect.position.x
		var u1 := uv_rect.end.x
		var span := _ground_px.y - _top_px
		var y0 := uv_rect.position.y + uv_rect.size.y * (_top_px + span * v0) / size_px.y
		var y1 := uv_rect.position.y + uv_rect.size.y * (_top_px + span * v1) / size_px.y
		var uvs := PackedVector2Array([Vector2(u0, y0), Vector2(u1, y0), Vector2(u1, y1), Vector2(u0, y1)])
		draw_polygon(quad, colors, uvs, draw_texture)


## The texture's own rect in its (atlas) texture's UV space.
func _uv_rect() -> Rect2:
	if _texture is AtlasTexture:
		var atlas := _texture as AtlasTexture
		var full := atlas.atlas.get_size()
		return Rect2(atlas.region.position / full, atlas.region.size / full)
	return Rect2(0.0, 0.0, 1.0, 1.0)


## Strip edges bottom to top: points[i] = [left, right] at the i-th cut, and
## the light for that cut.
func _geometry() -> Dictionary:
	var size_px := _texture.get_size()
	var sink := float(_beat.get("sink", 1.0))
	var height := (_ground_px.y - _top_px) * _px_scale * sink
	var width := size_px.x * _px_scale * sink
	var lift := float(_beat.get("lift", 0.0)) * _ground_px.y * _px_scale
	var press := clampf(float(_beat.get("press", 0.0)), 0.0, 1.0)
	var pressed := press * height
	# The roll only forms once the hand has started pressing.
	var radius := PaperPop.CURL_RADIUS * height * smoothstep(0.0, 0.12, press)
	var center_x := _foot.x + (_ground_px.x - size_px.x * 0.5) * _px_scale * sink
	var points: Array = []
	var lights: Array = []
	for i in SLICES + 1:
		var s := height * float(i) / SLICES
		var at := PaperPop.curl_point(s, pressed, radius)
		var depth := float(at["depth"])
		var up := float(at["up"])
		var angle := float(at["angle"])
		var y := _foot.y - lift - depth * PaperPop.FLAT_K - up
		var narrow := 1.0 - FAR_NARROW * clampf(depth / maxf(height, 1.0), 0.0, 1.0)
		var half := width * 0.5 * narrow
		points.append([Vector2(center_x - half, y), Vector2(center_x + half, y)])
		var light := STAND_LIGHT
		if angle <= 0.0:
			light = FLAT_LIGHT
		elif angle < PI * 0.5:
			# Brightest on the roll's shoulder, where the paper faces the light.
			light = lerpf(FLAT_LIGHT, STAND_LIGHT, angle / (PI * 0.5)) + (CURL_LIGHT - FLAT_LIGHT) * sin(angle * 2.0)
		lights.append(light)
	return {"points": points, "lights": lights}


func _outline() -> Array:
	if _texture == null or _beat.is_empty() or not bool(_beat.get("decal", false)):
		return []
	var out: Array = []
	for pair in _geometry()["points"]:
		out.append(pair[0])
		out.append(pair[1])
	return out


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	if radii.x <= 0.5 or color.a <= 0.0:
		return
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(pts, color)
