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


## Replaces the current clip. Safe to call more than once.
func use(frames: SpriteFrames) -> void:
	if _sprite != null:
		_sprite.free()
		_sprite = null
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
	var anchor_fit := _anchor_canvas.x > 1.0 and _anchor_canvas.y > 1.0
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
	if _motion and base == "idle":
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
