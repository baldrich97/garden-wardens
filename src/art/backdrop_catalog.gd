## The backdrop the match starts on. The main scene plus its mood variants;
## a match picks one from its visual seed, and the button still cycles them.
class_name BackdropCatalog
extends RefCounted

const NAMES: Array[String] = [
	"Main",
	"Sunny",
	"Overcast",
	"Dusk",
]

## Main uses the sun-free copy Asset Gen made for the per-match random suns
## (SkyLayer paints the sun); the moods keep their own painted sun or moon.
const PATHS: Array[String] = [
	"res://assets/art/environment/backdrops/main_noclouds_nosun.png",
	"res://assets/art/environment/backdrops/mood_1_sunny_noclouds.png",
	"res://assets/art/environment/backdrops/mood_3_overcast_noclouds.png",
	"res://assets/art/environment/backdrops/mood_4_dusk_noclouds.png",
]


static func count() -> int:
	return NAMES.size()


static func texture_at(index: int) -> Texture2D:
	return load(PATHS[posmod(index, PATHS.size())]) as Texture2D


## The look this match opens with. Same seed, same look, always.
static func pick_index(seed_value: int) -> int:
	var rng := MatchSeed.with_value(seed_value).rng("backdrop")
	return rng.randi_range(0, NAMES.size() - 1)
