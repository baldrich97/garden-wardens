## The death poof: plays the fx/poof clip once at the spot a Warden vacated,
## then removes itself. Purely cosmetic — the match does not wait for it.
class_name PoofActor
extends Node2D

## Safety cap so a stalled clip can never leak the node.
const LIFETIME_CAP := 3.0

var _sprite: AnimatedSprite2D
var _life := 0.0


## Places the puff centred at `at` (lawn pixels) roughly `diameter` across.
func play_at(at: Vector2, diameter: float) -> void:
	z_index = 8
	var frames := AnimLibrary.poof()
	if frames == null:
		return
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.centered = true
	var texture := frames.get_frame_texture(AnimLibrary.POOF_ANIM, 0)
	if texture != null:
		var longest := maxf(texture.get_width(), texture.get_height())
		if longest > 0.0:
			_sprite.scale = Vector2.ONE * (diameter / longest)
	_sprite.animation_finished.connect(_on_finished)
	add_child(_sprite)
	position = at
	_sprite.play(AnimLibrary.POOF_ANIM)


func _process(delta: float) -> void:
	_life += delta
	if _life >= LIFETIME_CAP:
		queue_free()


func _on_finished() -> void:
	queue_free()
