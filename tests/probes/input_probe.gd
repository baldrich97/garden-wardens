## GW-P3 synthetic-input playtest (test harness, never shipped).
##
## Loads the real res://src/prototype/garden_board.tscn under this driver and
## plays it end to end using ONLY synthetic events fed through
## Input.parse_input_event() with real process_frame pacing. This file never
## calls advance(), try_place(), dig(), collect(), or spawn_* — inspection is
## strictly reading nodes/properties. Prints STEP_OK/STEP_FAIL per step and
## ends with INPUT_PROBE_OK + quit(0), or a FAIL list + quit(1).
##
## Run WINDOWED (the animation clock and viewport picking need real frames;
## this host has no xvfb, a brief visible window is expected):
##   tools/godot/Godot_v4.6-stable_win64.exe --path . res://tests/probes/input_probe.tscn
extends Control

const DEW := 0
const NEEDLE := 1
## Level 1 "First Row": 200 water, cards Dew/Needle/Bark; wave = FLY row 2 at
## 4 s, FLY row 2 at 10 s, FLY row 1 + FLY row 3 at 16 s. Cells are chosen so
## nothing collides: hover/place/dig at (5,0), dropper at (3,4), keyboard
## plant at (1,2) (default aim (0,2) + one ui_right), chew bait at (8,1).
const HOVER_CELL := Vector2i(5, 0)
const DROPPER_CELL := Vector2i(3, 4)
const KEY_CELL := Vector2i(1, 2)
const VICTIM_CELL := Vector2i(8, 1)
## Parking spot on the bottom bar — jumps (no sweep) keep waits clean of
## accidental hover-collects on the lawn.
const PARK := Vector2(640.0, 706.0)

var _board: Node
var _last_mouse := Vector2.ZERO
var _fails: PackedStringArray = []
var _deadline_ms := 0

# Step 9 evidence: placement must not auto-start; Start came from the button.
var _started_at_first_place := true
# Step 10 sampler state (all times in match-seconds unless noted).
var _watching := false
var _spawn_seen := -1.0
var _spawn_detail := ""
var _action_seen := -1.0
var _action_detail := ""
var _victim: Node = null
var _victim_damage_t := -1.0
var _victim_hurt_t := -1.0
var _victim_hurt_seen := false
var _victim_suffixes: Dictionary = {}
var _hp_last: Dictionary = {}
var _kills: Dictionary = {}
var _kill_order: Array = []
var _shots_ever := false
var _watch_abort := ""
# Click-collect path discriminators (step 6).
var _enter_hits := 0
var _gui_hits := 0


