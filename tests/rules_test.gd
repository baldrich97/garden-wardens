extends SceneTree

## Checks the lawn, water, cooldown, targeting, and win/lose rules without opening a scene.


func _init() -> void:
	var failures: PackedStringArray = []
	_grid(failures)
	_wallet(failures)
	_cooldown(failures)
	_targeting(failures)
	_outcome(failures)
	if failures.is_empty():
		print("RULES_OK")
		quit(0)
		return
	for failure in failures:
		push_error("RULES %s" % failure)
	quit(1)


func _grid(failures: PackedStringArray) -> void:
	var grid := LawnGrid.new(9, 5)
	if not grid.try_place(1, 2, 4):
		failures.append("empty cell rejected a warden")
	if grid.try_place(1, 2, 5):
		failures.append("occupied cell accepted a second warden")
	if grid.try_place(-1, 0, 1) or grid.try_place(0, 0, 0):
		failures.append("invalid placement was accepted")
	if grid.occupant(1, 2) != 4:
		failures.append("occupant was not stored")
	grid.remove(1, 2)
	if grid.occupant(1, 2) != 0:
		failures.append("removed cell was not empty")
	var inside := LawnGrid.cell_at(Vector2(25, 15), Vector2(10, 10), 10.0, 9, 5)
	if inside != Vector2i(1, 0):
		failures.append("cell_at missed an inside point: %s" % str(inside))
	var outside := LawnGrid.cell_at(Vector2(0, 0), Vector2(10, 10), 10.0, 9, 5)
	if outside != Vector2i(-1, -1):
		failures.append("cell_at accepted an outside point")


func _wallet(failures: PackedStringArray) -> void:
	var wallet := WaterWallet.new(150)
	if wallet.try_spend(200):
		failures.append("spend succeeded without enough water")
	if not wallet.try_spend(100) or wallet.amount != 50:
		failures.append("spend did not subtract the cost")
	wallet.add(25)
	if wallet.amount != 75:
		failures.append("add did not increase water")


func _cooldown(failures: PackedStringArray) -> void:
	var cooldown := Cooldown.new()
	if not cooldown.is_ready():
		failures.append("a new cooldown was not ready")
	cooldown.start(2.0)
	cooldown.tick(0.5)
	if cooldown.is_ready() or not is_equal_approx(cooldown.remaining, 1.5):
		failures.append("cooldown tick was wrong")
	cooldown.tick(2.0)
	if not cooldown.is_ready():
		failures.append("cooldown did not finish")


func _targeting(failures: PackedStringArray) -> void:
	var spots: Array[Vector2] = [Vector2(2.0, 1), Vector2(5.0, 1), Vector2(3.0, 0)]
	if RowTarget.first_ahead(1, 1.0, spots) != 0:
		failures.append("first_ahead missed the nearest vermin")
	if RowTarget.first_ahead(1, 4.0, spots) != 1:
		failures.append("first_ahead kept a vermin behind the shot")
	if RowTarget.first_ahead(2, 0.0, spots) != -1:
		failures.append("first_ahead found a vermin on an empty row")
	if RowTarget.reached_column(4.0, [1, 3]) != 3:
		failures.append("reached_column ignored the plant in front")
	if RowTarget.reached_column(5.2, [1, 3]) != -1:
		failures.append("reached_column stopped a vermin that has not arrived")
	if not RowTarget.shot_reaches(1.8, 2.4, 2.1):
		failures.append("shot_reaches missed a vermin the needle passed")
	if RowTarget.shot_reaches(3.0, 3.6, 2.0):
		failures.append("shot_reaches hit a vermin behind the needle")


func _outcome(failures: PackedStringArray) -> void:
	if MatchOutcome.evaluate(false, 2, 3) != MatchOutcome.Result.ONGOING:
		failures.append("a live wave was not ongoing")
	if MatchOutcome.evaluate(true, 2, 3) != MatchOutcome.Result.LOST:
		failures.append("a breach was not a loss")
	if MatchOutcome.evaluate(false, 0, 0) != MatchOutcome.Result.WON:
		failures.append("a cleared wave was not a win")
	if MatchOutcome.evaluate(false, 0, 1) != MatchOutcome.Result.ONGOING:
		failures.append("a pending spawn was treated as a win")
