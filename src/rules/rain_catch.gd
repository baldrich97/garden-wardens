## Which landed droplets a Rain Barrel scoops up. It watches the eight tiles around it.
class_name RainCatch
extends RefCounted


## True when a droplet sitting on the lawn is on a neighbor tile. Its own tile is left alone.
static func catches(origin: Vector2i, column_pos: float, row_pos: float, falling: bool) -> bool:
	if falling or row_pos < 0.0:
		return false
	var cell := Vector2i(int(floor(column_pos)), int(floor(row_pos)))
	if cell == origin:
		return false
	return absi(cell.x - origin.x) <= 1 and absi(cell.y - origin.y) <= 1
