## The Option B perspective lawn (GW-AA pass 3): a true projective mapping from
## the 12x5 felt grid onto a trapezoid that recedes toward the painted horizon.
## All coordinates are "stage" pixels: the 1280x720 reference frame the
## backdrop is painted in. The board frame of board_v1_compost_eyes.png maps
## onto the trapezoid below; the felt grid inside it follows through the same
## homography, so every cell is an exact perspective quad.
##
## Units stand on "rails": one per row, RAIL_DEPTH into the row, with a scale
## taken from the cell width on that rail, and draw order rising toward the
## viewer (z_for_row), so a front unit's top covers the base of the one behind.
class_name LawnGeometry
extends RefCounted

## Stage size the trapezoid and the backdrop are authored in.
const REF_SIZE := Vector2(1280.0, 720.0)
## Option B board frame corners in stage pixels: far edge (horizon side) and
## near edge (viewer side). Matches mockup_b_painted_ends.png.
const FAR_LEFT := Vector2(168.0, 334.0)
const FAR_RIGHT := Vector2(1104.0, 334.0)
const NEAR_RIGHT := Vector2(1240.0, 584.0)
const NEAR_LEFT := Vector2(40.0, 584.0)
## Where a unit's feet stand inside its row (0 = far line, 1 = near line).
const RAIL_DEPTH := 0.72
## Draw order: z of rail 0, plus Z_PER_ROW per rail toward the viewer.
const Z_RAIL_BASE := 10
const Z_PER_ROW := 4

var columns: int
var rows: int
var frame_src: Rect2
var grid_src: Rect2
## Source (board PNG) pixels -> stage pixels, row-major 3x3.
var _h: PackedFloat64Array
## Stage pixels -> source pixels.
var _inv: PackedFloat64Array
var _cell_src := Vector2.ONE


func _init(p_frame_src: Rect2, p_grid_src: Rect2, p_columns: int, p_rows: int, quad: PackedVector2Array = PackedVector2Array()) -> void:
	columns = p_columns
	rows = p_rows
	frame_src = p_frame_src
	grid_src = p_grid_src
	_cell_src = Vector2(grid_src.size.x / float(columns), grid_src.size.y / float(rows))
	var dst := quad if quad.size() == 4 else PackedVector2Array([FAR_LEFT, FAR_RIGHT, NEAR_RIGHT, NEAR_LEFT])
	var src := PackedVector2Array([
		frame_src.position,
		Vector2(frame_src.end.x, frame_src.position.y),
		frame_src.end,
		Vector2(frame_src.position.x, frame_src.end.y),
	])
	_h = solve(src, dst)
	_inv = invert(_h)


## The 3x3 homography (row-major) taking the four [param src] points onto the
## four [param dst] points. Gaussian elimination with partial pivoting on the
## standard 8x8 system (h22 fixed at 1).
static func solve(src: PackedVector2Array, dst: PackedVector2Array) -> PackedFloat64Array:
	var a: Array = []
	for i in 4:
		var x := src[i].x
		var y := src[i].y
		var u := dst[i].x
		var v := dst[i].y
		a.append([x, y, 1.0, 0.0, 0.0, 0.0, -u * x, -u * y, u])
		a.append([0.0, 0.0, 0.0, x, y, 1.0, -v * x, -v * y, v])
	for col in 8:
		var pivot := col
		for r in range(col + 1, 8):
			if absf(a[r][col]) > absf(a[pivot][col]):
				pivot = r
		var tmp: Array = a[col]
		a[col] = a[pivot]
		a[pivot] = tmp
		var p: float = a[col][col]
		if absf(p) < 1e-12:
			return PackedFloat64Array([1, 0, 0, 0, 1, 0, 0, 0, 1])
		for k in range(col, 9):
			a[col][k] /= p
		for r in 8:
			if r == col:
				continue
			var f: float = a[r][col]
			if f == 0.0:
				continue
			for k in range(col, 9):
				a[r][k] -= f * a[col][k]
	var h := PackedFloat64Array()
	for i in 8:
		h.append(a[i][8])
	h.append(1.0)
	return h


static func apply(h: PackedFloat64Array, p: Vector2) -> Vector2:
	var w := h[6] * p.x + h[7] * p.y + h[8]
	return Vector2((h[0] * p.x + h[1] * p.y + h[2]) / w, (h[3] * p.x + h[4] * p.y + h[5]) / w)


