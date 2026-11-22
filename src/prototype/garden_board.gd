## The playable match. Drag a card onto the lawn, spend water, and stop the level.
class_name GardenBoard
extends Control

const WATER_ICON: Texture2D = preload("res://assets/sprites/board/water.png")
const CARD_SCENE := preload("res://src/ui/warden_card.tscn")
## Card faces for the bottom bar, index-aligned with UnitCatalog.Warden.
const SEED_PACKETS := [
	preload("res://assets/art/ui/seed_packets/seed_packet_dew_dropper.png"),
	preload("res://assets/art/ui/seed_packets/seed_packet_needle_spitter.png"),
	preload("res://assets/art/ui/seed_packets/seed_packet_stubborn_cone.png"),
	preload("res://assets/art/ui/seed_packets/seed_packet_rain_catcher.png"),
	preload("res://assets/art/ui/seed_packets/seed_packet_seed_lobber.png"),
]
const _PORCH_TEXTURE: Texture2D = preload("res://assets/art/environment/board/player_end_porch.png")
const _VERMIN_END_TEXTURE: Texture2D = preload("res://assets/art/environment/board/vermin_end_compost_eyes.png")
const DRAG_SLOP := 18.0
## Cells of snail travel between slime puddles (presentation only).
const TRAIL_SPACING := 0.22

@onready var _margin: MarginContainer = %SafeMargin
@onready var _top: TopBar = %TopBar
@onready var _lawn: LawnView = %Lawn
@onready var _bottom: BottomBar = %BottomBar
@onready var _background: TextureRect = %Background

var _wallet: WaterWallet
var _level: LevelDef
var _grid := LawnGrid.new(LawnView.COLUMNS, LawnView.ROWS)
var _cooldowns: Array[Cooldown] = []
var _wardens: Array[WardenActor] = []
var _dying_wardens: Array[WardenActor] = []
var _vermin: Array[VerminActor] = []
var _dying_vermin: Array[VerminActor] = []
var _shots: Array[ShotActor] = []
var _lobs: Array[LobActor] = []
var _selected := -1
var _removing := false
var _fast := false
var _hover := Vector2i(-1, -1)
var _key_aim := Vector2i(0, 2)
var _aim_from_keys := false
var _next_id := 1
var _next_spawn := 0
var _time := 0.0
var _paused := false
var _breached := false
var _result := MatchOutcome.Result.ONGOING
var _hint: PanelContainer
var _seed_panel: PanelContainer
var _result_layer: Control
var _drops: Array[WaterDrop] = []
var _next_sky := 0.0
var _tip: GameTooltip
var _roster: WaveRoster
var _play_shot := ""
var _fall_shot := ""
var _backdrop := 0
var _match_seed: MatchSeed
var _seed_label: Label
var _end_porch: TextureRect
var _end_vermin: TextureRect
var _golden_hour: GoldenHourBackdrop
var _started := false
var _press_card := -1
var _press_pos := Vector2.ZERO
var _dragging := false
var _drag_ghost: WardenCard
var _drag_kind := -1
var _ghost: Control
var _ghost_clip: ClipView
var _ghost_kind := -1
var _mouse_over_lawn := false
var _grub_rolls: Array[float] = []
var _next_button: Button
## The snail's pooled slime trail, laid on the lawn under the vermin.
var _trail: SnailTrail
## Last puddle column per snail actor, so puddles drop at a steady spacing.
var _snail_last: Dictionary = {}


func _ready() -> void:
	_level = LevelCatalog.current()
	_match_seed = _read_match_seed()
	_wallet = WaterWallet.new(_level.water)
	_bind_slot_keys()
	_apply_content_scale()
	_apply_safe_area()
	get_viewport().size_changed.connect(_on_viewport_resized)
	_lawn.resized.connect(_layout_actors)
	_lawn.cell_pressed.connect(_on_cell_pressed)
	_lawn.cell_hovered.connect(_on_cell_hovered)
	_top.pause_toggled.connect(_on_pause_toggled)
	_top.speed_toggled.connect(_on_speed_toggled)
	_top.preview_requested.connect(_open_preview)
	_bottom.remove_toggled.connect(_on_remove_toggled)
	_bottom.backdrop_requested.connect(_cycle_backdrop)
	_top.set_water_icon(WATER_ICON)
	_bottom.show_roster(_level.cards)
	for card in _bottom.cards():
		card.pointer_down.connect(_on_card_pointer_down.bind(card))
	for _index in UnitCatalog.Warden.size():
		_cooldowns.append(Cooldown.new())
	_build_hint()
	_build_result()
	_build_hud_extras()
	_build_trail()
	_build_ghost()
	_build_board_ends()
	_build_seed_label()
	_schedule_sky()
	_present_cards()
	_bind_tooltips()
	_refresh_hud()
	use_backdrop(BackdropCatalog.pick_index(_match_seed.value))
	_read_shot_args()


func _process(delta: float) -> void:
	var step := delta * 2.0 if _fast else delta
	if _started:
		advance(step)
	if _roster != null and _roster.visible:
		var visual := 0.0 if _paused else step
		_roster.tick(visual)
	_refresh_hud()
	_refresh_cursor()
	if not _play_shot.is_empty() and _time >= 1.2:
		_save_shot(_play_shot)
		_play_shot = ""
	if not _fall_shot.is_empty() and _time >= 5.5:
		_save_shot(_fall_shot)
		_fall_shot = ""


## Steps the match forward. Headless tests call this directly.
func advance(delta: float) -> void:
	if not _started or _result != MatchOutcome.Result.ONGOING or _paused:
		return
	_time += delta
	for cooldown in _cooldowns:
		cooldown.tick(delta)
	_spawn_due()
	_spawn_sky()
	_tick_wardens(delta)
	_tick_dying_wardens(delta)
	_tick_shots(delta)
	_tick_lobs(delta)
	_tick_vermin(delta)
	_tick_dying_vermin(delta)
	_tick_drops(delta)
	_trail.tick(delta)
	_collect_with_barrels()
	_result = MatchOutcome.evaluate(_breached, _vermin.size(), _pending_spawns())
	if _result != MatchOutcome.Result.ONGOING:
		_show_result()
	_layout_actors()


