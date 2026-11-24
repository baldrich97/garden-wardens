## One Vermin walking left along a row. [member column_pos] is in cell units.
## The board decides when it walks, chews, or dies; the actor renders the
## lifecycle from AnimLibrary clips: spawn at the lane entrance, move while
## advancing (idle while a Bee hovers between its tile steps), action while
## chewing, hurt on a hit (then back to the interrupted pose), and death
## played out and handed to the poof before the actor frees. A damage-state
## change swaps the showing clip in place keeping the frame, as on Wardens.
## The Bee's lane-change clips — rise (up) and drop (down) — hold in place
## for their authored duration, then hand back to the board's pose.
## A hopping Ladybug shows the flutter clips instead: the board owns the arc
## and names the clip (takeoff, air, land) each step through
## [method VerminActor.tick_flutter].
class_name VerminActor
extends Control

## Longest the death pose may hold before the poof takes over.
const DEATH_CAP := 2.5
## Longest the lane-entrance clip may hold before the walk takes over.
const SPAWN_CAP := 2.5
## Shortest a stride shows after a Bee hops a tile, so the walk clip reads
## before the hover idle comes back between steps.
const STEP_HOLD := 0.6

## Which lifecycle animation is showing right now.
enum Pose { MOVE, IDLE, SPAWN, ACTION, HURT, DEATH, RISE, DROP, FLUTTER }
## What the board says this Vermin is doing this step.
enum Mode { MOVE, IDLE, CHEW, FLUTTER }

var kind: UnitCatalog.Vermin
var row: int
var column_pos: float
var hp: int
var max_hp: int
var bee_column: int
var bee_since_forward: int
var bee_since_backward: int = 5
var bee_wait: float = UnitCatalog.BEE_STEP
## Seconds into the flutter hop, or -1 while grounded. The board drives these
## three fields through [method FlutterHop]; [member hop_lift_tiles] is the
## arc height the layout lifts the box by.
var hop_elapsed := -1.0
var hop_from := 0.0
var hop_lift_tiles := 0.0

var _clip: ClipView
var _bar: ColorRect
var _bar_back: ColorRect
## Rail stand (GW-AA pass 3): contact shadow, actor-local foot, rail cell width.
var _shadow: TextureRect
var _foot := Vector2.INF
var _rail_cell := 0.0
var _folder := ""
var _frames: SpriteFrames
var _pose := Pose.MOVE
var _pose_wait := 0.0
var _return_pose := Pose.MOVE
var _return_wait := 0.0
var _hp_state := "100"
var _forced_state := ""
var _dying := false
## Which flutter clip the board asked for this step (the hop base name).
var _flutter_base := FlutterHop.PHASE_AIR


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 3


func setup(p_kind: UnitCatalog.Vermin, p_row: int, p_column_pos: float) -> void:
	kind = p_kind
	row = p_row
	column_pos = p_column_pos
	max_hp = UnitCatalog.VERMIN_HP[kind]
	hp = max_hp
	if kind == UnitCatalog.Vermin.BEE:
		bee_column = maxi(0, int(floor(p_column_pos)))
		column_pos = float(bee_column) + 0.5
		bee_since_forward = 0
		bee_since_backward = 5
		bee_wait = UnitCatalog.BEE_STEP
	_folder = AnimLibrary.vermin_folder(kind)
	_frames = AnimLibrary.vermin(kind)
	_clip = ClipView.new()
	_clip.setup(_frames)
	# Ground vermin pin their authored ground point to the box floor; fliers
	# carry no ground point and keep the centered fit.
	var ground := AnimLibrary.ground_point_px(_folder)
	var canvas := AnimLibrary.canvas_px(_folder)
	if ground != Vector2.INF and canvas != Vector2.INF:
		_clip.set_anchor_fit(ground, canvas)
	_shadow = RailStand.make_shadow()
	add_child(_shadow)
	add_child(_clip)
	_clip.set_idle_bob(is_flying())
	_bar_back = ColorRect.new()
	_bar_back.color = Color(0.08, 0.1, 0.08, 0.85)
	_bar_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RailStand.style_bar(_bar_back)
	add_child(_bar_back)
	_bar = ColorRect.new()
	_bar.color = Color("e0704a")
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RailStand.style_bar(_bar)
	add_child(_bar)
	_start_pose(Pose.SPAWN)


func speed() -> float:
	return UnitCatalog.VERMIN_SPEED[kind]


func chew_damage() -> float:
	return UnitCatalog.VERMIN_CHEW[kind]


## Advances the pose machine and the clip for one step. [param mode] is what
## the board sees this Vermin doing: walking, hovering between tile steps, or
## chewing a Warden in range.
func tick(delta: float, mode: Mode) -> void:
	if _dying:
		return
	_advance_mode(mode, delta)
	_show_pose()
	_clip.tick(delta, size)


