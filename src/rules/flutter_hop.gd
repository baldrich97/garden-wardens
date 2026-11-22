## The Ladybug's flutter hop over a Stubborn Cone. The timings and the arc
## come from the authored hop_over notes in the Ladybug's frames.json:
## flutter_takeoff 0.8 s, flutter_air looped 1.2 s, flutter_land 0.8 s; the
## game slides the sprite 2 cells in the 2.0 s window that opens on takeoff
## frame 4 and closes on landing frame 5 (1 tile per second).
class_name FlutterHop
extends RefCounted

## Full length of takeoff + air + land, in seconds.
const TOTAL_SECONDS := 2.8
## Cells of forward travel across the blocker's tile.
const TRAVEL_TILES := 2.0
## Peak of the arc above the lane floor, in tiles: clears the 1-tile cone
## with a quarter-tile margin.
const PEAK_LIFT_TILES := 1.25
## The 10 fps clip boundaries: the takeoff clip, the air loop, and the window
## in which the sprite travels (takeoff frame 4 through landing frame 5).
const TAKEOFF_SECONDS := 0.8
const AIR_SECONDS := 1.2
const TRAVEL_START := 0.4
const TRAVEL_END := 2.4
## Clip bases the board hands the actor for each phase of the hop.
const PHASE_TAKEOFF := "flutter_takeoff"
const PHASE_AIR := "flutter_air"
const PHASE_LAND := "flutter_land"


## True when this Vermin hops over this Warden instead of chewing it. Only
## Ladybugs hop, and only the Stubborn Cone is hopped; every other pairing
## stops and chews exactly as before. A hopped cone never gets chewed, so it
## never loses HP to the hop itself.
static func can_hop(vermin_kind: int, warden_kind: int) -> bool:
	return vermin_kind == UnitCatalog.Vermin.LADYBUG \
			and warden_kind == UnitCatalog.Warden.BARK


## Travel progress 0..1 [param t] seconds into the hop. The bug holds still
## through the first three takeoff frames, then tracks the arc to the end of
## the window and stays put while the landing clip settles.
static func travel(elapsed: float) -> float:
	return clampf((elapsed - TRAVEL_START) / (TRAVEL_END - TRAVEL_START), 0.0, 1.0)


## Height above the lane floor in tiles at travel progress [param t].
## Parabolic: 0 at both ends, [const PEAK_LIFT_TILES] at t = 0.5.
static func lift_tiles(t: float) -> float:
	return 4.0 * PEAK_LIFT_TILES * t * (1.0 - t)


## Which flutter clip owns [param elapsed] seconds into the hop.
static func phase(elapsed: float) -> String:
	if elapsed < TAKEOFF_SECONDS:
		return PHASE_TAKEOFF
	if elapsed < TAKEOFF_SECONDS + AIR_SECONDS:
		return PHASE_AIR
	return PHASE_LAND
