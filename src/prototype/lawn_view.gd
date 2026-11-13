## The lawn. Five lanes and twelve columns. Tiles stay square.
class_name LawnView
extends Control

const COLUMNS := 12
const ROWS := 5

## Empty space kept above the tiles so a sky droplet is visible before it lands.
const SKY_ROWS := 0.85

signal cell_pressed(cell: Vector2i)
signal cell_hovered(cell: Vector2i)

@export var grass_texture: Texture2D
@export var stone_texture: Texture2D
@export var sand_texture: Texture2D

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


func column_count() -> int:
	return COLUMNS


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
	if grass_texture == null or stone_texture == null or sand_texture == null:
		push_error("LawnView is missing a soil texture.")
		return
	for row in ROWS:
		for column in COLUMNS:
			var tile := TextureRect.new()
			tile.texture = _texture_for(column, row)
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
	var rows_with_sky := float(ROWS) + SKY_ROWS
	_cell = minf(size.x / float(COLUMNS), size.y / rows_with_sky)
	var board_size := Vector2(_cell * COLUMNS, _cell * float(ROWS))
	var sky := _cell * SKY_ROWS
	var spare_y := size.y - sky - board_size.y
	_origin = Vector2((size.x - board_size.x) * 0.5, sky + maxf(0.0, spare_y) * 0.5)
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


func _texture_for(column: int, row: int) -> Texture2D:
	match SoilMap.kind_at(column, row, COLUMNS):
		SoilMap.Kind.STONY:
			return stone_texture
		SoilMap.Kind.SANDY:
			return sand_texture
		_:
			return grass_texture
