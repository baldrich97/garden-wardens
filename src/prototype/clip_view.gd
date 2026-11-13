## Plays a named clip and the temporary motion that is not in the drawings.
class_name ClipView
extends Node2D

var _sprite: AnimatedSprite2D
var _anim := ""
var _time := 0.0
var _squash := 0.0
var _flash := 0.0


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
	play("idle")


## Changes clip only when the name changes, so a looping walk is not restarted.
func play(anim_name: String) -> void:
	if _sprite == null or anim_name == _anim:
		return
	if not _sprite.sprite_frames.has_animation(anim_name):
		return
	_anim = anim_name
	_sprite.play(anim_name)


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


func _fit(bounds: Vector2) -> void:
	if _sprite == null or bounds.x <= 1.0 or bounds.y <= 1.0:
		return
	var texture := _sprite.sprite_frames.get_frame_texture(_anim, 0)
	if texture == null:
		return
	var fitted := minf(bounds.x / texture.get_width(), bounds.y / texture.get_height())
	var bob := 0.0
	var lean := 0.0
	var stretch_x := 1.0
	var stretch_y := 1.0
	if _anim == "idle":
		bob = sin(_time * 5.0) * bounds.y * 0.06
	elif _anim == "chew":
		lean = -0.28
	if _squash > 0.0:
		stretch_x = 1.0 + 0.22 * _squash
		stretch_y = 1.0 - 0.28 * _squash
	_sprite.position = Vector2(bounds.x * 0.5, bounds.y * 0.5 + bob)
	_sprite.rotation = lean
	_sprite.scale = Vector2(fitted * stretch_x, fitted * stretch_y)
	_sprite.modulate = Color.WHITE.lerp(Color(1.8, 1.8, 1.8), _flash)
