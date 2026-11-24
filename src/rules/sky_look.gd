## Seeded sky choices for one match (GW-AW-6b).
##
## Everything the sky shows is a pure function of the match seed and the
## current mood index: which sun, where it sits, whether it rains, which
## rain cloud, and the cloud drift spec. Art mapping and motion live in
## SkyLayer; this file only decides.
class_name SkyLook
extends RefCounted

## Index of the "Overcast" look in BackdropCatalog.NAMES: the one mood with
## no sun at all, and the one where rain is likely.
const MOOD_OVERCAST := 2
## Moods whose backdrop art already paints its own sun or moon (Sunny's sun,
## Dusk's moon). The seeded sun stays off on these so a look never shows two
## celestials. Main uses the sun-free copy of its backdrop, so it keeps the
## per-match sun.
const MOOD_MAIN := 0
const MOOD_SUNNY := 1
## Dusk Twilight (the old Dusk): soft lavender puffy clouds and the moon.
const MOOD_DUSK := 3
## Dusk Moonlit (GW-AA pass 5): a clear night sky, the moon, a few stars and
## no clouds. A cycle stop only; the seed never opens on it.
const MOOD_DUSK_MOONLIT := 4
## The composed Golden Hour look (the backdrop cycle's last stop). Not a
## BackdropCatalog index; the sky treats it as its own mood.
const MOOD_GOLDEN_HOUR := 5
const BAKED_CELESTIAL_MOODS: Array[int] = [MOOD_SUNNY, MOOD_DUSK, MOOD_DUSK_MOONLIT, MOOD_GOLDEN_HOUR]
## Moods that hang the paper moon (cut from the Dusk art) as a sky prop.
const MOON_MOODS: Array[int] = [MOOD_DUSK, MOOD_DUSK_MOONLIT]

## Mood-exclusive clouds (GW-AA pass 4). Each mood draws one cloud family:
## Main, Sunny, Dusk and Golden Hour the white puffy cotton set, Overcast the
## grey felt set. The flat streaky orange "torn" set is never used.
## Golden Hour's clouds: "tinted" (puffy, warm golden-peach) or "none".
## Flip this one constant to switch; Brandon's pick is still open.
const GOLDEN_HOUR_CLOUDS := "tinted"
const GOLDEN_HOUR_CLOUD_TINT := Color(1.0, 0.84, 0.66)
## Dusk Twilight's puffy clouds: soft lavender, never orange.
const DUSK_CLOUD_TINT := Color(0.86, 0.78, 1.0)

## Clouds per match, and their size classes (0 small, 1 medium, 2 large).
const CLOUD_MIN := 3
const CLOUD_MAX := 6
const CLOUD_SIZE_CLASSES := 3

## Drift speed per cloud, in pixels per second.
const CLOUD_SPEED_MIN := 10.0
const CLOUD_SPEED_MAX := 34.0

## Share of clouds that use a stick variant (the craft-prop look). Brandon's
## sky direction (Asset Gen Round 3/3b): every cloud hangs from a white stick
## that runs off the top of the screen, so this is all of them.
const CLOUD_STICK_SHARE := 1.0

## Stagehand bob: each stick cloud rises and dips on its own slow cycle, with
## a slight tilt around the hidden hand, as in the approved Round 3b sky
## motion preview. Amplitude is a share of the cloud body's on-screen height.
const BOB_AMP_MIN := 0.13
const BOB_AMP_MAX := 0.2
const BOB_PERIOD_MIN := 3.6
const BOB_PERIOD_MAX := 5.6
const BOB_TILT_MAX_DEG := 1.5

## Rain chances: likely on overcast and nowhere else (GW-AA pass 4: the rain
## cloud is an Overcast-only prop, never on Main).
const RAIN_CHANCE_OVERCAST := 0.8
const RAIN_CHANCE_NORMAL := 0.0


## Picks the match's sun variant once, from the seed.
static func sun_index(seed_value: int, sun_count: int) -> int:
	if sun_count <= 0:
		return 0
	return MatchSeed.with_value(seed_value).rng("sky_sun").randi_range(0, sun_count - 1)


## Where the sun sits across the band, 0..1.
static func sun_x_frac(seed_value: int) -> float:
	return MatchSeed.with_value(seed_value).rng("sky_sun_pos").randf_range(0.15, 0.85)


## Whether the seeded sun shows on this mood: never on overcast, and not on
## a mood whose backdrop already has its own sun or moon.
static func mood_shows_sun(mood_index: int) -> bool:
	return mood_index != MOOD_OVERCAST and not BAKED_CELESTIAL_MOODS.has(mood_index)


## Whether this mood rains, from the seed. Each mood rolls on its own
## channel, so cycling looks does not reshuffle the other moods.
static func rain_active(seed_value: int, mood_index: int) -> bool:
	if mood_index != MOOD_OVERCAST:
		return false
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


## Which cloud family a mood draws (SkyCatalog.FAMILY_*), or "" for none.
static func cloud_family(mood_index: int) -> String:
	if mood_index == MOOD_OVERCAST:
		return SkyCatalog.FAMILY_FELT
	if mood_index == MOOD_DUSK_MOONLIT:
		return ""
	if mood_index == MOOD_GOLDEN_HOUR:
		if GOLDEN_HOUR_CLOUDS == "none":
			return ""
		# Asset Gen's puffy sunset clouds take over as soon as they land.
		if SkyCatalog.has_sunset():
			return SkyCatalog.FAMILY_SUNSET
	return SkyCatalog.FAMILY_COTTON


## Whether a mood hangs the paper moon.
static func mood_shows_moon(mood_index: int) -> bool:
	return MOON_MOODS.has(mood_index)


## The tint a mood lays over its clouds (white = untinted).
static func cloud_tint(mood_index: int) -> Color:
	match mood_index:
		MOOD_DUSK:
			return DUSK_CLOUD_TINT
		MOOD_GOLDEN_HOUR:
			# Painted sunset clouds already carry their colour.
			return Color.WHITE if cloud_family(mood_index) == SkyCatalog.FAMILY_SUNSET else GOLDEN_HOUR_CLOUD_TINT
		_:
			return Color.WHITE


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


## The stagehand bob for each cloud, from the seed on its own channel (so the
## drift spec above is unchanged). Each entry carries {amp, period, phase,
## tilt_deg}: bob amplitude as a share of the body height, the cycle length in
## seconds, the start phase in radians, and the peak tilt in degrees.
static func cloud_bobs(seed_value: int, count: int) -> Array[Dictionary]:
	var rng := MatchSeed.with_value(seed_value).rng("sky_cloud_bob")
	var bobs: Array[Dictionary] = []
	for _i in count:
		bobs.append({
			"amp": rng.randf_range(BOB_AMP_MIN, BOB_AMP_MAX),
			"period": rng.randf_range(BOB_PERIOD_MIN, BOB_PERIOD_MAX),
			"phase": rng.randf_range(0.0, TAU),
			"tilt_deg": rng.randf_range(0.4, BOB_TILT_MAX_DEG),
		})
	return bobs
