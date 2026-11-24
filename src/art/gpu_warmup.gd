## Draws every preloaded texture and each custom material once, as 1 px
## quads at near-zero alpha under the stage matte, over the first two frames
## (half the textures each), so the renderer finishes uploads and compiles
## its shader variants before the player's first click. Frees itself after.
## See StartupPreload for the root causes.
class_name GpuWarmup
extends Control

const FRAMES := 2
## Drawn so faintly (and under the opaque matte) that nothing ever shows.
const ALPHA := 0.004

var _textures: Array[Texture2D] = []
var _frame := 0
var _drawn := 0
var _started_usec := 0
## Milliseconds the warmup frames took, filled when it finishes.
static var last_ms := -1.0
static var last_count := 0


func _init() -> void:
	name = "GpuWarmup"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_as_relative = false
	z_index = -100
	size = Vector2(4.0, 4.0)


func _ready() -> void:
	_started_usec = Time.get_ticks_usec()
	_textures = StartupPreload.textures()
	last_count = _textures.size()
	# One quad per custom material (the ray mask, the smoke boost).
	for material in StartupPreload.materials():
		var quad := TextureRect.new()
		quad.texture = _textures[0] if not _textures.is_empty() else null
		quad.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		quad.size = Vector2(2.0, 2.0)
		quad.material = material
		quad.modulate = Color(1, 1, 1, ALPHA)
		quad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(quad)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = AnimLibrary.poof()
	sprite.modulate = Color(1, 1, 1, ALPHA)
	sprite.scale = Vector2(0.002, 0.002)
	add_child(sprite)
	queue_redraw()


func _process(_delta: float) -> void:
	_frame += 1
	if _frame > FRAMES:
		last_ms = float(Time.get_ticks_usec() - _started_usec) / 1000.0
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if _textures.is_empty():
		return
	var per_frame := int(ceil(float(_textures.size()) / float(FRAMES)))
	var from := mini(_frame * per_frame, _textures.size())
	var to := mini(from + per_frame, _textures.size())
	var tint := Color(1, 1, 1, ALPHA)
	for i in range(from, to):
		draw_texture_rect(_textures[i], Rect2(Vector2(float(i % 4), 0.0), Vector2.ONE), false, tint)
	_drawn += to - from


## How many textures went through the warmup draw.
func drawn() -> int:
	return _drawn
