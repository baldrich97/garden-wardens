## The playable match. Drag a card onto the lawn, spend water, and stop the level.
class_name GardenBoard
extends Control

## The top-bar water counter icon: the small drop from the origami water set.
const WATER_ICON: Texture2D = FxArt.WATER_DROP_SMALL
const CARD_SCENE := preload("res://src/ui/warden_card.tscn")
## Card faces for the bottom bar, index-aligned with UnitCatalog.Warden.
const SEED_PACKETS := [
	preload("res://assets/art/ui/seed_packets/seed_packet_dew_dropper.png"),
	preload("res://assets/art/ui/seed_packets/seed_packet_needle_spitter.png"),
	preload("res://assets/art/ui/seed_packets/seed_packet_stubborn_cone.png"),
	preload("res://assets/art/ui/seed_packets/seed_packet_rain_catcher.png"),
	preload("res://assets/art/ui/seed_packets/seed_packet_seed_lobber.png"),
]
const _WIN_BANNER_TEXTURE: Texture2D = preload("res://assets/art/ui/win_banner_A.png")
## Brandon liked both win banners "interchangeably"; the match seed picks one.
const _WIN_BANNER_B_TEXTURE: Texture2D = preload("res://assets/art/ui/win_banner_B.png")
const _LOSS_BANNER_TEXTURE: Texture2D = preload("res://assets/art/ui/loss_banner.png")
## Normalized rects of the clean cream plaque inside each banner art, measured
## from the PNG pixels (GW-P1), where the headline text gets drawn.
const _WIN_PLATE_RECT := Rect2(0.245, 0.425, 0.50, 0.105)
## Banner B's cream plaque is drawn slightly tilted; this is the level box
## inside it (x 152-307, y 94-127 of 415 x 239 px, measured GW-AA pass 2).
const _WIN_B_PLATE_RECT := Rect2(0.366, 0.393, 0.373, 0.138)
const _LOSS_PLATE_RECT := Rect2(0.20, 0.315, 0.53, 0.20)
const DRAG_SLOP := 18.0
## Cells of snail travel between slime puddles (presentation only).
const TRAIL_SPACING := 0.22
## The look the backdrop button shows after the last mood (GW-AW-7 debug tour).
const GOLDEN_HOUR_NAME := "Golden Hour"
## The F8 damage-art cycle: normal, then the three authored damage states.
const DAMAGE_CYCLE: Array[String] = ["", "100", "66", "33"]
## Turns per second of the leaf ring under the placement ghost (slow, per Brandon).
const LEAF_RING_SPIN := 0.06
## Leaf ring size as a share of one cell.
const LEAF_RING_SIZE := 0.98

## Headless probes pin the match seed here (>= 0) so every gameplay roll (bee
## wander, seed volleys, sky drops, grubs) replays exactly. -1 = --seed or a roll.
static var forced_match_seed := -1
## Responsive HUD (GW-AA pass 3). Horizontal: slim top bar plus the bottom
## card tray. Vertical: the cards become a side bar with bigger cards, for
## small windows where the tray cards get too small to tap.
const LAYOUT_HORIZONTAL := "horizontal"
const LAYOUT_VERTICAL := "vertical"
## Real-window breakpoint in physical pixels: narrower or shorter snaps to
## the vertical side bar.
const COMPACT_MAX_WIDTH := 1100
const COMPACT_MAX_HEIGHT := 640
## Gap between the side bar and the stage, in logical pixels.
const SIDEBAR_GAP := 8.0
## Unit sizing on the perspective rails (Option B): a unit's art canvas is
## this many rail cell widths tall, so the drawn body fills most of its square.
const UNIT_HEIGHT_CELLS := 1.62
const VERMIN_SIZE := 0.74
## Fliers hover this many rail cell widths above their rail point.
const FLYER_HOVER_CELLS := 0.5
## Where the needle leaves the Needle Spitter's mouth, as a share of the art
## canvas height above the ground point.
const NEEDLE_MOUTH_HEIGHT := 0.34
## Sky band in stage pixels: the open sky under the top bar and above the
## fence and sunflower heads (Option B mockup clouds sit about y 85-185).
const SKY_BAND := Rect2(0.0, 76.0, 1280.0, 96.0)
## Rain falls past the band down to the lawn's far edge.
const RAIN_FLOOR_Y := 334.0
## Falling sky drops start here (stage y) and fall to their landing spot.
const SKY_DROP_TOP := 120.0
## HUD and overlay z (absolute): over every unit, bar and lob.
const Z_HUD := 60
const Z_HINT := 50
const Z_LOB := 40
const Z_RESULT := 100
const Z_DRAG := 110
## Forces the layout ("horizontal" / "vertical"); tests and --layout set it.
static var forced_layout := ""
## Ultrawide framing (GW-AA pass 4): how the 16:9 stage fills a window of a
## different shape. MATTE letterboxes/pillarboxes the whole stage on a crisp
## dark forest-green matte (the default); COVER zooms the stage until it fills
## the width and crops the bottom instead. Flip FRAMING_DEFAULT, or pass
## --framing cover / --framing matte. Vertical (side bar) layout always mattes.
enum Framing { MATTE, COVER }
const FRAMING_DEFAULT := Framing.MATTE
const MATTE_COLOR := Color(0.09, 0.16, 0.1)
static var framing := FRAMING_DEFAULT
## Startup preload + GPU warmup (StartupPreload, GpuWarmup). On by default;
## --no-preload turns it off (the startup probe measures both ways).
static var preload_enabled := true
## Main-thread milliseconds per frame the preload may spend collecting loads.
const PRELOAD_BUDGET_MS := 4.0

