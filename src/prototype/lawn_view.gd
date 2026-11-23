## The lawn. Five lanes and twelve columns. Tiles stay square.
class_name LawnView
extends Control

const COLUMNS := 12
const ROWS := 5

## Empty space kept above the tiles so a sky droplet is visible before it lands.
const SKY_ROWS := 0.85

## The locked felt board (Round 3b "Board v1") only ships baked into the
## 1280x720 composite board_v1_compost_eyes.png, so the lawn draws straight
## from that file through atlas regions instead of a cropped copy (the art
## stays untouched). Source-pixel rects measured from the PNG: the outer
## dark-green frame, and the 12x5 felt grid inside it (79 x 69.6 px cells).
const BOARD_FRAME_SRC := Rect2(149.0, 334.0, 962.0, 363.0)
const BOARD_GRID_SRC := Rect2(153.0, 337.0, 948.0, 348.0)
## Soil kinds have no felt art of their own yet; a translucent wash over the
## felt keeps sand and stone readable without mixing in the old tile style.
const SAND_WASH := Color(0.93, 0.80, 0.52, 0.55)
const STONE_WASH := Color(0.58, 0.58, 0.62, 0.6)

signal cell_pressed(cell: Vector2i)
signal cell_hovered(cell: Vector2i)

@export var grass_texture: Texture2D
@export var stone_texture: Texture2D
@export var sand_texture: Texture2D
## The board composite. When set, the felt board replaces the soil tiles.
@export var board_texture: Texture2D

var _tiles: Array[TextureRect] = []
var _washes: Array[ColorRect] = []
var _board_frame: TextureRect
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


## Whether the lawn draws the felt board art (true) or the soil tiles.
func uses_board_art() -> bool:
	return board_texture != null


func _build_tiles() -> void:
	if board_texture != null:
		_build_board()
		return
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


## Builds the felt board: one frame from the composite, then one felt cell
## per tile (so tiles stay addressable), plus a wash on sand and stone.
func _build_board() -> void:
	clip_contents = false
	_board_frame = TextureRect.new()
	_board_frame.name = "BoardFrame"
	_board_frame.texture = _board_region(BOARD_FRAME_SRC)
	_board_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_board_frame.stretch_mode = TextureRect.STRETCH_SCALE
	_board_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_board_frame)
	var cell_src := Vector2(BOARD_GRID_SRC.size.x / float(COLUMNS), BOARD_GRID_SRC.size.y / float(ROWS))
	for row in ROWS:
		for column in COLUMNS:
			var tile := TextureRect.new()
			tile.texture = _board_region(Rect2(BOARD_GRID_SRC.position + cell_src * Vector2(column, row), cell_src))
			tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tile.stretch_mode = TextureRect.STRETCH_SCALE
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tile.set_meta("column", column)
			tile.set_meta("row", row)
			add_child(tile)
			_tiles.append(tile)
			var wash_color := _wash_for(column, row)
			if wash_color.a > 0.0:
				var wash := ColorRect.new()
				wash.color = wash_color
				wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
				wash.set_meta("column", column)
				wash.set_meta("row", row)
				add_child(wash)
				_washes.append(wash)


func _board_region(region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = board_texture
	atlas.region = region
	atlas.filter_clip = true
	return atlas


func _wash_for(column: int, row: int) -> Color:
	match SoilMap.kind_at(column, row, COLUMNS):
		SoilMap.Kind.STONY:
			return STONE_WASH
		SoilMap.Kind.SANDY:
			return SAND_WASH
		_:
			return Color(0, 0, 0, 0)


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
	for wash in _washes:
		wash.position = _origin + Vector2(int(wash.get_meta("column")), int(wash.get_meta("row"))) * _cell
		wash.size = Vector2(_cell, _cell)
	if _board_frame != null:
		# Map the source grid onto the square-cell grid; the frame keeps its
		# authored margin around it in the same scale.
		var fit := board_size / BOARD_GRID_SRC.size
		_board_frame.position = _origin - (BOARD_GRID_SRC.position - BOARD_FRAME_SRC.position) * fit
		_board_frame.size = BOARD_FRAME_SRC.size * fit
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
	# On the green felt board a green wash disappears, so "allowed" is a pale
	# cream lift there; the soil-tile lawn keeps its green.
	var allowed_color := Color(1.0, 0.97, 0.78, 0.42) if board_texture != null else Color(0.45, 0.9, 0.35, 0.4)
	_cursor.color = allowed_color if _aim_allowed else Color(0.9, 0.28, 0.22, 0.42)


func _texture_for(column: int, row: int) -> Texture2D:
	match SoilMap.kind_at(column, row, COLUMNS):
		SoilMap.Kind.STONY:
			return stone_texture
		SoilMap.Kind.SANDY:
			return sand_texture
		_:
			return grass_texture
