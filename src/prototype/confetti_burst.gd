## The placement celebration (GW-AA pass 5): a burst of paper confetti
## (squares, chips and leaves cut from the win banner art by
## tools/art/cut_confetti.py) that pops out of the tile as a new Warden
## stands up, tumbles, flutters down and fades. Purely cosmetic: it rolls
## its own local RandomNumberGenerator (seeded by the Warden's id), never the
## match seed, and the match never waits for it.
class_name ConfettiBurst
extends Node2D

const DIR := "res://assets/art/fx/confetti/"
const PIECES: Array[String] = [
	DIR + "confetti_01_red_square.png",
	DIR + "confetti_02_red_chip.png",
	DIR + "confetti_03_blue_diamond.png",
	DIR + "confetti_04_yellow_square.png",
	DIR + "confetti_05_blue_card.png",
	DIR + "confetti_06_blue_chip.png",
	DIR + "confetti_07_leaf_left.png",
	DIR + "confetti_08_yellow_chip.png",
	DIR + "confetti_09_blue_tall.png",
	DIR + "confetti_10_yellow_chip_b.png",
	DIR + "confetti_11_leaf_bottom.png",
	DIR + "confetti_12_leaf_right.png",
]
const COUNT := 18
const LIFETIME := 1.15
## Launch speed and gravity, as multiples of the tile width per second.
const SPEED_MIN := 1.5
const SPEED_MAX := 2.6
const GRAVITY := 4.2
## Piece size as a share of the tile width.
const PIECE_MIN := 0.14
const PIECE_MAX := 0.22

## Ticked by the board's frame loop by default; captures can drive it.
var manual := false
var _pieces: Array[Sprite2D] = []
var _vel: Array[Vector2] = []
var _spin: Array[float] = []
var _flutter: Array[float] = []
var _life := 0.0
var _cell := 64.0


static func textures() -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	for path in PIECES:
		var texture := BackdropCatalog.cached(path)
		if texture != null:
			out.append(texture)
	return out


## Bursts from [param at] (parent-local px) for a tile [param cell] px wide.
func burst_at(at: Vector2, cell: float, seed_value: int) -> void:
	position = at
	_cell = maxf(cell, 8.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("confetti_%d" % seed_value)
	var art := textures()
	if art.is_empty():
		return
	for i in COUNT:
		var piece := Sprite2D.new()
		piece.texture = art[rng.randi_range(0, art.size() - 1)]
		var longest := maxf(piece.texture.get_width(), piece.texture.get_height())
		piece.scale = Vector2.ONE * (_cell * rng.randf_range(PIECE_MIN, PIECE_MAX) / longest)
		piece.rotation = rng.randf_range(-PI, PI)
		# Upward fan, a little wider than tall, leaning nowhere in particular.
		var angle := rng.randf_range(-PI * 0.86, -PI * 0.14)
		_vel.append(Vector2(cos(angle), sin(angle)) * _cell * rng.randf_range(SPEED_MIN, SPEED_MAX))
		_spin.append(rng.randf_range(-9.0, 9.0))
		_flutter.append(rng.randf_range(0.0, TAU))
		add_child(piece)
		_pieces.append(piece)


func piece_count() -> int:
	return _pieces.size()


func _process(delta: float) -> void:
	if not manual:
		tick(delta)


func tick(delta: float) -> void:
	_life += delta
	var fade := clampf((LIFETIME - _life) / (LIFETIME * 0.35), 0.0, 1.0)
	for i in _pieces.size():
		var piece := _pieces[i]
		# Paper drags: it slows, then flutters down side to side.
		_vel[i] *= pow(0.18, delta)
		_vel[i].y += GRAVITY * _cell * delta * 0.55
		piece.position += _vel[i] * delta + Vector2(sin(_life * 9.0 + _flutter[i]) * _cell * 0.12 * delta * 6.0, 0.0)
		piece.rotation += _spin[i] * delta
		# A flat paper square turning over: squash one axis as it spins.
		piece.scale.x = absf(piece.scale.y) * (0.35 + 0.65 * absf(cos(_life * 7.0 + _flutter[i])))
		piece.modulate.a = fade
	if _life >= LIFETIME:
		queue_free()
