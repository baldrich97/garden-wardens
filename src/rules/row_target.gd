## Row queries shared by shooting and chewing. Positions are in cell units, not pixels.
class_name RowTarget
extends RefCounted


## Index of the closest spot at or to the right of [param origin] in [param row]. Spots are (column_pos, row).
static func first_ahead(row: int, origin: float, spots: Array[Vector2]) -> int:
	var best := -1
	var best_x := 0.0
	for index in spots.size():
		var spot := spots[index]
		if int(spot.y) != row or spot.x + 0.001 < origin:
			continue
		if best == -1 or spot.x < best_x:
			best = index
			best_x = spot.x
	return best


## The rightmost Warden column a Vermin at [param column_pos] has reached, or -1.
static func reached_column(column_pos: float, columns: Array[int]) -> int:
	var best := -1
	for column in columns:
		var left := float(column)
		var right := left + 1.0
		if column_pos <= right + 0.05 and column_pos > left - 0.001 and column > best:
			best = column
	return best


## True when a shot traveling from [param previous_pos] to [param current_pos] meets [param target_pos].
static func shot_reaches(previous_pos: float, current_pos: float, target_pos: float) -> bool:
	return target_pos >= previous_pos - 0.05 and target_pos <= current_pos + 0.2
