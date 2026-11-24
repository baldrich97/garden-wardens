## The lawn: five lanes and twelve columns of felt, drawn in perspective
## (GW-AA pass 3, Option B). The lawn node covers the whole 1280x720 stage
## (the backdrop's own pixel frame); the felt board is warped onto a trapezoid
## that recedes toward the painted horizon, between the painted porch (left)
## and the painted compost heap (right). LawnGeometry holds the homography;
## everything that sits on the lawn asks it for rail points, scales, and cells.
class_name LawnView
extends Control

const COLUMNS := 12
const ROWS := 5

## The locked felt board (Round 3b "Board v1") only ships baked into the
## 1280x720 composite board_v1_compost_eyes.png, so the lawn samples straight
## from that file instead of a cropped copy (the art stays untouched).
## Source-pixel rects measured from the PNG: the outer dark-green frame, and
## the 12x5 felt grid inside it (79 x 69.6 px cells). The frame ends at
## x 1103 / y 687: one pixel more pulls in the compost heap's brown edge (the
## old 962 x 363 rect showed it as a dark sliver at the top-right corner) and
## a band of plain lawn under the bottom edge (GW-AA pass 2).
const BOARD_FRAME_SRC := Rect2(149.0, 334.0, 955.0, 354.0)
const BOARD_GRID_SRC := Rect2(153.0, 337.0, 948.0, 348.0)
## Soil kinds have no felt art of their own yet; a translucent wash over the
## felt keeps sand and stone readable without mixing in the old tile style.
const SAND_WASH := Color(0.93, 0.80, 0.52, 0.55)
const STONE_WASH := Color(0.58, 0.58, 0.62, 0.6)
## Board edge: the felt's front lip and the soft shadow it casts on the grass.
const LIP_PX := 7.0
const LIP_COLOR := Color8(58, 92, 32)
const LIP_HIGHLIGHT := Color8(95, 135, 55)
const SHADOW_COLOR := Color(0.1, 0.18, 0.04, 0.09)
## Draw order inside the lawn (units use LawnGeometry.z_for_row, 10 and up).
const Z_FELT := 0
const Z_WASH := 0
const Z_CURSOR := 1
const FELT_SHADER := preload("res://src/prototype/felt_perspective.gdshader")

signal cell_pressed(cell: Vector2i)
signal cell_hovered(cell: Vector2i)

## Kept for the scene file; the perspective lawn draws the felt board only.
@export var grass_texture: Texture2D
@export var stone_texture: Texture2D
@export var sand_texture: Texture2D
## The board composite. The felt board is required for the perspective lawn.
@export var board_texture: Texture2D

var geometry := LawnGeometry.new(BOARD_FRAME_SRC, BOARD_GRID_SRC, COLUMNS, ROWS)
var _cells: Array[PackedVector2Array] = []
var _washes: Array[Polygon2D] = []
var _board_frame: TextureRect
var _cursor: Polygon2D
var _aim := Vector2i(-1, -1)
var _aim_allowed := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = false
	_build_board()
	_cursor = Polygon2D.new()
	_cursor.name = "AimCursor"
	_cursor.z_index = Z_CURSOR
	_cursor.visible = false
	add_child(_cursor)
	queue_redraw()


func tile_count() -> int:
	return _cells.size()


func column_count() -> int:
	return COLUMNS


## The front rail's cell width: the reference size for anything that is not
## placed per rail (tooltips, fallbacks). Per-row sizes come from geometry.
func cell_size_px() -> float:
	return geometry.rail_cell_width(float(ROWS - 1))


func cell_at(local_position: Vector2) -> Vector2i:
	return geometry.cell_at(local_position)


## Cell center in lawn (stage) pixels.
func cell_center(cell: Vector2i) -> Vector2:
	return geometry.cell_to_screen(cell)


## Only the board takes the pointer, so the sky and the painted ends stay
## click-through (and mouse_entered/exited mean "over the board").
func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, geometry.frame_quad())


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


## Whether the lawn draws the felt board art.
func uses_board_art() -> bool:
	return board_texture != null and _board_frame != null


