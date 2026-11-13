## Where a Seed Lobber bursts, and which vermin one volley can hit.
class_name SeedBurst
extends RefCounted


## Every lawn tile in the 3 by 3 around [param center], including the center.
static func area(center: Vector2i, columns: int, rows: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(-1, 2):
		for x in range(-1, 2):
			var cell := center + Vector2i(x, y)
			if cell.x < 0 or cell.y < 0 or cell.x >= columns or cell.y >= rows:
				continue
			cells.append(cell)
	return cells


## The landing tile, plus up to [param extras] random tiles from the rest of the 3 by 3.
static func pick(center: Vector2i, columns: int, rows: int, extras: int) -> Array[Vector2i]:
	var chosen: Array[Vector2i] = []
	if center.x < 0 or center.y < 0 or center.x >= columns or center.y >= rows:
		return chosen
	chosen.append(center)
	var ring := area(center, columns, rows)
	ring.erase(center)
	var left := extras
	while left > 0 and not ring.is_empty():
		var index := randi() % ring.size()
		chosen.append(ring[index])
		ring.remove_at(index)
		left -= 1
	return chosen


## The vermin a lob should burst on. (-1, -1) when nothing is in reach.
static func aim(column: int, row: int, spots: Array[Vector2], columns: int, rows: int, reach: float) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_score := 0.0
	for spot in spots:
		if spot.x < float(column) + 0.75 or spot.x > float(column) + reach:
			continue
		var cell := Vector2i(
			clampi(int(floor(spot.x)), 0, columns - 1),
			clampi(int(spot.y), 0, rows - 1),
		)
		var score := (spot.x - float(column)) + absf(float(cell.y - row)) * 0.35
		if best.x < 0 or score < best_score:
			best = cell
			best_score = score
	return best


## True when a vermin at [param column_pos] is close enough to be the one seed on [param cell].
static func covers(column_pos: float, row: int, cell: Vector2i) -> bool:
	if row != cell.y:
		return false
	return absf(column_pos - (float(cell.x) + 0.5)) <= 0.7


## One vermin index per cell, the first one standing on that cell. A vermin is hit once.
static func hit_indices(cells: Array[Vector2i], column_pos: Array[float], row: Array[int]) -> Array[int]:
	var hits: Array[int] = []
	for cell in cells:
		for index in column_pos.size():
			if hits.has(index):
				continue
			if covers(column_pos[index], row[index], cell):
				hits.append(index)
				break
	return hits
