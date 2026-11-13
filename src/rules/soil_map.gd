## The ground under the lawn. Every row uses the same pattern, so each lane is fair.
class_name SoilMap
extends RefCounted

enum Kind { REGULAR, STONY, SANDY }


## Stone is the center column. Sand sits three columns to either side. The rest is regular soil.
static func kind_at(column: int, _row: int, columns: int = 12) -> int:
	if column < 0 or column >= columns:
		return Kind.REGULAR
	var center := int(columns / 2)
	if column == center:
		return Kind.STONY
	if absi(column - center) == 3:
		return Kind.SANDY
	return Kind.REGULAR


## Multiplier on vermin movement while they stand on this soil. 1 is normal.
static func vermin_scale(kind: int) -> float:
	match kind:
		Kind.STONY:
			return 0.5
		Kind.SANDY:
			return 1.5
		_:
			return 1.0


## Multiplier on how fast a shooter or dew plant acts. Walls do not use it. 1 is normal.
static func warden_rate(kind: int) -> float:
	match kind:
		Kind.STONY:
			return 0.65
		Kind.SANDY:
			return 0.8
		_:
			return 1.0


static func blurb(kind: int) -> String:
	match kind:
		Kind.STONY:
			return "Stony soil. Vermin take twice as long to cross it. Shooters and dew plants act more slowly. Walls still only block."
		Kind.SANDY:
			return "Sandy soil. Vermin cross it half again as fast. Shooters and dew plants act a little more slowly. Walls still only block."
		_:
			return "Regular soil. Plants work at their normal pace. Vermin cross it at their normal speed."
