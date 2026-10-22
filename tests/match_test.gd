extends SceneTree

## Places a Needle Spitter, lets it hit a Fly, and checks a breach on a second board.

var _phase := 0
var _fight: GardenBoard
var _breach: GardenBoard


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
	var failures := _check_breach(_breach)
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
		failures.append("occupied tile accepted a bark block")
	if board.water_amount() != 0:
		failures.append("water after two placements was %d" % board.water_amount())
	board.spawn_vermin(UnitCatalog.Vermin.FLY, 2, 3.2)
	board.advance(2.0)
	var hp := board.vermin_hp_in_row(2)
	if hp >= UnitCatalog.VERMIN_HP[UnitCatalog.Vermin.FLY]:
		failures.append("fly was not damaged, hp %d" % hp)
	board.advance(4.0)
	if board.water_amount() < UnitCatalog.DEW_AMOUNT:
		failures.append("dew dropper did not add water, amount %d" % board.water_amount())
	return failures


func _check_breach(board: GardenBoard) -> PackedStringArray:
	var failures: PackedStringArray = []
	board.spawn_vermin(UnitCatalog.Vermin.FLY, 0, 0.15)
	board.advance(0.5)
	if board.result() != MatchOutcome.Result.LOST:
		failures.append("a vermin that crossed the left edge did not lose the match")
	return failures


func _fail(failures: PackedStringArray) -> void:
	for failure in failures:
		push_error("MATCH %s" % failure)
	quit(1)