@onready var _margin: MarginContainer = %SafeMargin
@onready var _top: TopBar = %TopBar
@onready var _lawn: LawnView = %Lawn
@onready var _bottom: BottomBar = %BottomBar
@onready var _background: TextureRect = %Background
@onready var _stage: Control = %Stage
## The matte behind the stage (the old blurred StageFill node, now a flat
## colour: the blur smeared and its edges showed as white seams).
@onready var _matte: ColorRect = $StageFill
@onready var _sky_fill: ColorRect = $Sky
@onready var _body: HBoxContainer = $SafeMargin/Layout/Body

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
var _layout_mode := ""
var _layout_key := []
var _golden_hour: GoldenHourBackdrop
var _sky_layer: SkyLayer
## The stage's layer slots (sky backdrop, sky props, fence, shack, compost, lawn).
var _layers: StageLayers
var _warmed := false
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
## The F8 debug pin: "" lets HP pick the damage art, otherwise this state shows.
var _forced_state := ""
var _damage_step := 0
## The F7 debug overlay: gates the seed/mood pill watermark (GW-P1).
var _debug_overlay := false
var _win_banner: TextureRect
var _loss_banner: TextureRect
## [TextureRect, Label, plate Rect2] per banner, for headline relayouts.
var _banner_layouts: Array = []
## Gameplay dice, one MatchSeed channel each, so a seed replays the whole match.
var _bee_rng: RandomNumberGenerator
var _lob_rng: RandomNumberGenerator
var _sky_rng: RandomNumberGenerator
var _grub_rng: RandomNumberGenerator
## The rotating leaf ring under the placement ghost.
var _leaf_ring: TextureRect
## Lays the leaf ring flat on the perspective lawn (foreshortened).
var _leaf_ring_holder: Node2D


func _ready() -> void:
	_read_level_arg()
	_level = LevelCatalog.current()
	_match_seed = _read_match_seed()
	_bee_rng = _match_seed.rng("bee_path")
	_lob_rng = _match_seed.rng("seed_burst")
	_sky_rng = _match_seed.rng("sky_drops")
	_grub_rng = _match_seed.rng("grub_roll")
	_wallet = WaterWallet.new(_level.water)
	_bind_slot_keys()
	_apply_content_scale()
	_apply_safe_area()
	get_viewport().size_changed.connect(_on_viewport_resized)
	# The root viewport is the window, so its size_changed covers real window
	# resizes too; connect the window only when it is a different object.
	var window := get_window()
	if window != null and window != get_viewport() and not window.size_changed.is_connected(_on_viewport_resized):
		window.size_changed.connect(_on_viewport_resized)
	_margin.z_index = Z_HUD
	_run_preload()
	_read_framing_arg()
	_build_matte()
	_build_stage_layers()
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
	_build_sky()
	_build_seed_label()
	_schedule_sky()
	_present_cards()
	_place_presets()
	_bind_tooltips()
	_refresh_hud()
	use_backdrop(BackdropCatalog.pick_index(_match_seed.value))
	apply_layout(_pick_layout())
	_read_shot_args()


func _process(delta: float) -> void:
	var step := delta * 2.0 if _fast else delta
	if _started:
		advance(step)
	elif not _paused:
		# Planted-before-Start Wardens still animate: the place hold runs on
		# real frames even though the match clock is stopped.
		for warden in _wardens:
			warden.idle_tick(step)
	if _roster != null and _roster.visible:
		var visual := 0.0 if _paused else step
		_roster.tick(visual)
	_emit_place_puffs()
	_preload_tick()
	_refresh_hud()
	_refresh_cursor()
	_relayout_if_needed()
	if _layers != null:
		_layers.tick(delta)
	if _leaf_ring != null and _leaf_ring.visible:
		_leaf_ring.rotation = fmod(_leaf_ring.rotation + delta * TAU * LEAF_RING_SPIN, TAU)
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
	if not _forced_state.is_empty():
		actor.set_forced_damage_state(_forced_state)
	_lawn.add_child(actor)
	_wardens.append(actor)
	_cooldowns[kind].start(UnitCatalog.WARDEN_COOLDOWN[kind])
	if _hint != null:
		_hint.visible = false
	_layout_actors()
	return true


## The placement pop (PaperPop): a small puff at the base of each Warden the
## moment it springs up from its pressed-flat sticker.
func _emit_place_puffs() -> void:
	for warden in _wardens:
		if not warden.consume_pop_cue():
			continue
		var cell := _lawn.geometry.rail_cell_width(float(warden.row))
		var poof := PoofActor.new()
		poof.name = "PlacePuff"
		_lawn.add_child(poof)
		poof.z_index = LawnGeometry.z_for_row(warden.row) + 3
		poof.play_at(_lawn.geometry.rail_point(float(warden.column) + 0.5, float(warden.row)) - Vector2(0.0, cell * 0.12), cell * 0.8)


## Plants the level's pre-set Wardens (LevelDef.pre_placed) for free, before
## Start. The showcase's Ladybug-hop demo uses this; no water, no cooldown.
func _place_presets() -> void:
	for preset in _level.pre_placed:
		if not _grid.is_inside(preset.x, preset.y) or _grid.occupant(preset.x, preset.y) != 0:
			continue
		var id := _next_id
		_next_id += 1
		if not _grid.try_place(preset.x, preset.y, id):
			_next_id -= 1
			continue
		var actor := WardenActor.new()
		actor.setup(int(preset.z), preset.x, preset.y, id)
		if not _forced_state.is_empty():
			actor.set_forced_damage_state(_forced_state)
		_lawn.add_child(actor)
		_wardens.append(actor)
	_layout_actors()


## Drops a Vermin into a row. The wave and the match test both use this.
func spawn_vermin(kind: UnitCatalog.Vermin, row: int, column_pos: float) -> void:
	var actor := VerminActor.new()
	actor.setup(kind, row, column_pos)
	if not _forced_state.is_empty():
		actor.set_forced_damage_state(_forced_state)
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
				_spawn_fx_still(FxArt.SMALL_BURST, _hit_point(vermin, -0.18), 0.6, 0.3, 0.0, vermin.row)
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
		_bee_rng,
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
	var last: float = _snail_last.get(vermin, INF)
	if last - vermin.column_pos < TRAIL_SPACING:
		return
	_snail_last[vermin] = vermin.column_pos
	var geometry := _lawn.geometry
	# The puddle lies on the rail just behind the shell.
	var ground := geometry.rail_point(vermin.column_pos + 0.15, float(vermin.row))
	_trail.drop(ground, geometry.rail_cell_width(float(vermin.row)))


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
		SeedBurst.pick(target, _lawn.column_count(), LawnView.ROWS, UnitCatalog.LOB_EXTRA, _lob_rng),
	)
	_lawn.add_child(lob)
	_lobs.append(lob)


