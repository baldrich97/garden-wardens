## Occupancy for the lawn. A cell is empty or holds one id. Ids start at 1.
class_name LawnGrid
extends RefCounted

var _columns: int
var _rows: int
var _cells: Array[int] = []


func _init(columns: int = 9, rows: int = 5) -> void:
	_columns = columns
	_rows = rows
	for _i in columns * rows:
		_cells.append(0)


func is_inside(column: int, row: int) -> bool:
	return column >= 0 and row >= 0 and column < _columns and row < _rows


func occupant(column: int, row: int) -> int:
	if not is_inside(column, row):
		return 0
	return _cells[_index(column, row)]


## Places [param id] when the cell is empty and inside the grid. Id 0 is rejected.
func try_place(column: int, row: int, id: int) -> bool:
	if id == 0 or not is_inside(column, row):
		return false
	var index := _index(column, row)
	if _cells[index] != 0:
		return false
	_cells[index] = id
	return true


func remove(column: int, row: int) -> void:
	if is_inside(column, row):
		_cells[_index(column, row)] = 0


## Returns the cell under a lawn-local point, or (-1, -1) when the point misses the grid.
static func cell_at(local_position: Vector2, origin: Vector2, cell_size: float, columns: int, rows: int) -> Vector2i:
	if cell_size <= 0.0:
		return Vector2i(-1, -1)
	var column := int(floor((local_position.x - origin.x) / cell_size))
	var row := int(floor((local_position.y - origin.y) / cell_size))
	if column < 0 or row < 0 or column >= columns or row >= rows:
		return Vector2i(-1, -1)
	return Vector2i(column, row)


func _index(column: int, row: int) -> int:
	return row * _columns + column
