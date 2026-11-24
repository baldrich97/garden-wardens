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
	_anim_clips(failures)
	_flutter(failures)
	_match_seed(failures)
	_golden_hour(failures)
	_sky_look(failures)
	_fx_art(failures)
	_lawn_geometry(failures)
	_responsive(failures)
	_paper_pop(failures)
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
	# Seeded wander (GW-AA pass 2): the same match seed replays the same steps.
	var walk_a: Array[Vector2i] = []
	var walk_b: Array[Vector2i] = []
	var rng_a := MatchSeed.with_value(4242).rng("bee_path")
	var rng_b := MatchSeed.with_value(4242).rng("bee_path")
	for _step in 24:
		walk_a.append(BeePath.next_step(5, 2, 12, 5, 0, 5, rng_a))
		walk_b.append(BeePath.next_step(5, 2, 12, 5, 0, 5, rng_b))
	if walk_a != walk_b:
		failures.append("the same match seed gave a bee two different wanders")
	for step in walk_a:
		if not BeePath.legal_steps(5, 2, 12, 5, 0, 5).has(step):
			failures.append("a seeded bee took an illegal step %s" % step)
			break


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
	if BackdropCatalog.count() != 5 or BackdropCatalog.NAMES.size() != BackdropCatalog.PATHS.size() \
			or BackdropCatalog.MOOD_KEYS.size() != BackdropCatalog.count() or BackdropCatalog.SET_TINTS.size() != BackdropCatalog.count() \
			or BackdropCatalog.BACKDROP_TINTS.size() != BackdropCatalog.count() or BackdropCatalog.EYES_ON.size() != BackdropCatalog.count():
		failures.append("look list was not Main, Sunny, Overcast, Dusk Twilight, Dusk Moonlit (index-aligned)")
	# The seed never opens on Moonlit (seeded pick stays on the first four).
	for probe in 200:
		if BackdropCatalog.pick_index(probe * 7919) >= BackdropCatalog.SEEDED_LOOKS:
			failures.append("a seed opened on a cycle-only look")
			break
	for index in BackdropCatalog.count():
		if BackdropCatalog.texture_at(index) == null:
			failures.append("backdrop %s did not load" % BackdropCatalog.NAMES[index])
	# batch2 slot: a look's own sky_backdrop.png replaces its PATHS backdrop
	# (Dusk Moonlit falls back to the shared dusk folder).
	var sky_probe := ImageTexture.create_from_image(Image.create(16, 9, false, Image.FORMAT_RGBA8))
	var sky_path := BackdropCatalog.STAGE_DIR + "dusk/" + BackdropCatalog.SKY_BACKDROP_NAME
	BackdropCatalog.inject(sky_path, sky_probe)
	if BackdropCatalog.texture_at(4) != sky_probe or BackdropCatalog.texture_at(3) != sky_probe or BackdropCatalog.texture_at(0) == sky_probe:
		failures.append("a mood's sky_backdrop.png slot did not replace only that mood's backdrop")
	BackdropCatalog.inject(sky_path, null)
	if BackdropCatalog.texture_at(3) == sky_probe:
		failures.append("the sky_backdrop slot stuck after its art went away")
	if BackdropCatalog.pick_index(12345) != BackdropCatalog.pick_index(12345):
		failures.append("the same seed picked a different backdrop")
	if BackdropCatalog.pick_index(0) < 0 or BackdropCatalog.pick_index(0) >= BackdropCatalog.count():
		failures.append("a seeded pick left the backdrop list")
	var seen: Dictionary[int, bool] = {}
	for probe in 64:
		seen[BackdropCatalog.pick_index(probe * 99991)] = true
	if seen.size() < 2:
		failures.append("64 seeds all picked the same backdrop")


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
		failures.append("a rain catcher missed a landed drop on a neighbor")
	if not RainCatch.catches(origin, 1.1, 1.2, false):
		failures.append("a rain catcher missed a diagonal neighbor")
	if RainCatch.catches(origin, 2.4, 2.0, false):
		failures.append("a rain catcher collected the drop on its own tile")
	if RainCatch.catches(origin, 4.2, 2.0, false):
		failures.append("a rain catcher collected a drop two tiles away")
	if RainCatch.catches(origin, 3.0, 2.0, true):
		failures.append("a rain catcher collected a drop that was still falling")


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
	var seeded_a := SeedBurst.pick(Vector2i(4, 2), 12, 5, UnitCatalog.LOB_EXTRA, MatchSeed.with_value(7).rng("seed_burst"))
	var seeded_b := SeedBurst.pick(Vector2i(4, 2), 12, 5, UnitCatalog.LOB_EXTRA, MatchSeed.with_value(7).rng("seed_burst"))
	if seeded_a != seeded_b:
		failures.append("the same match seed picked two different seed volleys")
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
	if LevelCatalog.count() != 8:
		failures.append("expected 8 levels, found %d" % LevelCatalog.count())
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
		for preset in level.pre_placed:
			if preset.x < 0 or preset.x >= LawnView.COLUMNS or preset.y < 0 or preset.y >= LawnView.ROWS \
					or preset.z < 0 or preset.z >= UnitCatalog.Warden.size():
				failures.append("level %d has a bad pre-placed Warden" % index)
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