func _tick_lobs(delta: float) -> void:
	var kept: Array[LobActor] = []
	for lob in _lobs:
		var landed := lob.tick(delta)
		if lob.take_burst():
			_spawn_seed_burst(lob.target_cell())
		if landed:
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
				_spawn_fx_still(FxArt.IMPACT_BURST, _hit_point(vermin, 0.0), 0.8, 0.35, 0.0, vermin.row)
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
				warden.play_catch()
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
		return _grub_rng.randf()
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


## A papercraft still (impact burst, collect flecks) that pops and fades at
## [param at] in stage pixels, [param size_cells] rail cells across (the cell
## width on [param row]'s rail), drawn just over that rail's units.
func _spawn_fx_still(texture: Texture2D, at: Vector2, size_cells: float, duration: float, rise_cells: float = 0.0, row: float = 2.0) -> void:
	var cell := _lawn.geometry.rail_cell_width(row)
	var fx := FxActor.new()
	_lawn.add_child(fx)
	fx.z_index = LawnGeometry.z_for_row(roundi(row)) + 3
	fx.play_still(texture, at, cell * size_cells, duration, cell * rise_cells)


## Where an impact lands on a Vermin: its body centre (from the art's anchor),
## nudged [param toward_cells] rail cells sideways (negative = toward the
## Wardens, where a needle comes from).
func _hit_point(vermin: VerminActor, toward_cells: float) -> Vector2:
	var cell := _lawn.geometry.rail_cell_width(float(vermin.row))
	var canvas := vermin.canvas_px()
	var body := vermin.body_center_px()
	if canvas == Vector2.INF or body == Vector2.INF or canvas.x <= 0.0:
		return vermin.position + vermin.size * Vector2(0.5, 0.6) + Vector2(cell * toward_cells, 0.0)
	return vermin.position + body * (vermin.size.x / canvas.x) + Vector2(cell * toward_cells, 0.0)


## The Seed Lobber's landing burst: the fluff ball bursting into seed fluff,
## centred on the landing tile's rail; the 480 px canvas covers about the
## 3 by 3. Drawn over every rail, with the lobbed ball.
func _spawn_seed_burst(target: Vector2i) -> void:
	var geometry := _lawn.geometry
	var cell := geometry.rail_cell_width(float(target.y))
	var at := geometry.rail_point(float(target.x) + 0.5, float(target.y)) - Vector2(0.0, cell * 0.3)
	var fx := FxActor.new()
	_lawn.add_child(fx)
	fx.z_as_relative = false
	fx.z_index = Z_LOB + 1
	fx.play_frames(FxArt.lobber_burst(), at, cell * 2.4, 30.0)


## Plays out the death poses (bounded), then poofs at the actor and frees it.
func _tick_dying_vermin(delta: float) -> void:
	var kept: Array[VerminActor] = []
	for vermin in _dying_vermin:
		if not vermin.tick_death(delta):
			kept.append(vermin)
			continue
		var poof := PoofActor.new()
		_lawn.add_child(poof)
		poof.z_index = LawnGeometry.z_for_row(vermin.row) + 3
		poof.play_at(_hit_point(vermin, 0.0), _lawn.geometry.rail_cell_width(float(vermin.row)) * 0.95)
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
		var cell := _lawn.geometry.rail_cell_width(float(warden.row))
		var poof := PoofActor.new()
		_lawn.add_child(poof)
		poof.z_index = LawnGeometry.z_for_row(warden.row) + 3
		poof.play_at(_lawn.geometry.rail_point(float(warden.column) + 0.5, float(warden.row)) - Vector2(0.0, cell * 0.45), cell * 1.0)
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
	var geometry := _lawn.geometry
	for warden in _wardens:
		_stand_unit(warden, float(warden.column) + 0.5, float(warden.row), UNIT_HEIGHT_CELLS, 0.0)
	for warden in _dying_wardens:
		_stand_unit(warden, float(warden.column) + 0.5, float(warden.row), UNIT_HEIGHT_CELLS, 0.0)
	for vermin in _vermin:
		var lift := vermin.hop_lift_tiles * geometry.rail_cell_width(float(vermin.row))
		_stand_unit(vermin, vermin.column_pos, float(vermin.row), UNIT_HEIGHT_CELLS * VERMIN_SIZE, lift)
	for vermin in _dying_vermin:
		_stand_unit(vermin, vermin.column_pos, float(vermin.row), UNIT_HEIGHT_CELLS * VERMIN_SIZE, 0.0)
	for shot in _shots:
		var cell := geometry.rail_cell_width(float(shot.row))
		var box := cell * 0.55
		var mouth := geometry.rail_point(shot.column_pos + 0.1, float(shot.row)) - Vector2(0.0, cell * UNIT_HEIGHT_CELLS * NEEDLE_MOUTH_HEIGHT)
		shot.size = Vector2(box, box)
		shot.position = mouth - shot.size * 0.5
		shot.z_index = LawnGeometry.z_for_row(shot.row) + 2
	for lob in _lobs:
		lob.place_on_lawn(geometry)
		lob.z_as_relative = false
		lob.z_index = Z_LOB
	for drop in _drops:
		if is_instance_valid(drop):
			_place_drop(drop)
	_place_hint()


