## A placement cooldown. It starts full and counts down to ready.
class_name Cooldown
extends RefCounted

var remaining: float = 0.0


func start(seconds: float) -> void:
	remaining = maxf(seconds, 0.0)


func tick(delta: float) -> void:
	remaining = maxf(0.0, remaining - delta)


func is_ready() -> bool:
	return remaining <= 0.0