func _flutter(failures: PackedStringArray) -> void:
	if not FlutterHop.can_hop(UnitCatalog.Vermin.LADYBUG, UnitCatalog.Warden.BARK):
		failures.append("a ladybug refused to hop a Stubborn Cone")
	for warden in UnitCatalog.Warden.size():
		if warden != UnitCatalog.Warden.BARK and FlutterHop.can_hop(UnitCatalog.Vermin.LADYBUG, warden):
			failures.append("a ladybug hops Warden %d instead of chewing it" % warden)
	for vermin in UnitCatalog.Vermin.size():
		if vermin != UnitCatalog.Vermin.LADYBUG and FlutterHop.can_hop(vermin, UnitCatalog.Warden.BARK):
			failures.append("%s was allowed to hop a Stubborn Cone" % UnitCatalog.VERMIN_NAMES[vermin])
	if not is_zero_approx(FlutterHop.travel(0.2)) or FlutterHop.travel(FlutterHop.TRAVEL_START) > 0.001:
		failures.append("the hop slid before takeoff frame 4")
	if not is_equal_approx(FlutterHop.travel(1.4), 0.5):
		failures.append("the hop midpoint was not half travelled")
	if not is_equal_approx(FlutterHop.travel(FlutterHop.TRAVEL_END), 1.0) \
			or not is_equal_approx(FlutterHop.travel(FlutterHop.TOTAL_SECONDS), 1.0):
		failures.append("the hop did not finish its 2 cells by landing frame 5")
	if not is_zero_approx(FlutterHop.lift_tiles(0.0)) or not is_zero_approx(FlutterHop.lift_tiles(1.0)):
		failures.append("the arc left the ground at its ends")
	if not is_equal_approx(FlutterHop.lift_tiles(0.5), FlutterHop.PEAK_LIFT_TILES):
		failures.append("the arc peak was not the authored 1.25 tiles")
	if FlutterHop.lift_tiles(0.5) <= 1.0:
		failures.append("the arc peak did not clear the 1-tile cone")
	if FlutterHop.phase(0.0) != FlutterHop.PHASE_TAKEOFF \
			or FlutterHop.phase(0.79) != FlutterHop.PHASE_TAKEOFF:
		failures.append("the first 0.8 s of the hop were not the takeoff clip")
	if FlutterHop.phase(0.8) != FlutterHop.PHASE_AIR \
			or FlutterHop.phase(1.99) != FlutterHop.PHASE_AIR:
		failures.append("the middle second of the hop was not the air loop")
	if FlutterHop.phase(2.0) != FlutterHop.PHASE_LAND \
			or FlutterHop.phase(2.79) != FlutterHop.PHASE_LAND:
		failures.append("the last 0.8 s of the hop were not the landing clip")


func _anim_clips(failures: PackedStringArray) -> void:
	_anim_manifests(failures)
	_anim_loader(failures)


func _anim_manifests(failures: PackedStringArray) -> void:
	for folder in AnimLibrary.WARDEN_FOLDERS + AnimLibrary.VERMIN_FOLDERS:
		var manifest := AnimLibrary.manifest_for_folder(folder)
		var animations: Variant = manifest.get("animations")
		if not (animations is Dictionary) or animations.is_empty():
			failures.append("%s has no parsable frames.json animations" % folder)
			continue
		for anim_name in animations:
			if not (animations[anim_name] is Dictionary):
				failures.append("%s %s is not a dict" % [folder, anim_name])
				continue
			var anim: Dictionary = animations[anim_name]
			var frame_count := int(anim.get("frame_count", 0))
			var durations: Variant = anim.get("durations_ms")
			if frame_count < 1 or not (durations is Array) or durations.size() != frame_count:
				failures.append("%s %s durations do not match frame_count" % [folder, anim_name])
				continue
			if not (anim.get("loop") is bool):
				failures.append("%s %s loop flag is not a bool" % [folder, anim_name])
			var states: Variant = anim.get("states")
			if not (states is Dictionary) or states.is_empty():
				failures.append("%s %s has no damage states" % [folder, anim_name])
				continue
			for state_key in states:
				var state_dict: Variant = states[state_key]
				var paths: Variant = state_dict.get("frames") if state_dict is Dictionary else null
				if not (paths is Array) or paths.size() != frame_count:
					failures.append("%s %s state %s is not aligned index-for-index" % [folder, anim_name, state_key])
					continue
				for path in paths:
					if not FileAccess.file_exists(folder + "/" + String(path)):
						failures.append("%s %s state %s references missing frame %s" % [folder, anim_name, state_key, path])
	var poof := AnimLibrary.manifest_for_folder(AnimLibrary.POOF_FOLDER)
	var poof_frames: Variant = poof.get("frames")
	var poof_durations: Variant = poof.get("durations_ms")
	if not (poof_frames is Array) or poof_frames.is_empty():
		failures.append("poof manifest has no frames")
	elif not (poof_durations is Array) or poof_durations.size() != poof_frames.size():
		failures.append("poof durations do not match its frame count")
	else:
		for path in poof_frames:
			if not FileAccess.file_exists(AnimLibrary.POOF_FOLDER + "/" + String(path)):
				failures.append("poof references missing frame %s" % path)
		if not (poof.get("pivot_px") is Array) or poof.get("pivot_px").size() != 2:
			failures.append("poof has no pivot_px")


