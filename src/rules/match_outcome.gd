## Win when the wave is gone. Lose when a Vermin crosses the left edge.
class_name MatchOutcome
extends RefCounted

enum Result { ONGOING, WON, LOST }


static func evaluate(breached: bool, living: int, pending_spawns: int) -> Result:
	if breached:
		return Result.LOST
	if living <= 0 and pending_spawns <= 0:
		return Result.WON
	return Result.ONGOING
