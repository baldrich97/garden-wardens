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
## Rain-cloud composites (cloud with a little baked-in drizzle).
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