func _anim_loader(failures: PackedStringArray) -> void:
	if AnimLibrary.state_for_hp(1.0) != "100" or AnimLibrary.state_for_hp(0.67) != "100":
		failures.append("state_for_hp kept a healthy ratio out of 100")
	if AnimLibrary.state_for_hp(0.66) != "66" or AnimLibrary.state_for_hp(0.34) != "66":
		failures.append("state_for_hp kept a hurt ratio out of 66")
	if AnimLibrary.state_for_hp(0.33) != "33" or AnimLibrary.state_for_hp(0.0) != "33":
		failures.append("state_for_hp kept a dying ratio out of 33")
	if AnimLibrary.clip_for_folder(AnimLibrary.ROOT + "/wardens/not_a_real_unit") != null:
		failures.append("a missing unit folder built a clip instead of failing clean")
	if AnimLibrary.warden(UnitCatalog.Warden.BARK) == null or AnimLibrary.vermin(UnitCatalog.Vermin.FLY) == null:
		failures.append("warden() or vermin() returned null")
	var bark_folder := AnimLibrary.warden_folder(UnitCatalog.Warden.BARK)
	var bark := AnimLibrary.clip_for_folder(bark_folder)
	if bark == null:
		failures.append("Stubborn Cone clips did not build from frames.json")
	else:
		_bark_states(failures, bark)
		_anim_swap(failures, bark)
	var fly := AnimLibrary.clip_for_folder(AnimLibrary.vermin_folder(UnitCatalog.Vermin.FLY))
	if fly == null or not fly.has_animation("move_100"):
		failures.append("Fly clips did not build from frames.json")
	var snail_folder := AnimLibrary.vermin_folder(UnitCatalog.Vermin.SNAIL)
	var snail := AnimLibrary.clip_for_folder(snail_folder)
	var snail_move: Dictionary = AnimLibrary.manifest_for_folder(snail_folder).get("animations", {}).get("move", {})
	var snail_durations: Variant = snail_move.get("durations_ms")
	if snail == null or not snail.has_animation("move_100") or not (snail_durations is Array) \
			or snail_durations.is_empty() \
			or not is_equal_approx(snail.get_frame_duration("move_100", 0), float(snail_durations[0]) / 1000.0):
		failures.append("Snail move did not keep its authored per-frame holds")
	var poof_clips := AnimLibrary.poof()
	if poof_clips == null or poof_clips.get_frame_count(AnimLibrary.POOF_ANIM) < 1:
		failures.append("poof clips did not build")
	elif poof_clips.get_animation_loop(AnimLibrary.POOF_ANIM):
		failures.append("poof should not loop")
	if AnimLibrary.poof_pivot() == Vector2.INF:
		failures.append("poof pivot was not exposed")


func _bark_states(failures: PackedStringArray, bark: SpriteFrames) -> void:
	var manifest := AnimLibrary.manifest_for_folder(AnimLibrary.warden_folder(UnitCatalog.Warden.BARK))
	var animations: Dictionary = manifest.get("animations", {})
	var idle: Dictionary = animations.get("idle", {})
	var idle_frames := int(idle.get("frame_count", 0))
	for state in AnimLibrary.DAMAGE_STATES:
		var clip_name := "idle_" + state
		if not bark.has_animation(clip_name) or bark.get_frame_count(clip_name) != idle_frames:
			failures.append("Stubborn Cone is missing %s" % clip_name)
			continue
		var durations: Array = idle.get("durations_ms", [])
		if durations.is_empty() or not is_equal_approx(bark.get_frame_duration(clip_name, 0), float(durations[0]) / 1000.0):
			failures.append("Stubborn Cone %s ignores authored frame durations" % clip_name)
		if bark.get_animation_loop(clip_name) != bool(idle.get("loop", false)):
			failures.append("Stubborn Cone %s ignores the loop flag" % clip_name)
	if not bark.has_animation("place_100") or bark.has_animation("place_66"):
		failures.append("Stubborn Cone place states are wrong")
	if not bark.has_animation("death_33") or bark.has_animation("death_100"):
		failures.append("Stubborn Cone death states are wrong")
	if AnimLibrary.animation_name(bark, "place", "66") != "place_100":
		failures.append("animation_name missed the place fallback")
	if AnimLibrary.animation_name(bark, "death", "100") != "death_33":
		failures.append("animation_name missed the death fallback")
	if AnimLibrary.animation_name(UnitClips.warden(UnitCatalog.Warden.BARK), "idle", "100") != "idle":
		failures.append("animation_name missed the legacy bare-name fallback")


