extends SceneTree

## Checks the lawn, water, cooldown, targeting, and win/lose rules without opening a scene.


func _init() -> void:
	var failures: PackedStringArray = []
	_grid(failures)
	_wallet(failures)
	_cooldown(failures)
	_targeting(failures)
	_outcome(failures)
	_soil(failures)
	_sky(failures)
	_backdrops(failures)
	_wave(failures)
	_roster_rules(failures)
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
	var grown := LawnGrid.new(9, 5)
	grown.try_place(8, 1, 3)
	grown.resize(11, 5)
	if grown.occupant(8, 1) != 3 or not grown.try_place(10, 1, 4):
		failures.append("growing the lawn did not keep the old occupant")
	grown.resize(9, 5)
	if grown.occupant(8, 1) != 3 or grown.is_inside(10, 1):
		failures.append("shrinking the lawn kept a column that no longer exists")
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
	_bees(failures)


func _bees(failures: PackedStringArray) -> void:
	var forced := BeePath.legal_steps(4, 2, 9, 5, 2, 5)
	if forced.size() != 1 or forced[0] != BeePath.FORWARD:
		failures.append("a bee was not forced forward on its third move")
	var no_back := BeePath.legal_steps(4, 2, 9, 5, 0, 4)
	if no_back.has(BeePath.BACK):
		failures.append("a bee stepped backward before five moves had passed")
	var can_back := BeePath.legal_steps(4, 2, 9, 5, 0, 5)
	if not can_back.has(BeePath.BACK):
		failures.append("a bee could not step backward after five moves")
	var top := BeePath.legal_steps(8, 0, 9, 5, 0, 0)
	if top.has(BeePath.UP) or top.has(BeePath.BACK):
		failures.append("a bee on the top-right corner had an illegal step")
	var bottom := BeePath.legal_steps(0, 4, 9, 5, 0, 5)
	if bottom.has(BeePath.DOWN):
		failures.append("a bee stepped below the lawn")
	if not bottom.has(BeePath.FORWARD):
		failures.append("a bee lost its forward step at the left edge")


func _outcome(failures: PackedStringArray) -> void:
	if MatchOutcome.evaluate(false, 2, 3) != MatchOutcome.Result.ONGOING:
		failures.append("a live wave was not ongoing")
	if MatchOutcome.evaluate(true, 2, 3) != MatchOutcome.Result.LOST:
		failures.append("a breach was not a loss")
	if MatchOutcome.evaluate(false, 0, 0) != MatchOutcome.Result.WON:
		failures.append("a cleared wave was not a win")
	if MatchOutcome.evaluate(false, 0, 1) != MatchOutcome.Result.ONGOING:
		failures.append("a pending spawn was treated as a win")
	_clips(failures)


func _soil(failures: PackedStringArray) -> void:
	if LawnView.COLUMNS != 12 or LawnView.ROWS != 5:
		failures.append("the lawn was not 5 by 12")
	if SoilMap.kind_at(0, 2) != SoilMap.Kind.REGULAR or SoilMap.kind_at(11, 4) != SoilMap.Kind.REGULAR:
		failures.append("edge columns were not regular soil")
	if SoilMap.kind_at(6, 0) != SoilMap.Kind.STONY or SoilMap.kind_at(6, 4) != SoilMap.Kind.STONY:
		failures.append("the center column was not stony soil")
	if SoilMap.kind_at(3, 1) != SoilMap.Kind.SANDY or SoilMap.kind_at(9, 3) != SoilMap.Kind.SANDY:
		failures.append("sand columns were wrong")
	if not is_equal_approx(SoilMap.vermin_scale(SoilMap.Kind.STONY), 0.5):
		failures.append("stony soil did not halve vermin speed")
	if SoilMap.vermin_scale(SoilMap.Kind.SANDY) <= 1.0:
		failures.append("sandy soil did not speed vermin up")
	if not is_equal_approx(SoilMap.vermin_scale(SoilMap.Kind.REGULAR), 1.0):
		failures.append("regular soil changed vermin speed")
	if SoilMap.warden_rate(SoilMap.Kind.STONY) >= 1.0 or SoilMap.warden_rate(SoilMap.Kind.SANDY) >= 1.0:
		failures.append("poor soil did not slow shooters and dew plants")
	if not is_equal_approx(SoilMap.warden_rate(SoilMap.Kind.REGULAR), 1.0):
		failures.append("regular soil changed how fast plants act")
	if not SoilMap.blurb(SoilMap.Kind.REGULAR).contains("Regular soil"):
		failures.append("regular soil hover text was missing")
	if not SoilMap.blurb(SoilMap.Kind.STONY).contains("Stony soil") or not SoilMap.blurb(SoilMap.Kind.STONY).contains("Vermin"):
		failures.append("stony soil hover text was missing")
	if not SoilMap.blurb(SoilMap.Kind.SANDY).contains("Sandy soil") or not SoilMap.blurb(SoilMap.Kind.SANDY).contains("Walls"):
		failures.append("sandy soil hover text was missing")