## Stands one unit on its rail (Option B): the art canvas is [param height_cells]
## rail cell widths tall; ground units pin their ground point to the rail point,
## fliers hover their body centre above it. [param lift] raises the unit (hops).
## Z follows the rail, so a front-rail unit's top covers a back-rail unit's base.
func _stand_unit(actor: Control, column_pos: float, row_pos: float, height_cells: float, lift: float) -> void:
	var geometry := _lawn.geometry
	var cell := geometry.rail_cell_width(row_pos)
	var foot := geometry.rail_point(column_pos, row_pos)
	var canvas: Vector2 = actor.call("canvas_px")
	var flying: bool = actor.call("is_flying")
	var z := LawnGeometry.z_for_row(roundi(row_pos))
	actor.z_index = z + (1 if actor is VerminActor else 0)
	if canvas == Vector2.INF or canvas.y <= 0.0:
		# Legacy clip with no manifest: a square box standing on the rail.
		var box := cell * height_cells * 0.7
		actor.size = Vector2(box, box)
		actor.position = foot - Vector2(box * 0.5, box + lift)
	else:
		var f := height_cells * cell / canvas.y
		actor.size = canvas * f
		if flying:
			var body: Vector2 = actor.call("body_center_px")
			var center := foot - Vector2(0.0, FLYER_HOVER_CELLS * cell + lift)
			actor.position = center - body * f
		else:
			actor.position = foot - Vector2(actor.size.x * 0.5, actor.size.y + lift)
	actor.call("set_rail_stand", foot - actor.position, cell)


## A water drop on the perspective lawn: landed drops sit on their rail spot;
## sky drops fall in screen space from the sky to that spot as they progress.
func _place_drop(drop: WaterDrop) -> void:
	var geometry := _lawn.geometry
	var cell := geometry.rail_cell_width(drop.land_row)
	var ground := geometry.rail_point(drop.column_pos, drop.land_row)
	var box := cell * drop.box_scale()
	drop.size = Vector2(box, box)
	var bottom := ground.y + cell * WaterDrop.LANDED_BOX * 0.12
	if drop.falling:
		var span := drop.land_row - UnitCatalog.SKY_SPAWN_ROW
		var progress := 1.0 if absf(span) < 0.001 else clampf((drop.row_pos - UnitCatalog.SKY_SPAWN_ROW) / span, 0.0, 1.0)
		bottom = lerpf(SKY_DROP_TOP, bottom, progress)
	drop.position = Vector2(ground.x - box * 0.5, bottom - box)
	drop.z_index = LawnGeometry.z_for_row(roundi(drop.land_row)) + 2


## Builds the drifting sky over the lawn (GW-AW-6b): stick clouds, the
## match's sun, and rain when the seed says so. Sits on the stage over the
## backdrop and under the lawn, so actors always draw over it.
func _build_sky() -> void:
	_sky_layer = SkyLayer.new()
	_sky_layer.name = "SkyLayer"
	_layers.sky_props.add_child(_sky_layer)
	_layout_sky()


## The sky band in stage pixels: clouds and the sun stay in the open sky
## above the fence; rain still falls to the lawn's far edge. Cloud and sun
## tuning (sizes, bob, speed) is untouched; only the band moved.
func _layout_sky() -> void:
	if _sky_layer == null:
		return
	_sky_layer.set_band(SKY_BAND, RAIN_FLOOR_Y)


## A small watermark naming the visual seed and look, so a match can be
## replayed with --seed N.
func _build_seed_label() -> void:
	_seed_panel = PanelContainer.new()
	_seed_panel.name = "SeedLabel"
	# PASS (not IGNORE) so hovering the watermark can raise its debug tooltip;
	# clicks still reach the lawn underneath.
	_seed_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_seed_panel.add_theme_stylebox_override("panel", FlatStyle.panel(Color(FlatStyle.PANEL, 0.55), FlatStyle.INK, 10, 2))
	_seed_label = Label.new()
	_seed_label.add_theme_color_override("font_color", FlatStyle.CREAM)
	_seed_label.add_theme_font_size_override("font_size", 12)
	_seed_panel.add_child(_seed_label)
	_lawn.add_child(_seed_panel)
	_seed_panel.z_as_relative = false
	_seed_panel.z_index = Z_HINT
	_seed_panel.position = LawnGeometry.FAR_LEFT + Vector2(0.0, -34.0)
	_refresh_seed_label()


func _refresh_seed_label() -> void:
	if _seed_label == null or _match_seed == null:
		return
	# GW-P1: the pill is a debug watermark, not HUD. It shows only with the
	# F7 debug overlay on, or while F8 pins a damage state (pinned art is
	# itself debug-only, and the pin reads inside this pill).
	_seed_panel.visible = _debug_overlay or not _forced_state.is_empty()
	var look := GOLDEN_HOUR_NAME if _golden_hour != null else BackdropCatalog.NAMES[_backdrop]
	var damage_hint := "" if _forced_state.is_empty() else ", Dmg %s" % _forced_state
	_seed_label.text = "Seed %d, %s%s" % [_match_seed.value, look, damage_hint]


func _set_debug_overlay(active: bool) -> void:
	_debug_overlay = active
	_refresh_seed_label()


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
	var allowed := _can_place(kind, aim.x, aim.y)
	_lawn.show_aim(aim, allowed)
	_refresh_ghost(aim, kind, allowed)


## The snail's slime trail: a pooled node on the lawn, under the vermin.
func _build_trail() -> void:
	_trail = SnailTrail.new()
	_lawn.add_child(_trail)


## Builds the translucent hover preview once and parks it on the lawn.
func _build_ghost() -> void:
	_ghost = Control.new()
	_ghost.name = "PlantGhost"
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost.modulate = Color(1, 1, 1, 0.4)
	_ghost.visible = false
	_ghost_clip = ClipView.new()
	_ghost_clip.set_motion_enabled(false)
	_ghost.add_child(_ghost_clip)
	_leaf_ring = TextureRect.new()
	_leaf_ring.name = "LeafRing"
	_leaf_ring.texture = FxArt.LEAF_RING
	_leaf_ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_leaf_ring.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_leaf_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_leaf_ring.visible = false
	# The holder lies the ring flat on the tile: it scales the round ring to
	# the tile's foreshortened depth while the ring turns inside it.
	_leaf_ring_holder = Node2D.new()
	_leaf_ring_holder.name = "LeafRingHolder"
	_leaf_ring_holder.z_index = LawnView.Z_CURSOR + 2
	_leaf_ring_holder.add_child(_leaf_ring)
	_lawn.add_child(_leaf_ring_holder)
	_lawn.add_child(_ghost)
	_lawn.mouse_entered.connect(_on_lawn_mouse_entered)
	_lawn.mouse_exited.connect(_on_lawn_mouse_exited)


func _on_lawn_mouse_entered() -> void:
	_mouse_over_lawn = true