func _anim_swap(failures: PackedStringArray, bark: SpriteFrames) -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = bark
	sprite.play("idle_100")
	sprite.frame = 4
	if not AnimLibrary.swap_keep_frame(sprite, "idle_66"):
		failures.append("damage-state swap was refused")
	elif sprite.animation != &"idle_66" or sprite.frame != 4 or not sprite.is_playing():
		failures.append("damage-state swap lost the frame index or playback")
	sprite.frame = bark.get_frame_count("idle_66") - 1
	if not AnimLibrary.swap_keep_frame(sprite, "hurt_100") or sprite.frame != 4:
		failures.append("a swap into a shorter animation did not clamp the frame")
	if AnimLibrary.swap_keep_frame(sprite, "idle_99"):
		failures.append("a swap to a missing animation was accepted")
	sprite.stop()
	# Godot's stop() resets the frame to 0 itself, so a stopped sprite's swap
	# must switch the animation, keep whatever frame the engine settled on, and
	# not start playback.
	if not AnimLibrary.swap_keep_frame(sprite, "place_100") or sprite.animation != &"place_100" or sprite.is_playing():
		failures.append("a swap on a stopped sprite did not hold its place")
	sprite.free()


func _match_seed(failures: PackedStringArray) -> void:
	var cup := MatchSeed.with_value(4242)
	if cup.value != 4242:
		failures.append("the dice cup lost its rolled value")
	var first: Array[int] = []
	var second: Array[int] = []
	var a := MatchSeed.with_value(4242).rng("backdrop")
	var b := MatchSeed.with_value(4242).rng("backdrop")
	for draw in 8:
		first.append(a.randi())
		second.append(b.randi())
	if first != second:
		failures.append("the same seed and channel drew different numbers")
	var other := MatchSeed.with_value(4242).rng("mood")
	if other.randi_range(0, 999999) == first[0] % 1000000:
		failures.append("two channels shared a stream")


func _golden_hour(failures: PackedStringArray) -> void:
	var spec: Variant = JSON.parse_string(FileAccess.get_file_as_string(GoldenHourBackdrop.SPEC_PATH))
	if spec == null or not spec is Dictionary:
		failures.append("golden hour layer spec did not parse")
		return
	for key in ["canvas", "ray_pivot_px", "wheel_size", "rotation_deg_per_s", "sun_sprite_topleft"]:
		if not spec.has(key):
			failures.append("golden hour spec lost %s" % key)
	for key in GoldenHourBackdrop.LAYER_PATHS:
		if load(GoldenHourBackdrop.LAYER_PATHS[key]) as Texture2D == null:
			failures.append("golden hour layer %s did not load" % key)


