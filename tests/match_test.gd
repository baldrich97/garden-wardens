extends SceneTree

## Places a Needle Spitter, lets it hit a Fly, and checks a breach on a second board.

var _phase := 0
var _fight: GardenBoard
var _breach: GardenBoard
var _extra: GardenBoard


func _process(_delta: float) -> bool:
	if _phase == 0:
		_fight = _make_board()
		_phase = 1
		return false
	if _phase == 1:
		var failures := _check_fight(_fight)
		if not failures.is_empty():
			_fail(failures)
			return true
		_breach = _make_board()
		_phase = 2
		return false
	if _phase == 2:
		var breach_failures := _check_breach(_breach)
		if not breach_failures.is_empty():
			_fail(breach_failures)
			return true
		_extra = _make_board()
		_phase = 3
		return false
	var failures := _check_extra(_extra)
	if failures.is_empty():
		print("MATCH_OK")
		quit(0)
		return true
	_fail(failures)
	return true


func _make_board() -> GardenBoard:
	var packed := load("res://src/prototype/garden_board.tscn") as PackedScene
	var board := packed.instantiate() as GardenBoard
	root.add_child(board)
	board.set_process(false)
	return board


func _check_fight(board: GardenBoard) -> PackedStringArray:
	var failures: PackedStringArray = []
	if not board.try_place(UnitCatalog.Warden.DEW, 0, 4):
		failures.append("dew dropper refused an empty tile")
	if not board.try_place(UnitCatalog.Warden.NEEDLE, 1, 2):
		failures.append("needle spitter refused an empty tile")
	if board.try_place(UnitCatalog.Warden.BARK, 1, 2):
		failures.append("occupied tile accepted a stubborn cone")
	if board.water_amount() != LevelCatalog.current().water - UnitCatalog.WARDEN_COST[UnitCatalog.Warden.DEW] - UnitCatalog.WARDEN_COST[UnitCatalog.Warden.NEEDLE]:
		failures.append("water after two placements was %d" % board.water_amount())
	board.spawn_vermin(UnitCatalog.Vermin.FLY, 2, 3.2)
	board.start_wave()
	board.advance(2.0)
	var hp := board.vermin_hp_in_row(2)
	if hp >= UnitCatalog.VERMIN_HP[UnitCatalog.Vermin.FLY]:
		failures.append("fly was not damaged, hp %d" % hp)
	var before_drop := board.water_amount()
	board.advance(4.0)
	if board.water_amount() != before_drop:
		failures.append("dew added water before the droplet was collected")
	board.collect_all_drops()
	if board.water_amount() < before_drop + UnitCatalog.DEW_AMOUNT:
		failures.append("dew dropper did not add water, amount %d" % board.water_amount())
	return failures


func _check_breach(board: GardenBoard) -> PackedStringArray:
	var failures: PackedStringArray = []
	if not board.try_place(UnitCatalog.Warden.NEEDLE, 2, 1):
		failures.append("needle spitter refused a tile before digging")
	var water_after_place := board.water_amount()
	if not board.dig(2, 1):
		failures.append("dig did not remove the warden")
	if board.water_amount() != water_after_place:
		failures.append("dig refunded water")
	if not board.try_place(UnitCatalog.Warden.BARK, 2, 1):
		failures.append("dug tile did not accept another warden")
	board.spawn_vermin(UnitCatalog.Vermin.FLY, 0, 0.15)
	board.start_wave()
	board.advance(1.0)
	if board.result() != MatchOutcome.Result.LOST:
		failures.append("a vermin that crossed the left edge did not lose the match")
	return failures


func _check_extra(board: GardenBoard) -> PackedStringArray:
	var failures: PackedStringArray = []
	var water := board.water_amount()
	board.drag_cancel(0)
	if board.water_amount() != water:
		failures.append("cancelling a drag spent water")
	if not board.drag_place(0, 4, 1):
		failures.append("dragging a dew dropper onto an empty tile did not plant")
	water = board.water_amount()
	if board.drag_place(2, 4, 1):
		failures.append("dragging onto an occupied tile planted a second warden")
	if board.water_amount() != water:
		failures.append("a refused drag spent water")
	if not board.drag_place(2, 5, 1):
		failures.append("dragging a stubborn cone onto an empty tile did not plant")
	if not board.try_place(UnitCatalog.Warden.RAIN, 2, 2):
		failures.append("rain catcher refused an empty tile")
	var before_catch := board.water_amount()
	board.spawn_test_drop(3.2, 2.0)
	board.spawn_test_drop(2.2, 2.0)
	board.start_wave()
	board.advance(0.2)
	if board.water_amount() != before_catch + UnitCatalog.DEW_AMOUNT:
		failures.append("rain catcher collected the wrong drops, water %d" % board.water_amount())
	for _drop in 4:
		board.spawn_test_drop(10.5, 0.0)
	board.collect_all_drops()
	if not board.try_place(UnitCatalog.Warden.SEED, 1, 2):
		failures.append("seed lobber refused an empty tile")
	board.spawn_vermin(UnitCatalog.Vermin.FLY, 2, 4.5)
	board.advance(1.4)
	var fly_hp := board.vermin_hp_in_row(2)
	if fly_hp < 0 or fly_hp >= UnitCatalog.VERMIN_HP[UnitCatalog.Vermin.FLY]:
		failures.append("seed lobber did not damage the fly, hp %d" % fly_hp)
	board.push_grub_roll(0.0)
	board.advance(3.2)
	if board.vermin_of_kind(UnitCatalog.Vermin.GRUB) < 1:
		failures.append("a dead fly did not leave a grub")
	return failures


func _fail(failures: PackedStringArray) -> void:
	for failure in failures:
		push_error("MATCH %s" % failure)
	quit(1)