func _on_lawn_mouse_exited() -> void:
	_mouse_over_lawn = false


## Shows the selected Warden on the hovered tile at a quarter of its strength,
## so a placed Warden and the green or red tile cursor still read on top, on
## the slowly turning leaf ring (dimmed red when the plant cannot go there).
func _refresh_ghost(aim: Vector2i, kind: int, allowed: bool = true) -> void:
	var hovered := _mouse_over_lawn or _aim_from_keys
	if not hovered or _grid.occupant(aim.x, aim.y) != 0:
		_hide_ghost()
		return
	if kind != _ghost_kind:
		_ghost_kind = kind
		_build_ghost_clip(kind)
	_stand_ghost(aim)
	_ghost_clip.tick(0.0, _ghost.size)
	_ghost.visible = true
	var geometry := _lawn.geometry
	var cell := geometry.cell_width(float(aim.y) + 0.5)
	var ring := cell * LEAF_RING_SIZE
	_leaf_ring.size = Vector2(ring, ring)
	_leaf_ring.position = -_leaf_ring.size * 0.5
	_leaf_ring.pivot_offset = _leaf_ring.size * 0.5
	_leaf_ring_holder.position = geometry.point(float(aim.x) + 0.5, float(aim.y) + 0.5)
	_leaf_ring_holder.scale = Vector2(1.0, geometry.row_height(aim.y) / maxf(cell, 1.0))
	_leaf_ring.modulate = Color(1, 1, 1, 0.9) if allowed else Color(1.0, 0.55, 0.5, 0.75)
	_leaf_ring.visible = true


func _hide_ghost() -> void:
	if _ghost != null:
		_ghost.visible = false
	if _leaf_ring != null:
		_leaf_ring.visible = false


## The preview stands on the hovered tile's rail exactly like a planted Warden.
func _stand_ghost(aim: Vector2i) -> void:
	var geometry := _lawn.geometry
	var cell := geometry.rail_cell_width(float(aim.y))
	var foot := geometry.rail_point(float(aim.x) + 0.5, float(aim.y))
	var canvas := AnimLibrary.canvas_px(AnimLibrary.warden_folder(_ghost_kind))
	if canvas == Vector2.INF or canvas.y <= 0.0:
		_ghost.size = Vector2(cell, cell)
		_ghost.position = foot - Vector2(cell * 0.5, cell)
	else:
		_ghost.size = canvas * (UNIT_HEIGHT_CELLS * cell / canvas.y)
		_ghost.position = foot - Vector2(_ghost.size.x * 0.5, _ghost.size.y)
	_ghost.z_index = LawnGeometry.z_for_row(aim.y)


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


## The debug look tour (GW-AW-7): the four seeded moods, then the composed
## Golden Hour as its last stop, then back to the first mood.
func _cycle_backdrop() -> void:
	if _golden_hour != null:
		use_golden_hour(false)
		use_backdrop(0)
		return
	if _backdrop == BackdropCatalog.count() - 1:
		use_golden_hour(true)
		return
	use_backdrop(_backdrop + 1)


func _apply_backdrop() -> void:
	var texture := BackdropCatalog.texture_at(_backdrop)
	if texture != null:
		_background.texture = texture
	_apply_set_light(_backdrop)
	_bottom.set_backdrop_name(BackdropCatalog.NAMES[_backdrop])
	_refresh_seed_label()
	if _sky_layer != null:
		_sky_layer.apply_look(_match_seed.value, _backdrop)


## Lights the shared set (fence, porch, heap, lawn ground, felt) for a look;
## [param look] -1 is Golden Hour.
func _apply_set_light(look: int) -> void:
	if _layers != null:
		_layers.apply_look(look)
	_lawn.set_felt_tint(BackdropCatalog.felt_tint(look))


## The value this match's look was picked from. Shown on the debug label.
func visual_seed() -> int:
	return _match_seed.value


## Forces the Golden Hour layered backdrop on or off. AW-7's showcase toggle
## (the backdrop cycle's last stop, and --golden-hour) calls this; ordinary
## matches leave it alone. The seeded sky hides while it is on: Golden Hour
## paints its own sky and sun, and two skies would double the celestials.
func use_golden_hour(enabled: bool) -> void:
	if enabled and _golden_hour == null:
		# Golden Hour's sky (base, ray wheels, sun) fills the sky backdrop
		# slot; the shared set plates stand in front of it, warmly lit. Its
		# own foreground plate is left out (the set plates replace it).
		_golden_hour = GoldenHourBackdrop.compose(_layers.sky_backdrop, false)
		_apply_set_light(-1)
		if _sky_layer != null:
			_sky_layer.apply_look(_match_seed.value, SkyLook.MOOD_GOLDEN_HOUR)
		# The look button names whatever look is showing, however it was set.
		_bottom.set_backdrop_name(GOLDEN_HOUR_NAME)
	elif not enabled and _golden_hour != null:
		_golden_hour.queue_free()
		_golden_hour = null
		_apply_backdrop()
	_refresh_seed_label()


## Whether the composed Golden Hour look is showing.
func golden_hour_active() -> bool:
	return _golden_hour != null


## The stage's layer slots, for tests and probes.
func stage_layers() -> StageLayers:
	return _layers


## The sky props layer, for tests and probes.
func sky_layer() -> SkyLayer:
	return _sky_layer


## F8 (and --damage-state): pin every visible unit's art to the next damage
## state in the cycle normal -> 100 -> 66 -> 33 -> normal, no combat needed.
## Units placed or spawned after a pin adopt it too, until the cycle returns
## to normal. HP, bars, and combat are untouched.
func _cycle_damage_state() -> void:
	_damage_step = (_damage_step + 1) % DAMAGE_CYCLE.size()
	_forced_state = DAMAGE_CYCLE[_damage_step]
	_apply_forced_state()


## Pins every live actor's damage art to the current _forced_state.
func _apply_forced_state() -> void:
	for warden in _wardens:
		warden.set_forced_damage_state(_forced_state)
	for vermin in _vermin:
		vermin.set_forced_damage_state(_forced_state)
	_refresh_seed_label()


