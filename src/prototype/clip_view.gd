## Plays a named clip and the temporary motion that is not in the drawings.
class_name ClipView
extends Node2D

## Damage-state suffixes that can end a clip name (`idle_66` -> `idle`).
const STATE_SUFFIXES: Array[String] = ["100", "66", "33"]

var _sprite: AnimatedSprite2D
var _anim := ""
var _time := 0.0
var _squash := 0.0
var _flash := 0.0
## Anchor-fit inputs from the unit's frames.json. Vector2.INF keeps the old
## center-fit; when set, the art is scaled uniformly from `canvas_px` and the
## `ground_px` point is pinned to the bottom-center of the bounds, so feet and
## pots sit on the tile ground line and every animation of the unit shares one
## scale (the canvas is constant across a unit's animations).
var _anchor_ground := Vector2.INF
var _anchor_canvas := Vector2.INF
## Extra motion (idle bob, chew lean, squash, flash) is on by default. The
## anim preview turns it off so the drawings show exactly as authored.
var _motion := true
## The idle bob (GW-AA pass 3): off by default, because ground units stand
## still on their rail; fliers and the wave roster portraits turn it on.
var _idle_bob := false
## Optional per-frame overlay (the Needle Spitter's smoke): one texture per
## frame of `_overlay_base` animations, drawn on the same canvas as the clip.
var _overlay: Sprite2D
var _overlay_base := ""
var _overlay_frames: Array[Texture2D] = []
## Overlay boost (GW-AA pass 3): scale about a canvas pivot, alpha gain, and
## a lift toward white, so the Needle smoke reads at the bigger unit size.
var _overlay_scale := 1.0
var _overlay_pivot := Vector2.INF
var _overlay_gain := 1.0
var _overlay_lift := 0.0

const _OVERLAY_SHADER_CODE := """
shader_type canvas_item;
uniform float gain = 1.0;
uniform float lift = 0.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	c.rgb = mix(c.rgb, vec3(1.0), lift);
	c.a = clamp(c.a * gain, 0.0, 1.0);
	COLOR = c * COLOR;
}
"""


## Replaces the current clip. Safe to call more than once.
func use(frames: SpriteFrames) -> void:
	if _sprite != null:
		_sprite.free()
		_sprite = null
		_overlay = null
	_anim = ""
	_squash = 0.0
	_flash = 0.0
	setup(frames)


func setup(frames: SpriteFrames) -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.centered = true
	add_child(_sprite)
	# Legacy clips ship a bare "idle"; the new clips name it `idle_100` and
	# friends, so fall back to whatever the clip carries first.
	var names := frames.get_animation_names()
	if names.has("idle"):
		play("idle")
	elif names.has("idle_100"):
		play("idle_100")
	elif not names.is_empty():
		play(names[0])


## Draws [param frames][i] over frame i of every [param anim_base] animation
## (any damage state), e.g. the Needle Spitter's smoke over its action frames.
## The overlay shares the clip's canvas, anchor, scale, and squash.
func set_overlay(anim_base: String, frames: Array[Texture2D]) -> void:
	_overlay_base = anim_base
	_overlay_frames = frames
	if _sprite == null or frames.is_empty():
		return
	if _overlay == null:
		_overlay = Sprite2D.new()
		_overlay.name = "Overlay"
		_overlay.centered = true
		_sprite.add_child(_overlay)
		# Follow the clip's own frame clock so smoke never lags a frame behind.
		_sprite.frame_changed.connect(_refresh_overlay)
		_sprite.animation_changed.connect(_refresh_overlay)
	_apply_overlay_boost()
	_refresh_overlay()


## Enlarges the overlay about [param pivot_px] (canvas pixels, e.g. the
## Needle Spitter's mouth), multiplies its alpha by [param gain] and lifts its
## colour [param lift] of the way to white.
func set_overlay_boost(scale_factor: float, pivot_px: Vector2, gain: float, lift: float) -> void:
	_overlay_scale = scale_factor
	_overlay_pivot = pivot_px
	_overlay_gain = gain
	_overlay_lift = lift
	_apply_overlay_boost()


func overlay_boost() -> float:
	return _overlay_scale


func _apply_overlay_boost() -> void:
	if _overlay == null or _sprite == null:
		return
	var canvas := Vector2.ZERO
	if _overlay_frames.size() > 0 and _overlay_frames[0] != null:
		canvas = _overlay_frames[0].get_size()
	_overlay.scale = Vector2(_overlay_scale, _overlay_scale)
	if _overlay_pivot != Vector2.INF and canvas != Vector2.ZERO:
		var pivot := _overlay_pivot - canvas * 0.5
		_overlay.position = pivot * (1.0 - _overlay_scale)
	else:
		_overlay.position = Vector2.ZERO
	if _overlay_gain != 1.0 or _overlay_lift != 0.0:
		var boost := _overlay.material as ShaderMaterial
		if boost == null:
			var shader := Shader.new()
			shader.code = _OVERLAY_SHADER_CODE
			boost = ShaderMaterial.new()
			boost.shader = shader
			_overlay.material = boost
		boost.set_shader_parameter("gain", _overlay_gain)
		boost.set_shader_parameter("lift", _overlay_lift)


## The overlay texture showing right now, or null when none is drawn.
func overlay_texture() -> Texture2D:
	if _overlay == null or not _overlay.visible:
		return null
	return _overlay.texture