func _sky_look(failures: PackedStringArray) -> void:
	# One sun per match, always textured, never on the overcast mood.
	var sky := SkyLayer.new()
	root.add_child(sky)
	sky.set_band(Rect2(100.0, 40.0, 1080.0, 120.0))
	sky.apply_look(4242, 0)
	if not sky.sun_visible():
		failures.append("the sun hid on a clear mood")
	if sky.sun_texture() == null:
		failures.append("the match sun had no texture")
	var clouds := sky.cloud_count()
	if clouds < SkyLook.CLOUD_MIN or clouds > SkyLook.CLOUD_MAX:
		failures.append("cloud count %d left the %d-%d range" % [clouds, SkyLook.CLOUD_MIN, SkyLook.CLOUD_MAX])
	if not sky.clouds_have_textures():
		failures.append("a drifting cloud lost its texture")
	# Stick clouds: every stick runs off the top, and every cloud bobs up and
	# down on its own (the stagehand motion), not just sideways.
	if not sky.sticks_reach_top():
		failures.append("a cloud stick stopped short of the top of the screen")
	var low: Array[float] = []
	var high: Array[float] = []
	for i in clouds:
		low.append(INF)
		high.append(-INF)
	for _step in 60:
		sky.tick(0.1)
		for i in clouds:
			var off := sky.cloud_bob_offset(i)
			low[i] = minf(low[i], off)
			high[i] = maxf(high[i], off)
		if not sky.sticks_reach_top():
			failures.append("a cloud stick dipped into view mid-bob")
			break
	for i in clouds:
		if high[i] - low[i] < sky.cloud_bob_amplitude(i) or sky.cloud_bob_amplitude(i) < 3.0:
			failures.append("cloud %d barely moved vertically (%.1f px)" % [i, high[i] - low[i]])
	# Moods that paint their own sun or moon never get a second one.
	for mood in [SkyLook.MOOD_SUNNY, SkyLook.MOOD_DUSK]:
		if SkyLook.mood_shows_sun(mood):
			failures.append("mood %d would show two celestials" % mood)
	if not SkyLook.mood_shows_sun(0):
		failures.append("the main look lost its per-match sun")
	# Determinism: the same seed builds the same sky.
	var again := SkyLayer.new()
	root.add_child(again)
	again.set_band(Rect2(0.0, 0.0, 1080.0, 120.0))
	again.apply_look(4242, 0)
	if sky.sun_texture() != again.sun_texture():
		failures.append("the same seed picked a different sun")
	if sky.cloud_count() != again.cloud_count() or sky.raining() != again.raining():
		failures.append("the same seed built a different sky")
	if sky.raining() != SkyLook.rain_active(4242, 0):
		failures.append("the sky disagreed with its seeded rain call")
	# Overcast: the sun goes out.
	sky.apply_look(4242, SkyLook.MOOD_OVERCAST)
	if sky.sun_visible():
		failures.append("the sun showed on the overcast mood")
	sky.free()
	again.free()
	_mood_clouds(failures)
	# Rain (pass 4): only the Overcast mood ever rains; a seeded Overcast
	# match where it falls shows drops, then splashes at the grass.
	for mood in [SkyLook.MOOD_MAIN, SkyLook.MOOD_SUNNY, SkyLook.MOOD_DUSK, SkyLook.MOOD_GOLDEN_HOUR]:
		for probe in 64:
			if SkyLook.rain_active(probe, mood):
				failures.append("mood %d rained (seed %d); rain is Overcast-only" % [mood, probe])
				break
	var rainy := -1
	for probe in 64:
		if SkyLook.rain_active(probe, SkyLook.MOOD_OVERCAST):
			rainy = probe
			break
	if rainy < 0:
		failures.append("64 seeds never rained on the Overcast mood")
		return
	var shower := SkyLayer.new()
	root.add_child(shower)
	shower.set_band(Rect2(100.0, 40.0, 1080.0, 120.0))
	shower.apply_look(rainy, SkyLook.MOOD_OVERCAST)
	# The rain cloud is a full-size stick cloud: its body matches the largest
	# drifting-cloud class, not a thumbnail; drops stay small and subtle.
	if shower.rain_cloud() == null or not shower.rain_cloud().visible:
		failures.append("the Overcast rain cloud did not show")
	elif absf(shower.rain_cloud_body_height() - SkyLayer.RAIN_CLOUD_BODY_TARGET) > 1.5:
		failures.append("rain cloud body %.1f px, want %.0f (largest cloud class)" % [shower.rain_cloud_body_height(), SkyLayer.RAIN_CLOUD_BODY_TARGET])
	if SkyLayer.RAIN_CLOUD_BODY_TARGET < float(SkyLayer.CLOUD_BODY_TARGETS.max()):
		failures.append("the rain cloud is smaller than the drifting clouds")
	if shower.drop_height() > SkyLayer.DROP_TARGET_H + 0.5:
		failures.append("rain drops %.1f px tall; keep them subtle" % shower.drop_height())
	if not shower.raining():
		failures.append("a seeded rainy match stayed dry")
		shower.free()
		return
	var saw_drop := false
	var saw_splash := false
	for _step in 30:
		shower.tick(0.1)
		if shower.active_drops() > 0:
			saw_drop = true
		if shower.active_splashes() > 0:
			saw_splash = true
		if saw_drop and saw_splash:
			break
	if not saw_drop:
		failures.append("no drops were falling mid-rain")
	if not saw_splash:
		failures.append("no splash appeared where a drop landed")
	shower.free()


