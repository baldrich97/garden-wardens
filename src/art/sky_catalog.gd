## The pre-made sky art (GW-AW-6b): five suns, stick and plain clouds in
## three size classes, and the rain set. The art is locked; this file only
## points at it.
class_name SkyCatalog
extends RefCounted

const SUNS: Array[String] = [
	"res://assets/art/sky/suns/sun_01_pointed_layers.png",
	"res://assets/art/sky/suns/sun_02_layered_flame_paper.png",
	"res://assets/art/sky/suns/sun_05_cardstock_petal.png",
	"res://assets/art/sky/suns/sun_06_origami_star.png",
	"res://assets/art/sky/suns/sun_08_folded_ray_taped.png",
]

## Cloud entries are {path, body_h}: the image, and the cloud body's height
## in source pixels. The stick composites are far taller than their body
## (the stick rises out of the cloud), so the body height drives scaling.
## Size classes: 0 small, 1 medium, 2 large.
const CLOUD_SMALL_STICKS: Array[Dictionary] = [
	{"path": "res://assets/art/sky/clouds/small/cotton_s1_stick.png", "body_h": 165},
	{"path": "res://assets/art/sky/clouds/small/cotton_s2_stick.png", "body_h": 135},
	{"path": "res://assets/art/sky/clouds/small/cotton_s3_stick.png", "body_h": 138},
	{"path": "res://assets/art/sky/clouds/small/cotton_s4_stick.png", "body_h": 135},
	{"path": "res://assets/art/sky/clouds/small/felt_s1_stick.png", "body_h": 141},
	{"path": "res://assets/art/sky/clouds/small/felt_s2_stick.png", "body_h": 165},
	{"path": "res://assets/art/sky/clouds/small/felt_s3_stick.png", "body_h": 154},
	{"path": "res://assets/art/sky/clouds/small/felt_s4_stick.png", "body_h": 123},
	{"path": "res://assets/art/sky/clouds/small/felt_s5_stick.png", "body_h": 113},
	{"path": "res://assets/art/sky/clouds/small/felt_s6_stick.png", "body_h": 105},
	{"path": "res://assets/art/sky/clouds/small/torn_s1_stick.png", "body_h": 139},
	{"path": "res://assets/art/sky/clouds/small/torn_s2_stick.png", "body_h": 128},
	{"path": "res://assets/art/sky/clouds/small/torn_s3_stick.png", "body_h": 76},
	{"path": "res://assets/art/sky/clouds/small/torn_s4_stick.png", "body_h": 116},
	{"path": "res://assets/art/sky/clouds/small/torn_s5_stick.png", "body_h": 124},
	{"path": "res://assets/art/sky/clouds/small/torn_s6_stick.png", "body_h": 119},
	{"path": "res://assets/art/sky/clouds/small/torn_s7_stick.png", "body_h": 117},
]
const CLOUD_MEDIUM_STICKS: Array[Dictionary] = [
	{"path": "res://assets/art/sky/clouds/medium/cotton_m1_stick.png", "body_h": 194},
	{"path": "res://assets/art/sky/clouds/medium/cotton_m2_stick.png", "body_h": 188},
	{"path": "res://assets/art/sky/clouds/medium/cotton_m3_stick.png", "body_h": 202},
	{"path": "res://assets/art/sky/clouds/medium/cotton_m4_stick.png", "body_h": 184},
	{"path": "res://assets/art/sky/clouds/medium/felt_m1_stick.png", "body_h": 206},
	{"path": "res://assets/art/sky/clouds/medium/felt_m2_stick.png", "body_h": 193},
	{"path": "res://assets/art/sky/clouds/medium/felt_m3_stick.png", "body_h": 209},
	{"path": "res://assets/art/sky/clouds/medium/felt_m4_stick.png", "body_h": 215},
	{"path": "res://assets/art/sky/clouds/medium/torn_m1_stick.png", "body_h": 149},
	{"path": "res://assets/art/sky/clouds/medium/torn_m2_stick.png", "body_h": 139},
	{"path": "res://assets/art/sky/clouds/medium/torn_m3_stick.png", "body_h": 125},
	{"path": "res://assets/art/sky/clouds/medium/torn_m4_stick.png", "body_h": 118},
]
const CLOUD_LARGE_STICKS: Array[Dictionary] = [
	{"path": "res://assets/art/sky/clouds/large/cotton_L1_stick.png", "body_h": 201},
	{"path": "res://assets/art/sky/clouds/large/cotton_L2_stick.png", "body_h": 214},
	{"path": "res://assets/art/sky/clouds/large/cotton_L3_stick.png", "body_h": 213},
	{"path": "res://assets/art/sky/clouds/large/cotton_L4_stick.png", "body_h": 253},
	{"path": "res://assets/art/sky/clouds/large/cotton_L5_stick.png", "body_h": 265},
	{"path": "res://assets/art/sky/clouds/large/cotton_L6_stick.png", "body_h": 257},
	{"path": "res://assets/art/sky/clouds/large/felt_L1_stick.png", "body_h": 178},
	{"path": "res://assets/art/sky/clouds/large/felt_L2_stick.png", "body_h": 178},
	{"path": "res://assets/art/sky/clouds/large/felt_L3_stick.png", "body_h": 177},
	{"path": "res://assets/art/sky/clouds/large/felt_L4_stick.png", "body_h": 288},
	{"path": "res://assets/art/sky/clouds/large/felt_L5_stick.png", "body_h": 296},
	{"path": "res://assets/art/sky/clouds/large/felt_L6_stick.png", "body_h": 273},
	{"path": "res://assets/art/sky/clouds/large/torn_L1_stick.png", "body_h": 207},
	{"path": "res://assets/art/sky/clouds/large/torn_L2_stick.png", "body_h": 199},
	{"path": "res://assets/art/sky/clouds/large/torn_L3_stick.png", "body_h": 207},
	{"path": "res://assets/art/sky/clouds/large/torn_L4_stick.png", "body_h": 186},
	{"path": "res://assets/art/sky/clouds/large/torn_L5_stick.png", "body_h": 214},
	{"path": "res://assets/art/sky/clouds/large/torn_L6_stick.png", "body_h": 195},
]
const CLOUD_SMALL_PLAIN: Array[Dictionary] = [
	{"path": "res://assets/art/sky/clouds/small/cotton_s1.png", "body_h": 165},
	{"path": "res://assets/art/sky/clouds/small/cotton_s2.png", "body_h": 135},
	{"path": "res://assets/art/sky/clouds/small/cotton_s3.png", "body_h": 138},
	{"path": "res://assets/art/sky/clouds/small/cotton_s4.png", "body_h": 135},
	{"path": "res://assets/art/sky/clouds/small/felt_s1.png", "body_h": 141},
	{"path": "res://assets/art/sky/clouds/small/felt_s2.png", "body_h": 165},
	{"path": "res://assets/art/sky/clouds/small/felt_s3.png", "body_h": 154},
	{"path": "res://assets/art/sky/clouds/small/felt_s4.png", "body_h": 123},
	{"path": "res://assets/art/sky/clouds/small/felt_s5.png", "body_h": 113},
	{"path": "res://assets/art/sky/clouds/small/felt_s6.png", "body_h": 105},
	{"path": "res://assets/art/sky/clouds/small/torn_s1.png", "body_h": 139},
	{"path": "res://assets/art/sky/clouds/small/torn_s2.png", "body_h": 128},
	{"path": "res://assets/art/sky/clouds/small/torn_s3.png", "body_h": 76},
	{"path": "res://assets/art/sky/clouds/small/torn_s4.png", "body_h": 116},
	{"path": "res://assets/art/sky/clouds/small/torn_s5.png", "body_h": 124},
	{"path": "res://assets/art/sky/clouds/small/torn_s6.png", "body_h": 119},
	{"path": "res://assets/art/sky/clouds/small/torn_s7.png", "body_h": 117},
]
const CLOUD_MEDIUM_PLAIN: Array[Dictionary] = [
	{"path": "res://assets/art/sky/clouds/medium/cotton_m1.png", "body_h": 194},
	{"path": "res://assets/art/sky/clouds/medium/cotton_m2.png", "body_h": 188},
	{"path": "res://assets/art/sky/clouds/medium/cotton_m3.png", "body_h": 202},
	{"path": "res://assets/art/sky/clouds/medium/cotton_m4.png", "body_h": 184},
	{"path": "res://assets/art/sky/clouds/medium/felt_m1.png", "body_h": 206},
	{"path": "res://assets/art/sky/clouds/medium/felt_m2.png", "body_h": 193},
	{"path": "res://assets/art/sky/clouds/medium/felt_m3.png", "body_h": 209},
	{"path": "res://assets/art/sky/clouds/medium/felt_m4.png", "body_h": 215},
	{"path": "res://assets/art/sky/clouds/medium/torn_m1.png", "body_h": 149},
	{"path": "res://assets/art/sky/clouds/medium/torn_m2.png", "body_h": 139},
	{"path": "res://assets/art/sky/clouds/medium/torn_m3.png", "body_h": 125},
	{"path": "res://assets/art/sky/clouds/medium/torn_m4.png", "body_h": 118},
]
const CLOUD_LARGE_PLAIN: Array[Dictionary] = [
	{"path": "res://assets/art/sky/clouds/large/cotton_L1.png", "body_h": 201},
	{"path": "res://assets/art/sky/clouds/large/cotton_L2.png", "body_h": 214},
	{"path": "res://assets/art/sky/clouds/large/cotton_L3.png", "body_h": 213},
	{"path": "res://assets/art/sky/clouds/large/cotton_L4.png", "body_h": 253},
	{"path": "res://assets/art/sky/clouds/large/cotton_L5.png", "body_h": 265},
	{"path": "res://assets/art/sky/clouds/large/cotton_L6.png", "body_h": 257},
	{"path": "res://assets/art/sky/clouds/large/felt_L1.png", "body_h": 178},
	{"path": "res://assets/art/sky/clouds/large/felt_L2.png", "body_h": 178},
	{"path": "res://assets/art/sky/clouds/large/felt_L3.png", "body_h": 177},
	{"path": "res://assets/art/sky/clouds/large/felt_L4.png", "body_h": 288},
	{"path": "res://assets/art/sky/clouds/large/felt_L5.png", "body_h": 296},
	{"path": "res://assets/art/sky/clouds/large/felt_L6.png", "body_h": 273},
	{"path": "res://assets/art/sky/clouds/large/torn_L1.png", "body_h": 207},
	{"path": "res://assets/art/sky/clouds/large/torn_L2.png", "body_h": 199},
	{"path": "res://assets/art/sky/clouds/large/torn_L3.png", "body_h": 207},
	{"path": "res://assets/art/sky/clouds/large/torn_L4.png", "body_h": 186},
	{"path": "res://assets/art/sky/clouds/large/torn_L5.png", "body_h": 214},
	{"path": "res://assets/art/sky/clouds/large/torn_L6.png", "body_h": 195},
]
## Rain-cloud composites (cloud with a little baked-in drizzle). Only the grey
## felt ones hang on Overcast (GW-AA pass 4: grey/rainy clouds only there);
## RAIN_CLOUD_BODY_H is each one's cloud-body height in source pixels, so the
## rain cloud scales in the same family as the drifting clouds.
const OVERCAST_RAIN_CLOUDS: Array[String] = [
	"res://assets/art/sky/rain/rain_01_felt_cloud_3_strands.png",
	"res://assets/art/sky/rain/rain_03_felt_cloud_dense.png",
]
const RAIN_CLOUD_BODY_H := {
	"res://assets/art/sky/rain/rain_01_felt_cloud_3_strands.png": 127.0,
	"res://assets/art/sky/rain/rain_03_felt_cloud_dense.png": 129.0,
}
## Main's sun (GW-AA pass 4): the layered paper sun from the Golden Hour set,
## with a soft paper drop shadow cut from the same sprite, instead of the
## small flat sticker suns.
const MAIN_SUN := "res://assets/art/environment/golden_hour/golden_hour_sun_sprite.png"
const MAIN_SUN_SHADOW := "res://assets/art/sky/suns/main_sun_shadow.png"
## The paper crescent moon cut from the Dusk art (tools/art/cut_dusk_stage.py),
## hung on both Dusk looks.
const MOON := "res://assets/art/sky/moon/dusk_moon.png"
## Cloud families by file-name prefix: cotton is the white puffy set, felt the
## grey set, torn the flat streaky orange set.
const FAMILY_COTTON := "cotton"
const FAMILY_FELT := "felt"
const FAMILY_TORN := "torn"
## Golden Hour's puffy peach/gold sunset clouds (Asset Gen batch 1): the
## approved cotton canvases and white sticks, regraded. body_h is measured
## the cotton way (the plain cloud's height; the stick twin shares it). They
## live beside the cotton set as cotton_sunset_*; the cotton family filter
## skips them (FAMILY_SUNSET owns them). If the files go missing, Golden Hour
## falls back to the warm-tinted cotton clouds.
const FAMILY_SUNSET := "sunset"
const SUNSET_CLOUDS: Array[Dictionary] = [
	{"path": "res://assets/art/sky/clouds/small/cotton_sunset_s1_stick.png", "body_h": 165, "size": 0, "stick": true},
	{"path": "res://assets/art/sky/clouds/small/cotton_sunset_s1.png", "body_h": 165, "size": 0, "stick": false},
	{"path": "res://assets/art/sky/clouds/small/cotton_sunset_s2_stick.png", "body_h": 135, "size": 0, "stick": true},
	{"path": "res://assets/art/sky/clouds/small/cotton_sunset_s2.png", "body_h": 135, "size": 0, "stick": false},
	{"path": "res://assets/art/sky/clouds/small/cotton_sunset_s3_stick.png", "body_h": 138, "size": 0, "stick": true},
	{"path": "res://assets/art/sky/clouds/small/cotton_sunset_s3.png", "body_h": 138, "size": 0, "stick": false},
	{"path": "res://assets/art/sky/clouds/small/cotton_sunset_s4_stick.png", "body_h": 135, "size": 0, "stick": true},
	{"path": "res://assets/art/sky/clouds/small/cotton_sunset_s4.png", "body_h": 135, "size": 0, "stick": false},
	{"path": "res://assets/art/sky/clouds/medium/cotton_sunset_m1_stick.png", "body_h": 194, "size": 1, "stick": true},
	{"path": "res://assets/art/sky/clouds/medium/cotton_sunset_m1.png", "body_h": 194, "size": 1, "stick": false},
	{"path": "res://assets/art/sky/clouds/medium/cotton_sunset_m2_stick.png", "body_h": 188, "size": 1, "stick": true},
	{"path": "res://assets/art/sky/clouds/medium/cotton_sunset_m2.png", "body_h": 188, "size": 1, "stick": false},
	{"path": "res://assets/art/sky/clouds/medium/cotton_sunset_m3_stick.png", "body_h": 202, "size": 1, "stick": true},
	{"path": "res://assets/art/sky/clouds/medium/cotton_sunset_m3.png", "body_h": 202, "size": 1, "stick": false},
	{"path": "res://assets/art/sky/clouds/medium/cotton_sunset_m4_stick.png", "body_h": 184, "size": 1, "stick": true},
	{"path": "res://assets/art/sky/clouds/medium/cotton_sunset_m4.png", "body_h": 184, "size": 1, "stick": false},
	{"path": "res://assets/art/sky/clouds/large/cotton_sunset_L1_stick.png", "body_h": 201, "size": 2, "stick": true},
	{"path": "res://assets/art/sky/clouds/large/cotton_sunset_L1.png", "body_h": 201, "size": 2, "stick": false},
	{"path": "res://assets/art/sky/clouds/large/cotton_sunset_L3_stick.png", "body_h": 213, "size": 2, "stick": true},
	{"path": "res://assets/art/sky/clouds/large/cotton_sunset_L3.png", "body_h": 213, "size": 2, "stick": false},
	{"path": "res://assets/art/sky/clouds/large/cotton_sunset_L4_stick.png", "body_h": 253, "size": 2, "stick": true},
	{"path": "res://assets/art/sky/clouds/large/cotton_sunset_L4.png", "body_h": 253, "size": 2, "stick": false},
	{"path": "res://assets/art/sky/clouds/large/cotton_sunset_L5_stick.png", "body_h": 265, "size": 2, "stick": true},
	{"path": "res://assets/art/sky/clouds/large/cotton_sunset_L5.png", "body_h": 265, "size": 2, "stick": false},
]