## The felt shader's inputs, for tests (stage->source basis and frame rect).
func felt_material() -> ShaderMaterial:
	return _board_frame.material as ShaderMaterial if _board_frame != null else null


## Builds the felt: one TextureRect over the whole stage whose shader samples
## the composite through the inverse homography, then a perspective-quad wash
## per sand or stone cell.
func _build_board() -> void:
	for row in ROWS:
		for column in COLUMNS:
			_cells.append(geometry.cell_corners(column, row))
	if board_texture != null:
		_board_frame = TextureRect.new()
		_board_frame.name = "BoardFrame"
		_board_frame.texture = board_texture
		_board_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_board_frame.stretch_mode = TextureRect.STRETCH_SCALE
		_board_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_board_frame.position = Vector2.ZERO
		_board_frame.size = LawnGeometry.REF_SIZE
		_board_frame.z_index = Z_FELT
		var felt_mat := ShaderMaterial.new()
		felt_mat.shader = FELT_SHADER
		felt_mat.set_shader_parameter("stage_to_source", geometry.stage_to_source_basis())
		felt_mat.set_shader_parameter("stage_size", LawnGeometry.REF_SIZE)
		felt_mat.set_shader_parameter("frame_src", Vector4(
			BOARD_FRAME_SRC.position.x, BOARD_FRAME_SRC.position.y,
			BOARD_FRAME_SRC.end.x, BOARD_FRAME_SRC.end.y))
		felt_mat.set_shader_parameter("texture_px", board_texture.get_size())
		felt_mat.set_shader_parameter("felt", board_texture)
		_board_frame.material = felt_mat
		add_child(_board_frame)
	for row in ROWS:
		for column in COLUMNS:
			var wash_color := _wash_for(column, row)
			if board_texture == null:
				# No felt art: plain checker quads so the lawn still reads.
				wash_color = Color(0.36, 0.62, 0.22) if (row + column) % 2 == 0 else Color(0.3, 0.54, 0.18)
				var base := _wash_for(column, row)
				if base.a > 0.0:
					wash_color = wash_color.lerp(Color(base, 1.0), base.a)
			if wash_color.a <= 0.0:
				continue
			var wash := Polygon2D.new()
			wash.polygon = geometry.cell_corners(column, row)
			wash.color = wash_color
			wash.z_index = Z_WASH
			wash.set_meta("column", column)
			wash.set_meta("row", row)
			add_child(wash)
			_washes.append(wash)


func _wash_for(column: int, row: int) -> Color:
	match SoilMap.kind_at(column, row, COLUMNS):
		SoilMap.Kind.STONY:
			return STONE_WASH
		SoilMap.Kind.SANDY:
			return SAND_WASH
		_:
			return Color(0, 0, 0, 0)


## Shadow on the grass and the felt's front lip, under the felt itself.
func _draw() -> void:
	var quad := geometry.frame_quad()
	var far_l := quad[0]
	var far_r := quad[1]
	var near_r := quad[2]
	var near_l := quad[3]
	for step in 6:
		var grow := 3.0 + float(step) * 3.0
		draw_colored_polygon(PackedVector2Array([
			far_l + Vector2(-grow * 0.4, 4.0),
			far_r + Vector2(grow * 0.4, 4.0),
			near_r + Vector2(grow, LIP_PX + grow),
			near_l + Vector2(-grow, LIP_PX + grow),
		]), SHADOW_COLOR)
	draw_colored_polygon(PackedVector2Array([
		near_l, near_r, near_r + Vector2(-1.0, LIP_PX), near_l + Vector2(1.0, LIP_PX),
	]), LIP_COLOR)
	draw_line(near_l + Vector2(0, 1), near_r + Vector2(0, 1), LIP_HIGHLIGHT, 1.0, true)


func _place_cursor() -> void:
	if _cursor == null:
		return
	if _aim.x < 0:
		_cursor.visible = false
		return
	_cursor.visible = true
	_cursor.polygon = geometry.cell_corners(_aim.x, _aim.y)
	# On the green felt a green wash disappears, so "allowed" is a pale cream
	# lift; "refused" stays red.
	_cursor.color = Color(1.0, 0.97, 0.78, 0.42) if _aim_allowed else Color(0.9, 0.28, 0.22, 0.42)
