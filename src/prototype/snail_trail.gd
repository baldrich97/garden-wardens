## The snail's cellophane slime trail. A small pool of A6 puddles laid along
## its ground path, each fading out on its own. Purely presentational: the
## match never waits on a puddle, and nothing in src/rules/ knows about it.
class_name SnailTrail
extends Control

## Cellophane slime puddle (assets/art/fx/A6.png), 321 x 139.
const PUDDLE: Texture2D = preload("res://assets/art/fx/A6.png")
const PUDDLE_W := 321.0
const PUDDLE_H := 139.0

## How many puddles are pooled at once.
const POOL_SIZE := 12
## Seconds a puddle stays before it is gone.
const LIFE := 3.5
## Opacity of a fresh puddle; it fades to zero over LIFE.
const ALPHA := 0.7
## Puddle width as a fraction of a lawn cell.
const WIDTH_CELLS := 0.6

var _paddles: Array[TextureRect] = []
## Remaining life per pooled paddle, parallel to _paddles; 0.0 means pooled.
var _lives: Array[float] = []
## Round-robin cursor so a busy snail reclaims the oldest puddle first.
var _next := 0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 2
	for _i in POOL_SIZE:
		var paddle := TextureRect.new()
		paddle.texture = PUDDLE
		paddle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		paddle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		paddle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		paddle.modulate = Color(1.0, 1.0, 1.0, 0.0)
		paddle.visible = false
		add_child(paddle)
		_paddles.append(paddle)
		_lives.append(0.0)


## Lays a puddle centered on [param at], in lawn-local pixels.
func drop(at: Vector2, cell: float) -> void:
	var i := _next
	_next = (_next + 1) % POOL_SIZE
	var width := cell * WIDTH_CELLS
	var height := width * PUDDLE_H / PUDDLE_W
	var paddle := _paddles[i]
	paddle.size = Vector2(width, height)
	paddle.position = at - Vector2(width * 0.5, height * 0.5)
	paddle.modulate = Color(1.0, 1.0, 1.0, ALPHA)
	paddle.visible = true
	_lives[i] = LIFE


## Fades every live puddle a little more.
func tick(delta: float) -> void:
	for i in POOL_SIZE:
		if _lives[i] <= 0.0:
			continue
		_lives[i] -= delta
		var paddle := _paddles[i]
		if _lives[i] <= 0.0:
			paddle.visible = false
			paddle.modulate = Color(1.0, 1.0, 1.0, 0.0)
			continue
		paddle.modulate = Color(1.0, 1.0, 1.0, ALPHA * _lives[i] / LIFE)