## Dusk Twilight's lavender/slate puffy clouds (Asset Gen batch2): the cotton
## canvases regraded, so body_h is the cotton twin's. They live beside the
## cotton set as cotton_lavender_*; FAMILY_LAVENDER owns them. Missing files
## fall back to the lavender-tinted cotton.
const FAMILY_LAVENDER := "lavender"
const LAVENDER_CLOUDS: Array[Dictionary] = [
	{"path": "res://assets/art/sky/clouds/small/cotton_lavender_s1_stick.png", "body_h": 165, "size": 0, "stick": true},
	{"path": "res://assets/art/sky/clouds/small/cotton_lavender_s1.png", "body_h": 165, "size": 0, "stick": false},
	{"path": "res://assets/art/sky/clouds/small/cotton_lavender_s2_stick.png", "body_h": 135, "size": 0, "stick": true},
	{"path": "res://assets/art/sky/clouds/small/cotton_lavender_s2.png", "body_h": 135, "size": 0, "stick": false},
	{"path": "res://assets/art/sky/clouds/small/cotton_lavender_s3_stick.png", "body_h": 138, "size": 0, "stick": true},
	{"path": "res://assets/art/sky/clouds/small/cotton_lavender_s3.png", "body_h": 138, "size": 0, "stick": false},
	{"path": "res://assets/art/sky/clouds/medium/cotton_lavender_m1_stick.png", "body_h": 194, "size": 1, "stick": true},
	{"path": "res://assets/art/sky/clouds/medium/cotton_lavender_m1.png", "body_h": 194, "size": 1, "stick": false},
	{"path": "res://assets/art/sky/clouds/medium/cotton_lavender_m2_stick.png", "body_h": 188, "size": 1, "stick": true},
	{"path": "res://assets/art/sky/clouds/medium/cotton_lavender_m2.png", "body_h": 188, "size": 1, "stick": false},
	{"path": "res://assets/art/sky/clouds/medium/cotton_lavender_m3_stick.png", "body_h": 202, "size": 1, "stick": true},
	{"path": "res://assets/art/sky/clouds/medium/cotton_lavender_m3.png", "body_h": 202, "size": 1, "stick": false},
	{"path": "res://assets/art/sky/clouds/large/cotton_lavender_L1_stick.png", "body_h": 201, "size": 2, "stick": true},
	{"path": "res://assets/art/sky/clouds/large/cotton_lavender_L1.png", "body_h": 201, "size": 2, "stick": false},
	{"path": "res://assets/art/sky/clouds/large/cotton_lavender_L4_stick.png", "body_h": 253, "size": 2, "stick": true},
	{"path": "res://assets/art/sky/clouds/large/cotton_lavender_L4.png", "body_h": 253, "size": 2, "stick": false},
	{"path": "res://assets/art/sky/clouds/large/cotton_lavender_L5_stick.png", "body_h": 265, "size": 2, "stick": true},
	{"path": "res://assets/art/sky/clouds/large/cotton_lavender_L5.png", "body_h": 265, "size": 2, "stick": false},
]
## Painted families (prefix cotton_<family>_) and their explicit lists.
const PAINTED_FAMILIES := {FAMILY_SUNSET: SUNSET_CLOUDS, FAMILY_LAVENDER: LAVENDER_CLOUDS}
## Moonlit's paper stars (Asset Gen batch2).
const STARS: Array[String] = [
	"res://assets/art/sky/stars/star_4pt_cream.png",
	"res://assets/art/sky/stars/star_4pt_gold.png",
	"res://assets/art/sky/stars/star_5pt_cream.png",
	"res://assets/art/sky/stars/star_6pt_slate.png",
]

