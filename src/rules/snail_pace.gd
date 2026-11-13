## The speed bonus a snail gives to ground vermin that are still behind it.
class_name SnailPace
extends RefCounted

## Behind means farther from the house, so a greater column than the snail.
const BOOST := 1.85


## 1 when this vermin is not hurried. Snails do not stack.
static func scale(column_pos: float, row: int, ground: bool, snails: Array[Vector2]) -> float:
	if not ground:
		return 1.0
	for snail in snails:
		if int(snail.y) != row:
			continue
		if snail.x < column_pos - 0.05:
			return BOOST
	return 1.0