## GW-AA pass 2: the origami water set, the Round 3 effect stills, and the
## per-unit fx sequences all load at the sizes the wiring expects.
func _fx_art(failures: PackedStringArray) -> void:
	var stills := {
		"water parachute": FxArt.WATER_PARACHUTE, "water medium": FxArt.WATER_DROP_MEDIUM,
		"water small": FxArt.WATER_DROP_SMALL, "A4 small burst": FxArt.SMALL_BURST,
		"A3 impact burst": FxArt.IMPACT_BURST, "B3 collect flecks": FxArt.COLLECT_FLECKS,
		"leaf ring": FxArt.LEAF_RING,
	}
	for label in stills:
		var texture: Texture2D = stills[label]
		if texture == null or texture.get_width() < 64:
			failures.append("fx still %s did not load" % label)
	var smoke := FxArt.needle_smoke()
	if smoke.size() != 16:
		failures.append("needle smoke loaded %d overlays, expected 16 (one per action frame)" % smoke.size())
	elif smoke[0].get_size() != AnimLibrary.canvas_px(AnimLibrary.warden_folder(UnitCatalog.Warden.NEEDLE)):
		failures.append("needle smoke is not on the Needle Spitter canvas (%s)" % smoke[0].get_size())
	if FxArt.lobber_spin().size() != FxArt.LOBBER_SPIN_COUNT:
		failures.append("seed lobber spin did not load 8 frames")
	if FxArt.lobber_burst().size() != FxArt.LOBBER_BURST_COUNT:
		failures.append("seed lobber burst did not load 20 frames")
	var sky_drop := WaterDrop.new()
	sky_drop.setup(UnitCatalog.DEW_AMOUNT, 3.5, 2.0, true)
	if sky_drop.art() != FxArt.WATER_PARACHUTE:
		failures.append("a falling sky drop did not use the parachute drop")
	for _tick in 20:
		sky_drop.tick(0.5)
	if sky_drop.falling or sky_drop.art() != FxArt.WATER_DROP_MEDIUM:
		failures.append("a landed sky drop did not fold to the medium drop")
	sky_drop.free()
	var dew := WaterDrop.new()
	dew.setup(UnitCatalog.DEW_AMOUNT, 3.5, 2.0, false)
	if dew.art() != FxArt.WATER_DROP_MEDIUM:
		failures.append("a dew drop did not use the medium drop")
	dew.free()


## GW-AA pass 3, Option B: the perspective lawn's homography round-trips every
## cell, the frame lands on the locked trapezoid, and the rails stack back to
## front (rail y, scale, and z all grow toward the viewer).
func _lawn_geometry(failures: PackedStringArray) -> void:
	var geometry := LawnGeometry.new(LawnView.BOARD_FRAME_SRC, LawnView.BOARD_GRID_SRC, LawnView.COLUMNS, LawnView.ROWS)
	var misses := 0
	for row in LawnView.ROWS:
		for column in LawnView.COLUMNS:
			var cell := Vector2i(column, row)
			if geometry.cell_at(geometry.cell_to_screen(cell)) != cell:
				misses += 1
			# Points near each corner (inside the cell) must still map back.
			var corners := geometry.cell_corners(column, row)
			var middle := geometry.cell_to_screen(cell)
			for corner in corners:
				if geometry.cell_at(middle.lerp(corner, 0.9)) != cell:
					misses += 1
	if misses > 0:
		failures.append("lawn homography round trip missed %d cell probes of %d" % [misses, LawnView.COLUMNS * LawnView.ROWS * 5])
	var quad := geometry.frame_quad()
	var want := [LawnGeometry.FAR_LEFT, LawnGeometry.FAR_RIGHT, LawnGeometry.NEAR_RIGHT, LawnGeometry.NEAR_LEFT]
	for index in 4:
		if quad[index].distance_to(want[index]) > 0.5:
			failures.append("lawn frame corner %d at %s, expected %s" % [index, quad[index], want[index]])
	if geometry.cell_at(Vector2(640.0, 300.0)) != Vector2i(-1, -1) or geometry.cell_at(Vector2(20.0, 500.0)) != Vector2i(-1, -1):
		failures.append("lawn cell_at accepted a point off the trapezoid")
	var round_trip := geometry.stage_to_source(geometry.source_to_stage(Vector2(500.0, 500.0)))
	if round_trip.distance_to(Vector2(500.0, 500.0)) > 0.01:
		failures.append("lawn homography inverse drifted (%s)" % round_trip)
	for row in range(1, LawnView.ROWS):
		if geometry.rail_y(row) <= geometry.rail_y(row - 1):
			failures.append("rail %d is not in front of rail %d" % [row, row - 1])
		if geometry.rail_scale(row) <= geometry.rail_scale(row - 1):
			failures.append("rail %d does not scale up from rail %d" % [row, row - 1])
		if LawnGeometry.z_for_row(row) - LawnGeometry.z_for_row(row - 1) < 3:
			failures.append("rail %d z does not clear rail %d's units, shots, and fx" % [row, row - 1])
	if absf(geometry.rail_scale(LawnView.ROWS - 1) - 1.0) > 0.001 or geometry.rail_scale(0) < 0.78 or geometry.rail_scale(0) > 0.86:
		failures.append("rail scales are not about 0.82 to 1.00 (%.3f..%.3f)" % [geometry.rail_scale(0), geometry.rail_scale(LawnView.ROWS - 1)])
	for row in LawnView.ROWS:
		var top := geometry.point(0.5, float(row)).y
		var bottom := geometry.point(0.5, float(row + 1)).y
		var expected := lerpf(top, bottom, LawnGeometry.RAIL_DEPTH)
		if absf(geometry.rail_y(row) - expected) > 1.0:
			failures.append("rail %d is not 0.72 into its row" % row)


