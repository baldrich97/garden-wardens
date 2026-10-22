## Demo numbers for the first match. Art can change without editing these.
class_name UnitCatalog
extends RefCounted

enum Warden { DEW, NEEDLE, BARK }
enum Vermin { FLY, BEE, LADYBUG }

const STARTING_WATER := 150
const WARDEN_NAMES: Array[String] = ["Dew Dropper", "Needle Spitter", "Bark Block"]
const WARDEN_COST: Array[int] = [50, 100, 50]
const WARDEN_COOLDOWN: Array[float] = [4.0, 1.5, 3.0]
const WARDEN_HP: Array[int] = [80, 120, 360]
const NEEDLE_DAMAGE := 34
const NEEDLE_INTERVAL := 1.15
const NEEDLE_SHOT_SPEED := 6.0
const DEW_INTERVAL := 5.0
const DEW_AMOUNT := 25
const VERMIN_NAMES: Array[String] = ["Fly", "Bee", "Ladybug"]
const VERMIN_HP: Array[int] = [45, 100, 240]
const VERMIN_SPEED: Array[float] = [1.45, 0.75, 0.38]
const VERMIN_CHEW: Array[float] = [30.0, 28.0, 22.0]

## Each entry is (time in seconds, vermin kind, row).
const WAVE: Array[Vector3] = [
	Vector3(6.0, Vermin.FLY, 2),
	Vector3(9.0, Vermin.BEE, 1),
	Vector3(12.0, Vermin.FLY, 3),
	Vector3(16.0, Vermin.BEE, 2),
	Vector3(20.0, Vermin.LADYBUG, 4),
	Vector3(23.0, Vermin.BEE, 0),
]
