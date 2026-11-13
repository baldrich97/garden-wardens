## The seven levels. The index stays put when the scene reloads for the next level.
class_name LevelCatalog
extends RefCounted

static var index := 0

static var _built: Array[LevelDef] = []


static func count() -> int:
	return _levels().size()


static func at(level_index: int) -> LevelDef:
	return _levels()[level_index]


static func current() -> LevelDef:
	return _levels()[clampi(index, 0, count() - 1)]


## 1-based level number for the top bar.
static func number() -> int:
	return clampi(index, 0, count() - 1) + 1


static func has_next() -> bool:
	return index + 1 < count()


static func advance() -> void:
	if has_next():
		index += 1


static func reset() -> void:
	index = 0


static func _levels() -> Array[LevelDef]:
	if not _built.is_empty():
		return _built
	var basic: Array[int] = [UnitCatalog.Warden.DEW, UnitCatalog.Warden.NEEDLE, UnitCatalog.Warden.BARK]
	var with_rain: Array[int] = basic.duplicate()
	with_rain.append(UnitCatalog.Warden.RAIN)
	var with_seed: Array[int] = with_rain.duplicate()
	with_seed.append(UnitCatalog.Warden.SEED)
	_built = [
		LevelDef.new("First Row", 200, basic, [
			Vector3(4.0, UnitCatalog.Vermin.FLY, 2),
			Vector3(10.0, UnitCatalog.Vermin.FLY, 2),
			Vector3(16.0, UnitCatalog.Vermin.FLY, 1),
			Vector3(16.0, UnitCatalog.Vermin.FLY, 3),
		]),
		LevelDef.new("The Shell", 200, basic, [
			Vector3(3.0, UnitCatalog.Vermin.FLY, 0),
			Vector3(6.0, UnitCatalog.Vermin.LADYBUG, 2),
			Vector3(12.0, UnitCatalog.Vermin.FLY, 2),
			Vector3(12.0, UnitCatalog.Vermin.FLY, 4),
			Vector3(18.0, UnitCatalog.Vermin.LADYBUG, 4),
		]),
		LevelDef.new("Wander", 225, basic, [
			Vector3(3.0, UnitCatalog.Vermin.FLY, 2),
			Vector3(8.0, UnitCatalog.Vermin.BEE, 1),
			Vector3(8.0, UnitCatalog.Vermin.BEE, 3),
			Vector3(14.0, UnitCatalog.Vermin.BEE, 2),
			Vector3(18.0, UnitCatalog.Vermin.LADYBUG, 0),
			Vector3(18.0, UnitCatalog.Vermin.FLY, 4),
		]),
		LevelDef.new("Rain Catch", 225, with_rain, [
			Vector3(3.0, UnitCatalog.Vermin.FLY, 1),
			Vector3(3.0, UnitCatalog.Vermin.FLY, 3),
			Vector3(9.0, UnitCatalog.Vermin.BEE, 2),
			Vector3(14.0, UnitCatalog.Vermin.LADYBUG, 2),
			Vector3(20.0, UnitCatalog.Vermin.FLY, 0),
			Vector3(20.0, UnitCatalog.Vermin.FLY, 4),
			Vector3(24.0, UnitCatalog.Vermin.BEE, 1),
		]),
		LevelDef.new("Seed Storm", 300, with_seed, [
			Vector3(4.0, UnitCatalog.Vermin.BEE, 0),
			Vector3(4.0, UnitCatalog.Vermin.BEE, 2),
			Vector3(4.0, UnitCatalog.Vermin.BEE, 4),
			Vector3(10.0, UnitCatalog.Vermin.FLY, 1),
			Vector3(10.0, UnitCatalog.Vermin.FLY, 3),
			Vector3(16.0, UnitCatalog.Vermin.LADYBUG, 2),
			Vector3(22.0, UnitCatalog.Vermin.BEE, 1),
			Vector3(22.0, UnitCatalog.Vermin.LADYBUG, 4),
		]),
		LevelDef.new("The Slick", 275, with_seed, [
			Vector3(4.0, UnitCatalog.Vermin.SNAIL, 2),
			Vector3(7.0, UnitCatalog.Vermin.LADYBUG, 2),
			Vector3(7.0, UnitCatalog.Vermin.BEE, 2),
			Vector3(12.0, UnitCatalog.Vermin.SNAIL, 0),
			Vector3(15.0, UnitCatalog.Vermin.LADYBUG, 0),
			Vector3(18.0, UnitCatalog.Vermin.FLY, 1),
			Vector3(18.0, UnitCatalog.Vermin.FLY, 3),
			Vector3(24.0, UnitCatalog.Vermin.BEE, 4),
		]),
		LevelDef.new("The Brood", 300, with_seed, [
			Vector3(3.0, UnitCatalog.Vermin.FLY, 0),
			Vector3(3.0, UnitCatalog.Vermin.FLY, 2),
			Vector3(3.0, UnitCatalog.Vermin.FLY, 4),
			Vector3(8.0, UnitCatalog.Vermin.GRUB, 2),
			Vector3(10.0, UnitCatalog.Vermin.LADYBUG, 1),
			Vector3(10.0, UnitCatalog.Vermin.SNAIL, 3),
			Vector3(14.0, UnitCatalog.Vermin.BEE, 3),
			Vector3(18.0, UnitCatalog.Vermin.FLY, 1),
			Vector3(18.0, UnitCatalog.Vermin.FLY, 2),
			Vector3(24.0, UnitCatalog.Vermin.LADYBUG, 4),
		]),
	]
	return _built