## Places a Warden of this kind. Returns false when the cell, water, or cooldown refuses.
func try_place(kind: int, column: int, row: int) -> bool:
	if _result != MatchOutcome.Result.ONGOING:
		return false
	if not _can_place(kind, column, row):
		return false
	if not _wallet.try_spend(UnitCatalog.WARDEN_COST[kind]):
		return false
	var id := _next_id
	_next_id += 1
	if not _grid.try_place(column, row, id):
		_wallet.add(UnitCatalog.WARDEN_COST[kind])
		_next_id -= 1
		return false
	var actor := WardenActor.new()
	actor.setup(kind, column, row, id)
	_lawn.add_child(actor)
	_wardens.append(actor)
	_cooldowns[kind].start(UnitCatalog.WARDEN_COOLDOWN[kind])
	if _hint != null:
		_hint.visible = false
	_layout_actors()
	return true


## Drops a Vermin into a row. The wave and the match test both use this.
func spawn_vermin(kind: UnitCatalog.Vermin, row: int, column_pos: float) -> void:
	var actor := VerminActor.new()
	actor.setup(kind, row, column_pos)
	_lawn.add_child(actor)
	_vermin.append(actor)
	_layout_actors()


func water_amount() -> int:
	return _wallet.amount


func vermin_hp_in_row(row: int) -> int:
	for vermin in _vermin:
		if vermin.row == row:
			return vermin.hp
	return -1


## The column of the first Vermin on a row, or -1. The hop test uses this.
func vermin_column_in_row(row: int) -> float:
	for vermin in _vermin:
		if vermin.row == row:
			return vermin.column_pos
	return -1.0


## The remaining HP of the Warden on a tile, or -1 when the tile is empty.
## The hop test uses this.
func warden_hp_at(column: int, row: int) -> int:
	var warden := _warden_at(column, row)
	return -1 if warden == null else warden.hp


func vermin_of_kind(kind: int) -> int:
	var count := 0
	for vermin in _vermin:
		if vermin.kind == kind and vermin.hp > 0:
			count += 1
	return count


func result() -> MatchOutcome.Result:
	return _result


## Digs up the Warden on a tile. Water is not refunded, and the card cooldown stays.
func dig(column: int, row: int) -> bool:
	if _result != MatchOutcome.Result.ONGOING:
		return false
	var warden := _warden_at(column, row)
	if warden == null:
		return false
	_remove_warden(warden)
	_set_removing(false)
	return true


func _can_place(kind: int, column: int, row: int) -> bool:
	if kind < 0 or kind >= _cooldowns.size():
		return false
	if not _cooldowns[kind].is_ready():
		return false
	if not _wallet.can_afford(UnitCatalog.WARDEN_COST[kind]):
		return false
	return _grid.is_inside(column, row) and _grid.occupant(column, row) == 0


func _spawn_due() -> void:
	while _next_spawn < _level.wave.size():
		var entry := _level.wave[_next_spawn]
		if _time < entry.x:
			return
		spawn_vermin(int(entry.y), int(entry.z), float(_lawn.column_count()) - 0.15)
		_next_spawn += 1


func _tick_wardens(delta: float) -> void:
	var spots := _vermin_spots()
	for warden in _wardens:
		var ahead := RowTarget.first_ahead(warden.row, float(warden.column) + 0.8, spots)
		var rate := SoilMap.warden_rate(SoilMap.kind_at(warden.column, warden.row, _lawn.column_count()))
		var can_act := false
		if warden.kind == UnitCatalog.Warden.NEEDLE:
			can_act = ahead >= 0
		elif warden.kind == UnitCatalog.Warden.SEED:
			can_act = SeedBurst.aim(warden.column, warden.row, spots, _lawn.column_count(), LawnView.ROWS, UnitCatalog.LOB_RANGE).x >= 0
		var action := warden.tick(delta * rate, can_act)
		if action == "shot":
			_add_shot(warden)
		elif action == "water":
			_spawn_drop(float(warden.column) + 0.85, float(warden.row), false)
		elif action == "lob":
			_add_lob(warden, spots)


func _tick_shots(delta: float) -> void:
	var kept: Array[ShotActor] = []
	for shot in _shots:
		var previous := shot.column_pos
		shot.column_pos += UnitCatalog.NEEDLE_SHOT_SPEED * delta
		var hit := false
		for vermin in _vermin:
			if vermin.row != shot.row or vermin.hp <= 0:
				continue
			if RowTarget.shot_reaches(previous, shot.column_pos, vermin.column_pos):
				vermin.take_damage(shot.damage)
				hit = true
				break
		if hit or shot.column_pos > float(_lawn.column_count()) + 0.4:
			shot.queue_free()
		else:
			kept.append(shot)
	_shots = kept
	_drop_dead_vermin()


func _tick_vermin(delta: float) -> void:
	for vermin in _vermin:
		if vermin.kind == UnitCatalog.Vermin.BEE:
			_tick_bee(vermin, delta)
			continue
		if vermin.hop_elapsed >= 0.0:
			_advance_hop(vermin, delta)
			continue
		var columns := _warden_columns(vermin.row)
		var blocking := RowTarget.reached_column(vermin.column_pos, columns)
		if blocking >= 0:
			vermin.column_pos = float(blocking) + 1.0
			var warden := _warden_at(blocking, vermin.row)
			if warden != null and FlutterHop.can_hop(vermin.kind, warden.kind):
				_start_hop(vermin, vermin.column_pos)
				continue
			if warden != null and warden.take_damage(vermin.chew_damage() * delta):
				_kill_warden(warden)
		else:
			var column := clampi(int(floor(vermin.column_pos)), 0, _lawn.column_count() - 1)
			var scale := SoilMap.vermin_scale(SoilMap.kind_at(column, vermin.row, _lawn.column_count()))
			var pace := SnailPace.scale(vermin.column_pos, vermin.row, UnitCatalog.is_ground(vermin.kind), _snail_spots())
			vermin.column_pos -= vermin.speed() * scale * pace * delta
			if vermin.column_pos <= 0.0:
				_breached = true
			if vermin.kind == UnitCatalog.Vermin.SNAIL:
				_snail_trail_drop(vermin)
		vermin.tick(delta, VerminActor.Mode.CHEW if blocking >= 0 else VerminActor.Mode.MOVE)


## A Ladybug reaching a Stubborn Cone takes off instead of chewing: it lifts
## off the cone's right edge and [method _advance_hop] carries it over.
func _start_hop(vermin: VerminActor, stand_pos: float) -> void:
	vermin.hop_from = stand_pos
	vermin.column_pos = stand_pos
	vermin.hop_elapsed = 0.0
	vermin.tick_flutter(0.0, FlutterHop.phase(0.0))


