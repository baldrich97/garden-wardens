## The looks a match can show, as layered stage slots (GW-AA pass 4).
##
## Every look is the same stage built from six slots, back to front:
##   sky_backdrop  far sky and hills (the only thing a look really swaps)
##   sky_props     clouds, rain cloud, sun or moon (SkyLayer)
##   fence_layer   the fence, sunflowers and grass strip
##   shack_layer   the porch on the left
##   compost_layer the compost heap on the right, plus its glowing eyes
##   lawn_layer    the lawn ground plate, then the perspective felt and units
## Switching looks swaps the sky backdrop (and the sky props' mood) and tints
## the shared set plates; the fence, porch, heap and lawn never move. All slot
## art is in 1280x720 stage pixels. See docs/ASSET_SOURCES.md "Stage layer
## slots" for the contract Asset Gen paints to.
class_name BackdropCatalog
extends RefCounted

const NAMES: Array[String] = [
	"Main",
	"Sunny",
	"Overcast",
	"Dusk",
]

## The sky_backdrop slot per look. Main uses the sun-free copy Asset Gen made
## for the per-match sun (SkyLayer paints the sun); the moods keep their own
## painted sun or moon. Each mood's own painted fence and porch sit lower in
## its frame and end up hidden behind the shared set plates.
const PATHS: Array[String] = [
	"res://assets/art/environment/backdrops/main_noclouds_nosun.png",
	"res://assets/art/environment/backdrops/mood_1_sunny_noclouds.png",
	"res://assets/art/environment/backdrops/mood_3_overcast_noclouds.png",
	"res://assets/art/environment/backdrops/mood_4_dusk_noclouds.png",
]

## Shared set plates: exact cut-outs of the Main backdrop (made by
## tools/art/cut_stage_plates.py) until Asset Gen paints dedicated slot art.
## Each is {path, offset}: the PNG and its top-left corner in stage pixels.
const STAGE_DIR := "res://assets/art/environment/stage/"
const FENCE_PLATE := {"path": STAGE_DIR + "stage_fence.png", "offset": Vector2(145.0, 166.0)}
const SHACK_PLATE := {"path": STAGE_DIR + "stage_shack.png", "offset": Vector2(0.0, 0.0)}
const COMPOST_PLATE := {"path": STAGE_DIR + "stage_compost.png", "offset": Vector2(1069.0, 221.0)}
const LAWN_GROUND_PLATE := {"path": STAGE_DIR + "stage_lawn_ground.png", "offset": Vector2(0.0, 297.0)}
## The glowing eyes in the heap's dark hollow, cropped from the Board v1
## composite (board_v1_compost_eyes.png) so only the hollow and the eyes
## overlay the painted heap, never a second pile.
const COMPOST_EYES := {
	"path": "res://assets/art/environment/board/compost_eyes_overlay.png",
	"offset": Vector2(1139.0, 313.0),
	## The heap hollow the eyes sit in (stage pixels).
	"hollow": Vector2(1177.0, 334.5),
}

## Per-look light on the shared set (fence, porch, heap, lawn ground). Index
## aligned with NAMES; Golden Hour has its own below.
const SET_TINTS: Array[Color] = [
	Color(1.0, 1.0, 1.0),
	Color(1.0, 1.0, 1.0),
	Color(0.84, 0.87, 0.92),
	Color(0.62, 0.59, 0.78),
]
const GOLDEN_HOUR_SET_TINT := Color(1.0, 0.86, 0.7)
## The felt takes half the set tint, so the play surface stays readable.
const FELT_TINT_SHARE := 0.5
## Whether the compost eyes glow on each look (index aligned with NAMES).
## The heap is shared, so its eyes show on every look by default.
const EYES_ON: Array[bool] = [true, true, true, true]
const GOLDEN_HOUR_EYES_ON := true

static var _textures: Dictionary = {}


static func count() -> int:
	return NAMES.size()


static func texture_at(index: int) -> Texture2D:
	return cached(PATHS[posmod(index, PATHS.size())])


## Loads once and keeps a strong reference, so a look switch never reloads
## (or re-uploads) an image the startup preload already brought in.
static func cached(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D
	return _textures[path]


## Records a texture the preload already loaded (no second load).
static func remember(path: String, texture: Texture2D) -> void:
	if texture != null and not _textures.has(path):
		_textures[path] = texture


## The set tint for a look; [param index] < 0 means Golden Hour.
static func set_tint(index: int) -> Color:
	if index < 0:
		return GOLDEN_HOUR_SET_TINT
	return SET_TINTS[posmod(index, SET_TINTS.size())]


static func felt_tint(index: int) -> Color:
	return Color.WHITE.lerp(set_tint(index), FELT_TINT_SHARE)


static func eyes_on(index: int) -> bool:
	if index < 0:
		return GOLDEN_HOUR_EYES_ON
	return EYES_ON[posmod(index, EYES_ON.size())]


## Every texture a look can show, for the startup preload.
static func all_paths() -> Array[String]:
	var out: Array[String] = []
	out.append_array(PATHS)
	for plate in [FENCE_PLATE, SHACK_PLATE, COMPOST_PLATE, LAWN_GROUND_PLATE, COMPOST_EYES]:
		out.append(String(plate["path"]))
	return out


## The look this match opens with. Same seed, same look, always.
static func pick_index(seed_value: int) -> int:
	var rng := MatchSeed.with_value(seed_value).rng("backdrop")
	return rng.randi_range(0, NAMES.size() - 1)
