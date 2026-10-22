## The 5 by 9 lawn. Tiles stay square and the grid stays centered.
class_name LawnView
extends Control

const COLUMNS := 9
const ROWS := 5

## Cells that use the dirt tile so the board is not one flat texture.
const PATH_CELLS: Array[Vector2i] = [
	Vector2i(4, 0),
	Vector2i(4, 1),
	Vector2i(4, 2),
	Vector2i(4, 3),
	Vector2i(4, 4),
	Vector2i(3, 4),
	Vector2i(5, 4),
]

signal cell_pressed(cell: Vector2i)
signal cell_hovered(cell: Vector2i)

@export var grass_texture: Texture2D
@export var dirt_texture: Texture2D

var _tiles: Array[TextureRect] = []
var _cursor: ColorRect
var _cell := 64.0
var _origin := Vector2.ZERO
var _aim := Vector2i(-1, -1)
var _aim_allowed := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_build_tiles()
	_cursor = ColorRect.new()
	_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor.z_index = 8
	_cursor.visible = false
	add_child(_cursor)
	resized.connect(_layout)
	_layout()


func tile_count() -> int:
	return _tiles.size()


func cell_size_px() -> float:
	return _cell


func grid_origin() -> Vector2:
	return _origin


func cell_at(local_position: Vector2) -> Vector2i:
	return LawnGrid.cell_at(local_position, _origin, _cell, COLUMNS, ROWS)


## Shows or hides the placement highlight. An x below 0 hides it.
func show_aim(cell: Vector2i, allowed: bool) -> void:
	_aim = cell
	_aim_allowed = allowed
	_place_cursor()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		cell_hovered.emit(cell_at(event.position))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := cell_at(event.position)
		if cell.x >= 0:
			cell_pressed.emit(cell)
			accept_event()


func _build_tiles() -> void:
	if grass_texture == null or dirt_texture == null:
		push_error("LawnView is missing a grass or dirt texture.")
		return
	for row in ROWS:
		for column in COLUMNS:
			var tile := TextureRect.new()
			tile.texture = dirt_texture if _is_path(column, row) else grass_texture
			tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tile.stretch_mode = TextureRect.STRETCH_SCALE
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tile.set_meta("column", column)
			tile.set_meta("row", row)
			add_child(tile)
			_tiles.append(tile)


func _layout() -> void:
	if size.x < 8.0 or size.y < 8.0:
		return
	_cell = minf(size.x / float(COLUMNS), size.y / float(ROWS))
	var board_size := Vector2(_cell * COLUMNS, _cell * ROWS)
	_origin = (size - board_size) * 0.5
	for tile in _tiles:
		var column := int(tile.get_meta("column"))
		var row := int(tile.get_meta("row"))
		tile.position = _origin + Vector2(column, row) * _cell
		tile.size = Vector2(_cell, _cell)
	_place_cursor()


func _place_cursor() -> void:
	if _cursor == null:
		return
	if _aim.x < 0 or _cell <= 0.0:
		_cursor.visible = false
		return
	_cursor.visible = true
	_cursor.position = _origin + Vector2(_aim) * _cell
	_cursor.size = Vector2(_cell, _cell)
	_cursor.color = Color(0.45, 0.9, 0.35, 0.4) if _aim_allowed else Color(0.9, 0.28, 0.22, 0.42)


func _is_path(column: int, row: int) -> bool:
	return Vector2i(column, row) in PATH_CELLS