func _sky(failures: PackedStringArray) -> void:
	var sky := WaterDrop.new()
	sky.setup(UnitCatalog.DEW_AMOUNT, 4.5, 4.0, true)
	if not sky.falling or not is_equal_approx(sky.row_pos, UnitCatalog.SKY_SPAWN_ROW):
		failures.append("sky drop did not start above the lawn")
	var before := sky.row_pos
	if sky.tick(1.0):
		failures.append("sky drop expired while it was still falling")
	var moved := sky.row_pos - before
	if moved < 0.2 or moved > 0.7 or not sky.falling:
		failures.append("sky drop fell %s rows in one second" % moved)
	var dew := WaterDrop.new()
	dew.setup(UnitCatalog.DEW_AMOUNT, 1.5, 2.0, false)
	dew.tick(1.0)
	if dew.falling or not is_equal_approx(dew.row_pos, 2.0):
		failures.append("dew drop did not stay on its tile")
	sky.free()
	dew.free()


func _backdrops(failures: PackedStringArray) -> void:
	if BackdropCatalog.count() != 5 or BackdropCatalog.NAMES.size() != BackdropCatalog.PATHS.size():
		failures.append("backdrop list was not the five test paintings")
	for index in BackdropCatalog.count():
		if BackdropCatalog.texture_at(index) == null:
			failures.append("backdrop %s did not load" % BackdropCatalog.NAMES[index])


func _wave(failures: PackedStringArray) -> void:
	var level := LevelCatalog.current()
	var seen: Array[float] = []
	var shared := false
	for entry in level.wave:
		if seen.has(entry.x):
			shared = true
		else:
			seen.append(entry.x)
	if not shared:
		failures.append("the first level never sends two vermin at the same time")


func _roster_rules(failures: PackedStringArray) -> void:
	_rain(failures)
	_seeds(failures)
	_snails(failures)
	_grubs(failures)
	_levels(failures)


func _rain(failures: PackedStringArray) -> void:
	var origin := Vector2i(2, 2)
	if not RainCatch.catches(origin, 3.2, 2.0, false):
		failures.append("a rain barrel missed a landed drop on a neighbor")
	if not RainCatch.catches(origin, 1.1, 1.2, false):
		failures.append("a rain barrel missed a diagonal neighbor")
	if RainCatch.catches(origin, 2.4, 2.0, false):
		failures.append("a rain barrel collected the drop on its own tile")
	if RainCatch.catches(origin, 4.2, 2.0, false):
		failures.append("a rain barrel collected a drop two tiles away")
	if RainCatch.catches(origin, 3.0, 2.0, true):
		failures.append("a rain barrel collected a drop that was still falling")


func _seeds(failures: PackedStringArray) -> void:
	var middle := SeedBurst.area(Vector2i(4, 2), 12, 5)
	if middle.size() != 9:
		failures.append("a seed burst in the middle was not 9 tiles")
	var corner := SeedBurst.area(Vector2i(0, 0), 12, 5)
	if corner.size() != 4:
		failures.append("a seed burst in the corner was not clipped")
	var picked := SeedBurst.pick(Vector2i(4, 2), 12, 5, UnitCatalog.LOB_EXTRA)
	if picked.size() != 1 + UnitCatalog.LOB_EXTRA or picked[0] != Vector2i(4, 2):
		failures.append("a seed burst did not keep the landing tile and three more")
	for cell in picked:
		if not middle.has(cell):
			failures.append("a seed left the 3 by 3")
	var spots: Array[Vector2] = [Vector2(6.2, 2), Vector2(2.2, 0)]
	if SeedBurst.aim(1, 2, spots, 12, 5, UnitCatalog.LOB_RANGE) != Vector2i(2, 0):
		failures.append("the lobber did not aim at the closer vermin")
	if SeedBurst.aim(1, 2, [Vector2(1.2, 2)], 12, 5, UnitCatalog.LOB_RANGE).x != -1:
		failures.append("the lobber aimed at a vermin behind it")
	var columns: Array[float] = [4.5, 4.6, 3.2]
	var rows: Array[int] = [2, 2, 2]
	var hits := SeedBurst.hit_indices([Vector2i(4, 2)], columns, rows)
	if hits.size() != 1 or hits[0] != 0:
		failures.append("one seed hit more than one vermin on its tile")
	if not SeedBurst.covers(4.5, 2, Vector2i(4, 2)) or SeedBurst.covers(3.2, 2, Vector2i(4, 2)):
		failures.append("seed cover distance was wrong")


