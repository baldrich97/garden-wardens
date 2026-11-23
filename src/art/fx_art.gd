## The locked papercraft effect art (Round 3 "Projectiles & Effects" and the
## origami water set) plus the per-unit fx frame sequences that ship inside the
## animation folders. One place to swap a mapping if Brandon re-picks an asset.
class_name FxArt
extends RefCounted

## Origami water set (locked Round 3): parachute = a sky drop still falling,
## medium = a drop sitting on the lawn (Dew Dropper output, landed sky drops),
## small = the top-bar water counter icon.
const WATER_PARACHUTE: Texture2D = preload("res://assets/art/fx/water/water_parachute_drop.png")
const WATER_DROP_MEDIUM: Texture2D = preload("res://assets/art/fx/water/water_drop_medium.png")
const WATER_DROP_SMALL: Texture2D = preload("res://assets/art/fx/water/water_drop_small.png")
## A4 small burst: a Needle Spitter spine landing on a vermin.
const SMALL_BURST: Texture2D = preload("res://assets/art/fx/A4.png")
## A3 impact burst: a Seed Lobber seed striking a vermin.
const IMPACT_BURST: Texture2D = preload("res://assets/art/fx/A3.png")
## B3 collect flecks: a water drop scooped up (hover, tap, or Rain Catcher).
const COLLECT_FLECKS: Texture2D = preload("res://assets/art/fx/B3.png")
## The slowly rotating leaf ring under the placement ghost (B4/B5 + D6 combo).
const LEAF_RING: Texture2D = preload("res://assets/art/fx/leaf_ring_rotating.png")

const NEEDLE_SMOKE_DIR := "/fx/smoke/smoke_%02d.png"
const LOBBER_SPIN_DIR := "/fx/projectile/spin/fluff_ball_%02d.png"
const LOBBER_BURST_DIR := "/fx/projectile/burst/seed_burst_%02d.png"
const LOBBER_SPIN_COUNT := 8
const LOBBER_BURST_COUNT := 20

static var _cache: Dictionary = {}


## Needle Spitter smoke overlays, one per action frame (same canvas, aligned);
## most are empty, frames 12-14 carry the puff. Empty when the art is missing.
static func needle_smoke() -> Array[Texture2D]:
	var folder := AnimLibrary.warden_folder(UnitCatalog.Warden.NEEDLE)
	return _sequence(folder + NEEDLE_SMOKE_DIR, _action_frame_count(folder, 16))


## The Seed Lobber fluff ball spinning in flight (8 frames, 104 px).
static func lobber_spin() -> Array[Texture2D]:
	var folder := AnimLibrary.warden_folder(UnitCatalog.Warden.SEED)
	return _sequence(folder + LOBBER_SPIN_DIR, LOBBER_SPIN_COUNT)


## The Seed Lobber landing burst: the ball bursts into drifting seed fluff
## (20 frames, 480 px canvas centred on the landing point).
static func lobber_burst() -> Array[Texture2D]:
	var folder := AnimLibrary.warden_folder(UnitCatalog.Warden.SEED)
	return _sequence(folder + LOBBER_BURST_DIR, LOBBER_BURST_COUNT)


static func _action_frame_count(folder: String, fallback: int) -> int:
	var animations: Variant = AnimLibrary.manifest_for_folder(folder).get("animations")
	if animations is Dictionary and animations.get("action") is Dictionary:
		var count: Variant = animations["action"].get("frame_count")
		if count is int or count is float:
			return int(count)
	return fallback


## Loads `pattern % 1..count` once and caches it. All-or-nothing: a gap returns
## an empty array so callers fall back to their still art.
static func _sequence(pattern: String, count: int) -> Array[Texture2D]:
	if _cache.has(pattern):
		return _cache[pattern]
	var frames: Array[Texture2D] = []
	for index in count:
		var path := pattern % (index + 1)
		if not ResourceLoader.exists(path):
			frames.clear()
			break
		var texture := load(path) as Texture2D
		if texture == null:
			frames.clear()
			break
		frames.append(texture)
	_cache[pattern] = frames
	return frames
