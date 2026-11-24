## Paper-craft entrance beats (GW-AA pass 4, reworked in pass 5), pure
## functions of elapsed time:
##
## Vermin entrance: the cut-out slides in lying flat from the right (a card
## pushed slowly along the stage floor, leaning back, its shadow stretched),
## then flips up on its feet as if a stagehand tugged a back tab: flat -> a
## touch too tall -> a small settle wobble -> standing. No stick, no string:
## the entrance shows the idle frame, never the authored spawn clip.
##
## Warden placement (a sticker being placed, ~1.5 s):
##   DESCEND  the sticker comes down full size, a flat 2D paper decal facing
##            the camera, until its bottom edge touches the tile
##   CURL     an invisible hand presses it on from the bottom up: the pressed
##            part lies flat on the felt (foreshortened), the rest bends over
##            a paper roll and still stands, until it is flat on the tile
##   FLAT     a beat lying flat
##   SINK     the flat sticker shrinks and sinks into the tile
##   POP      the live Warden pops up from the tile (squash, overshoot,
##            settle) with a confetti burst
##
## Presentation only: actors read these each frame; no match timer or rule
## ever waits on them, so seeded matches (combat_probe) stay identical. A
## hand cursor can ride [method placement]'s "press" (0..1, how much of the
## sticker is pressed flat) and "lift" (descent height share).
class_name PaperPop
extends RefCounted

enum Phase { SLIDE, FLIP, PRESS, POP, DONE, DESCEND, CURL, FLAT, SINK, SETTLE }

## Vermin: slide time, flip time, settle wobble time, how far right it
## starts (rail cells), how flat it lies (scale.y), the flip's overshoot, the
## settle's dip, and the lean (skew, radians). GW-AA pass 5: much slower.
const SLIDE_TIME := 1.6
const FLIP_TIME := 0.9
const SETTLE_TIME := 0.3
const SLIDE_CELLS := 1.3
const FLAT_SCALE := 0.15
const FLIP_OVERSHOOT := 1.08
const SETTLE_DIP := 0.97
const LEAN := 0.32
## Warden sticker: phase times (seconds).
const DESCEND_TIME := 0.3
const CURL_TIME := 0.6
const FLAT_TIME := 0.12
const SINK_TIME := 0.22
const POP_TIME := 0.3
## How high the sticker starts its descent (share of its own height).
const DESCEND_LIFT := 0.55
## How foreshortened the sticker looks lying flat on the felt (screen height
## per unit of sticker length).
const FLAT_K := 0.2
## The paper roll's radius as a share of the sticker's height.
const CURL_RADIUS := 0.16
## How small the flat sticker gets as it sinks into the tile.
const SINK_SCALE := 0.3
## The live Warden's pop: from this flat scale.y up past 1 to the overshoot.
const POP_FROM := 0.12
const POP_OVERSHOOT := 1.12
## Share of the flip / pop spent rising to the overshoot (the rest settles).
const RISE_SHARE := 0.68
## Older name kept for callers that only need "how flat the pop starts".
const PRESS_SCALE := POP_FROM


## The vermin entrance at [param t] seconds after spawning:
## {phase, scale: Vector2, offset_cells: float, skew: float}.
static func entrance(t: float) -> Dictionary:
	if t < SLIDE_TIME:
		var k := clampf(t / SLIDE_TIME, 0.0, 1.0)
		# Ease in-out: a slow push that glides to a stop.
		var eased := k * k * (3.0 - 2.0 * k)
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
	var t3 := t2 - FLIP_TIME
	if t3 < SETTLE_TIME:
		var k := clampf(t3 / SETTLE_TIME, 0.0, 1.0)
		# One small dip and back: the cut-out finds its footing.
		var sy := 1.0 - (1.0 - SETTLE_DIP) * sin(PI * k)
		return {
			"phase": Phase.SETTLE,
			"scale": Vector2(1.0 + (1.0 - sy) * 0.5, sy),
			"offset_cells": 0.0,
			"skew": 0.02 * sin(TAU * k),
		}
	return {"phase": Phase.DONE, "scale": Vector2.ONE, "offset_cells": 0.0, "skew": 0.0}


