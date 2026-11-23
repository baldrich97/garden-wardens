## Coordinator playability probe v2. Sections, each on its own
## board chosen to stay quiet under manual drive:
##  0 anim matrix — every pose base x damage state x unit resolves via AnimLibrary
##  A sandbox (level 1): needle kill loop -> dying lane -> poof/free; bark stalls
##    the wave rows; a clean row-0 bark + two grubs proves the warden dying lane
##    and tile release
##  B rain catch (level 4): auto-collect works; RAIN action clip usage reported
##  C bee (level 3): lane change happens and rise/drop clips show
##  D economy win (level 1): dew income buys late needles, WIN + banner
## Run: Godot --headless --path . --script res://tests/probes/playability_probe.gd
extends SceneTree

var _phase := 0
var _board: Node
var _ticks := 0
var _fails: PackedStringArray = []
var _missing_clips: PackedStringArray = []
var _bee_start_row := -1
var _bee_seen_lane_change := false
var _bee_seen_flight_clip := false
var _dying_snapshot: Array = []


func _make_board() -> Node:
	var packed := load("res://src/prototype/garden_board.tscn") as PackedScene
	var board := packed.instantiate()
	root.add_child(board)
	board.set_process(false)
	return board


func _process(_delta: float) -> bool:
	match _phase:
		0:
			_probe_anim_matrix()
			LevelCatalog.index = 1  # The Shell: bench has BARK, lanes leave room
			_board = _make_board()
			_dig_semantics()
			if not _board.try_place(UnitCatalog.Warden.NEEDLE, 1, 2):
				_fails.append("sandbox: needle placement refused")
			if not _board.try_place(UnitCatalog.Warden.BARK, 2, 0):
				_fails.append("sandbox: bark0 (death sandbox) placement refused")
			_board.spawn_vermin(UnitCatalog.Vermin.FLY, 2, 8.2)
			_board.start_wave()
			# second BARK waits its per-card cooldown (3.0 s) while the match runs
			_board.advance(4.0)
			if not _board.try_place(UnitCatalog.Warden.BARK, 3, 4):
				_fails.append("sandbox: bark4 placement refused (after cooldown)")
			_ticks = 0
			_phase = 1
		1:
			_board.advance(0.5)
			if len(_board._dying_vermin) > 0:
				_dying_snapshot.assign(_board._dying_vermin)
				_ticks = 0
				_phase = 2
			else:
				_ticks += 1
				if _ticks > 80:
					_fails.append("kill loop: fly never died to the needle (40 s)")
					_phase = 3
		2:
			_board.advance(0.5)
			_ticks += 1
			var stuck := 0
			for v in _dying_snapshot:
				if is_instance_valid(v):
					stuck += 1
			if stuck == 0:
				var poofs := 0
				for child in _board._lawn.get_children():
					if child is PoofActor:
						poofs += 1
				if poofs == 0:
					_fails.append("kill loop: no PoofActor ever spawned on the lawn")
				# warden death: two grubs join the wave fly already chewing bark(2,0)
				_board.spawn_vermin(UnitCatalog.Vermin.GRUB, 0, 3.2)
				_board.spawn_vermin(UnitCatalog.Vermin.GRUB, 0, 3.8)
				_ticks = 0
				_phase = 3
			elif _ticks > 20:
				_fails.append("kill loop: %d dying vermin never freed (lane stuck)" % stuck)
				_phase = 3
		3:
			_board.advance(0.5)
			_ticks += 1
			if len(_board._dying_wardens) > 0:
				_dying_snapshot.assign([_board._dying_wardens[0]])
				_ticks = 0
				_phase = 4
			elif _ticks > 240:
				_fails.append("warden death: bark never died to two grubs (120 s)")
				_phase = 5
		4:
			_board.advance(0.5)
			_ticks += 1
			if not is_instance_valid(_dying_snapshot[0]):
				_phase = 5
			elif _ticks > 20:
				_fails.append("warden death: dying warden never freed after its hold")
				_phase = 5
		5:
			# the death hold released the grid -> the tile takes a card again
			var released := false
			for _i in 12:
				if _board._grid.occupant(2, 0) == 0:
					released = true
					break
				_board.advance(0.5)
			if not released:
				_fails.append("warden death: grid never released the tile after the hold")
			_board = _rain_board()
			_phase = 6
		6:
			for _i in 14:
				_board.advance(0.5)
			_check_rain_catcher()
			_board = _bee_board()
			_board.start_wave()
			_ticks = 0
			_phase = 7
		7:
			_board.advance(0.4)
			_ticks += 1
			_scan_bee()
			if (_bee_seen_lane_change and _bee_seen_flight_clip) or _ticks > 230 or _board.result() != MatchOutcome.Result.ONGOING:
				_phase = 8
		8:
			if not _bee_seen_lane_change:
				_fails.append("bee: never changed lane within 90 s of wave time")
			if not _bee_seen_flight_clip:
				_fails.append("bee: never showed a rise/drop clip on a lane change")
			_board = _win_board()
			_phase = 9
		9:
			for _i in 240:
				if _board.result() != MatchOutcome.Result.ONGOING:
					break
				_win_grind()
			_phase = 10
		10:
			if _board.result() != MatchOutcome.Result.WON:
				_fails.append("economy win: greedy dew->needle play did not WIN (result %d)" % _board.result())
			else:
				var banner := _board.find_child("WinBanner", true, false)
				if banner == null or not banner.visible:
					_fails.append("economy win: WIN but WinBanner not visible")
			_finish()
			return true
	return false


# ---------- sections ----------

