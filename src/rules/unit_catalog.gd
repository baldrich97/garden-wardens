## Demo numbers for the roster. Art can change without editing these.
class_name UnitCatalog
extends RefCounted

enum Warden { DEW, NEEDLE, BARK, RAIN, SEED }
enum Vermin { FLY, BEE, LADYBUG, SNAIL, GRUB }

const WARDEN_NAMES: Array[String] = ["Dew Dropper", "Needle Spitter", "Bark Block", "Rain Barrel", "Seed Lobber"]
const WARDEN_SHORT: Array[String] = ["Dew", "Needle", "Bark", "Rain", "Seeds"]
const WARDEN_COST: Array[int] = [50, 100, 50, 50, 150]
const WARDEN_COOLDOWN: Array[float] = [4.0, 1.5, 3.0, 6.0, 2.4]
const WARDEN_HP: Array[int] = [80, 120, 360, 140, 110]
const NEEDLE_DAMAGE := 34
const NEEDLE_INTERVAL := 1.15
const NEEDLE_SHOT_SPEED := 3.2
const DEW_INTERVAL := 5.0
const DEW_AMOUNT := 25
const LOB_INTERVAL := 2.4
const LOB_RANGE := 8.0
const LOB_EXTRA := 3
const SEED_DAMAGE := 28
const VERMIN_NAMES: Array[String] = ["Fly", "Bee", "Ladybug", "Snail", "Grub"]
const VERMIN_HP: Array[int] = [45, 100, 240, 260, 30]
## Cells per second. Bees step by BEE_STEP instead of sliding.
const VERMIN_SPEED: Array[float] = [0.42, 0.24, 0.15, 0.17, 0.22]
const VERMIN_CHEW: Array[float] = [30.0, 28.0, 22.0, 16.0, 14.0]
## Seconds a bee waits between tile steps on regular soil.
const BEE_STEP := 1.6
const SKY_INTERVAL := 10.0
const SKY_JITTER := 2.0
const DROP_LIFE := 12.0
## Rows per second for a droplet that falls from the sky.
const SKY_FALL_SPEED := 0.45
## Row where a sky droplet appears. Negative is above the top row of tiles.
const SKY_SPAWN_ROW := -0.9
## A dead vermin leaves a grub when a random roll is below this. Grubs do not.
const GRUB_CHANCE := 0.35


static func warden_blurb(kind: int) -> String:
	match kind:
		Warden.NEEDLE:
			return "Needle Spitter. Costs 100 water. Shoots vermin in its row."
		Warden.BARK:
			return "Bark Block. Costs 50 water. A tough wall that does not attack."
		Warden.RAIN:
			return "Rain Barrel. Costs 50 water. Collects droplets on the eight tiles around it. It does not make water, and it leaves a drop on its own tile."
		Warden.SEED:
			return "Seed Lobber. Costs 150 water. Lobs a bundle that bursts into seeds. The landing tile is always hit, and three more tiles in that 3 by 3 are random. Each seed hits one vermin."
		_:
			return "Dew Dropper. Costs 50 water. Leaves a droplet on its tile. Hover or tap the droplet to collect it."


static func vermin_blurb(kind: int) -> String:
	match kind:
		Vermin.FLY:
			return "Fly. Fast and fragile. It walks straight toward the house. A snail does not speed it up."
		Vermin.LADYBUG:
			return "Ladybug. Slow and tough. It takes many hits to stop."
		Vermin.SNAIL:
			return "Snail. Tough and slow. Ground vermin behind it, farther from the house, move faster. Flies are left alone."
		Vermin.GRUB:
			return "Grub. Small and weak. One sometimes crawls out of a dead vermin. A grub does not leave another grub."
		_:
			return "Bee. It wanders up, down, and sometimes back, but it still has to come forward."


static func is_ground(kind: int) -> bool:
	return kind != Vermin.FLY


## [param roll] is 0 to 1. Grubs never leave a grub.
static func leaves_grub(kind: int, roll: float) -> bool:
	if kind == Vermin.GRUB:
		return false
	return roll < GRUB_CHANCE