func _snails(failures: PackedStringArray) -> void:
	var snails: Array[Vector2] = [Vector2(5.0, 2)]
	if not is_equal_approx(SnailPace.scale(8.0, 2, true, snails), SnailPace.BOOST):
		failures.append("a ground vermin behind a snail was not sped up")
	if not is_equal_approx(SnailPace.scale(4.0, 2, true, snails), 1.0):
		failures.append("a vermin in front of a snail was sped up")
	if not is_equal_approx(SnailPace.scale(8.0, 2, false, snails), 1.0):
		failures.append("a fly behind a snail was sped up")
	if not is_equal_approx(SnailPace.scale(8.0, 0, true, snails), 1.0):
		failures.append("a snail sped up a different row")
	if UnitCatalog.is_ground(UnitCatalog.Vermin.FLY) or not UnitCatalog.is_ground(UnitCatalog.Vermin.LADYBUG):
		failures.append("ground and fly were swapped")


func _grubs(failures: PackedStringArray) -> void:
	if not UnitCatalog.leaves_grub(UnitCatalog.Vermin.FLY, 0.0):
		failures.append("a dead fly did not leave a grub")
	if UnitCatalog.leaves_grub(UnitCatalog.Vermin.FLY, 0.99):
		failures.append("every death left a grub")
	if UnitCatalog.leaves_grub(UnitCatalog.Vermin.GRUB, 0.0):
		failures.append("a grub left another grub")


func _levels(failures: PackedStringArray) -> void:
	if LevelCatalog.count() != 7:
		failures.append("expected 7 levels, found %d" % LevelCatalog.count())
	var wardens: Array[int] = []
	var vermin: Array[int] = []
	for index in LevelCatalog.count():
		var level := LevelCatalog.at(index)
		if level.cards.is_empty() or level.wave.is_empty() or level.water < 150:
			failures.append("level %d is missing cards, a wave, or water" % index)
		var previous := -1.0
		for entry in level.wave:
			if entry.x + 0.001 < previous:
				failures.append("level %d spawns out of order" % index)
			previous = entry.x
			var kind := int(entry.y)
			var row := int(entry.z)
			if kind < 0 or kind >= UnitCatalog.Vermin.size() or row < 0 or row >= LawnView.ROWS:
				failures.append("level %d has a bad spawn" % index)
			if not vermin.has(kind):
				vermin.append(kind)
		for card in level.cards:
			if not wardens.has(card):
				wardens.append(card)
	if wardens.size() != UnitCatalog.Warden.size():
		failures.append("a warden is missing from every level")
	if vermin.size() != UnitCatalog.Vermin.size():
		failures.append("a vermin is missing from every level")
	LevelCatalog.reset()


func _clips(failures: PackedStringArray) -> void:
	for kind in UnitCatalog.Warden.size():
		var frames := UnitClips.warden(kind)
		for anim_name in UnitClips.warden_animations(kind):
			if not frames.has_animation(anim_name) or frames.get_frame_count(anim_name) < 1:
				failures.append("warden %d missing %s" % [kind, anim_name])
	for kind in UnitCatalog.Vermin.size():
		var frames := UnitClips.vermin(kind)
		var walk := frames.get_frame_count("walk")
		if walk < 2:
			failures.append("vermin %d walk has %d frames" % [kind, walk])
		for anim_name in UnitClips.vermin_animations():
			if not frames.has_animation(anim_name) or frames.get_frame_count(anim_name) < 1:
				failures.append("vermin %d missing %s" % [kind, anim_name])
