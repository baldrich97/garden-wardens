## Paper-craft entrance beats (GW-AA pass 4), pure functions of elapsed time:
##
## Vermin entrance: the cut-out slides in lying flat from the right (a card
## pushed along the stage floor, leaning back, its shadow stretched), then
## flips up on its feet as if a stagehand tugged a back tab: flat -> a touch
## too tall -> settled.
##
## Warden placement: the sticker presses flat onto the tile, then pops up
## from its bottom edge (squash, overshoot, settle) with a puff at the base.
##
## Presentation only: actors read these each frame to set their clip's
## transform; no match timer or rule ever waits on them, so seeded matches
## (combat_probe) stay identical. The pointer stays the regular cursor; a
## small hand can later ride [method placement] (see AGENT_HANDOFF).
class_name PaperPop
extends RefCounted

enum Phase { SLIDE, FLIP, PRESS, POP, DONE }

## Vermin: slide time, flip time, how far right it starts (rail cells), how
## flat it lies (scale.y), the flip's overshoot, and the lean (skew, radians).
const SLIDE_TIME := 0.46
const FLIP_TIME := 0.33
const SLIDE_CELLS := 1.3
const FLAT_SCALE := 0.15
const FLIP_OVERSHOOT := 1.08
const LEAN := 0.32
## Warden: press time, pop time, how flat the pressed sticker is, how wide it
## starts before the press settles it, and the pop's overshoot.
const PRESS_TIME := 0.21
const POP_TIME := 0.25
const PRESS_SCALE := 0.12
const PRESS_WIDE := 1.22
const POP_OVERSHOOT := 1.12
## Share of the flip / pop spent rising to the overshoot (the rest settles).
const RISE_SHARE := 0.68


## The vermin entrance at [param t] seconds after spawning:
## {phase, scale: Vector2, offset_cells: float, skew: float}.
static func entrance(t: float) -> Dictionary:
	if t < SLIDE_TIME:
		var k := clampf(t / SLIDE_TIME, 0.0, 1.0)
		var eased := 1.0 - pow(1.0 - k, 3.0)
		return {
			"phase": Phase.SLIDE,
			"scale": Vector2(1.0, FLAT_SCALE),
			"offset_cells": SLIDE_CELLS * (1.0 - eased),
			"skew": -LEAN,
		}
	var t2 := t - SLIDE_TIME
	if t2 < FLIP_TIME:
		var k := clampf(t2 / FLIP_TIME, 0.0, 1.0)
		return {
			"phase": Phase.FLIP,
			"scale": Vector2(1.0, _rise(k, FLAT_SCALE, FLIP_OVERSHOOT)),
			"offset_cells": 0.0,
			"skew": lerpf(-LEAN, 0.0, minf(k / RISE_SHARE, 1.0)),
		}
	return {"phase": Phase.DONE, "scale": Vector2.ONE, "offset_cells": 0.0, "skew": 0.0}


## Total vermin entrance length.
static func entrance_time() -> float:
	return SLIDE_TIME + FLIP_TIME


## The warden placement at [param t] seconds after planting:
## {phase, scale: Vector2}.
static func placement(t: float) -> Dictionary:
	if t < PRESS_TIME:
		var k := clampf(t / PRESS_TIME, 0.0, 1.0)
		var eased := 1.0 - pow(1.0 - k, 2.0)
		return {"phase": Phase.PRESS, "scale": Vector2(lerpf(PRESS_WIDE, 1.08, eased), PRESS_SCALE)}
	var t2 := t - PRESS_TIME
	if t2 < POP_TIME:
		var k := clampf(t2 / POP_TIME, 0.0, 1.0)
		var sy := _rise(k, PRESS_SCALE, POP_OVERSHOOT)
		# Paper keeps its area roughly: a tall moment is a touch narrower.
		var sx := lerpf(1.08, 1.0, k) / sqrt(maxf(sy, 0.5))
		return {"phase": Phase.POP, "scale": Vector2(clampf(sx, 0.9, 1.25), sy)}
	return {"phase": Phase.DONE, "scale": Vector2.ONE}


## Total warden placement length.
static func placement_time() -> float:
	return PRESS_TIME + POP_TIME


## The transform for a clip scaled/skewed about [param pivot] (actor-local),
## then shifted by [param offset].
static func pivot_transform(scale: Vector2, skew: float, pivot: Vector2, offset: Vector2) -> Transform2D:
	var xf := Transform2D(0.0, scale, skew, Vector2.ZERO)
	xf.origin = pivot + offset - xf.basis_xform(pivot)
	return xf


## flat -> overshoot (ease out) -> 1.0 (ease in-out).
static func _rise(k: float, low: float, peak: float) -> float:
	if k < RISE_SHARE:
		var a := k / RISE_SHARE
		return lerpf(low, peak, 1.0 - pow(1.0 - a, 3.0))
	var b := (k - RISE_SHARE) / (1.0 - RISE_SHARE)
	return lerpf(peak, 1.0, b * b * (3.0 - 2.0 * b))