func _probe_anim_matrix() -> void:
	var warden_bases := ["place", "idle", "action", "hurt", "death"]
	var vermin_bases := ["spawn", "move", "idle", "action", "hurt", "death"]
	for kind in UnitCatalog.Warden.size():
		var frames := AnimLibrary.warden(kind)
		var folder := AnimLibrary.warden_folder(kind)
		if AnimLibrary.manifest_for_folder(folder).is_empty():
			_missing_clips.append("WARDEN %s still on LEGACY clips" % folder)
		for base in warden_bases:
			for state in AnimLibrary.DAMAGE_STATES:
				if AnimLibrary.animation_name(frames, base, state).is_empty():
					_missing_clips.append("%s %s_%s" % [folder, base, state])
	for kind in UnitCatalog.Vermin.size():
		var frames := AnimLibrary.vermin(kind)
		var folder := AnimLibrary.vermin_folder(kind)
		if AnimLibrary.manifest_for_folder(folder).is_empty():
			_missing_clips.append("VERMIN %s still on LEGACY clips" % folder)
		for base in vermin_bases:
			for state in AnimLibrary.DAMAGE_STATES:
				if AnimLibrary.animation_name(frames, base, state).is_empty():
					_missing_clips.append("%s %s_%s" % [folder, base, state])
		if kind == UnitCatalog.Vermin.BEE:
			for base in ["rise", "drop"]:
				if AnimLibrary.animation_name(frames, base, "100").is_empty():
					_missing_clips.append("%s %s_100" % [folder, base])
		if kind == UnitCatalog.Vermin.LADYBUG:
			for base in ["flutter_takeoff", "flutter_air", "flutter_land"]:
				if AnimLibrary.animation_name(frames, base, "100").is_empty():
					_missing_clips.append("%s %s_100" % [folder, base])
	if AnimLibrary.poof() == null:
		_missing_clips.append("POOF clips missing")


func _dig_semantics() -> void:
	var board := _make_board()  # disposable board; keeps sandbox water exact
	var w0: int = board.water_amount()
	if not board.try_place(UnitCatalog.Warden.DEW, 0, 4):
		_fails.append("dig section: dew placement refused")
		return
	if not board.dig(0, 4):
		_fails.append("dig refused a planted tile")
	if board.water_amount() != w0 - UnitCatalog.WARDEN_COST[UnitCatalog.Warden.DEW]:
		print("NOTE: dig refund observed: water %d vs no-refund expectation %d" % [board.water_amount(), w0 - UnitCatalog.WARDEN_COST[UnitCatalog.Warden.DEW]])
	# same tile right after a dig takes ANY card (grid released instantly); the
	# same KIND is gated by its per-card cooldown (game rule, not a bug).
	if not board.try_place(UnitCatalog.Warden.BARK, 0, 4):
		_fails.append("dig section: dug tile rejected even a fresh card (grid release bug)")


func _rain_board() -> Node:
	LevelCatalog.index = 3
	var board := _make_board()
	board.try_place(UnitCatalog.Warden.RAIN, 3, 1)
	board.start_wave()
	return board


func _check_rain_catcher() -> void:
	var rain_alive := false
	for warden in _board._wardens:
		if warden.kind == UnitCatalog.Warden.RAIN:
			rain_alive = true
	if not rain_alive:
		_fails.append("rain catcher died within 7 s of wave start (playability risk)")
		return
	var w0: int = _board.water_amount()
	_board.spawn_test_drop(2.5, 1.0)
	for _i in 14:
		_board.advance(0.5)
	if _board.water_amount() <= w0:
		_fails.append("rain catcher never auto-collected an adjacent landed drop")
	for warden in _board._wardens:
		if warden.kind == UnitCatalog.Warden.RAIN:
			var shown: String = warden._clip.animation_name()
			print("RAIN_ACTION_CLIP: showing '%s' after catches" % shown)


func _bee_board() -> Node:
	LevelCatalog.index = 2
	var board := _make_board()
	return board


func _scan_bee() -> void:
	for v in _board._vermin:
		if v.kind != UnitCatalog.Vermin.BEE:
			continue
		var row: int = v.row
		if _bee_start_row == -1:
			_bee_start_row = row
		elif row != _bee_start_row:
			_bee_seen_lane_change = true
		var clip: String = v._clip.animation_name()
		if clip.contains("rise") or clip.contains("drop"):
			_bee_seen_flight_clip = true


func _win_board() -> Node:
	LevelCatalog.index = 0
	var board := _make_board()
	board.try_place(UnitCatalog.Warden.NEEDLE, 1, 2)
	board.try_place(UnitCatalog.Warden.DEW, 0, 0)
	board.try_place(UnitCatalog.Warden.BARK, 3, 1)
	board.start_wave()
	return board


func _win_grind() -> void:
	for drop in _board._drops.duplicate():
		if is_instance_valid(drop):
			drop.collect()
	var cost := UnitCatalog.WARDEN_COST[UnitCatalog.Warden.NEEDLE]
	if _board.water_amount() >= cost:
		for row in [3, 1, 4, 0]:
			if _board.try_place(UnitCatalog.Warden.NEEDLE, 1, row):
				break
	_board.advance(1.0)


func _finish() -> void:
	for m in _missing_clips:
		print("MISSING_CLIP: ", m)
	if _fails.is_empty():
		print("PLAYABILITY_PROBE_OK (missing-clip count: %d)" % _missing_clips.size())
		quit(0)
	else:
		for f in _fails:
			print("PLAY_FAIL: ", f)
		quit(1)
