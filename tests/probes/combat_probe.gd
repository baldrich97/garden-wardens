## Coordinator combat verification probe. Proves, by live
## damage observation only (no catalog trust):
##  A. every vermin kind attacks and damages plants (measured chew dps vs catalog)
##     — ladybug chews a DEW (it HOPS over cones by design, so bark would never chew)
##  B. Needle Spitter single-target damage per hit and a real kill
##  C. Seed Lobber area damage: same-tick damage on multiple distinct vermin
## Run: Godot --headless --path . --script res://tests/probes/combat_probe.gd
extends SceneTree

var _phase := 0
var _board: Node
var _ticks := 0
var _fails: PackedStringArray = []
var _notes: PackedStringArray = []

# chew test state
var _chew_kind := 0
var _chew_target: Node
var _chew_vermin: Array = []
var _hp0 := 0
var _chew_started := -1.0
var _chew_stopped := false
var _last_t := 0.0

# needle test state
var _needle_fly: Node
var _needle_first_hit := -1.0
var _needle_dmg := 0
var _needle_killed := false

# lobber test state
var _lob_tracked: Array = []
var _lob_prev_hp: Dictionary = {}
var _lob_multi_events := 0
var _lob_single_events := 0


## Every board in this probe replays one match seed, so the bee's wander, the
## seed volleys, sky drops, and grub rolls are identical run to run.
const PROBE_SEED := 4242


func _make_board(level: int) -> Node:
	GardenBoard.forced_match_seed = PROBE_SEED
	LevelCatalog.index = level
	var packed := load("res://src/prototype/garden_board.tscn") as PackedScene
	var board := packed.instantiate()
	root.add_child(board)
	board.set_process(false)
	return board


func _free_board() -> void:
	if _board != null:
		root.remove_child(_board)
		_board.queue_free()
		_board = null


## spawn_vermin is void; capture the fresh actor by diffing _vermin.
func _spawn_capture(kind: int, row: int, column_pos: float) -> Node:
	var before := {}
	for v in _board._vermin:
		before[v.get_instance_id()] = true
	_board.spawn_vermin(kind, row, column_pos)
	for v in _board._vermin:
		if not before.has(v.get_instance_id()):
			return v
	return null


func _process(_delta: float) -> bool:
	match _phase:
		0:
			_start_chew_test()
		1:
			_tick_chew(0.25)
		2:
			_start_needle_test()
		3:
			_tick_needle(0.25)
		4:
			_start_lob_test()
		5:
			_tick_lob(0.25)
		6:
			_finish()
			return true
	return false


# ---------- A. chew matrix ----------

func _start_chew_test() -> void:
	_free_board()
	_chew_target = null
	_chew_vermin.clear()
	_board = _make_board(0)  # First Row: lanes 1/3 openers at t=16, row 0 quiet
	var target_kind: int = UnitCatalog.Warden.BARK
	if _chew_kind == UnitCatalog.Vermin.LADYBUG:
		target_kind = UnitCatalog.Warden.DEW  # ladybugs hop cones by design
	if not _board.try_place(target_kind, 2, 0):
		_fails.append("chew: target placement refused")
		return
	_chew_target = null
	for warden in _board._wardens:
		if warden.row == 0:
			_chew_target = warden
	if _chew_target == null:
		_fails.append("chew: target actor not found")
		_phase = 2
		return
	_hp0 = _chew_target.hp
	var spawn_column := 4.0 if _chew_kind != UnitCatalog.Vermin.SNAIL else 5.0
	_board.spawn_vermin(_chew_kind, 0, spawn_column)
	_board.start_wave()
	_chew_started = -1.0
	_chew_stopped = false
	_ticks = 0
	_last_t = 0.0
	_phase = 1


func _tick_chew(step: float) -> void:
	var limit := 60 if _chew_kind == UnitCatalog.Vermin.BEE else 45
	var cap := 240 if _chew_kind == UnitCatalog.Vermin.BEE else 120
	for _i in cap:
		if _board.result() != MatchOutcome.Result.ONGOING or _ticks * step > limit:
			break
		_board.advance(step)
		_ticks += 1
		_last_t = _ticks * step
		if _chew_target != null and is_instance_valid(_chew_target):
			if _chew_target.hp < _hp0 and _chew_started < 0.0:
				_chew_started = _last_t
			if _chew_target.hp <= 0:
				_chew_stopped = true
				break
		elif not _chew_stopped:
			_chew_stopped = true
			break
	# bee may wander off row 0; give it second chances with fresh bees
	if _chew_kind == UnitCatalog.Vermin.BEE and _chew_started < 0.0 and _ticks * step > 12.0 \
			and _ticks * step < 55.0 and _ticks % 16 == 0:
		_board.spawn_vermin(UnitCatalog.Vermin.BEE, 0, 3.4)
	if _chew_started >= 0.0:
		var hp_now: int = 0
		if _chew_target != null and is_instance_valid(_chew_target):
			hp_now = maxi(0, _chew_target.hp)
		var span: float = maxf(0.5, _last_t - _chew_started)
		var dps := float(_hp0 - hp_now) / span
		var catalog := UnitCatalog.VERMIN_CHEW[_chew_kind]
		var flag := "ok" if dps > catalog * 0.5 else "LOW?"
		_notes.append("chew %s: first damage at %.2fs, measured %.1f dps vs catalog %.1f (%s%s)" % [
			UnitCatalog.VERMIN_NAMES[_chew_kind], _chew_started, dps, catalog, flag,
			", plant killed" if _chew_stopped and hp_now == 0 else "",
		])
		if dps <= catalog * 0.5:
			_fails.append("chew %s never applied real damage (dps %.1f)" % [
				UnitCatalog.VERMIN_NAMES[_chew_kind], dps])
	elif not _chew_stopped:
		_fails.append("chew %s: target never took damage (t=%.0fs, board result %d)" % [
			UnitCatalog.VERMIN_NAMES[_chew_kind], _last_t, _board.result()])
	elif _chew_stopped and _chew_started < 0.0:
		_notes.append("chew %s: target vanished before first sampled damage (board result %d)" % [
			UnitCatalog.VERMIN_NAMES[_chew_kind], _board.result()])
	_chew_kind += 1
	if _chew_kind < UnitCatalog.Vermin.size():
		_phase = 0
	else:
		_phase = 2