## Changes clip only when the name changes, so a looping walk is not restarted.
func play(anim_name: String) -> void:
	if _sprite == null or anim_name == _anim:
		return
	if not _sprite.sprite_frames.has_animation(anim_name):
		return
	_anim = anim_name
	_sprite.play(anim_name)


## Resumes playback of the current animation from its held frame.
func resume() -> void:
	if _sprite == null or _anim.is_empty():
		return
	_sprite.play(_anim)


## Stops and hides the current clip (used when a unit slot has no clips).
func clear() -> void:
	if _sprite != null:
		_sprite.stop()
		_sprite.visible = false
	_anim = ""
	_squash = 0.0
	_flash = 0.0


## Turns the idle hover bob on (fliers, roster portraits) or off (ground units).
func set_idle_bob(enabled: bool) -> void:
	_idle_bob = enabled


func idle_bob_enabled() -> bool:
	return _idle_bob


## Toggles the temporary motion (idle bob, chew lean) on or off.
func set_motion_enabled(enabled: bool) -> void:
	_motion = enabled


## Pins the frames.json `ground_px` point (canvas coordinates) to the
## bottom-center of the bounds, with a uniform scale fitted to `canvas_px`.
func set_anchor_fit(ground_px: Vector2, canvas_px: Vector2) -> void:
	_anchor_ground = ground_px
	_anchor_canvas = canvas_px


## Switches to `new_animation` keeping the frame index and in-frame progress
## (the damage states are authored index-for-index). Returns false, leaving the
## clip untouched, when nothing changed or the animation does not exist.
func retarget(new_animation: String) -> bool:
	if _sprite == null or new_animation.is_empty() or new_animation == _anim:
		return false
	if not AnimLibrary.swap_keep_frame(_sprite, new_animation):
		return false
	_anim = new_animation
	return true


## The sprite driving the current clip, for reading frame state or stepping.
func sprite() -> AnimatedSprite2D:
	return _sprite


## Frame count of the current animation, or 0 when nothing is selected.
func frame_count() -> int:
	if _sprite == null or _anim.is_empty():
		return 0
	return _sprite.sprite_frames.get_frame_count(_anim)


func pulse() -> void:
	_squash = 1.0


func flash() -> void:
	_flash = 1.0


func animation_name() -> String:
	return _anim


func is_still() -> bool:
	if _sprite == null or _anim.is_empty():
		return true
	return _sprite.sprite_frames.get_frame_count(_anim) <= 1


func tick(delta: float, bounds: Vector2) -> void:
	_time += delta
	_squash = maxf(0.0, _squash - delta * 5.0)
	_flash = maxf(0.0, _flash - delta * 4.0)
	_fit(bounds)
	_refresh_overlay()


func _refresh_overlay() -> void:
	if _overlay == null:
		return
	var index := _sprite.frame
	var drawn := not _anim.is_empty() and _anim_base() == _overlay_base and index < _overlay_frames.size()
	_overlay.visible = drawn
	if drawn:
		_overlay.texture = _overlay_frames[index]


## Animation name without a damage-state suffix, so `idle_66` still reads as
## idle and the temporary motion still applies to the damaged states.
func _anim_base() -> String:
	var index := _anim.rfind("_")
	if index > 0 and _anim.substr(index + 1) in STATE_SUFFIXES:
		return _anim.left(index)
	return _anim


func _fit(bounds: Vector2) -> void:
	if _sprite == null or bounds.x <= 1.0 or bounds.y <= 1.0 or _anim.is_empty():
		return
	# Fliers carry no ground point (INF): they keep the centred fit. INF > 1.0
	# is true, so test for a finite anchor explicitly (an INF anchor made the
	# fit NaN and hid every bee and fly).
	var anchor_fit := _anchor_ground.is_finite() and _anchor_canvas.is_finite() \
			and _anchor_canvas.x > 1.0 and _anchor_canvas.y > 1.0
	var texture: Texture2D = null
	if not anchor_fit:
		texture = _sprite.sprite_frames.get_frame_texture(_anim, 0)
		if texture == null:
			return
	var canvas := _anchor_canvas if anchor_fit else Vector2(texture.get_width(), texture.get_height())
	var fitted := minf(bounds.x / canvas.x, bounds.y / canvas.y)
	var bob := 0.0
	var lean := 0.0
	var stretch_x := 1.0
	var stretch_y := 1.0
	var base := _anim_base()
	if _motion and _idle_bob and base == "idle":
		bob = sin(_time * 5.0) * bounds.y * 0.06
	elif _motion and base == "chew":
		lean = -0.28
	if _squash > 0.0:
		stretch_x = 1.0 + 0.22 * _squash
		stretch_y = 1.0 - 0.28 * _squash
	if anchor_fit:
		# The ground point is pinned so squash pivots at the feet.
		var ground := _anchor_ground - canvas * 0.5
		var sprite_scale := Vector2(fitted * stretch_x, fitted * stretch_y)
		_sprite.position = Vector2(bounds.x * 0.5, bounds.y + bob) - ground * sprite_scale
	else:
		_sprite.position = Vector2(bounds.x * 0.5, bounds.y * 0.5 + bob)
	_sprite.rotation = lean
	_sprite.scale = Vector2(fitted * stretch_x, fitted * stretch_y)
	_sprite.modulate = Color.WHITE.lerp(Color(1.8, 1.8, 1.8), _flash)
