## The dice cup for one match. A match rolls a seed once at start and every
## derived choice (looks, moods) replays from that value. Never wall-clock.
class_name MatchSeed
extends RefCounted

## The rolled value. Shown on the debug label so a look is reproducible.
var value := 0


## Rolls a fresh value for a new match: mixed once here, never inside a
## look choice. Same value, same look; --seed N replays any roll.
static func rolled() -> MatchSeed:
	var bytes := Crypto.new().generate_random_bytes(8)
	if bytes.size() == 8:
		var value := 0
		for byte in bytes:
			value = (value << 8) | int(byte)
		return with_value(value)
	return with_value(hash("%s|%d" % [Time.get_datetime_string_from_system(true, true), Time.get_ticks_msec()]))


## Replays the match's dice cup from a recorded value.
static func with_value(seed_value: int) -> MatchSeed:
	var cup := MatchSeed.new()
	cup.value = seed_value
	return cup


## A generator for one named channel. The same value and channel always
## produce the same sequence, independent of other channels.
func rng(channel: String) -> RandomNumberGenerator:
	var generator := RandomNumberGenerator.new()
	generator.seed = hash("gw-match-%d-%s" % [value, channel])
	return generator