## Walks the flutter-hop arc: hold through the crouch frames, slide one tile
## per second across the cone's tile on the parabola, land two tiles short of
## the takeoff spot, and hand the clip back to the walk. The cone is never
## chewed during a hop, so it keeps every point of its HP.
func _advance_hop(vermin: VerminActor, delta: float) -> void:
	vermin.hop_elapsed += delta
	if vermin.hop_elapsed >= FlutterHop.TOTAL_SECONDS:
		vermin.hop_elapsed = -1.0
		vermin.hop_lift_tiles = 0.0
		vermin.column_pos = vermin.hop_from - FlutterHop.TRAVEL_TILES
		if vermin.column_pos <= 0.0:
			_breached = true
		vermin.tick(delta, VerminActor.Mode.MOVE)
		return
	var t := FlutterHop.travel(vermin.hop_elapsed)
	vermin.column_pos = vermin.hop_from - FlutterHop.TRAVEL_TILES * t
	vermin.hop_lift_tiles = FlutterHop.lift_tiles(t)
	if vermin.column_pos <= 0.0:
		_breached = true
	vermin.tick_flutter(delta, FlutterHop.phase(vermin.hop_elapsed))


## Bees step one tile at a time. Forward is left, toward the house. They
## hover (idle) while the step timer runs and show one stride after a hop.
func _tick_bee(vermin: VerminActor, delta: float) -> void:
	var ahead := vermin.bee_column - 1
	var warden := _warden_at(vermin.bee_column, vermin.row)
	if warden == null and ahead >= 0:
		warden = _warden_at(ahead, vermin.row)
	if warden != null:
		vermin.tick(delta, VerminActor.Mode.CHEW)
		if warden.take_damage(vermin.chew_damage() * delta):
			_kill_warden(warden)
		return
	var scale := SoilMap.vermin_scale(SoilMap.kind_at(vermin.bee_column, vermin.row, _lawn.column_count()))
	var pace := SnailPace.scale(vermin.column_pos, vermin.row, UnitCatalog.is_ground(vermin.kind), _snail_spots())
	vermin.bee_wait -= delta * scale * pace
	if vermin.bee_wait > 0.0:
		vermin.tick(delta, VerminActor.Mode.IDLE)
		return
	vermin.bee_wait = UnitCatalog.BEE_STEP
	var step := BeePath.next_step(
		vermin.bee_column,
		vermin.row,
		_lawn.column_count(),
		LawnView.ROWS,
		vermin.bee_since_forward,
		vermin.bee_since_backward,
	)
	_apply_bee_step(vermin, step)
	vermin.tick(delta, VerminActor.Mode.MOVE)


func _apply_bee_step(vermin: VerminActor, step: Vector2i) -> void:
	if step.x < 0:
		vermin.bee_since_forward = 0
		vermin.bee_since_backward += 1
		if vermin.bee_column <= 0:
			_breached = true
			return
		vermin.bee_column -= 1
	elif step.x > 0:
		vermin.bee_since_forward += 1
		vermin.bee_since_backward = 0
		vermin.bee_column += 1
	else:
		vermin.bee_since_forward += 1
		vermin.bee_since_backward += 1
		vermin.row = clampi(vermin.row + step.y, 0, LawnView.ROWS - 1)
		# In-place rise (up) / drop (down) clip while the lane change happens.
		vermin.start_lane_change(step.y < 0)
	vermin.column_pos = float(vermin.bee_column) + 0.5


## Lays a slime puddle behind the snail once it has scooted TRAIL_SPACING
## cells since its last puddle; the pool fades and recycles the puddles.
func _snail_trail_drop(vermin: VerminActor) -> void:
	var cell := _lawn.cell_size_px()
	if cell <= 0.0:
		return
	var last: float = _snail_last.get(vermin, INF)
	if last - vermin.column_pos < TRAIL_SPACING:
		return
	_snail_last[vermin] = vermin.column_pos
	var ground := _lawn.grid_origin() + Vector2(
		vermin.column_pos * cell,
		(float(vermin.row) + 0.85) * cell,
	)
	_trail.drop(ground, cell)


func _add_shot(warden: WardenActor) -> void:
	var shot := ShotActor.new()
	shot.row = warden.row
	shot.column_pos = float(warden.column) + 0.85
	shot.damage = UnitCatalog.NEEDLE_DAMAGE
	_lawn.add_child(shot)
	_shots.append(shot)


func _add_lob(warden: WardenActor, spots: Array[Vector2]) -> void:
	var target := SeedBurst.aim(warden.column, warden.row, spots, _lawn.column_count(), LawnView.ROWS, UnitCatalog.LOB_RANGE)
	if target.x < 0:
		return
	var lob := LobActor.new()
	lob.setup(
		Vector2(float(warden.column) + 0.5, float(warden.row)),
		target,
		SeedBurst.pick(target, _lawn.column_count(), LawnView.ROWS, UnitCatalog.LOB_EXTRA),
	)
	_lawn.add_child(lob)
	_lobs.append(lob)


func _tick_lobs(delta: float) -> void:
	var kept: Array[LobActor] = []
	for lob in _lobs:
		if lob.tick(delta):
			_apply_seed_hits(lob.cells, UnitCatalog.SEED_DAMAGE)
		if lob.finished():
			lob.queue_free()
		else:
			kept.append(lob)
	_lobs = kept


func _apply_seed_hits(cells: Array[Vector2i], damage: int) -> void:
	var used: Array[VerminActor] = []
	for cell in cells:
		for vermin in _vermin:
			if used.has(vermin) or vermin.hp <= 0:
				continue
			if SeedBurst.covers(vermin.column_pos, vermin.row, cell):
				vermin.take_damage(damage)
				used.append(vermin)
				break
	_drop_dead_vermin()


func _collect_with_barrels() -> void:
	for warden in _wardens:
		if warden.kind != UnitCatalog.Warden.RAIN:
			continue
		var origin := Vector2i(warden.column, warden.row)
		for drop in _drops.duplicate():
			if not is_instance_valid(drop):
				continue
			if RainCatch.catches(origin, drop.column_pos, drop.row_pos, drop.falling):
				drop.collect()


func _snail_spots() -> Array[Vector2]:
	var spots: Array[Vector2] = []
	for vermin in _vermin:
		if vermin.hp > 0 and vermin.kind == UnitCatalog.Vermin.SNAIL:
			spots.append(Vector2(vermin.column_pos, vermin.row))
	return spots


func push_grub_roll(roll: float) -> void:
	_grub_rolls.append(roll)