static func invert(h: PackedFloat64Array) -> PackedFloat64Array:
	var a := h[0]; var b := h[1]; var c := h[2]
	var d := h[3]; var e := h[4]; var f := h[5]
	var g := h[6]; var i := h[7]; var j := h[8]
	var det := a * (e * j - f * i) - b * (d * j - f * g) + c * (d * i - e * g)
	if absf(det) < 1e-12:
		return PackedFloat64Array([1, 0, 0, 0, 1, 0, 0, 0, 1])
	var inv := PackedFloat64Array([
		(e * j - f * i), -(b * j - c * i), (b * f - c * e),
		-(d * j - f * g), (a * j - c * g), -(a * f - c * d),
		(d * i - e * g), -(a * i - b * g), (a * e - b * d),
	])
	for k in 9:
		inv[k] /= det
	return inv


## Stage -> source pixels as a shader mat3 (Basis columns = matrix columns).
func stage_to_source_basis() -> Basis:
	return Basis(
		Vector3(_inv[0], _inv[3], _inv[6]),
		Vector3(_inv[1], _inv[4], _inv[7]),
		Vector3(_inv[2], _inv[5], _inv[8]),
	)


func source_to_stage(p: Vector2) -> Vector2:
	return apply(_h, p)


func stage_to_source(p: Vector2) -> Vector2:
	return apply(_inv, p)


## Grid coordinates (column_pos, row_pos; 0..columns, 0..rows, fractional) -> stage pixels.
func point(column_pos: float, row_pos: float) -> Vector2:
	return source_to_stage(grid_src.position + _cell_src * Vector2(column_pos, row_pos))


## Stage pixels -> fractional grid coordinates (exact inverse of [method point]).
func grid_coords(stage_point: Vector2) -> Vector2:
	return (stage_to_source(stage_point) - grid_src.position) / _cell_src


## The cell under [param stage_point], or (-1, -1) off the felt grid.
func cell_at(stage_point: Vector2) -> Vector2i:
	var g := grid_coords(stage_point)
	var column := int(floor(g.x))
	var row := int(floor(g.y))
	if column < 0 or row < 0 or column >= columns or row >= rows:
		return Vector2i(-1, -1)
	return Vector2i(column, row)


## Center of a cell in stage pixels (the perspective center, not the quad mean).
func cell_to_screen(cell: Vector2i) -> Vector2:
	return point(float(cell.x) + 0.5, float(cell.y) + 0.5)


## The cell's four corners, clockwise from far-left.
func cell_corners(column: int, row: int) -> PackedVector2Array:
	return PackedVector2Array([
		point(column, row), point(column + 1, row),
		point(column + 1, row + 1), point(column, row + 1),
	])


## The board frame's four stage corners (far-left, far-right, near-right, near-left).
func frame_quad() -> PackedVector2Array:
	return PackedVector2Array([
		source_to_stage(frame_src.position),
		source_to_stage(Vector2(frame_src.end.x, frame_src.position.y)),
		source_to_stage(frame_src.end),
		source_to_stage(Vector2(frame_src.position.x, frame_src.end.y)),
	])


## Width of one column at fractional depth [param row_pos]. Rows stay
## horizontal under this mapping, so the width is the same across a row.
func cell_width(row_pos: float) -> float:
	return (point(float(columns), row_pos).x - point(0.0, row_pos).x) / float(columns)


## Height of one row (far line to near line) at row [param row].
func row_height(row: int) -> float:
	return point(0.0, float(row) + 1.0).y - point(0.0, float(row)).y


## Stage y of a row's rail.
func rail_y(row: float) -> float:
	return point(0.0, row + RAIL_DEPTH).y


## Where a unit at [param column_pos] stands on [param row]'s rail.
func rail_point(column_pos: float, row: float) -> Vector2:
	return point(column_pos, row + RAIL_DEPTH)


## Unit scale on a rail relative to the front rail (1.0 at the last row).
func rail_scale(row: float) -> float:
	return cell_width(row + RAIL_DEPTH) / cell_width(float(rows - 1) + RAIL_DEPTH)


## Cell width on a rail (the unit sizing reference).
func rail_cell_width(row: float) -> float:
	return cell_width(row + RAIL_DEPTH)


## Draw order of a rail: back rows first, so front units overlap them.
static func z_for_row(row: int) -> int:
	return Z_RAIL_BASE + row * Z_PER_ROW