## GW-AA pass 3: the card selector snaps to the side bar on small real windows.
func _responsive(failures: PackedStringArray) -> void:
	var cases := {
		Vector2i(960, 540): GardenBoard.LAYOUT_VERTICAL,
		Vector2i(1099, 800): GardenBoard.LAYOUT_VERTICAL,
		Vector2i(1280, 639): GardenBoard.LAYOUT_VERTICAL,
		Vector2i(1280, 720): GardenBoard.LAYOUT_HORIZONTAL,
		Vector2i(1100, 640): GardenBoard.LAYOUT_HORIZONTAL,
		Vector2i(1920, 1080): GardenBoard.LAYOUT_HORIZONTAL,
		Vector2i(2560, 1440): GardenBoard.LAYOUT_HORIZONTAL,
	}
	for window: Vector2i in cases:
		if GardenBoard.layout_for_window(window) != cases[window]:
			failures.append("window %s picked the %s layout" % [window, GardenBoard.layout_for_window(window)])


## Pass 4: each mood shows one cloud family only (no mixed white/grey/orange),
## tinted per mood; the Main sun is the big layered paper sun with a shadow.
func _mood_clouds(failures: PackedStringArray) -> void:
	var want := {
		SkyLook.MOOD_MAIN: "cotton", SkyLook.MOOD_SUNNY: "cotton",
		SkyLook.MOOD_OVERCAST: "felt", SkyLook.MOOD_DUSK: "cotton",
		SkyLook.MOOD_DUSK_MOONLIT: "",
		SkyLook.MOOD_GOLDEN_HOUR: ("sunset" if SkyCatalog.has_sunset() else "cotton") if SkyLook.GOLDEN_HOUR_CLOUDS == "tinted" else "",
	}
	# Asset Gen batch 1's sunset clouds are installed: Golden Hour uses them.
	if SkyCatalog.sunset_entries().size() != 24:
		failures.append("sunset cloud family has %d files, want the 24 batch-1 clouds" % SkyCatalog.sunset_entries().size())
	for size in 3:
		for entry in SkyCatalog.family_entries(size, SkyCatalog.FAMILY_COTTON, true):
			if String(entry["path"]).find("sunset") >= 0:
				failures.append("a sunset cloud leaked into the white cotton family")
	for entry in SkyCatalog.sunset_entries():
		if float(entry["body_h"]) <= 0.0 or (bool(entry["stick"]) and float(entry["body_h"]) > 400.0):
			failures.append("sunset cloud %s has a bad body height %.0f" % [entry["path"], entry["body_h"]])
	for mood in want:
		if SkyLook.cloud_family(mood) != want[mood]:
			failures.append("mood %d cloud family '%s', want '%s'" % [mood, SkyLook.cloud_family(mood), want[mood]])
		var sky := SkyLayer.new()
		root.add_child(sky)
		sky.set_band(Rect2(100.0, 40.0, 1080.0, 120.0))
		sky.apply_look(4242, mood)
		for path in sky.cloud_paths():
			var file := path.get_file()
			var family_ok := file.find("sunset_") >= 0 if want[mood] == "sunset" else file.begins_with(want[mood] + "_")
			if file.begins_with("torn_") or (want[mood] != "" and not family_ok):
				failures.append("mood %d showed off-family cloud %s" % [mood, file])
				break
		if want[mood] == "" and not sky.cloud_paths().is_empty():
			failures.append("mood %d should be clear but drew %d clouds" % [mood, sky.cloud_paths().size()])
		if SkyLook.mood_shows_moon(mood) != (sky.moon_height() > 0.0):
			failures.append("mood %d moon shown %s" % [mood, sky.moon_height() > 0.0])
		if (mood == SkyLook.MOOD_DUSK_MOONLIT) != (sky.star_count() > 0):
			failures.append("mood %d stars %d (only Moonlit twinkles)" % [mood, sky.star_count()])
		if sky.cloud_tint() != SkyLook.cloud_tint(mood):
			failures.append("mood %d cloud tint not applied" % mood)
		if mood == SkyLook.MOOD_MAIN:
			if not sky.sun_has_shadow() or absf(sky.sun_height() - SkyLayer.SUN_TARGET_H) > 1.5:
				failures.append("Main sun: want the %.0f px layered sun with a drop shadow (got %.1f px, shadow %s)" % [SkyLayer.SUN_TARGET_H, sky.sun_height(), sky.sun_has_shadow()])
		sky.free()
	if SkyLook.cloud_tint(SkyLook.MOOD_MAIN) != Color.WHITE:
		failures.append("Main clouds should stay white")
	var dusk := SkyLook.cloud_tint(SkyLook.MOOD_DUSK)
	if not (dusk.b > dusk.r and dusk.b > dusk.g):
		failures.append("Dusk clouds should lean lavender/slate")
	var gold := SkyLook.cloud_tint(SkyLook.MOOD_GOLDEN_HOUR)
	if SkyCatalog.has_sunset():
		# The painted peach/gold sunset clouds carry their own colour.
		if gold != Color.WHITE:
			failures.append("Golden Hour tints the already-painted sunset clouds")
	elif not (gold.r > gold.g and gold.g > gold.b):
		failures.append("Golden Hour clouds should lean warm")