static var _painted: Dictionary = {}
const RAIN_CLOUDS: Array[String] = [
	"res://assets/art/sky/rain/rain_01_felt_cloud_3_strands.png",
	"res://assets/art/sky/rain/rain_03_felt_cloud_dense.png",
	"res://assets/art/sky/rain/rain_04_cotton_drizzle.png",
	"res://assets/art/sky/rain/rain_13_cotton_light_shower.png",
	"res://assets/art/sky/rain/rain_16_cotton_two_big_drops.png",
]
const RAIN_DROP := "res://assets/art/sky/rain/rain_08_drop_M.png"
const RAIN_SPLASH := "res://assets/art/sky/rain/rain_12_ground_splash.png"


## How many textures a size class offers (stick and plain lists match).
static func class_count(size: int) -> int:
	match size:
		0:
			return CLOUD_SMALL_STICKS.size()
		1:
			return CLOUD_MEDIUM_STICKS.size()
		2:
			return CLOUD_LARGE_STICKS.size()
		_:
			return 0


static func stick_at(size: int, index: int) -> Dictionary:
	match size:
		0:
			return CLOUD_SMALL_STICKS[index]
		1:
			return CLOUD_MEDIUM_STICKS[index]
		2:
			return CLOUD_LARGE_STICKS[index]
		_:
			return {}