func play(anim_name: String) -> void:
	if _clip != null:
		_clip.play(anim_name)


## One flutter-hop step: [param base] is the flutter clip for this point of
## the arc (takeoff, air, or land). The board owns the hop timing and the
## sprite's arc position; the actor only shows the clip the phase names.
func tick_flutter(delta: float, base: String) -> void:
	_flutter_base = base
	tick(delta, Mode.FLUTTER)


## Bee lane change: holds the rise (up) or drop (down) clip in place for its
## authored duration, then hands back to whatever the board asks next.
## Skipped while the lane-entrance clip or a hurt flinch owns the frame.
func start_lane_change(up: bool) -> void:
	if _dying or _pose == Pose.SPAWN or _pose == Pose.HURT:
		return
	_start_pose(Pose.RISE if up else Pose.DROP)


## Starts the bounded death pose. The board keeps drawing the actor, calls
## tick_death() each step until it returns true, then poofs and frees it.
func die() -> void:
	if _dying:
		return
	_dying = true
	_pose = Pose.DEATH
	# A hop that gets killed mid-air lands for its death pose.
	hop_elapsed = -1.0
	hop_lift_tiles = 0.0
	_bar.visible = false
	_bar_back.visible = false
	var clip_name := _clip_name("death")
	_pose_wait = minf(_hold_for(clip_name, 1.1), DEATH_CAP)
	if not clip_name.is_empty():
		_clip.play(clip_name)


## Advances the death pose. Returns true once it has played out (capped).
func tick_death(delta: float) -> bool:
	_pose_wait -= delta
	_clip.tick(delta, size)
	return _pose_wait <= 0.0


## True while the death pose is playing out before the poof takes over.
func is_dying() -> bool:
	return _dying


## Returns true when this Vermin is destroyed.
func take_damage(amount: int) -> bool:
	if _dying:
		return true
	hp -= amount
	refresh_bar()
	if hp <= 0:
		_hp_state = _display_state()
		return true
	var next_state := _display_state()
	if next_state != _hp_state:
		_hp_state = next_state
		_retarget_pose_clip()
	_clip.flash()
	if _pose != Pose.HURT:
		_start_pose(Pose.HURT)
	return false


## Fliers (bee, fly) carry no ground point: they hover over their rail.
func is_flying() -> bool:
	return AnimLibrary.ground_point_px(_folder) == Vector2.INF


func canvas_px() -> Vector2:
	return AnimLibrary.canvas_px(_folder)


## Hover pivot for fliers (frames.json anchor.body_center_px); canvas center otherwise.
func body_center_px() -> Vector2:
	var center := AnimLibrary.body_center_px(_folder)
	if center == Vector2.INF:
		var canvas := canvas_px()
		return canvas * 0.5 if canvas != Vector2.INF else Vector2.INF
	return center


func clip() -> ClipView:
	return _clip


func refresh_bar() -> void:
	if _clip != null:
		_clip.tick(0.0, size)
	if _bar == null:
		return
	var fraction := 0.0 if max_hp <= 0 else clampf(float(hp) / float(max_hp), 0.0, 1.0)
	if _foot != Vector2.INF:
		RailStand.layout(_shadow, _bar_back, _bar, _foot, _rail_cell, is_flying(), fraction)
	else:
		var width := size.x
		var height := maxf(5.0, size.y * 0.08)
		_bar_back.position = Vector2(0.0, size.y - height)
		_bar_back.size = Vector2(width, height)
		_bar.position = _bar_back.position
		_bar.size = Vector2(width * fraction, height)


## Where the feet stand (actor-local pixels) and the cell width on this rail;
## the board sets this every layout so the shadow and bar sit on the ground.
func set_rail_stand(foot_local: Vector2, rail_cell: float) -> void:
	_foot = foot_local
	_rail_cell = rail_cell
	refresh_bar()


## The ground point (actor-local), or Vector2.INF before the first layout.
func rail_foot() -> Vector2:
	return _foot


## The contact shadow node under the feet.
func contact_shadow() -> TextureRect:
	return _shadow


## Debug view (GW-AW-7): show one damage state's art ("100", "66", "33") no
## matter the real HP, or "" to go back to HP-driven states. Combat still
## updates HP and the bar; only the art stays pinned while a state is forced.
func set_forced_damage_state(state: String) -> void:
	_forced_state = state
	var next := _display_state()
	if next != _hp_state:
		_hp_state = next
		_retarget_pose_clip()


## The damage-state key the clips should show: the forced debug state, or the
## one the current HP dictates.
func _display_state() -> String:
	if not _forced_state.is_empty():
		return _forced_state
	if max_hp <= 0:
		return AnimLibrary.state_for_hp(0.0)
	return AnimLibrary.state_for_hp(clampf(float(hp) / float(max_hp), 0.0, 1.0))


