## A lobbed seed bundle. It travels to a tile, then the seeds finish the trip.
## Visuals: the Seed Lobber's fx/projectile art (fluff_ball.png bundle,
## seed_single.png seeds); the flight and burst timing are unchanged.
class_name LobActor
extends Control

const TRAVEL_TIME := 0.42
const SEED_TIME := 0.24
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


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 5


func setup(from_pos: Vector2, target: Vector2i, seed_cells: Array[Vector2i]) -> void:
	_from = from_pos
	_target = target
	cells = seed_cells
	column_pos = from_pos.x
	row_pos = from_pos.y
	_bundle = _make_puff(FLUFF)
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
		row_pos = lerpf(_from.y, float(_target.y), t) + sin(t * PI) * -0.8
		if t < 1.0:
			return false
		_phase = 1
		column_pos = float(_target.x) + 0.5
		row_pos = float(_target.y)
		_bundle.visible = false
		delta = _travel - TRAVEL_TIME
	_seed_time += delta
	if _seed_time >= SEED_TIME and not _hit:
		_hit = true
		return true
	return false


func finished() -> bool:
	return _hit


## Places the bundle, and the seeds while they fly out from the burst.
func place_on_lawn(origin: Vector2, cell: float) -> void:
	var center := origin + Vector2(column_pos * cell, (row_pos + 0.5) * cell)
	var box := cell * 0.34
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
		var spot := Vector2(column_pos, row_pos).lerp(goal, t)
		var seed_box := cell * 0.22
		seed.size = Vector2(seed_box, seed_box)
		var world := origin + Vector2(spot.x * cell, (spot.y + 0.5) * cell)
		seed.position = world - position - seed.size * 0.5