# ---------- B. needle single-target ----------

func _start_needle_test() -> void:
	_free_board()
	_board = _make_board(0)
	if not _board.try_place(UnitCatalog.Warden.NEEDLE, 1, 2):
		_fails.append("needle: placement refused")
		_phase = 4
		return
	_board.start_wave()
	_needle_fly = _spawn_capture(UnitCatalog.Vermin.FLY, 2, 8.4)
	_needle_first_hit = -1.0
	_needle_dmg = 0
	_needle_killed = false
	_ticks = 0
	_phase = 3


func _tick_needle(step: float) -> void:
	for _i in 200:
		if _board.result() != MatchOutcome.Result.ONGOING:
			break
		_board.advance(step)
		_ticks += 1
		if _ticks % 8 == 0 and _needle_fly != null and is_instance_valid(_needle_fly):
			_notes.append("needle_watch t=%.1f fly hp=%d col=%.2f row=%d result=%d" % [
				_ticks * step, _needle_fly.hp, _needle_fly.column_pos, _needle_fly.row, _board.result()])
		if _needle_fly != null and is_instance_valid(_needle_fly):
			var hp: int = _needle_fly.hp
			if _needle_first_hit < 0.0 and hp < UnitCatalog.VERMIN_HP[UnitCatalog.Vermin.FLY]:
				_needle_first_hit = _ticks * step
				_needle_dmg = UnitCatalog.VERMIN_HP[UnitCatalog.Vermin.FLY] - hp
			if hp <= 0:
				_needle_killed = true  # queue_free only lands at frame end; hp<=0 is the kill
				break
	if _needle_dmg != UnitCatalog.NEEDLE_DAMAGE:
		_fails.append("needle: first hit dealt %d dmg, expected %d" % [_needle_dmg, UnitCatalog.NEEDLE_DAMAGE])
	if not _needle_killed:
		_fails.append("needle: fly never died")
	_notes.append("needle: first hit %d dmg at %.2fs, fly (45 hp) killed=%s" % [
		_needle_dmg, _needle_first_hit, "yes" if _needle_killed else "NO"])
	_phase = 4


# ---------- C. lobber area damage ----------

func _start_lob_test() -> void:
	_free_board()
	_lob_tracked.clear()
	_lob_prev_hp.clear()
	_lob_multi_events = 0
	_lob_single_events = 0
	_board = _make_board(4)  # Seed Storm, 300 water, bench has SEED
	if not _board.try_place(UnitCatalog.Warden.SEED, 1, 0):
		_fails.append("lob: seed lobber placement refused")
		_phase = 6
		return
	if not _board.try_place(UnitCatalog.Warden.BARK, 2, 0):
		_fails.append("lob: bark shield placement refused")
	_board.start_wave()
	for spot in [Vector2(6.2, 0), Vector2(6.2, 1), Vector2(6.2, 2), Vector2(7.2, 0), Vector2(7.2, 1)]:
		var fly := _spawn_capture(UnitCatalog.Vermin.FLY, int(spot.y), spot.x)
		if fly != null:
			_lob_tracked.append(fly)
			_lob_prev_hp[fly.get_instance_id()] = fly.hp
	_ticks = 0
	_phase = 5


func _tick_lob(step: float) -> void:
	for _i in 140:
		if _board.result() != MatchOutcome.Result.ONGOING or _ticks * step > 34.0:
			break
		_board.advance(step)
		_ticks += 1
		var hits_this_tick := 0
		for fly in _lob_tracked:
			if not is_instance_valid(fly):
				continue
			var id: int = fly.get_instance_id()
			var hp: int = maxi(0, fly.hp)
			if hp < int(_lob_prev_hp.get(id, hp)):
				hits_this_tick += 1
			_lob_prev_hp[id] = hp
		if hits_this_tick >= 2:
			_lob_multi_events += 1
		elif hits_this_tick == 1:
			_lob_single_events += 1
	if _lob_multi_events == 0:
		_fails.append("lob: no burst ever damaged 2+ vermin on different tiles (multi=%d single=%d)" % [
			_lob_multi_events, _lob_single_events])
	if _lob_single_events + _lob_multi_events == 0:
		_fails.append("lob: seed volley never damaged any tracked vermin")
	_notes.append("lobber: %d multi-target burst ticks, %d single-target ticks over %.0fs" % [
		_lob_multi_events, _lob_single_events, _ticks * step])
	_phase = 6


func _finish() -> void:
	_free_board()
	for n in _notes:
		print("COMBAT_NOTE: ", n)
	if _fails.is_empty():
		print("COMBAT_PROBE_OK")
		quit(0)
	else:
		for f in _fails:
			print("COMBAT_FAIL: ", f)
		quit(1)
