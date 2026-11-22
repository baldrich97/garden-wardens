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