## Picks the level for a debug run (the showcase is --level 8) without
## playing to it. 1-based, clamped to the catalog.
func _read_level_arg() -> void:
	var args := OS.get_cmdline_user_args()
	var index := args.find("--level")
	if index >= 0 and index + 1 < args.size() and args[index + 1].is_valid_int():
		LevelCatalog.index = clampi(int(args[index + 1]) - 1, 0, LevelCatalog.count() - 1)


## The match's dice cup. --seed N on the command line (or forced_match_seed
## from a headless probe) replays a look and every gameplay roll.
func _read_match_seed() -> MatchSeed:
	if forced_match_seed >= 0:
		return MatchSeed.with_value(forced_match_seed)
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


## Flips pause the same way the top bar's Pause button does (Space).
func toggle_pause() -> void:
	if _result != MatchOutcome.Result.ONGOING:
		return
	_top.set_paused(not _paused)


func is_paused() -> bool:
	return _paused


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_F7:
		_set_debug_overlay(not _debug_overlay)
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_F8:
		_cycle_damage_state()
		return
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


func _toggle_card(index: int) -> void:
	_set_removing(false)
	_selected = -1 if _selected == index else index


func _selected_kind() -> int:
	if _selected < 0 or _selected >= _bottom.cards().size():
		return -1
	return _bottom.cards()[_selected].kind


func _input(event: InputEvent) -> void:
	# Space pauses and un-pauses (GW-AA pass 4), through the top bar's Pause
	# button so the two always agree. Taken in _input so a focused button can
	# never turn the key into its own press; key repeat is ignored.
	if event is InputEventKey and event.pressed and not event.echo \
			and (event as InputEventKey).physical_keycode == KEY_SPACE:
		toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		# Right-click cancels anywhere in the window. The viewport eats mouse events over
		# STOP controls (the lawn among them), so _unhandled_input never sees them.
		_selected = -1
		_cancel_pointer()
		_set_removing(false)
		return
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
		if button.button_index == MOUSE_BUTTON_LEFT and not button.pressed:
			_release_pointer()
			# Do NOT mark the release handled: the viewport needs it to drop
			# mouse_focus. Swallowing it strands focus on the card, and every
			# later mouse motion gets dispatched to the card instead of the lawn.


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
	_drag_ghost.z_index = Z_DRAG
	_set_drops_locked(true)
	if _tip != null:
		_tip.dismiss()
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
	_tip.avoid_provider = _tip_avoid_rects
	add_child(_tip)
	_roster = WaveRoster.new()
	# The pre-wave panel is a slim strip in the sky's top-right corner, under
	# the top bar: it never covers the lawn (GW-AA pass 3).
	add_child(_roster)
	_roster.z_index = Z_HUD
	_roster.fill(_tip, _level.wave)
	_roster.start_requested.connect(start_wave)
	_lawn.mouse_exited.connect(func() -> void: _tip.cancel())


## What a locked tooltip must never cover: the pre-wave hint banner and the
## wave roster, while they show (global pixels).
func _tip_avoid_rects() -> Array:
	var out: Array = []
	if _hint != null and _hint.is_visible_in_tree():
		out.append(_hint.get_global_rect())
	if _roster != null and _roster.is_visible_in_tree():
		out.append(_roster.get_global_rect())
	return out


## The tooltip, for tests and probes.
func tooltip() -> GameTooltip:
	return _tip


## The pre-wave hint banner, for tests and probes.
func hint_banner() -> Control:
	return _hint


func _bind_tooltips() -> void:
	var cards := _bottom.cards()
	for card in cards:
		GameTooltip.attach(card, UnitCatalog.warden_blurb(card.kind), _tip)
	GameTooltip.attach(_bottom.find_child("AbilityButton", true, false) as Control, "No ability yet.", _tip)
	GameTooltip.attach(_bottom.find_child("RemoveButton", true, false) as Control, "Dig up a planted Warden. The water is not returned.", _tip)
	GameTooltip.attach(_top.find_child("SpeedButton", true, false) as Control, "Run the wave at double time.", _tip)
	GameTooltip.attach(_top.find_child("PauseButton", true, false) as Control, "Freeze the match.", _tip)
	GameTooltip.attach(_top.find_child("PreviewButton", true, false) as Control, "Preview each unit's idle, attack, and walk clips.", _tip)
	GameTooltip.attach(_bottom.find_child("BackdropButton", true, false) as Control, "Show the next look. The match opens on the look its seed picked: Main, Sunny, Overcast, or Dusk; one stop past Dusk shows the Golden Hour backdrop.", _tip)
	GameTooltip.attach(_seed_panel, "Debug: F8 cycles every unit's damage art 100, 66, 33, normal.", _tip)
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
	# In the sky just above the felt's far edge (board pixels), never over tiles.
	var far_edge := (_lawn.get_global_transform() * LawnGeometry.FAR_LEFT).y
	_tip.request("cell:%d,%d" % [cell.x, cell.y], text, maxf(far_edge - 6.0, 80.0))


func _warden_blurb(kind: UnitCatalog.Warden) -> String:
	return UnitCatalog.warden_blurb(kind)


func _vermin_blurb(kind: UnitCatalog.Vermin) -> String:
	return UnitCatalog.vermin_blurb(kind)


func _schedule_sky() -> void:
	_next_sky = _time + UnitCatalog.SKY_INTERVAL + _sky_rng.randf_range(-UnitCatalog.SKY_JITTER, UnitCatalog.SKY_JITTER)


func _spawn_sky() -> void:
	if _time < _next_sky:
		return
	_schedule_sky()
	var column := _sky_rng.randi_range(0, _lawn.column_count() - 1)
	var row := _sky_rng.randi_range(0, LawnView.ROWS - 1)
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
	if is_instance_valid(drop):
		_spawn_fx_still(FxArt.COLLECT_FLECKS, drop.position + drop.size * 0.5, 0.7, 0.45, 0.25)


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
	_hint.z_as_relative = false
	_hint.z_index = Z_HINT
	_hint.add_theme_stylebox_override("panel", FlatStyle.panel(Color(FlatStyle.PANEL, 0.92), FlatStyle.INK, 14, 3))
	var label := Label.new()
	label.text = "Level %d, %s. Drag a card onto a tile, or select it and tap. Then press Start." % [LevelCatalog.number(), _level.title]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.custom_minimum_size = Vector2(440, 0)
	label.add_theme_color_override("font_color", FlatStyle.CREAM)
	label.add_theme_font_size_override("font_size", 16)
	_hint.add_child(label)
	_lawn.add_child(_hint)
	_place_hint()