func _next_grub_roll() -> float:
	if _grub_rolls.is_empty():
		return randf()
	return _grub_rolls.pop_front()


## Drops a landed droplet. The rain test uses this.
func spawn_test_drop(column: float, row: float) -> void:
	_spawn_drop(column, row, false)


## Zero-HP Vermin start their bounded death pose here, on the same step the
## killing blow landed. Grub births keep the kill-step timing; only the
## visual lingers until _tick_dying_vermin poofs and frees the actor.
func _drop_dead_vermin() -> void:
	var kept: Array[VerminActor] = []
	var births: Array[Vector2] = []
	for vermin in _vermin:
		if vermin.hp <= 0:
			_snail_last.erase(vermin)
			if UnitCatalog.leaves_grub(vermin.kind, _next_grub_roll()):
				births.append(Vector2(maxf(0.2, vermin.column_pos), vermin.row))
			vermin.die()
			_dying_vermin.append(vermin)
		else:
			kept.append(vermin)
	_vermin = kept
	for birth in births:
		spawn_vermin(UnitCatalog.Vermin.GRUB, int(birth.y), birth.x)


## Plays out the death poses (bounded), then poofs at the actor and frees it.
func _tick_dying_vermin(delta: float) -> void:
	var kept: Array[VerminActor] = []
	for vermin in _dying_vermin:
		if not vermin.tick_death(delta):
			kept.append(vermin)
			continue
		var cell := _lawn.cell_size_px()
		if cell > 0.0:
			var poof := PoofActor.new()
			_lawn.add_child(poof)
			poof.play_at(vermin.position + vermin.size * Vector2(0.5, 0.6), cell * 0.6)
		vermin.queue_free()
	_dying_vermin = kept


func _remove_warden(warden: WardenActor) -> void:
	_grid.remove(warden.column, warden.row)
	_wardens.erase(warden)
	warden.queue_free()


## Chewing reached zero HP: play the death pose out (bounded), then poof at the
## actor and free the tile. The match stops seeing the Warden right away.
func _kill_warden(warden: WardenActor) -> void:
	_wardens.erase(warden)
	warden.die()
	_dying_wardens.append(warden)


func _tick_dying_wardens(delta: float) -> void:
	var kept: Array[WardenActor] = []
	for warden in _dying_wardens:
		if not warden.tick_death(delta):
			kept.append(warden)
			continue
		var cell := _lawn.cell_size_px()
		if cell > 0.0:
			var poof := PoofActor.new()
			_lawn.add_child(poof)
			poof.play_at(warden.position + warden.size * Vector2(0.5, 0.92), cell * 0.7)
		_grid.remove(warden.column, warden.row)
		warden.queue_free()
	_dying_wardens = kept


func _warden_at(column: int, row: int) -> WardenActor:
	for warden in _wardens:
		if warden.column == column and warden.row == row:
			return warden
	return null


func _warden_columns(row: int) -> Array[int]:
	var columns: Array[int] = []
	for warden in _wardens:
		if warden.row == row:
			columns.append(warden.column)
	return columns


func _vermin_spots() -> Array[Vector2]:
	var spots: Array[Vector2] = []
	for vermin in _vermin:
		if vermin.hp > 0:
			spots.append(Vector2(vermin.column_pos, vermin.row))
	return spots


func _pending_spawns() -> int:
	return _level.wave.size() - _next_spawn


func _layout_actors() -> void:
	var cell := _lawn.cell_size_px()
	if cell <= 0.0:
		return
	var origin := _lawn.grid_origin()
	for warden in _wardens:
		_place_box(warden, origin, cell, float(warden.column) + 0.5, float(warden.row), 1.0)
		warden.refresh_bar()
	for warden in _dying_wardens:
		_place_box(warden, origin, cell, float(warden.column) + 0.5, float(warden.row), 1.0)
	for vermin in _vermin:
		_place_box(vermin, origin, cell, vermin.column_pos, float(vermin.row) - vermin.hop_lift_tiles, 0.7)
		vermin.refresh_bar()
	for vermin in _dying_vermin:
		_place_box(vermin, origin, cell, vermin.column_pos, float(vermin.row), 0.7)
	for shot in _shots:
		_place_box(shot, origin, cell, shot.column_pos, float(shot.row), 0.55)
	for lob in _lobs:
		lob.place_on_lawn(origin, cell)
	for drop in _drops:
		if is_instance_valid(drop):
			_place_box(drop, origin, cell, drop.column_pos, drop.row_pos, 0.63)
	_place_hint()
	_layout_board_ends()


## Builds the porch and the compost eyes that flank the lawn. Drawn under the
## UI: they sit over the backdrop, behind every actor.
func _build_board_ends() -> void:
	_end_porch = _make_board_end("PlayerEnd", _PORCH_TEXTURE)
	_end_vermin = _make_board_end("VerminEnd", _VERMIN_END_TEXTURE)
	add_child(_end_porch)
	add_child(_end_vermin)
	move_child(_end_porch, 2)
	move_child(_end_vermin, 3)