static func plain_at(size: int, index: int) -> Dictionary:
	match size:
		0:
			return CLOUD_SMALL_PLAIN[index]
		1:
			return CLOUD_MEDIUM_PLAIN[index]
		2:
			return CLOUD_LARGE_PLAIN[index]
		_:
			return {}


## The entries of one size class that belong to one cloud family (cotton,
## felt, torn), stick or plain.
static func family_entries(size: int, family: String, stick: bool) -> Array[Dictionary]:
	if PAINTED_FAMILIES.has(family):
		return _painted_entries(family, size, stick)
	var out: Array[Dictionary] = []
	for index in class_count(size):
		var entry := stick_at(size, index) if stick else plain_at(size, index)
		var path: String = entry.get("path", "")
		if path.get_file().begins_with(family + "_") and not _is_painted_file(path):
			out.append(entry)
	return out


## Whether Asset Gen's sunset clouds are installed.
static func has_sunset() -> bool:
	return has_painted(FAMILY_SUNSET)


## Every sunset cloud: {path, body_h, size, stick}.
static func sunset_entries() -> Array[Dictionary]:
	return painted_entries(FAMILY_SUNSET)


## Test hook: pretend these sunset entries are on disk ([] = none); null
## rescans the folder.
static func inject_sunset(entries: Variant) -> void:
	inject_painted(FAMILY_SUNSET, entries)