## Keeps the instruction in the sky just over the lawn's far edge, centred
## on the felt. Hiding it must not move the lawn.
func _place_hint() -> void:
	if _hint == null or not _hint.visible:
		return
	var hint_size := _hint.get_combined_minimum_size()
	_hint.size = hint_size
	var far_mid := (LawnGeometry.FAR_LEFT.x + LawnGeometry.FAR_RIGHT.x) * 0.5
	_hint.position = Vector2(far_mid - hint_size.x * 0.5, LawnGeometry.FAR_LEFT.y - hint_size.y - 10.0)


func _build_result() -> void:
	_result_layer = Control.new()
	_result_layer.visible = false
	_result_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_result_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_layer.z_index = Z_RESULT
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
	var banner_b := _match_seed.rng("win_banner").randi_range(0, 1) == 1
	_win_banner = _make_banner(
		_WIN_BANNER_B_TEXTURE if banner_b else _WIN_BANNER_TEXTURE,
		"VICTORY!",
		_WIN_B_PLATE_RECT if banner_b else _WIN_PLATE_RECT,
	)
	_win_banner.name = "WinBanner"
	_win_banner.visible = false
	column.add_child(_win_banner)
	_loss_banner = _make_banner(_LOSS_BANNER_TEXTURE, "DEFEAT", _LOSS_PLATE_RECT)
	_loss_banner.name = "LossBanner"
	_loss_banner.visible = false
	column.add_child(_loss_banner)
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
	if _win_banner != null:
		_win_banner.visible = _result == MatchOutcome.Result.WON
	if _loss_banner != null:
		_loss_banner.visible = _result == MatchOutcome.Result.LOST
	for layout in _banner_layouts:
		_layout_banner(layout[0], layout[1], layout[2])
	_result_layer.visible = true
	if _next_button != null:
		_next_button.visible = _result == MatchOutcome.Result.WON and LevelCatalog.has_next()


func _go_to_next_level() -> void:
	LevelCatalog.advance()
	get_tree().reload_current_scene()


