## Seeded sky choices for one match (GW-AW-6b).
##
## Everything the sky shows is a pure function of the match seed and the
## current mood index: which sun, where it sits, whether it rains, which
## rain cloud, and the cloud drift spec. Art mapping and motion live in
## SkyLayer; this file only decides.
class_name SkyLook
extends RefCounted

## Index of the "Overcast" look in BackdropCatalog.NAMES: the only mood
## that hides the sun, and the one where rain is likely.
const MOOD_OVERCAST := 2

## Clouds per match, and their size classes (0 small, 1 medium, 2 large).
const CLOUD_MIN := 3
const CLOUD_MAX := 6
const CLOUD_SIZE_CLASSES := 3

## Drift speed per cloud, in pixels per second.
const CLOUD_SPEED_MIN := 10.0
const CLOUD_SPEED_MAX := 34.0

## Share of clouds that use a stick variant (the craft-prop look).
const CLOUD_STICK_SHARE := 0.7

## Rain chances: likely on overcast, occasional elsewhere.
const RAIN_CHANCE_OVERCAST := 0.8
const RAIN_CHANCE_NORMAL := 0.3


## Picks the match's sun variant once, from the seed.
static func sun_index(seed_value: int, sun_count: int) -> int:
	if sun_count <= 0:
		return 0
	return MatchSeed.with_value(seed_value).rng("sky_sun").randi_range(0, sun_count - 1)


## Where the sun sits across the band, 0..1.
static func sun_x_frac(seed_value: int) -> float:
	return MatchSeed.with_value(seed_value).rng("sky_sun_pos").randf_range(0.15, 0.85)


## Whether this mood rains, from the seed. Each mood rolls on its own
## channel, so cycling looks does not reshuffle the other moods.
static func rain_active(seed_value: int, mood_index: int) -> bool:
	var chance := RAIN_CHANCE_OVERCAST if mood_index == MOOD_OVERCAST else RAIN_CHANCE_NORMAL
	return MatchSeed.with_value(seed_value).rng("sky_rain_%d" % mood_index).randf() < chance


## Which rain-cloud variant this match uses, from the seed.
static func rain_cloud_index(seed_value: int, cloud_count: int) -> int:
	if cloud_count <= 0:
		return 0
	return MatchSeed.with_value(seed_value).rng("sky_rain_cloud").randi_range(0, cloud_count - 1)


## Where the rain cloud sits across the band, 0..1.
static func rain_cloud_x_frac(seed_value: int) -> float:
	return MatchSeed.with_value(seed_value).rng("sky_rain_pos").randf_range(0.1, 0.9)


## How many clouds drift this match, from the seed.
static func cloud_count(seed_value: int) -> int:
	return MatchSeed.with_value(seed_value).rng("sky_clouds").randi_range(CLOUD_MIN, CLOUD_MAX)


## The full cloud spec, from the seed. Each entry carries
## {size, stick, variant, height, speed, phase}: the size class, whether the
## stick variant is used, the texture index within that class, the 0..1
## height in the band, the drift speed in px/s, and the 0..1 start position.
static func cloud_specs(seed_value: int, class_counts: Array[int]) -> Array[Dictionary]:
	var rng := MatchSeed.with_value(seed_value).rng("sky_clouds")
	var count := rng.randi_range(CLOUD_MIN, CLOUD_MAX)
	var specs: Array[Dictionary] = []
	for _i in count:
		var size := rng.randi_range(0, CLOUD_SIZE_CLASSES - 1)
		var class_count := class_counts[size] if size < class_counts.size() else 1
		specs.append({
			"size": size,
			"stick": rng.randf() < CLOUD_STICK_SHARE,
			"variant": rng.randi_range(0, maxi(class_count, 1) - 1),
			"height": rng.randf(),
			"speed": rng.randf_range(CLOUD_SPEED_MIN, CLOUD_SPEED_MAX),
			"phase": rng.randf(),
		})
	return specs