## Total vermin entrance length.
static func entrance_time() -> float:
	return SLIDE_TIME + FLIP_TIME + SETTLE_TIME


## The warden placement at [param t] seconds after planting:
## {phase, scale: Vector2 (the live clip's, once it pops), decal: bool (the
## flat sticker shows instead of the clip), lift (0..1 share of the sticker
## height still above the tile), press (0..1 share pressed flat), sink (1 at
## full size .. SINK_SCALE), shade (0..1 how far the sink has darkened it)}.
static func placement(t: float) -> Dictionary:
	var out := {
		"phase": Phase.DONE, "scale": Vector2.ONE, "decal": false,
		"lift": 0.0, "press": 1.0, "sink": 1.0, "shade": 0.0,
	}
	if t < DESCEND_TIME:
		var k := clampf(t / DESCEND_TIME, 0.0, 1.0)
		out["phase"] = Phase.DESCEND
		out["decal"] = true
		out["lift"] = DESCEND_LIFT * pow(1.0 - k, 2.0)
		out["press"] = 0.0
		out["scale"] = Vector2(1.0, POP_FROM)
		return out
	var t2 := t - DESCEND_TIME
	if t2 < CURL_TIME:
		var k := clampf(t2 / CURL_TIME, 0.0, 1.0)
		out["phase"] = Phase.CURL
		out["decal"] = true
		# The hand rolls it on: quick at first, then smoothing the top down.
		out["press"] = 1.0 - pow(1.0 - k, 1.6)
		out["scale"] = Vector2(1.0, POP_FROM)
		return out
	var t3 := t2 - CURL_TIME
	if t3 < FLAT_TIME:
		out["phase"] = Phase.FLAT
		out["decal"] = true
		out["scale"] = Vector2(1.0, POP_FROM)
		return out
	var t4 := t3 - FLAT_TIME
	if t4 < SINK_TIME:
		var k := clampf(t4 / SINK_TIME, 0.0, 1.0)
		var eased := k * k
		out["phase"] = Phase.SINK
		out["decal"] = true
		out["sink"] = lerpf(1.0, SINK_SCALE, eased)
		out["shade"] = eased
		out["scale"] = Vector2(1.0, POP_FROM)
		return out
	var t5 := t4 - SINK_TIME
	if t5 < POP_TIME:
		var k := clampf(t5 / POP_TIME, 0.0, 1.0)
		var sy := _rise(k, POP_FROM, POP_OVERSHOOT)
		# Paper keeps its area roughly: a tall moment is a touch narrower.
		var sx := lerpf(1.08, 1.0, k) / sqrt(maxf(sy, 0.5))
		out["phase"] = Phase.POP
		out["scale"] = Vector2(clampf(sx, 0.9, 1.25), sy)
		return out
	return out


## When the live Warden pops up (the confetti cue), seconds after planting.
static func pop_start() -> float:
	return DESCEND_TIME + CURL_TIME + FLAT_TIME + SINK_TIME


## Total warden placement length.
static func placement_time() -> float:
	return pop_start() + POP_TIME


## The sticker's shape mid-curl: where a point [param s] along the sticker
## (0 at its bottom edge, [param height] at its top, in px) sits, as
## {depth, up, angle}. [param pressed] px are already flat on the felt; the
## next stretch wraps a roll of radius [param radius]; the rest stands up.
## depth runs back into the tile (foreshortened by FLAT_K on screen), up is
## straight up the screen, angle 0 = lying flat, PI/2 = standing.
static func curl_point(s: float, pressed: float, radius: float) -> Dictionary:
	if s <= pressed:
		return {"depth": s, "up": 0.0, "angle": 0.0}
	var arc := PI * 0.5 * radius
	var into := s - pressed
	if into <= arc and radius > 0.0:
		var a := into / radius
		return {"depth": pressed + radius * sin(a), "up": radius * (1.0 - cos(a)), "angle": a}
	return {"depth": pressed + radius, "up": radius + (into - arc), "angle": PI * 0.5}


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