## A result-banner image: fixed box, art centered inside at its own aspect,
## and the headline Label painted onto the art's cream plaque (GW-P1: the
## ribbons are text-free art, so the game draws the word itself).
func _make_banner(texture: Texture2D, headline: String, plate: Rect2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.custom_minimum_size = Vector2(320, 190)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var label := Label.new()
	label.name = "Headline"
	label.text = headline
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", FlatStyle.INK)
	rect.add_child(label)
	rect.resized.connect(_layout_banner.bind(rect, label, plate))
	_banner_layouts.append([rect, label, plate])
	return rect


## Places the headline Label over the plaque region of the drawn art and sizes
## the font down until the word fits inside it.
func _layout_banner(rect: TextureRect, label: Label, plate: Rect2) -> void:
	if rect.texture == null or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var tex_size := rect.texture.get_size()
	var fit := minf(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
	var drawn := tex_size * fit
	var origin := (rect.size - drawn) * 0.5
	var area := Rect2(origin + plate.position * drawn, plate.size * drawn)
	label.position = area.position
	label.size = area.size
	var font := ThemeDB.fallback_font
	var size := maxi(8, int(area.size.y * 0.85))
	while size > 8 and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, -1, size).x > area.size.x:
		size -= 1
	label.add_theme_font_size_override("font_size", size)


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
	var mode := _pick_layout()
	if mode != _layout_mode:
		apply_layout(mode)
	_layout_key = []


## Which layout a real window of [param window_px] physical pixels gets:
## narrower than COMPACT_MAX_WIDTH or shorter than COMPACT_MAX_HEIGHT snaps
## the cards to the vertical side bar.
static func layout_for_window(window_px: Vector2i) -> String:
	if window_px.x < COMPACT_MAX_WIDTH or window_px.y < COMPACT_MAX_HEIGHT:
		return LAYOUT_VERTICAL
	return LAYOUT_HORIZONTAL


## The layout to use now: forced_layout, then --layout, then the real window.
func _pick_layout() -> String:
	if forced_layout == LAYOUT_HORIZONTAL or forced_layout == LAYOUT_VERTICAL:
		return forced_layout
	var args := OS.get_cmdline_user_args()
	var at := args.find("--layout")
	if at >= 0 and at + 1 < args.size() and args[at + 1] in [LAYOUT_HORIZONTAL, LAYOUT_VERTICAL]:
		return args[at + 1]
	var window := get_window()
	if window == null or DisplayServer.get_name() == "headless":
		return LAYOUT_HORIZONTAL
	return layout_for_window(window.size)


## The active layout ("horizontal" or "vertical").
func layout_mode() -> String:
	return _layout_mode


## Switches the card selector between the bottom tray and the side bar, live.
func apply_layout(mode: String) -> void:
	_layout_mode = LAYOUT_VERTICAL if mode == LAYOUT_VERTICAL else LAYOUT_HORIZONTAL
	var vertical := _layout_mode == LAYOUT_VERTICAL
	var layout := _margin.get_node("Layout") as VBoxContainer
	if vertical and _bottom.get_parent() != _body:
		_bottom.reparent(_body, false)
		_body.move_child(_bottom, 0)
	elif not vertical and _bottom.get_parent() != layout:
		_bottom.reparent(layout, false)
		layout.move_child(_bottom, layout.get_child_count() - 1)
	_bottom.set_vertical(vertical)
	_top.set_compact(true)
	_layout_key = []
	_layout_stage()


## Re-fits the stage when the window, the safe area, or the HUD's sizes
## change (containers settle a frame after a switch).
func _relayout_if_needed() -> void:
	var key := [size, _bottom.get_global_rect(), _top.get_global_rect(), _layout_mode]
	if key != _layout_key:
		_layout_key = key
		_layout_stage()


## Fits the 1280x720 stage (backdrop, sky, lawn, units) into the area the HUD
## leaves: the whole screen in horizontal mode (the tray and top bar float
## over the painted sky and the porch step, as in Option B), right of the side
## bar in vertical mode. Uniform scale, centred, top-aligned; any gap shows
## a soft, blurred extension of the backdrop.
func _layout_stage() -> void:
	if _stage == null:
		return
	var area := Rect2(Vector2.ZERO, size)
	if _layout_mode == LAYOUT_VERTICAL:
		var side := _bottom.get_global_rect()
		var left := side.end.x + SIDEBAR_GAP - global_position.x
		area = Rect2(left, 0.0, maxf(size.x - left, 1.0), size.y)
	var fit_x := area.size.x / LawnGeometry.REF_SIZE.x
	var fit_y := area.size.y / LawnGeometry.REF_SIZE.y
	var s := minf(fit_x, fit_y)
	if framing == Framing.COVER and _layout_mode != LAYOUT_VERTICAL:
		s = maxf(fit_x, fit_y)
	s = maxf(s, 0.05)
	var stage_size := LawnGeometry.REF_SIZE * s
	_stage.size = LawnGeometry.REF_SIZE
	_stage.scale = Vector2(s, s)
	# Top-aligned: the stage's top edge is the screen's top edge, so the cloud
	# sticks always run up behind the top bar to y = 0. Spare width or height
	# shows the matte; cover framing crops the overflow instead. Whole pixels,
	# so no hairline of the window background shows at the stage's edges.
	_stage.position = Vector2(roundf(area.position.x + (area.size.x - stage_size.x) * 0.5), roundf(area.position.y))
	_place_roster()


## The stage's rect in board pixels (after the responsive fit).
func stage_rect() -> Rect2:
	return Rect2(_stage.position, LawnGeometry.REF_SIZE * _stage.scale)


## The matte: one flat colour behind the stage, and the stage clips its own
## contents (Golden Hour's ray wheels, drifting clouds, the backdrop) so
## nothing ever spills onto it.
func _build_matte() -> void:
	_matte.material = null
	_matte.color = MATTE_COLOR
	_sky_fill.color = MATTE_COLOR
	_stage.clip_contents = true


## The matte colour (tests check the margins against it).
func matte_color() -> Color:
	return MATTE_COLOR


func _read_framing_arg() -> void:
	var args := OS.get_cmdline_user_args()
	var index := args.find("--framing")
	if index >= 0 and index + 1 < args.size():
		framing = Framing.COVER if args[index + 1] == "cover" else Framing.MATTE


## Loads every clip, effect, look and shader before the first frame, then
## warms the renderer on frames 0-1 (see StartupPreload for the root causes).
func _run_preload() -> void:
	if OS.get_cmdline_user_args().has("--no-preload"):
		preload_enabled = false
	if not preload_enabled:
		return
	if not StartupPreload.threaded_ok():
		return  # Headless tests: no GPU and no player waiting on a first click.
	# Start loading once the first frame is up, so the board shows at once.
	await RenderingServer.frame_post_draw
	if is_inside_tree():
		StartupPreload.begin()


func _exit_tree() -> void:
	# Quitting mid-preload: stop and join the loader threads.
	if not StartupPreload.is_done():
		StartupPreload.cancel()


## Collects preloaded files a few ms per frame; once everything is in, warms
## the renderer for two frames (GpuWarmup).
func _preload_tick() -> void:
	if not preload_enabled or _warmed or not StartupPreload.threaded_ok() or not StartupPreload.begun():
		return
	if StartupPreload.poll(PRELOAD_BUDGET_MS):
		_warmed = true
		var warmup := GpuWarmup.new()
		add_child(warmup)
		move_child(warmup, 0)


## Builds the six layer slots inside the stage (see StageLayers).
func _build_stage_layers() -> void:
	_layers = StageLayers.new()
	_layers.build(_stage, _background, _lawn)


## The wave roster sits top-right, just under the top bar.
func _place_roster() -> void:
	if _roster == null:
		return
	var roster_size := _roster.get_combined_minimum_size()
	_roster.size = roster_size
	var top := _top.get_global_rect().end.y - global_position.y + 8.0
	_roster.position = Vector2(size.x - roster_size.x - 12.0, top)


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
	var pad_y := 6
	var left := pad
	var top := pad_y
	var right := pad
	var bottom := pad_y
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
	_margin.add_theme_constant_override("margin_top", maxi(top, pad_y))
	_margin.add_theme_constant_override("margin_right", maxi(right, pad))
	_margin.add_theme_constant_override("margin_bottom", maxi(bottom, pad_y))


func _read_shot_args() -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("--debug-overlay"):
		_set_debug_overlay(true)
	var gh_index := args.find("--golden-hour")
	if gh_index >= 0:
		use_golden_hour(true)
		_bottom.set_backdrop_name(GOLDEN_HOUR_NAME)
	var damage_index := args.find("--damage-state")
	if damage_index >= 0 and damage_index + 1 < args.size() \
			and DAMAGE_CYCLE.has(args[damage_index + 1]) and args[damage_index + 1] != "":
		_forced_state = args[damage_index + 1]
		_damage_step = DAMAGE_CYCLE.find(_forced_state)
		_apply_forced_state()
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
	var result_index := args.find("--result-shot")
	if result_index >= 0 and result_index + 1 < args.size():
		var won := args[result_index + 1] == "win"
		var output := args[result_index + 2] if result_index + 2 < args.size() \
				else "build/screenshots/result_%s.png" % ["win" if won else "loss"]
		_show_result_for_shot(won, output)


## Shows the win or loss banner on command (debug screenshot aid only). The
## match is frozen with its spawns consumed, so nothing keeps ticking behind
## the banner; LevelCatalog is never advanced.
func _show_result_for_shot(won: bool, output: String) -> void:
	_paused = true
	_next_spawn = _level.wave.size()
	_result = MatchOutcome.Result.WON if won else MatchOutcome.Result.LOST
	if _roster != null:
		_roster.visible = false
	_show_result()
	_capture_after_frames(output)


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