func _observe_drop_press(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_gui_hits += 1


func _ready() -> void:
	var board_scene := load("res://src/prototype/garden_board.tscn") as PackedScene
	assert(board_scene != null)
	_board = board_scene.instantiate()
	add_child(_board)
	# The viewport refuses to dispatch mouse MOTION to controls until it believes the
	# pointer is inside the window (gui.mouse_in_viewport — an OS window-enter fact a
	# synthetic pointer never earns). Window activation churn can post an EXIT after
	# this line, so _move/_btn_at re-assert ENTER before every mouse event.
	get_window().notify_mouse_entered()
	_deadline_ms = Time.get_ticks_msec() + 240000
	_run()


# ---------- driver ----------

func _run() -> void:
	var vp := get_viewport_rect().size
	print("PROBE viewport=%s content_scale=%s" % [vp, get_window().content_scale_mode])
	if not await _wait_until(180, func() -> bool: return _lawn() != null and _lawn().size.x > 200.0 and _lawn().cell_size_px() > 8.0):
		_finish("lawn never laid out")
		return
	print("PROBE lawn=%s cell=%.1f" % [_lawn().size, _lawn().cell_size_px()])
	var results: Array[bool] = []
	results.append(await _step1_select_card())
	results.append(await _step2_ghost())
	results.append(await _step3_click_place())
	results.append(await _step4_remove())
	results.append(await _step5_right_click())
	results.append(await _step6_start_and_drops())
	results.append(await _step7_keyboard())
	results.append(await _step8_pause())
	results.append(await _step9_wave_start())
	results.append(await _step10_combat_animations())
	_finish("")


func _finish(abort: String) -> void:
	if not abort.is_empty():
		_fails.append(abort)
	if _fails.is_empty():
		print("INPUT_PROBE_OK")
		get_tree().quit(0)
	else:
		for f in _fails:
			print("PROBE_FAIL: ", f)
		get_tree().quit(1)


func _step_pass(index: int, label: String, detail: String) -> void:
	print("STEP_OK %d %s — %s" % [index, label, detail])


func _step_fail(index: int, label: String, detail: String) -> bool:
	print("STEP_FAIL %d %s — %s" % [index, label, detail])
	_fails.append("step %d %s: %s" % [index, label, detail])
	return false


# ---------- input synthesis (the only way this file touches the game) ----------

func _move(p: Vector2) -> void:
	get_window().notify_mouse_entered()
	var ev := InputEventMouseMotion.new()
	ev.position = p
	ev.global_position = p
	ev.relative = p - _last_mouse
	_last_mouse = p
	Input.parse_input_event(ev)
	await get_tree().process_frame


func _btn_at(p: Vector2, button: int, pressed: bool) -> void:
	get_window().notify_mouse_entered()
	var ev := InputEventMouseButton.new()
	ev.position = p
	ev.global_position = p
	ev.button_index = button
	ev.pressed = pressed
	ev.button_mask = (1 << (button - 1)) if pressed else 0
	Input.parse_input_event(ev)
	await get_tree().process_frame


func _tap(p: Vector2, button: int = MOUSE_BUTTON_LEFT) -> void:
	await _move(p)
	await _btn_at(p, button, true)
	# Real frame between press and release: Input.parse_input_event flushes its whole
	# queue in one call, and a same-flush release would beat the press into the GUI
	# stack and get dropped before mouse_focus is armed (card clicks would never toggle).
	await get_tree().process_frame
	await _btn_at(p, button, false)


func _key(keycode: Key) -> void:
	var down := InputEventKey.new()
	down.keycode = keycode
	down.physical_keycode = keycode
	down.pressed = true
	Input.parse_input_event(down)
	await get_tree().process_frame
	var up := down.duplicate() as InputEventKey
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame


# ---------- state reads (never writes, never gameplay calls) ----------

func _lawn() -> Control:
	return _board.get("_lawn") as Control


func _bottom() -> Node:
	return _board.get("_bottom")


func _cards() -> Array:
	return _bottom().cards()


func _by_name(who: String) -> Node:
	return _board.find_child(who, true, false)


func _water() -> int:
	return _board.water_amount()


func _wardens() -> Array:
	return _board.get("_wardens")


func _time() -> float:
	return _board.get("_time")


func _tile_center(cell: Vector2i) -> Vector2:
	var lawn := _lawn()
	return lawn.global_position + lawn.grid_origin() + (Vector2(cell) + Vector2(0.5, 0.5)) * lawn.cell_size_px()


func _center_of(node: Node) -> Vector2:
	return (node as Control).get_global_rect().get_center()


func _clip_of(actor: Node) -> ClipView:
	for child in actor.get_children():
		if child is ClipView:
			return child as ClipView
	return null


func _anim_name(actor: Node) -> String:
	var clip := _clip_of(actor)
	return "" if clip == null else clip.animation_name()


func _warden_at(cell: Vector2i) -> Node:
	for warden in _wardens():
		if warden.column == cell.x and warden.row == cell.y:
			return warden
	return null


func _victim_tile_clear() -> bool:
	var point := _tile_center(VICTIM_CELL)
	for drop in _board.get("_drops"):
		if is_instance_valid(drop) and not drop.falling and drop.get_global_rect().has_point(point):
			return false
	return true


func _landed_drop_on_dropper() -> Node:
	for drop in _board.get("_drops"):
		if is_instance_valid(drop) and not drop.falling \
				and absf(drop.column_pos - (float(DROPPER_CELL.x) + 0.85)) < 0.05 \
				and int(drop.row_pos) == DROPPER_CELL.y:
			return drop
	return null


func _result() -> int:
	return _board.get("_result")


# ---------- waits (every frame pumped through the sampler) ----------

func _wait_until(max_frames: int, cond: Callable) -> bool:
	for _i in max_frames:
		_sample()
		if cond.call():
			return true
		if Time.get_ticks_msec() > _deadline_ms:
			return false
		await get_tree().process_frame
	_sample()
	return cond.call()


## Continuous observers, run every frame once the wave exists: spawn clip,
## chew action clip, victim hurt + damage-state suffixes, kill -> death clip
## -> PoofActor -> actor freed, plus the match-result guard.
func _sample() -> void:
	if _result() != MatchOutcome.Result.ONGOING and _watch_abort.is_empty():
		_watch_abort = "match ended (result=%d)" % _result()
	if not _watching:
		return
	var t: float = _time()
	for v in _board.get("_vermin"):
		if not is_instance_valid(v):
			continue
		_hp_last[v] = v.hp
		var nm := _anim_name(v)
		if _spawn_seen < 0.0 and nm.begins_with("spawn"):
			_spawn_seen = t
			_spawn_detail = "%s at t=%.2f (clip %s)" % [UnitCatalog.VERMIN_NAMES[v.kind], t, nm]
		if _action_seen < 0.0 and nm.begins_with("action"):
			_action_seen = t
			_action_detail = "%s row %d at t=%.2f (clip %s)" % [UnitCatalog.VERMIN_NAMES[v.kind], v.row, t, nm]
	for v in _board.get("_dying_vermin"):
		if is_instance_valid(v) and not _kills.has(v):
			var hp_before: int = _hp_last.get(v, 0)
			_kills[v] = {"hp_before": hp_before, "row": v.row, "kind": v.kind,
					"death_t": -1.0, "poof_t": -1.0, "free_t": -1.0, "closed": false}
			_kill_order.append(v)
	if not _kill_order.is_empty():
		var poof_now := false
		for child in _lawn().get_children():
			if child is PoofActor:
				poof_now = true
				break
		for v in _kill_order:
			var entry: Dictionary = _kills[v]
			if entry.closed:
				continue
			if is_instance_valid(v):
				if entry.death_t < 0.0 and _anim_name(v).begins_with("death"):
					entry.death_t = t
				if entry.death_t >= 0.0 and entry.poof_t < 0.0 and poof_now:
					entry.poof_t = t
			else:
				if entry.poof_t < 0.0 and poof_now:
					entry.poof_t = t
				entry.free_t = t
				entry.closed = true
	if _shots_ever == false and not (_board.get("_shots") as Array).is_empty():
		_shots_ever = true
	if _victim != null and is_instance_valid(_victim):
		if _victim_damage_t < 0.0 and _victim.hp < _victim.max_hp:
			_victim_damage_t = t
		var vnm := _anim_name(_victim)
		if vnm.begins_with("hurt"):
			_victim_hurt_seen = true
			if _victim_hurt_t < 0.0:
				_victim_hurt_t = t
			for suffix in ["100", "66", "33"]:
				if vnm.ends_with("_" + suffix):
					_victim_suffixes[suffix] = t


# ---------- steps ----------

func _step1_select_card() -> bool:
	var label := "click Dew Dropper card selects it"
	if _water() != 200:
		return _step_fail(1, label, "expected 200 water at match start, saw %d" % _water())
	var card: Node = _cards()[DEW]
	if card.kind != DEW:
		return _step_fail(1, label, "first bench card is kind %d, not DEW" % card.kind)
	await _tap(_center_of(card))
	await get_tree().process_frame
	if int(_board.get("_selected")) != DEW or not card.is_selected():
		return _step_fail(1, label, "_selected=%s card_selected=%s after click" \
				% [_board.get("_selected"), card.is_selected()])
	_step_pass(1, label, "press+release on card center selected bench slot 1 (DEW)")
	return true


func _step2_ghost() -> bool:
	var label := "hover empty tile shows ghost + highlight"
	await _move(_tile_center(HOVER_CELL))
	var ok := await _wait_until(8, func() -> bool: return _ghost_live())
	if not ok:
		return _step_fail(2, label, "hover=%s mouse_over_lawn=%s ghost=%s cursor=%s allowed=%s" % [
				_lawn().get("_aim"), _board.get("_mouse_over_lawn"), (_board.get("_ghost") as Node).visible,
				(_lawn().get("_cursor") as Node).visible, _lawn().get("_aim_allowed")])
	await _shot("gw_p3_ghost.png")
	_step_pass(2, label, "ghost + green aim cursor on %s, _aim_allowed=true" % HOVER_CELL)
	return true


func _ghost_live() -> bool:
	return _lawn().get("_aim") == HOVER_CELL and bool(_board.get("_mouse_over_lawn")) \
			and (_board.get("_ghost") as Node).visible and bool(_lawn().get("_aim_allowed")) \
			and (_lawn().get("_cursor") as Node).visible


func _step3_click_place() -> bool:
	var label := "click tile plants, place clip then idle"
	var before := _water()
	var center := _tile_center(HOVER_CELL)
	await _btn_at(center, MOUSE_BUTTON_LEFT, true)
	_started_at_first_place = bool(_board.get("_started"))
	var actor := _warden_at(HOVER_CELL)
	if actor == null or actor.kind != DEW:
		return _step_fail(3, label, "no DEW warden at %s after click (wardens=%d)" % [HOVER_CELL, _wardens().size()])
	if _water() != before - UnitCatalog.WARDEN_COST[DEW]:
		return _step_fail(3, label, "water %d after placing a %d-cost warden" % [_water(), UnitCatalog.WARDEN_COST[DEW]])
	if _started_at_first_place:
		return _step_fail(3, label, "board auto-started on the first placement")
	var place_ok := await _wait_until(30, func() -> bool: return _anim_name(actor).begins_with("place"))
	if not place_ok:
		return _step_fail(3, label, "clip never showed place* within 30 frames (showing '%s')" % _anim_name(actor))
	await _shot("gw_p3_placed.png")
	var ok_idle := await _wait_until(120, func() -> bool: return _anim_name(actor).begins_with("idle"))
	if not ok_idle:
		return _step_fail(3, label, "place clip did not hand back to idle within the authored hold (showing '%s')" % _anim_name(actor))
	_step_pass(3, label, "water %d->%d, actor at %s played place then idle (clip '%s'); _started stayed false" \
			% [before, _water(), HOVER_CELL, _anim_name(actor)])
	return true


func _step4_remove() -> bool:
	var label := "Remove button + tile click digs the tile"
	var actor := _warden_at(HOVER_CELL)
	if actor == null:
		return _step_fail(4, label, "nothing planted at %s to dig" % HOVER_CELL)
	await _tap(_center_of(_bottom().find_child("RemoveButton", true, false)))
	if not bool(_board.get("_removing")):
		return _step_fail(4, label, "_removing false after clicking the Remove button")
	await _tap(_tile_center(HOVER_CELL))
	await get_tree().process_frame
	if bool(_board.get("_removing")):
		return _step_fail(4, label, "_removing still on after the dig")
	if (_board.get("_grid")).occupant(HOVER_CELL.x, HOVER_CELL.y) != 0:
		return _step_fail(4, label, "grid still occupied at %s" % HOVER_CELL)
	await get_tree().process_frame
	if is_instance_valid(actor):
		return _step_fail(4, label, "dug actor was not freed within two frames")
	_step_pass(4, label, "actor freed, grid cell empty, removing mode auto-cleared")
	return true


func _step5_right_click() -> bool:
	var label := "right-click clears the selection"
	await _tap(_center_of(_cards()[DEW]))
	if int(_board.get("_selected")) != DEW:
		return _step_fail(5, label, "setup: card click did not select (selected=%s)" % _board.get("_selected"))
	await _tap(_tile_center(HOVER_CELL), MOUSE_BUTTON_RIGHT)
	if int(_board.get("_selected")) != -1 or bool(_board.get("_removing")):
		return _step_fail(5, label, "selected=%s removing=%s after right-click (press_card=%s dragging=%s hover=%s)" \
				% [_board.get("_selected"), _board.get("_removing"), _board.get("_press_card"), _board.get("_dragging"), _board.get("_hover")])
	_step_pass(5, label, "selection -1 after right-click over the lawn")
	return true


func _step6_start_and_drops() -> bool:
	var label := "Start button runs the wave; dew hover-collects and click-collects"
	_watching = true
	await _tap(_center_of(_by_name("StartButton")))
	if not bool(_board.get("_started")):
		return _step_fail(6, label, "_started still false after clicking StartButton")
	# The dew cooldown froze with the clock before Start; a human waits it out.
	if not await _wait_until(420, func() -> bool: return (_board.get("_cooldowns")[DEW]).is_ready()):
		return _step_fail(6, label, "dew card cooldown never came off (420 frames)")
	var before := _water()
	if int(_board.get("_selected")) != DEW:
		await _tap(_center_of(_cards()[DEW]))
	await _tap(_tile_center(DROPPER_CELL))
	if _warden_at(DROPPER_CELL) == null or _water() != before - UnitCatalog.WARDEN_COST[DEW]:
		return _step_fail(6, label, "dropper not planted at %s (water %d, was %d, selected=%s removing=%s cooling=%s)" % [
				DROPPER_CELL, _water(), before, _board.get("_selected"), _board.get("_removing"),
				(_board.get("_cooldowns")[DEW]).remaining])
	await _move(PARK)
	# First droplet: hover it. Prove the water moves on the MOTION event.
	if not await _wait_until(500, func() -> bool: return _landed_drop_on_dropper() != null):
		return _step_fail(6, label, "no dew drop landed on the dropper tile within 500 frames")
	var drop: Node = _landed_drop_on_dropper()
	var drop_center := _center_of(drop)
	var w0 := _water()
	await _move(drop_center + Vector2(70.0, 0.0))
	await get_tree().process_frame
	if _water() != w0 or not is_instance_valid(drop):
		return _step_fail(6, label, "water moved before hovering the drop (%d vs %d)" % [_water(), w0])
	await _move(drop_center)
	var hovered := await _wait_until(3, func() -> bool: return _water() == w0 + UnitCatalog.DEW_AMOUNT)
	if not hovered:
		return _step_fail(6, label, "hovering the drop did not collect (water %d, expected %d)" % [_water(), w0 + UnitCatalog.DEW_AMOUNT])
	# Second droplet: click it. No motion is sent first — the press itself is
	# the only event that can reach the drop, so a collect there is the
	# _on_gui_input click path. Observers record which handler saw what.
	await _move(PARK)
	var drop2_center := Vector2.INF
	var found2 := false
	for _frame in 500:
		await get_tree().process_frame
		var d: Node = _landed_drop_on_dropper()
		if d != null:
			drop2_center = _center_of(d)
			_enter_hits = 0
			_gui_hits = 0
			d.mouse_entered.connect(func() -> void: _enter_hits += 1)
			d.gui_input.connect(_observe_drop_press)
			found2 = true
			break
	if not found2:
		return _step_fail(6, label, "second dew drop never landed within 500 frames")
	var w1 := _water()
	await _btn_at(drop2_center, MOUSE_BUTTON_LEFT, true)
	var clicked := await _wait_until(3, func() -> bool: return _water() == w1 + UnitCatalog.DEW_AMOUNT)
	await _btn_at(drop2_center, MOUSE_BUTTON_LEFT, false)
	await _move(PARK)
	if not clicked:
		return _step_fail(6, label, "click on the drop did not collect (water %d, expected %d)" % [_water(), w1 + UnitCatalog.DEW_AMOUNT])
	_step_pass(6, label, "wave started via StartButton; drop1 hover-collect +%d, drop2 collected by the press itself (gui_input hits=%d, mouse_entered hits=%d)" \
			% [UnitCatalog.DEW_AMOUNT, _gui_hits, _enter_hits])
	return true


func _step7_keyboard() -> bool:
	var label := "select_slot_2 + ui_right + ui_accept plants; F7 toggles the pill"
	var before := _water()
	await _key(KEY_2)
	if int(_board.get("_selected")) != NEEDLE:
		return _step_fail(7, label, "select_slot_2 did not select slot 2 (selected=%s)" % _board.get("_selected"))
	await _key(KEY_RIGHT)
	var aim: Vector2i = _board.get("_key_aim")
	if not bool(_board.get("_aim_from_keys")) or aim != KEY_CELL:
		return _step_fail(7, label, "ui_right moved aim to %s (from_keys=%s)" % [aim, _board.get("_aim_from_keys")])
	await _key(KEY_ENTER)
	var actor := _warden_at(KEY_CELL)
	if actor == null or actor.kind != NEEDLE:
		return _step_fail(7, label, "ui_accept placed nothing at %s (water %d)" % [KEY_CELL, _water()])
	if _water() != before - UnitCatalog.WARDEN_COST[NEEDLE]:
		return _step_fail(7, label, "water %d, expected %d after the keyboard plant" % [_water(), before - UnitCatalog.WARDEN_COST[NEEDLE]])
	var pill: Node = _board.get("_seed_panel")
	await _key(KEY_F7)
	if not bool(_board.get("_debug_overlay")) or not pill.visible:
		return _step_fail(7, label, "F7 did not show the seed pill")
	await _key(KEY_F7)
	if bool(_board.get("_debug_overlay")) or pill.visible:
		return _step_fail(7, label, "second F7 did not hide the seed pill")
	_step_pass(7, label, "Needle planted at %s via keys (water %d->%d); pill toggles both ways" % [KEY_CELL, before, _water()])
	return true


func _step8_pause() -> bool:
	var label := "Pause freezes the match clock; un-pause resumes it"
	await _tap(_center_of(_by_name("PauseButton")))
	if not bool(_board.get("_paused")):
		return _step_fail(8, label, "_paused false after clicking Pause")
	var t0 := _time()
	await _wait_until(30, func() -> bool: return false)  # pump 30 frames through the sampler
	var t1 := _time()
	if t1 != t0:
		return _step_fail(8, label, "clock ran while paused (%.3f -> %.3f)" % [t0, t1])
	await _tap(_center_of(_by_name("PauseButton")))
	if bool(_board.get("_paused")):
		return _step_fail(8, label, "_paused still true after the second click")
	var resumed := await _wait_until(30, func() -> bool: return _time() > t1)
	if not resumed:
		return _step_fail(8, label, "clock never restarted after un-pausing")
	_step_pass(8, label, "clock held at %.2f over 30 frames, then resumed at %.2f" % [t0, _time()])
	return true


func _step9_wave_start() -> bool:
	var label := "wave start path is the roster Start button, not auto-start"
	if _started_at_first_place:
		return _step_fail(9, label, "the first placement auto-started the wave")
	if not bool(_board.get("_started")):
		return _step_fail(9, label, "_started false although Start was clicked in step 6")
	var roster := _by_name("WaveRoster")
	if roster.visible:
		return _step_fail(9, label, "roster still visible after the wave started")
	if absf(_lawn().offset_right) > 0.01:
		return _step_fail(9, label, "lawn did not reclaim the roster strip (offset_right=%s)" % _lawn().offset_right)
	_step_pass(9, label, "no auto-start on placement (checked at step 3); StartButton click (step 6) set _started, hid the roster, reset the lawn offset")
	return true


func _step10_combat_animations() -> bool:
	var label := "spawn / chew action / hurt states / Needle kill death->poof->freed, live"
	# Chew bait: a second dew dropper in the t=16 row-1 lane, bought with the
	# income collected in step 6. Click like a human, once the cooldown is off.
	if not await _wait_until(420, func() -> bool: return (_board.get("_cooldowns")[DEW]).is_ready()):
		return _step_fail(10, label, "dew cooldown never came off")
	if _water() < UnitCatalog.WARDEN_COST[DEW]:
		return _step_fail(10, label, "only %d water left for the chew bait" % _water())
	await _tap(_center_of(_cards()[DEW]))
	if not await _wait_until(240, func() -> bool: return _victim_tile_clear()):
		return _step_fail(10, label, "a stray droplet sat on the chew-bait tile too long")
	await _tap(_tile_center(VICTIM_CELL))
	_victim = _warden_at(VICTIM_CELL)
	if _victim == null or _victim.kind != DEW:
		return _step_fail(10, label, "chew bait never planted at %s" % VICTIM_CELL)
	await _move(PARK)
	var all_seen := func() -> bool:
		return _watch_abort != "" or (_spawn_seen >= 0.0 and _action_seen >= 0.0
				and _victim_hurt_seen and _victim_suffixes.has("66") and _victim_suffixes.has("33")
				and _kill_ready())
	if not await _wait_until(1500, all_seen):
		if _watch_abort != "":
			return _step_fail(10, label, _watch_abort)
		return _step_fail(10, label, "missing: spawn=%s action=%s hurt=%s (t=%.2f, damage t=%.2f) suffixes=%s kills=%s" % [
				_spawn_seen >= 0.0, _action_seen >= 0.0, _victim_hurt_seen, _victim_hurt_t, _victim_damage_t,
				_victim_suffixes.keys(), _kills_summary()])
	if _watch_abort != "":
		return _step_fail(10, label, _watch_abort)
	var hurt_soon := _victim_hurt_t >= 0.0 and _victim_hurt_t - _victim_damage_t <= 1.0
	if not hurt_soon:
		return _step_fail(10, label, "hurt clip %.2f s after first damage" % (_victim_hurt_t - _victim_damage_t))
	var kill_note := _kill_note()
	_step_pass(10, label, "vermin %s; chew %s; bait hurt at t=%.2f (%.2f s after damage), suffix states seen %s; kill: %s" % [
			_spawn_detail, _action_detail, _victim_hurt_t, _victim_hurt_t - _victim_damage_t,
			_victim_suffixes.keys(), kill_note])
	return true


func _kill_ready() -> bool:
	for v in _kill_order:
		var entry: Dictionary = _kills[v]
		if entry.closed and entry.death_t >= 0.0 and entry.poof_t >= 0.0 and entry.free_t >= 0.0 \
				and int(entry.row) == 2 and int(entry.hp_before) >= 0:
			return true
	return false


func _kills_summary() -> String:
	var parts: PackedStringArray = []
	for v in _kill_order:
		var entry: Dictionary = _kills[v]
		parts.append("row%s death=%s poof=%s free=%s" % [entry.row, entry.death_t, entry.poof_t, entry.free_t])
	return ", ".join(parts) if not parts.is_empty() else "none"


func _kill_note() -> String:
	for v in _kill_order:
		var entry: Dictionary = _kills[v]
		if entry.closed and entry.death_t >= 0.0 and entry.poof_t >= 0.0 and entry.free_t >= 0.0 and int(entry.row) == 2:
			return "%s (row %d) hp %d->shot->0 at t=%.2f: death clip -> PoofActor t=%.2f -> actor freed t=%.2f (needle shots seen: %s)" % [
					UnitCatalog.VERMIN_NAMES[entry.kind], entry.row, entry.hp_before, entry.death_t,
					entry.poof_t, entry.free_t, _shots_ever]
	return "unexpected kill set " + _kills_summary()


# ---------- screenshots ----------

func _shot(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var dir := ProjectSettings.globalize_path("res://build/screenshots")
	DirAccess.make_dir_recursive_absolute(dir)
	var err := image.save_png(dir + "/" + file_name)
	print("SHOT %s/%s %dx%d err=%d" % [dir, file_name, image.get_width(), image.get_height(), err])
