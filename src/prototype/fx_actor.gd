## A one-shot cosmetic effect on the lawn: a frame sequence (the Seed Lobber's
## seed burst) or a single papercraft still that pops in and fades (impact
## bursts, collect flecks). It frees itself; the match never waits for it.
class_name FxActor
extends Node2D

## Safety cap so a stalled effect can never leak the node.
const LIFETIME_CAP := 3.0

var _sprite: Sprite2D
var _frames: Array[Texture2D] = []
var _fps := 30.0
var _duration := 0.35
var _scale := 1.0
var _rise := 0.0
var _life := 0.0
var _origin := Vector2.ZERO


func _init() -> void:
	z_index = 8
	_sprite = Sprite2D.new()
	_sprite.centered = true
	add_child(_sprite)


## Plays [param frames] once at [param fps], centred on [param at] (lawn
## pixels), with the frame canvas scaled to [param diameter] px across.
func play_frames(frames: Array[Texture2D], at: Vector2, diameter: float, fps: float = 30.0) -> void:
	if frames.is_empty():
		queue_free()
		return
	_frames = frames
	_fps = maxf(1.0, fps)
	_duration = float(frames.size()) / _fps
	_sprite.texture = frames[0]
	_scale = _fit(frames[0], diameter)
	_sprite.scale = Vector2.ONE * _scale
	_origin = at
	position = at


## Pops [param texture] in at [param at], holds, and fades over [param duration]
## seconds, drifting up [param rise] px (collect flecks float away).
func play_still(texture: Texture2D, at: Vector2, diameter: float, duration: float = 0.35, rise: float = 0.0) -> void:
	if texture == null:
		queue_free()
		return
	_sprite.texture = texture
	_scale = _fit(texture, diameter)
	_duration = maxf(0.05, duration)
	_rise = rise
	_origin = at
	position = at
	_apply(0.0)


## Seconds the effect lasts (frame sequences: frames / fps).
func duration() -> float:
	return _duration


func _process(delta: float) -> void:
	_life += delta
	if _life >= minf(_duration, LIFETIME_CAP):
		queue_free()
		return
	_apply(_life / _duration)


func _apply(t: float) -> void:
	if not _frames.is_empty():
		var index := clampi(int(_life * _fps), 0, _frames.size() - 1)
		_sprite.texture = _frames[index]
		return
	# Still: quick pop to full size, hold, then fade out over the last 45%.
	var pop := clampf(t / 0.3, 0.0, 1.0)
	var grow := 0.55 + 0.45 * (1.0 - pow(1.0 - pop, 3.0))
	_sprite.scale = Vector2.ONE * _scale * grow
	var fade := clampf((t - 0.55) / 0.45, 0.0, 1.0)
	_sprite.modulate.a = 1.0 - fade
	position = _origin + Vector2(0.0, -_rise * t)


func _fit(texture: Texture2D, diameter: float) -> float:
	var longest := maxf(texture.get_width(), texture.get_height())
	return diameter / longest if longest > 0.0 else 1.0