## Whether a painted family's files are installed.
static func has_painted(family: String) -> bool:
	return not painted_entries(family).is_empty()


## The installed entries of a painted family: {path, body_h, size, stick}.
static func painted_entries(family: String) -> Array[Dictionary]:
	if not _painted.has(family):
		var found: Array[Dictionary] = []
		for entry in PAINTED_FAMILIES.get(family, []):
			if ResourceLoader.exists(String(entry["path"])):
				found.append(entry)
		_painted[family] = found
	return _painted[family]


## Test hook: pretend these entries of a painted family are on disk ([] =
## none); null rescans.
static func inject_painted(family: String, entries: Variant) -> void:
	if entries == null:
		_painted.erase(family)
		return
	var list: Array[Dictionary] = []
	for entry in entries:
		list.append(entry)
	_painted[family] = list


static func _is_painted_file(path: String) -> bool:
	for family in PAINTED_FAMILIES:
		if path.get_file().begins_with("cotton_%s_" % family):
			return true
	return false


## Moonlit's installed paper star textures.
static func star_paths() -> Array[String]:
	var out: Array[String] = []
	for path in STARS:
		if ResourceLoader.exists(path):
			out.append(path)
	return out


static func _painted_entries(family: String, size: int, stick: bool) -> Array[Dictionary]:
	var all := painted_entries(family)
	var out: Array[Dictionary] = []
	for want_size in [true, false]:
		for want_stick in [true, false]:
			for entry in all:
				if (not want_size or int(entry["size"]) == size) and (not want_stick or bool(entry["stick"]) == stick):
					out.append(entry)
			if not out.is_empty():
				return out
	return out


## Every texture path the sky can show, for the startup preload.
static func all_paths() -> Array[String]:
	var out: Array[String] = []
	out.append_array(SUNS)
	out.append(MAIN_SUN)
	out.append(MAIN_SUN_SHADOW)
	for size in 3:
		for index in class_count(size):
			out.append(String(stick_at(size, index)["path"]))
			out.append(String(plain_at(size, index)["path"]))
	out.append_array(RAIN_CLOUDS)
	out.append(RAIN_DROP)
	out.append(RAIN_SPLASH)
	out.append(MOON)
	for family in PAINTED_FAMILIES:
		for entry in painted_entries(family):
			out.append(String(entry["path"]))
	out.append_array(star_paths())
	return out
