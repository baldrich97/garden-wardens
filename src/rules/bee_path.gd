## Legal tile steps for a bee. Forward is toward the house, column - 1.
class_name BeePath
extends RefCounted

const FORWARD := Vector2i(-1, 0)
const BACK := Vector2i(1, 0)
const UP := Vector2i(0, -1)
const DOWN := Vector2i(0, 1)


## Steps the bee is allowed to take. Forward is always included, including off the left edge.
static func legal_steps(
	column: int,
	row: int,
	columns: int,
	rows: int,
	moves_since_forward: int,
	moves_since_backward: int,
) -> Array[Vector2i]:
	if moves_since_forward >= 2:
		return [FORWARD]
	var steps: Array[Vector2i] = [FORWARD]
	if row > 0:
		steps.append(UP)
	if row < rows - 1:
		steps.append(DOWN)
	if moves_since_backward >= 5 and column < columns - 1:
		steps.append(BACK)
	return steps


static func next_step(
	column: int,
	row: int,
	columns: int,
	rows: int,
	moves_since_forward: int,
	moves_since_backward: int,
) -> Vector2i:
	var steps := legal_steps(column, row, columns, rows, moves_since_forward, moves_since_backward)
	return steps[randi() % steps.size()]