## Pose transitions the board's mode drives, plus the timed holds: the lane
## entrance clip yields to the walk, and a hurt flinch yields back to the
## pose it interrupted (unless that was chewing and the chew has ended).
func _advance_mode(mode: Mode, delta: float) -> void:
	match _pose:
		Pose.SPAWN:
			_pose_wait -= delta
			if _pose_wait > 0.0 and mode != Mode.CHEW and mode != Mode.FLUTTER:
				return
			if mode == Mode.CHEW:
				_start_pose(Pose.ACTION)
			elif mode == Mode.FLUTTER:
				_start_pose(Pose.FLUTTER)
			else:
				_start_pose(Pose.MOVE)
		Pose.HURT:
			_pose_wait -= delta
			if _pose_wait > 0.0:
				return
			var back := _return_pose
			if back == Pose.ACTION and mode != Mode.CHEW:
				back = Pose.MOVE
			if back == Pose.FLUTTER and mode != Mode.FLUTTER:
				back = Pose.MOVE
			_pose = back
			_pose_wait = _return_wait
		Pose.ACTION:
			if mode != Mode.CHEW:
				_start_pose(Pose.MOVE)
		Pose.FLUTTER:
			if mode != Mode.FLUTTER:
				_start_pose(Pose.MOVE)
		Pose.RISE, Pose.DROP:
			_pose_wait -= delta
			if _pose_wait > 0.0:
				return
			if mode == Mode.MOVE:
				_start_pose(Pose.MOVE)
			elif mode == Mode.CHEW:
				_start_pose(Pose.ACTION)
			else:
				_start_pose(Pose.IDLE)
		_:
			if mode == Mode.CHEW:
				_start_pose(Pose.ACTION)
			elif mode == Mode.FLUTTER:
				_start_pose(Pose.FLUTTER)
			elif mode == Mode.IDLE and _pose == Pose.MOVE and _pose_wait > 0.0:
				_pose_wait -= delta
			elif mode == Mode.IDLE and _pose != Pose.IDLE:
				_start_pose(Pose.IDLE)
			elif mode == Mode.MOVE and _pose != Pose.MOVE:
				var strode := _pose == Pose.IDLE
				_start_pose(Pose.MOVE)
				if strode:
					_pose_wait = STEP_HOLD


func _start_pose(next: Pose) -> void:
	if next == Pose.HURT:
		_return_pose = _pose
		_return_wait = _pose_wait
	_pose = next
	var clip_name := _clip_name(_pose_base(next))
	match next:
		Pose.SPAWN:
			_pose_wait = minf(_hold_for(clip_name, 0.8), SPAWN_CAP)
		Pose.HURT:
			_pose_wait = _hold_for(clip_name, 0.5)
		Pose.RISE, Pose.DROP:
			# In-place lane change: hold the authored clip length, no cap. A
			# legacy clip without the animation holds as before, no wait added.
			_pose_wait = 0.0 if clip_name.is_empty() else _hold_for(clip_name, 0.8)
		_:
			_pose_wait = 0.0


func _show_pose() -> void:
	var clip_name := _clip_name(_pose_base(_pose))
	if not clip_name.is_empty():
		_clip.play(clip_name)


func _pose_base(pose: Pose) -> String:
	match pose:
		Pose.MOVE:
			return "move"
		Pose.SPAWN:
			return "spawn"
		Pose.ACTION:
			return "action"
		Pose.HURT:
			return "hurt"
		Pose.DEATH:
			return "death"
		Pose.RISE:
			return "rise"
		Pose.DROP:
			return "drop"
		Pose.FLUTTER:
			return _flutter_base
		_:
			return "idle"


## Resolves the clip name for one lifecycle pose against the current damage
## state. Legacy fallback clips name the walk `walk` and the chew `chew`,
## and ship no spawn or death, so those bases resolve empty and the showing
## clip simply holds.
func _clip_name(base: String) -> String:
	var clip_name := AnimLibrary.animation_name(_frames, base, _hp_state)
	if not clip_name.is_empty():
		return clip_name
	var legacy_base := ""
	match base:
		"move":
			legacy_base = "walk"
		"action":
			legacy_base = "chew"
	if not legacy_base.is_empty():
		clip_name = AnimLibrary.animation_name(_frames, legacy_base, _hp_state)
		if not clip_name.is_empty():
			return clip_name
	return ""


## Seconds one clip takes to play once, from its authored frame durations.
func _hold_for(clip_name: String, fallback: float) -> float:
	if clip_name.is_empty():
		return fallback
	var total := 0.0
	for index in _frames.get_frame_count(clip_name):
		total += _frames.get_frame_duration(clip_name, index)
	return maxf(total, 0.1)


## Swaps the showing clip to the same animation in the new damage state,
## keeping the frame index (the states are authored index-for-index).
func _retarget_pose_clip() -> void:
	var clip_name := _clip_name(_pose_base(_pose))
	if not clip_name.is_empty():
		_clip.retarget(clip_name)
