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
	"Dusk Twilight",
	"Dusk Moonlit",
]
## Folder key per look under stage/ and stage/<key>/ (GW-AA pass 5), index
## aligned with NAMES; Golden Hour's is GOLDEN_HOUR_KEY.
const MOOD_KEYS: Array[String] = ["main", "sunny", "overcast", "dusk_twilight", "dusk_moonlit"]
const GOLDEN_HOUR_KEY := "golden_hour"
## Extra folders a look also reads plates from, after its own: both Dusks
## share the plates cut from the Dusk art (stage/dusk/).
const MOOD_FALLBACK_DIRS := {"dusk_twilight": ["dusk"], "dusk_moonlit": ["dusk"]}
## How many looks the match seed picks from. The seeded pick stays on the
## first four (Main, Sunny, Overcast, Dusk Twilight) so a seed opens on the
## same look as before pass 5 (and Overcast's rain, and so the water drops
## and the combat hash, never change); Dusk Moonlit is a cycle stop.
const SEEDED_LOOKS := 4

## The sky_backdrop slot per look. Main uses the sun-free copy Asset Gen made
## for the per-match sun (SkyLayer paints the sun); Sunny keeps its painted
## sun. Sunny's and Overcast's own fence and porch sit lower in their frame
## and end up hidden behind the shared set plates. Both Dusks use the Dusk
## art lifted so its string-light fence stands on the fence line, with the
## moon cut out into a sky prop (tools/art/cut_dusk_stage.py).
const PATHS: Array[String] = [
	"res://assets/art/environment/backdrops/main_noclouds_nosun.png",
	"res://assets/art/environment/backdrops/mood_1_sunny_noclouds.png",
	"res://assets/art/environment/backdrops/mood_3_overcast_noclouds.png",
	"res://assets/art/environment/backdrops/mood_4_dusk_stage.png",
	"res://assets/art/environment/backdrops/mood_4_dusk_stage.png",
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

## Per-mood set plates (GW-AA pass 5): stage/<mood key>/stage_<slot>.png,
## then each MOOD_FALLBACK_DIRS folder, then the shared stage/stage_<slot>.png.
## A per-mood plate is either the shared plate's size (drawn at the shared
## offset) or a full 1280x720 stage canvas (drawn at 0,0).
const PLATE_SLOTS: Array[String] = ["fence", "shack", "compost", "lawn_ground"]
## Wide-screen side extensions per look: stage/<mood key>/side_left.png and
## side_right.png, drawn outside the stage's left/right edges at the stage's
## scale (any width; the height should be 720). Missing = the clean matte.
const SIDE_NAMES: Array[String] = ["side_left", "side_right"]
const SIDE_FRONT_SUFFIX := "_front"
## Optional per-look sky backdrop (batch2): stage/<mood key>/sky_backdrop.png.
const SKY_BACKDROP_NAME := "sky_backdrop.png"

## Per-look light on the shared set (fence, porch, heap, lawn ground). Index
## aligned with NAMES; Golden Hour has its own below. A look's own plates
## (painted for that look) take BACKDROP_TINTS instead, like its sky.
const SET_TINTS: Array[Color] = [
	Color(1.0, 1.0, 1.0),
	Color(1.0, 1.0, 1.0),
	Color(0.84, 0.87, 0.92),
	Color(0.7, 0.66, 0.84),
	Color(0.5, 0.54, 0.78),
]
## Light on the look's own art (sky backdrop and its own plates). Moonlit is
## the Dusk art in night light.
const BACKDROP_TINTS: Array[Color] = [
	Color(1.0, 1.0, 1.0),
	Color(1.0, 1.0, 1.0),
	Color(1.0, 1.0, 1.0),
	Color(1.0, 1.0, 1.0),
	Color(0.5, 0.56, 0.86),
]
const GOLDEN_HOUR_SET_TINT := Color(1.0, 0.86, 0.7)
## The felt takes half the set tint, so the play surface stays readable.
const FELT_TINT_SHARE := 0.5
## Per-look override (GW-AA pass 6): the painted Moonlit set is a deep night,
## so the felt takes more of the night light to sit in it (still readable).
const FELT_TINT_SHARES := {"dusk_moonlit": 0.72}
## Whether the compost eyes glow on each look (index aligned with NAMES).
## The heap is shared, so its eyes show on every look by default.
const EYES_ON: Array[bool] = [true, true, true, true, true]
const GOLDEN_HOUR_EYES_ON := true

static var _textures: Dictionary = {}
## Optional slot files (per-mood plates, side plates, tiles): looked up once.
static var _optional: Dictionary = {}


static func count() -> int:
	return NAMES.size()


## A look's sky backdrop: its own stage/<mood key>/sky_backdrop.png (full
## 1280x720, the batch2 slot) if one is installed, else PATHS.
static func texture_at(index: int) -> Texture2D:
	var own := own_sky(index)
	if own != null:
		return own
	return cached(PATHS[posmod(index, PATHS.size())])


## Loads once and keeps a strong reference, so a look switch never reloads
## (or re-uploads) an image the startup preload already brought in.
static func cached(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D
	return _textures[path]


## An optional slot file: the texture if it exists, else null, without an
## error for the missing file. Looked up once per path.
static func optional(path: String) -> Texture2D:
	if _textures.has(path):
		return _textures[path]
	if not _optional.has(path):
		_optional[path] = ResourceLoader.exists(path)
	if not bool(_optional[path]):
		return null
	return cached(path)


## Test hook: forget what optional() learned (a test drops in a slot file).
static func forget_optional() -> void:
	_optional.clear()


## Test hook: hand a slot path a texture as if the file existed.
static func inject(path: String, texture: Texture2D) -> void:
	_textures[path] = texture
	_optional[path] = texture != null
	if texture == null:
		_textures.erase(path)


## The folder key for a look ([param index] < 0 is Golden Hour).
static func mood_key(index: int) -> String:
	if index < 0:
		return GOLDEN_HOUR_KEY
	return MOOD_KEYS[posmod(index, MOOD_KEYS.size())]


## Folders a look reads its own plates from, most specific first.
static func mood_dirs(index: int) -> Array[String]:
	var key := mood_key(index)
	var dirs: Array[String] = [STAGE_DIR + key + "/"]
	for extra in MOOD_FALLBACK_DIRS.get(key, []):
		dirs.append(STAGE_DIR + String(extra) + "/")
	return dirs


## The plate a look shows in one slot ("fence", "shack", "compost",
## "lawn_ground"): {texture, offset, own}. own is true when the look has its
## own art for the slot; otherwise it is the shared plate.
static func plate_for(index: int, slot: String) -> Dictionary:
	var shared := _shared_plate(slot)
	for dir in mood_dirs(index):
		var texture := optional(dir + "stage_%s.png" % slot)
		if texture != null:
			var offset: Vector2 = shared["offset"]
			if texture.get_size() == Vector2(1280.0, 720.0):
				offset = Vector2.ZERO
			return {"texture": texture, "offset": offset, "own": true, "path": dir + "stage_%s.png" % slot}
	return {"texture": cached(String(shared["path"])), "offset": shared["offset"], "own": false, "path": shared["path"]}


static func _shared_plate(slot: String) -> Dictionary:
	match slot:
		"fence":
			return FENCE_PLATE
		"shack":
			return SHACK_PLATE
		"compost":
			return COMPOST_PLATE
		_:
			return LAWN_GROUND_PLATE


## A look's string lights over its own fence plate, or null.
static func fence_lights(index: int) -> Texture2D:
	var fence := plate_for(index, "fence")
	if not bool(fence["own"]):
		return null
	return optional(String(fence["path"]).get_base_dir() + "/stage_fence_lights.png")


## A look's side-panel front layer ("side_left" / "side_right"): the panel's
## own pixels where it is ground, lawn, tufts or the shack / compost
## continuation, clear in the open sky (built from Asset Gen's `_ground`
## splits plus the shack silhouette by tools/art/make_side_fronts.py). Drawn
## over the sky props so clouds pass behind the side shack the way they pass
## behind the stage's shack. Null when not shipped.
static func side_front(index: int, side: String) -> Texture2D:
	for dir in mood_dirs(index):
		if optional(dir + side + ".png") != null:
			return optional(dir + side + SIDE_FRONT_SUFFIX + ".png")
	return null


## A look's wide-screen side plate ("side_left" / "side_right"), or null.
static func side_plate(index: int, side: String) -> Texture2D:
	for dir in mood_dirs(index):
		var texture := optional(dir + side + ".png")
		if texture != null:
			return texture
	return null


## The light on a look's own art (sky backdrop, own plates). A look with its
## own painted sky (batch2) is already graded, so it takes no tint.
static func backdrop_tint(index: int) -> Color:
	if index < 0 or own_sky(index) != null:
		return Color.WHITE
	return BACKDROP_TINTS[posmod(index, BACKDROP_TINTS.size())]


## A look's own sky_backdrop.png ([param index] < 0 is Golden Hour), or null.
static func own_sky(index: int) -> Texture2D:
	for dir in mood_dirs(index):
		var own := optional(dir + SKY_BACKDROP_NAME)
		if own != null:
			return own
	return null


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
	var share := FELT_TINT_SHARE
	if index >= 0:
		share = float(FELT_TINT_SHARES.get(MOOD_KEYS[posmod(index, MOOD_KEYS.size())], FELT_TINT_SHARE))
	return Color.WHITE.lerp(set_tint(index), share)


static func eyes_on(index: int) -> bool:
	if index < 0:
		return GOLDEN_HOUR_EYES_ON
	return EYES_ON[posmod(index, EYES_ON.size())]


## Every texture a look can show, for the startup preload.
static func all_paths() -> Array[String]:
	var out: Array[String] = []
	for path in PATHS:
		if not out.has(path):
			out.append(path)
	for plate in [FENCE_PLATE, SHACK_PLATE, COMPOST_PLATE, LAWN_GROUND_PLATE, COMPOST_EYES]:
		out.append(String(plate["path"]))
	# The Dusk plates cut from the Dusk art (always shipped).
	for slot in ["fence", "fence_lights", "shack"]:
		out.append(STAGE_DIR + "dusk/stage_%s.png" % slot)
	# Each look's own set and sky (Asset Gen batch2), where installed.
	var keys: Array[String] = MOOD_KEYS.duplicate()
	keys.append(GOLDEN_HOUR_KEY)
	for key in keys:
		var names: Array[String] = [SKY_BACKDROP_NAME, "stage_fence_lights.png"]
		for side in SIDE_NAMES:
			names.append(side + ".png")
			names.append(side + SIDE_FRONT_SUFFIX + ".png")
		for slot in PLATE_SLOTS:
			names.append("stage_%s.png" % slot)
		for file in names:
			var path := STAGE_DIR + key + "/" + file
			if ResourceLoader.exists(path):
				out.append(path)
	return out


## The look this match opens with. Same seed, same look, always.
static func pick_index(seed_value: int) -> int:
	var rng := MatchSeed.with_value(seed_value).rng("backdrop")
	return rng.randi_range(0, SEEDED_LOOKS - 1)