## Pass 4 entrance beats stay inside Brandon's ranges and are pure functions
## of time (deterministic: the same t always gives the same pose).
func _paper_pop(failures: PackedStringArray) -> void:
	var ranges := [
		# GW-AA pass 5: much slower vermin entrance, sticker placement.
		["vermin slide time", PaperPop.SLIDE_TIME, 1.4, 1.8],
		["vermin flat scale.y", PaperPop.FLAT_SCALE, 0.12, 0.18],
		["vermin flip time", PaperPop.FLIP_TIME, 0.8, 1.0],
		["vermin flip overshoot", PaperPop.FLIP_OVERSHOOT, 1.08, 1.08],
		["warden sticker total", PaperPop.placement_time(), 1.2, 1.6],
		["warden pop time", PaperPop.POP_TIME, 0.22, 0.35],
		["warden pop starts flat", PaperPop.POP_FROM, 0.12, 0.12],
		["warden pop overshoot", PaperPop.POP_OVERSHOOT, 1.12, 1.12],
		["tooltip grace", GameTooltip.GRACE, 0.4, 0.5],
		["tooltip ring fill", GameTooltip.CHARGE, 1.1, 1.3],
		["dew buildup", WardenActor.DEW_BUILDUP, 1.5, 2.5],
	]
	for r in ranges:
		if float(r[1]) < float(r[2]) - 0.0001 or float(r[1]) > float(r[3]) + 0.0001:
			failures.append("%s %.3f outside %.2f-%.2f" % r)
	if not is_equal_approx(PaperPop.entrance(0.0)["scale"].y, PaperPop.FLAT_SCALE) or PaperPop.entrance(0.0)["offset_cells"] <= 0.0:
		failures.append("vermin entrance does not start flat, right of its spot")
	if PaperPop.entrance(PaperPop.entrance_time() + 0.001)["phase"] != PaperPop.Phase.DONE:
		failures.append("vermin entrance never finishes")
	if PaperPop.entrance(0.3) != PaperPop.entrance(0.3) or PaperPop.placement(0.3) != PaperPop.placement(0.3):
		failures.append("paper beats are not deterministic")
	# Sticker order: descend (standing, lifted) -> curl (pressed 0..1) ->
	# flat -> sink -> pop; the decal shows until the pop.
	var order := []
	var last_press := -1.0
	for i in 160:
		var t := i * PaperPop.placement_time() / 160.0
		var beat := PaperPop.placement(t)
		if order.is_empty() or order[-1] != beat["phase"]:
			order.append(beat["phase"])
		if beat["phase"] == PaperPop.Phase.CURL:
			if float(beat["press"]) < last_press - 0.0001:
				failures.append("sticker press went backwards at %.2f s" % t)
			last_press = float(beat["press"])
		if bool(beat["decal"]) != (t < PaperPop.pop_start()):
			failures.append("sticker decal shows at the wrong time (%.2f s)" % t)
	var want := [PaperPop.Phase.DESCEND, PaperPop.Phase.CURL, PaperPop.Phase.FLAT, PaperPop.Phase.SINK, PaperPop.Phase.POP]
	if order != want:
		failures.append("sticker phases %s, want %s" % [order, want])
	# A curl, not a scale: mid-press the sticker has a flat part, a bent part
	# and a standing part.
	var flat_at := PaperPop.curl_point(10.0, 30.0, 12.0)
	var bend_at := PaperPop.curl_point(36.0, 30.0, 12.0)
	var stand_at := PaperPop.curl_point(80.0, 30.0, 12.0)
	if float(flat_at["angle"]) != 0.0 or not (float(bend_at["angle"]) > 0.0 and float(bend_at["angle"]) < PI * 0.5) or not is_equal_approx(float(stand_at["angle"]), PI * 0.5):
		failures.append("curl_point does not bend flat -> roll -> standing")
	if PaperPop.entrance(PaperPop.SLIDE_TIME + PaperPop.FLIP_TIME + 0.1)["phase"] != PaperPop.Phase.SETTLE:
		failures.append("vermin entrance has no settle after the flip")
	var peak := 0.0
	for i in 200:
		peak = maxf(peak, PaperPop.placement(i * PaperPop.placement_time() / 200.0)["scale"].y)
	if absf(peak - PaperPop.POP_OVERSHOOT) > 0.01:
		failures.append("warden pop peaks at %.3f" % peak)
	# The pivot transform keeps the feet planted.
	var feet := Vector2(40.0, 100.0)
	var xf := PaperPop.pivot_transform(Vector2(1.0, 0.15), -0.3, feet, Vector2.ZERO)
	if not (xf * feet).is_equal_approx(feet):
		failures.append("the flip does not pivot at the feet")
