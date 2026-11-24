## A lobbed seed bundle. It travels to a tile, then the seeds finish the trip.
## Visuals: the Seed Lobber's fx/projectile art — the fluff ball spins through
## its 8 spin frames in flight, the board plays the 20-frame seed burst where it
## lands (take_burst), and seed_single.png seeds fly out to the struck tiles.
## The flight and burst timing are unchanged.
class_name LobActor
extends Control

const TRAVEL_TIME := 0.42
const SEED_TIME := 0.24
## Spin frames per second for the fluff ball in flight (8 frames, ~2.5 turns/s).
const SPIN_FPS := 20.0
const FLUFF: Texture2D = preload("res://assets/sprites/anim/wardens/seed_lobber/fx/projectile/fluff_ball.png")
const SEED_PUFF: Texture2D = preload("res://assets/sprites/anim/wardens/seed_lobber/fx/projectile/seed_single.png")

var column_pos: float
var row_pos: float
var cells: Array[Vector2i] = []

var _from := Vector2.ZERO
var _target := Vector2i.ZERO
var _phase := 0
var _travel := 0.0
var _seed_time := 0.0
var _hit := false
var _bundle: TextureRect
var _seeds: Array[TextureRect] = []
var _spin: Array[Texture2D] = []
var _burst_pending := false
## Ground track under the ball (grid rows) and the arc height (0..1), so the
## perspective lawn can lift the ball off its rail point (GW-AA pass 3).
var ground_row := 0.0
var arc := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 5


func setup(from_pos: Vector2, target: Vector2i, seed_cells: Array[Vector2i]) -> void:
	_from = from_pos
	_target = target
	cells = seed_cells
	column_pos = from_pos.x
	row_pos = from_pos.y
	ground_row = from_pos.y
	_spin = FxArt.lobber_spin()
	_bundle = _make_puff(FLUFF if _spin.is_empty() else _spin[0])
	_bundle.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bundle)
	for _cell in cells:
		var seed := _make_puff(SEED_PUFF)
		seed.visible = false
		add_child(seed)
		_seeds.append(seed)


## A borderless art rect sized by the lawn placement code.
func _make_puff(texture: Texture2D) -> TextureRect:
	var puff := TextureRect.new()
	puff.texture = texture
	puff.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	puff.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	puff.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return puff


## Returns true on the frame the seeds land and damage should be applied.
func tick(delta: float) -> bool:
	if _phase == 0:
		_travel += delta
		var t := clampf(_travel / TRAVEL_TIME, 0.0, 1.0)
		column_pos = lerpf(_from.x, float(_target.x) + 0.5, t)
		ground_row = lerpf(_from.y, float(_target.y), t)
		arc = sin(t * PI)
		row_pos = ground_row + arc * -0.8
		if not _spin.is_empty():
			_bundle.texture = _spin[int(_travel * SPIN_FPS) % _spin.size()]
		if t < 1.0:
			return false
		_phase = 1
		_burst_pending = true
		column_pos = float(_target.x) + 0.5
		row_pos = float(_target.y)
		ground_row = row_pos
		arc = 0.0
		_bundle.visible = false
		delta = _travel - TRAVEL_TIME
	_seed_time += delta
	if _seed_time >= SEED_TIME and not _hit:
		_hit = true
		return true
	return false


func finished() -> bool:
	return _hit


## True once, on the step the bundle lands, so the board plays the burst.
func take_burst() -> bool:
	var pending := _burst_pending
	_burst_pending = false
	return pending


## The tile the bundle lands on.
func target_cell() -> Vector2i:
	return _target


## Places the bundle, and the seeds while they fly out from the burst, on the
## perspective lawn: the ball rides an arc above its ground track (launched
## from about mid-height of the Lobber), the seeds fan out to their tiles.
func place_on_lawn(geometry: LawnGeometry) -> void:
	var cw := geometry.rail_cell_width(ground_row)
	var lift := cw * (0.55 * (1.0 - _landed_share()) + 1.3 * arc)
	var center := geometry.rail_point(column_pos, ground_row) - Vector2(0.0, lift)
	var box := cw * 0.42
	size = Vector2(box, box)
	position = center - size * 0.5
	var flying := _phase == 1
	var t := 1.0 if _hit else clampf(_seed_time / SEED_TIME, 0.0, 1.0)
	for index in _seeds.size():
		var seed := _seeds[index]
		seed.visible = flying
		if not flying:
			continue
		var goal := Vector2(float(cells[index].x) + 0.5, float(cells[index].y))
		var spot := Vector2(column_pos, ground_row).lerp(goal, t)
		var seed_cw := geometry.rail_cell_width(spot.y)
		var seed_box := seed_cw * 0.26
		seed.size = Vector2(seed_box, seed_box)
		var world := geometry.rail_point(spot.x, spot.y) - Vector2(0.0, seed_cw * 0.35 * (1.0 - t) + seed_box * 0.3)
		seed.position = world - position - seed.size * 0.5


## How far along the flight the ball is (0 at launch, 1 at landing).
func _landed_share() -> float:
	return 1.0 if _phase == 1 else clampf(_travel / TRAVEL_TIME, 0.0, 1.0)