func _make_board_end(node_name: String, texture: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = node_name
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## Stands both ends on the bottom row line, tight to the grid edges with a
## finger's gap. The art is taller-than-wide against the five lanes, but the
## gutters at 1280x720 cannot host that width, so an end that would run off
## the screen edge or under the wave panel shrinks to fit and stays complete.
func _layout_board_ends() -> void:
	if _end_porch == null or _end_vermin == null:
		return
	var cell := _lawn.cell_size_px()
	if cell <= 0.0:
		return
	# The board root covers the viewport from (0,0), so canvas coords are local here.
	var origin := _lawn.global_position + _lawn.grid_origin()
	var height := cell * float(LawnView.ROWS)
	var bottom := origin.y + height
	var lawn_right := _lawn.global_position.x + _lawn.size.x
	_size_board_end(_end_porch, height, maxf(origin.x - 10.0, 24.0))
	_end_porch.position = Vector2(origin.x - 6.0 - _end_porch.size.x, bottom - _end_porch.size.y)
	_size_board_end(_end_vermin, height, maxf(lawn_right - origin.x - cell * float(_lawn.column_count()) - 10.0, 24.0))
	_end_vermin.position = Vector2(origin.x + cell * float(_lawn.column_count()) + 6.0, bottom - _end_vermin.size.y)


func _size_board_end(rect: TextureRect, lane_height: float, max_width: float) -> void:
	var aspect := rect.texture.get_size().x / rect.texture.get_size().y
	var width := minf(lane_height * aspect, max_width)
	rect.size = Vector2(width, width / aspect)


## A small watermark naming the visual seed and look, so a match can be
## replayed with --seed N.
func _build_seed_label() -> void:
	_seed_panel = PanelContainer.new()
	_seed_panel.name = "SeedLabel"
	_seed_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_seed_panel.z_index = 7
	_seed_panel.add_theme_stylebox_override("panel", FlatStyle.panel(Color(FlatStyle.PANEL, 0.55), FlatStyle.INK, 10, 2))
	_seed_label = Label.new()
	_seed_label.add_theme_color_override("font_color", FlatStyle.CREAM)
	_seed_label.add_theme_font_size_override("font_size", 12)
	_seed_panel.add_child(_seed_label)
	_lawn.add_child(_seed_panel)
	_seed_panel.position = Vector2(4.0, 2.0)
	_refresh_seed_label()


func _refresh_seed_label() -> void:
	if _seed_label == null or _match_seed == null:
		return
	_seed_label.text = "Seed %d, %s" % [_match_seed.value, BackdropCatalog.NAMES[_backdrop]]


func _place_box(node: Control, origin: Vector2, cell: float, column_pos: float, row_pos: float, scale: float) -> void:
	var box := cell * scale
	var center := origin + Vector2(column_pos * cell, (row_pos + 0.5) * cell)
	node.size = Vector2(box, box)
	node.position = center - node.size * 0.5


func _present_cards() -> void:
	var cards := _bottom.cards()
	for index in cards.size():
		var kind: int = _level.cards[index]
		cards[index].present(kind, UnitCatalog.WARDEN_NAMES[kind], UnitCatalog.WARDEN_COST[kind], _card_face(kind), false, false, "")


## The card face for one Warden: its seed packet art.
func _card_face(kind: int) -> Texture2D:
	if kind < 0 or kind >= SEED_PACKETS.size():
		return null
	return SEED_PACKETS[kind]


func _refresh_hud() -> void:
	_top.show_status(_wallet.amount, LevelCatalog.number(), _vermin.size() + _pending_spawns())
	var cards := _bottom.cards()
	for index in cards.size():
		var kind := cards[index].kind
		var cooling := not _cooldowns[kind].is_ready()
		var poor := not _wallet.can_afford(UnitCatalog.WARDEN_COST[kind])
		cards[index].set_state(index == _selected, poor and not cooling, _cooldowns[kind].remaining)


func _refresh_cursor() -> void:
	if _dragging:
		_hide_ghost()
		return
	var aim := _key_aim if _aim_from_keys else _hover
	if aim.x < 0 or _result != MatchOutcome.Result.ONGOING:
		_lawn.show_aim(Vector2i(-1, -1), false)
		_hide_ghost()
		return
	if _removing:
		_lawn.show_aim(aim, _warden_at(aim.x, aim.y) != null)
		_hide_ghost()
		return
	var kind := _selected_kind()
	if kind < 0:
		_lawn.show_aim(Vector2i(-1, -1), false)
		_hide_ghost()
		return
	_lawn.show_aim(aim, _can_place(kind, aim.x, aim.y))
	_refresh_ghost(aim, kind)


## The snail's slime trail: a pooled node on the lawn, under the vermin.
func _build_trail() -> void:
	_trail = SnailTrail.new()
	_lawn.add_child(_trail)


## Builds the translucent hover preview once and parks it on the lawn.
func _build_ghost() -> void:
	_ghost = Control.new()
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost.z_index = 6
	_ghost.modulate = Color(1, 1, 1, 0.4)
	_ghost.visible = false
	_ghost_clip = ClipView.new()
	_ghost_clip.set_motion_enabled(false)
	_ghost.add_child(_ghost_clip)
	_lawn.add_child(_ghost)
	_lawn.mouse_entered.connect(_on_lawn_mouse_entered)
	_lawn.mouse_exited.connect(_on_lawn_mouse_exited)


func _on_lawn_mouse_entered() -> void:
	_mouse_over_lawn = true


func _on_lawn_mouse_exited() -> void:
	_mouse_over_lawn = false


## Shows the selected Warden on the hovered tile at a quarter of its strength,
## so a placed Warden and the green or red tile cursor still read on top.
func _refresh_ghost(aim: Vector2i, kind: int) -> void:
	var cell := _lawn.cell_size_px()
	if cell <= 0.0:
		_hide_ghost()
		return
	var hovered := _mouse_over_lawn or _aim_from_keys
	if not hovered or _grid.occupant(aim.x, aim.y) != 0:
		_hide_ghost()
		return
	if kind != _ghost_kind:
		_ghost_kind = kind
		_build_ghost_clip(kind)
	_place_box(_ghost, _lawn.grid_origin(), cell, float(aim.x) + 0.5, float(aim.y), 1.0)
	_ghost_clip.tick(0.0, _ghost.size)
	_ghost.visible = true


func _hide_ghost() -> void:
	if _ghost != null:
		_ghost.visible = false


## Idle clip for the preview, anchored and scaled the way a planted Warden is.
func _build_ghost_clip(kind: int) -> void:
	var frames := AnimLibrary.warden(kind)
	_ghost_clip.use(frames)
	var folder := AnimLibrary.warden_folder(kind)
	var ground := AnimLibrary.ground_point_px(folder)
	var canvas := AnimLibrary.canvas_px(folder)
	if ground != Vector2.INF and canvas != Vector2.INF:
		_ghost_clip.set_anchor_fit(ground, canvas)
	_ghost_clip.play(AnimLibrary.animation_name(frames, "idle", "100"))


func _on_card_pointer_down(card: WardenCard) -> void:
	if _result != MatchOutcome.Result.ONGOING:
		return
	_press_card = _bottom.cards().find(card)
	_press_pos = get_global_mouse_position()
	_dragging = false


func _on_cell_pressed(cell: Vector2i) -> void:
	_aim_from_keys = false
	_hover = cell
	if _removing:
		dig(cell.x, cell.y)
	elif _selected_kind() >= 0:
		try_place(_selected_kind(), cell.x, cell.y)


func _on_speed_toggled(fast: bool) -> void:
	_fast = fast


func _on_remove_toggled(active: bool) -> void:
	_set_removing(active)


## The wave clock, spawns, and attacks stay frozen until this is pressed.
func start_wave() -> void:
	if _started or _result != MatchOutcome.Result.ONGOING:
		return
	_started = true
	_time = 0.0
	if _roster != null:
		_roster.visible = false
	_lawn.offset_right = 0.0
	if _hint != null:
		_hint.visible = false


func wave_started() -> bool:
	return _started


func _open_preview() -> void:
	get_tree().change_scene_to_file("res://src/prototype/anim_preview.tscn")


## Shows one of the looks. A match opens on the look its seed picked; the
## button cycles them for the rest of the match.
func use_backdrop(index: int) -> void:
	_backdrop = posmod(index, BackdropCatalog.count())
	_apply_backdrop()


func _cycle_backdrop() -> void:
	use_backdrop(_backdrop + 1)


func _apply_backdrop() -> void:
	var texture := BackdropCatalog.texture_at(_backdrop)
	if texture != null:
		_background.texture = texture
	_bottom.set_backdrop_name(BackdropCatalog.NAMES[_backdrop])
	_refresh_seed_label()


## The value this match's look was picked from. Shown on the debug label.
func visual_seed() -> int:
	return _match_seed.value


## Forces the Golden Hour layered backdrop on or off. AW-7's showcase toggle
## calls this; ordinary matches leave it alone.
func use_golden_hour(enabled: bool) -> void:
	if enabled and _golden_hour == null:
		_golden_hour = GoldenHourBackdrop.compose(self)
		move_child(_golden_hour, 2)
	elif not enabled and _golden_hour != null:
		_golden_hour.queue_free()
		_golden_hour = null


## The match's visual dice cup. --seed N on the command line replays a look.
func _read_match_seed() -> MatchSeed:
	var args := OS.get_cmdline_user_args()
	var index := args.find("--seed")
	if index >= 0 and index + 1 < args.size() and args[index + 1].is_valid_int():
		return MatchSeed.with_value(int(args[index + 1]))
	return MatchSeed.rolled()


func _set_removing(active: bool) -> void:
	_removing = active
	if active:
		_selected = -1
	_bottom.set_removing(active)


func _on_cell_hovered(cell: Vector2i) -> void:
	if not _aim_from_keys:
		_hover = cell
	_show_cell_tip(cell)


func _on_pause_toggled(paused: bool) -> void:
	if _result == MatchOutcome.Result.ONGOING:
		_paused = paused


func _unhandled_input(event: InputEvent) -> void:
	if _result != MatchOutcome.Result.ONGOING or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		_selected = -1
		_cancel_pointer()
		_set_removing(false)
		return
	for slot in _bottom.cards().size():
		if event.is_action_pressed("select_slot_%d" % [slot + 1]):
			_toggle_card(slot)
			return
	if event.is_action_pressed("ui_left"):
		_nudge_aim(-1, 0)
	elif event.is_action_pressed("ui_right"):
		_nudge_aim(1, 0)
	elif event.is_action_pressed("ui_up"):
		_nudge_aim(0, -1)
	elif event.is_action_pressed("ui_down"):
		_nudge_aim(0, 1)
	elif event.is_action_pressed("ui_accept") and _removing:
		dig(_key_aim.x, _key_aim.y)
	elif event.is_action_pressed("ui_accept") and _selected_kind() >= 0:
		try_place(_selected_kind(), _key_aim.x, _key_aim.y)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_selected = -1
		_cancel_pointer()
		_set_removing(false)


func _toggle_card(index: int) -> void:
	_set_removing(false)
	_selected = -1 if _selected == index else index


func _selected_kind() -> int:
	if _selected < 0 or _selected >= _bottom.cards().size():
		return -1
	return _bottom.cards()[_selected].kind


func _input(event: InputEvent) -> void:
	if _press_card < 0:
		return
	if event is InputEventMouseMotion:
		if not _dragging and _press_pos.distance_to(get_global_mouse_position()) >= DRAG_SLOP:
			_begin_drag()
		if _dragging:
			_move_drag(get_global_mouse_position())
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_RIGHT and button.pressed:
			_selected = -1
			_cancel_pointer()
			_set_removing(false)
			get_viewport().set_input_as_handled()
		elif button.button_index == MOUSE_BUTTON_LEFT and not button.pressed:
			_release_pointer()
			get_viewport().set_input_as_handled()


func _release_pointer() -> void:
	var card := _press_card
	if _dragging:
		_finish_drag_at(_lawn.cell_at(_lawn.get_local_mouse_position()))
		return
	_press_card = -1
	if card >= 0:
		_toggle_card(card)


## Starts a drag from a visible card and plants on release. Tests call this without a pointer.
func drag_place(card_index: int, column: int, row: int) -> bool:
	_on_card_pointer_down(_bottom.cards()[card_index])
	_begin_drag()
	return _finish_drag_at(Vector2i(column, row))


## Picks up a card and puts it back. Tests call this without a pointer.
func drag_cancel(card_index: int) -> void:
	_on_card_pointer_down(_bottom.cards()[card_index])
	_begin_drag()
	_cancel_pointer()


func _begin_drag() -> void:
	if _press_card < 0 or _press_card >= _bottom.cards().size():
		return
	_dragging = true
	_set_removing(false)
	_selected = -1
	var card := _bottom.cards()[_press_card]
	_drag_kind = card.kind
	_drag_ghost = CARD_SCENE.instantiate() as WardenCard
	add_child(_drag_ghost)
	_drag_ghost.present(_drag_kind, UnitCatalog.WARDEN_NAMES[_drag_kind], UnitCatalog.WARDEN_COST[_drag_kind], _card_face(_drag_kind), true, false, "")
	_drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_ghost.z_index = 30
	_set_drops_locked(true)
	if _tip != null:
		_tip.hide_tip()
	_move_drag(get_global_mouse_position())


func _move_drag(pointer: Vector2) -> void:
	_position_ghost(pointer)
	var cell := _lawn.cell_at(_lawn.get_local_mouse_position())
	if cell.x < 0 or _result != MatchOutcome.Result.ONGOING:
		_lawn.show_aim(Vector2i(-1, -1), false)
		return
	_lawn.show_aim(cell, _can_place(_drag_kind, cell.x, cell.y))


func _position_ghost(pointer: Vector2) -> void:
	if _drag_ghost == null:
		return
	var ghost_size := _drag_ghost.custom_minimum_size
	_drag_ghost.size = ghost_size
	var origin := pointer - Vector2(ghost_size.x * 0.5, ghost_size.y + 36.0)
	var viewport := get_viewport_rect().size
	origin.x = clampf(origin.x, 8.0, maxf(8.0, viewport.x - ghost_size.x - 8.0))
	origin.y = clampf(origin.y, 8.0, maxf(8.0, viewport.y - ghost_size.y - 8.0))
	_drag_ghost.global_position = origin


func _finish_drag_at(cell: Vector2i) -> bool:
	var kind := _drag_kind
	_press_card = -1
	_end_drag()
	_selected = -1
	if kind < 0 or cell.x < 0:
		return false
	return try_place(kind, cell.x, cell.y)


func _cancel_pointer() -> void:
	_press_card = -1
	_end_drag()


func _end_drag() -> void:
	_dragging = false
	_drag_kind = -1
	if _drag_ghost != null:
		_drag_ghost.queue_free()
		_drag_ghost = null
	_set_drops_locked(false)


func _set_drops_locked(locked: bool) -> void:
	for drop in _drops:
		if is_instance_valid(drop):
			drop.set_collect_enabled(not locked)


func _nudge_aim(column_step: int, row_step: int) -> void:
	_aim_from_keys = true
	_key_aim.x = clampi(_key_aim.x + column_step, 0, _lawn.column_count() - 1)
	_key_aim.y = clampi(_key_aim.y + row_step, 0, LawnView.ROWS - 1)


func _build_hud_extras() -> void:
	_tip = GameTooltip.new()
	add_child(_tip)
	_roster = WaveRoster.new()
	var host := _margin.get_node("Layout/BoardHost") as Control
	host.add_child(_roster)
	_roster.set_anchors_preset(Control.PRESET_FULL_RECT)
	_roster.anchor_left = 1.0
	_roster.offset_left = -(WaveRoster.WIDTH + 4.0)
	_roster.offset_right = -4.0
	_roster.offset_top = 0.0
	_roster.offset_bottom = 0.0
	_lawn.offset_right = -(WaveRoster.WIDTH + 12.0)
	_roster.fill(_tip, _level.wave)
	_roster.start_requested.connect(start_wave)
	_lawn.mouse_exited.connect(func() -> void: _tip.hide_tip())


func _bind_tooltips() -> void:
	var cards := _bottom.cards()
	for card in cards:
		GameTooltip.attach(card, UnitCatalog.warden_blurb(card.kind), _tip)
	GameTooltip.attach(_bottom.find_child("AbilityButton", true, false) as Control, "No ability yet.", _tip)
	GameTooltip.attach(_bottom.find_child("RemoveButton", true, false) as Control, "Dig up a planted Warden. The water is not returned.", _tip)
	GameTooltip.attach(_top.find_child("SpeedButton", true, false) as Control, "Run the wave at double time.", _tip)
	GameTooltip.attach(_top.find_child("PauseButton", true, false) as Control, "Freeze the match.", _tip)
	GameTooltip.attach(_top.find_child("PreviewButton", true, false) as Control, "Preview each unit's idle, attack, and walk clips.", _tip)
	GameTooltip.attach(_bottom.find_child("BackdropButton", true, false) as Control, "Show the next backdrop. The match opens on the look its seed picked: Main, Sunny, Overcast, or Dusk.", _tip)
	GameTooltip.attach(_roster.find_child("StartButton", true, false) as Control, "Start the wave. Vermin stay off the lawn until then.", _tip)
	GameTooltip.attach(_top.find_child("WaterLabel", true, false) as Control, "Water spent to plant Wardens. Collect droplets to earn more.", _tip)
	GameTooltip.attach(_top.find_child("WaveLabel", true, false) as Control, "Level %d, %s." % [LevelCatalog.number(), _level.title], _tip)
	GameTooltip.attach(_top.find_child("RemainingLabel", true, false) as Control, "Vermin still coming, plus vermin still on the lawn.", _tip)


func _show_cell_tip(cell: Vector2i) -> void:
	if _tip == null or cell.x < 0:
		return
	var text := SoilMap.blurb(SoilMap.kind_at(cell.x, cell.y, _lawn.column_count()))
	var warden := _warden_at(cell.x, cell.y)
	if warden != null:
		text += "\n" + _warden_blurb(warden.kind)
	else:
		for vermin in _vermin:
			if vermin.row == cell.y and vermin.column_pos >= float(cell.x) and vermin.column_pos < float(cell.x) + 1.0:
				text += "\n" + _vermin_blurb(vermin.kind)
				break
	_tip.show_text(text)


func _warden_blurb(kind: UnitCatalog.Warden) -> String:
	return UnitCatalog.warden_blurb(kind)


func _vermin_blurb(kind: UnitCatalog.Vermin) -> String:
	return UnitCatalog.vermin_blurb(kind)


func _schedule_sky() -> void:
	_next_sky = _time + UnitCatalog.SKY_INTERVAL + randf_range(-UnitCatalog.SKY_JITTER, UnitCatalog.SKY_JITTER)


func _spawn_sky() -> void:
	if _time < _next_sky:
		return
	_schedule_sky()
	var column := randi_range(0, _lawn.column_count() - 1)
	var row := randi_range(0, LawnView.ROWS - 1)
	_spawn_drop(float(column) + 0.5, float(row), true)


func _spawn_drop(column: float, row: float, from_sky: bool) -> void:
	var drop := WaterDrop.new()
	drop.setup(UnitCatalog.DEW_AMOUNT, column, row, from_sky)
	drop.collected.connect(_on_drop_collected.bind(drop))
	_lawn.add_child(drop)
	_drops.append(drop)
	if _dragging:
		drop.set_collect_enabled(false)
	_layout_actors()


func _on_drop_collected(amount: int, drop: WaterDrop) -> void:
	_wallet.add(amount)
	_drops.erase(drop)


func _tick_drops(delta: float) -> void:
	var kept: Array[WaterDrop] = []
	for drop in _drops:
		if not is_instance_valid(drop):
			continue
		if drop.tick(delta):
			drop.queue_free()
		else:
			kept.append(drop)
	_drops = kept


func collect_all_drops() -> void:
	for drop in _drops.duplicate():
		if is_instance_valid(drop):
			drop.collect()


func _build_hint() -> void:
	_hint = PanelContainer.new()
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.z_index = 7
	_hint.add_theme_stylebox_override("panel", FlatStyle.panel(Color(FlatStyle.PANEL, 0.92), FlatStyle.INK, 14, 3))
	var label := Label.new()
	label.text = "Level %d, %s. Drag a card onto a tile, or select it and tap. Then press Start." % [LevelCatalog.number(), _level.title]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.custom_minimum_size = Vector2(480, 0)
	label.add_theme_color_override("font_color", FlatStyle.CREAM)
	label.add_theme_font_size_override("font_size", 18)
	_hint.add_child(label)
	_lawn.add_child(_hint)
	_place_hint()


## Keeps the instruction over the sky band. Hiding it must not resize the lawn.
func _place_hint() -> void:
	if _hint == null or not _hint.visible or _lawn.cell_size_px() <= 0.0:
		return
	var hint_size := _hint.get_combined_minimum_size()
	var origin := _lawn.grid_origin()
	var grid_width := _lawn.cell_size_px() * _lawn.column_count()
	_hint.size = hint_size
	var x := origin.x + (grid_width - hint_size.x) * 0.5
	x = clampf(x, 8.0, maxf(8.0, _lawn.size.x - hint_size.x - 8.0))
	var y := origin.y - hint_size.y - 4.0
	_hint.position = Vector2(x, maxf(2.0, y))


func _build_result() -> void:
	_result_layer = Control.new()
	_result_layer.visible = false
	_result_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_result_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_layer.z_index = 20
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.08, 0.05, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_layer.add_child(dim)
	var box := PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -220.0
	box.offset_right = 220.0
	box.offset_top = -90.0
	box.offset_bottom = 90.0
	box.add_theme_stylebox_override("panel", FlatStyle.panel(FlatStyle.PANEL, FlatStyle.GOLD, 18, 4))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	var message := Label.new()
	message.name = "Message"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_color_override("font_color", FlatStyle.CREAM)
	message.add_theme_font_size_override("font_size", 28)
	column.add_child(message)
	var again := Button.new()
	again.text = "Retry"
	again.custom_minimum_size = Vector2(180, 64)
	FlatStyle.apply_button(again)
	again.pressed.connect(func() -> void: get_tree().reload_current_scene())
	column.add_child(again)
	_next_button = Button.new()
	_next_button.text = "Next level"
	_next_button.custom_minimum_size = Vector2(180, 64)
	_next_button.visible = false
	FlatStyle.apply_button(_next_button)
	_next_button.pressed.connect(_go_to_next_level)
	column.add_child(_next_button)
	box.add_child(column)
	_result_layer.add_child(box)
	add_child(_result_layer)


func _show_result() -> void:
	_cancel_pointer()
	_lawn.show_aim(Vector2i(-1, -1), false)
	if _hint != null:
		_hint.visible = false
	var message := _result_layer.find_child("Message", true, false) as Label
	if message != null:
		message.text = "The garden holds." if _result == MatchOutcome.Result.WON else "The vermin broke through."
	_result_layer.visible = true
	if _next_button != null:
		_next_button.visible = _result == MatchOutcome.Result.WON and LevelCatalog.has_next()


func _go_to_next_level() -> void:
	LevelCatalog.advance()
	get_tree().reload_current_scene()


func _bind_slot_keys() -> void:
	for slot in 5:
		var key := (KEY_1 + slot) as Key
		var pad := (KEY_KP_1 + slot) as Key
		_bind_key("select_slot_%d" % [slot + 1], key)
		_bind_key("select_slot_%d" % [slot + 1], pad)


func _bind_key(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for existing in InputMap.action_get_events(action):
		if existing is InputEventKey and (existing as InputEventKey).physical_keycode == key:
			return
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)


## Screen insets when the window is fullscreen, plus a small design pad everywhere else.
func _on_viewport_resized() -> void:
	_apply_content_scale()
	_apply_safe_area()


## Fills the real window. Integer scaling leaves a tiny 1280×720 island when the window is maximized.
func _apply_content_scale() -> void:
	var window := get_window()
	if window == null:
		return
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	window.content_scale_size = Vector2i(1280, 720)
	window.content_scale_factor = 1.0


func _apply_safe_area() -> void:
	var pad := 12
	var left := pad
	var top := pad
	var right := pad
	var bottom := pad
	var mode := DisplayServer.window_get_mode()
	var fullscreen := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if fullscreen and DisplayServer.get_name() != "headless":
		var screen_index := DisplayServer.window_get_current_screen()
		var screen := Vector2(DisplayServer.screen_get_size(screen_index))
		var safe := DisplayServer.get_display_safe_area()
		var window_px := Vector2(DisplayServer.window_get_size())
		var viewport := get_viewport_rect().size
		if screen.x > 0.0 and screen.y > 0.0 and window_px.x > 0.0 and window_px.y > 0.0:
			var to_viewport := viewport / window_px
			left = int(maxf(safe.position.x, 0.0) * to_viewport.x)
			top = int(maxf(safe.position.y, 0.0) * to_viewport.y)
			right = int(maxf(screen.x - safe.end.x, 0.0) * to_viewport.x)
			bottom = int(maxf(screen.y - safe.end.y, 0.0) * to_viewport.y)
	_margin.add_theme_constant_override("margin_left", maxi(left, pad))
	_margin.add_theme_constant_override("margin_top", maxi(top, pad))
	_margin.add_theme_constant_override("margin_right", maxi(right, pad))
	_margin.add_theme_constant_override("margin_bottom", maxi(bottom, pad))


func _read_shot_args() -> void:
	var args := OS.get_cmdline_user_args()
	var shot_index := args.find("--shot")
	if shot_index >= 0 and shot_index + 1 < args.size():
		_capture_after_frames(args[shot_index + 1])
		return
	var fall_index := args.find("--fall-shot")
	if fall_index >= 0 and fall_index + 1 < args.size():
		_fall_shot = args[fall_index + 1]
		start_wave()
		_spawn_drop(4.5, 4.0, true)
		return
	var play_index := args.find("--play-shot")
	if play_index >= 0 and play_index + 1 < args.size():
		_play_shot = args[play_index + 1]
		start_wave()
		try_place(UnitCatalog.Warden.NEEDLE, 1, 2)
		try_place(UnitCatalog.Warden.BARK, 3, 2)
		spawn_vermin(UnitCatalog.Vermin.FLY, 2, 6.2)


func _capture_after_frames(output: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_save_shot(output)


func _save_shot(output: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var directory := output.get_base_dir()
	if not directory.is_empty():
		DirAccess.make_dir_recursive_absolute(directory)
	var err := image.save_png(output)
	if err != OK:
		push_error("Screenshot failed for %s: %s" % [output, error_string(err)])
		get_tree().quit(1)
		return
	print("SHOT %s %dx%d" % [output, image.get_width(), image.get_height()])
	get_tree().quit(0)
