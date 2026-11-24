## One planted Warden. The match decides when it shoots or produces water;
## the actor renders the lifecycle from AnimLibrary clips: place -> idle,
## action on the match's own timers, hurt on chew damage (then back to the
## previous pose), death played out and handed to the poof before the tile frees.
class_name WardenActor
extends Control

## Longest the death pose may hold the tile before the poof takes over.
const DEATH_CAP := 2.5
## Longest a looping action clip holds before falling back to idle.
const ACTION_HOLD_CAP := 1.6
## Dew Dropper buildup (GW-AA pass 4, "like the PvZ Sunflower"): the produce
## clip's fill phase (frames 14-34 at 10 fps: water gathers and swells on the
## leaf) now plays BEFORE the match's water tick, so the drop pops out at the
## moment the leaf tips it (frame 35), then the startle/settle tail plays.
## The match timer is untouched: the clip is simply started early.
const DEW_FILL_FRAME := 13
const DEW_POP_FRAME := 34
const DEW_FPS := 10.0
const DEW_BUILDUP := (DEW_POP_FRAME - DEW_FILL_FRAME) / DEW_FPS
## The buildup brightens the plant a touch, peaking as the drop pops.
const DEW_GLOW := 0.14

## Which lifecycle animation is showing right now.
enum Pose { IDLE, PLACE, ACTION, HURT, DEATH }

var kind: UnitCatalog.Warden
var column: int
var row: int
var grid_id: int
var hp: int
var max_hp: int
var fire_wait: float = 0.35
var produce_wait: float = UnitCatalog.DEW_INTERVAL

var _clip: ClipView
var _bar: ColorRect
var _bar_back: ColorRect
## Needle smoke boost: scale about the mouth (canvas px), alpha gain, whiten.
const SMOKE_BOOST_SCALE := 1.7
const SMOKE_MOUTH_PX := Vector2(312.0, 286.0)
const SMOKE_BOOST_GAIN := 2.1
const SMOKE_BOOST_LIFT := 0.35
## Rail stand (GW-AA pass 3): contact shadow, actor-local foot, rail cell width.
var _shadow: TextureRect
var _foot := Vector2.INF
var _rail_cell := 0.0
var _label: Label
var _folder := ""
var _frames: SpriteFrames
var _legacy := false
var _pose := Pose.IDLE
var _pose_wait := 0.0
var _return_pose := Pose.IDLE
var _return_wait := 0.0
var _hp_state := "100"
var _forced_state := ""
var _dying := false
## Placement beat (PaperPop): seconds since planting, and the one-shot cue
## the board turns into a puff at the base when the pop starts.
var _entry_t := 0.0
var _pop_cue := false
var _pop_cued := false
var _dew_building := false
## The flat paper sticker shown before the pop (GW-AA pass 5).
var _decal: StickerDecal


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 2


func setup(p_kind: UnitCatalog.Warden, p_column: int, p_row: int, p_id: int) -> void:
	kind = p_kind
	column = p_column
	row = p_row
	grid_id = p_id
	max_hp = UnitCatalog.WARDEN_HP[kind]
	hp = max_hp
	_folder = AnimLibrary.warden_folder(kind)
	_legacy = AnimLibrary.clip_for_folder(_folder) == null
	_frames = AnimLibrary.warden(kind)
	_clip = ClipView.new()
	_clip.setup(_frames)
	var ground := AnimLibrary.ground_point_px(_folder)
	var canvas := AnimLibrary.canvas_px(_folder)
	if ground != Vector2.INF and canvas != Vector2.INF:
		_clip.set_anchor_fit(ground, canvas)
	_shadow = RailStand.make_shadow()
	add_child(_shadow)
	add_child(_clip)
	_decal = StickerDecal.new()
	_decal.name = "StickerDecal"
	add_child(_decal)
	if kind == UnitCatalog.Warden.NEEDLE and not _legacy:
		# The spit's smoke ships as a per-frame overlay on the action canvas.
		_clip.set_overlay("action", FxArt.needle_smoke())
		# GW-AA pass 3: the puff is small and pale against the felt at the
		# bigger Option B size, so grow it from the mouth and firm it up.
		_clip.set_overlay_boost(SMOKE_BOOST_SCALE, SMOKE_MOUTH_PX, SMOKE_BOOST_GAIN, SMOKE_BOOST_LIFT)
	_bar_back = ColorRect.new()
	_bar_back.color = Color(0.08, 0.1, 0.08, 0.85)
	_bar_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RailStand.style_bar(_bar_back)
	add_child(_bar_back)
	_bar = ColorRect.new()
	_bar.color = Color("7dce4a")
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RailStand.style_bar(_bar)
	add_child(_bar)
	# The text label only stands in while a role has no drawings (legacy clip
	# fallback); on the new art the drawings carry the identity.
	if UnitClips.needs_label(kind) and _legacy:
		_label = Label.new()
		_label.text = UnitCatalog.WARDEN_SHORT[kind]
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		_label.add_theme_color_override("font_color", FlatStyle.INK)
		_label.add_theme_font_size_override("font_size", 14)
		_label.z_index = 2
		_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_label)
	# The live clip waits under the sticker; the place clip plays once the
	# Warden pops up out of the tile (see _advance_entry).
	_start_pose(Pose.IDLE)
	_show_pose()
	_apply_entry()


## Returns "shot", "lob", "water", or "" for what happened this step.
func tick(delta: float, can_shoot: bool) -> String:
	if _dying:
		return ""
	var action := ""
	if kind == UnitCatalog.Warden.NEEDLE:
		fire_wait = maxf(0.0, fire_wait - delta)
		if can_shoot and fire_wait <= 0.0:
			fire_wait = UnitCatalog.NEEDLE_INTERVAL
			action = "shot"
	elif kind == UnitCatalog.Warden.DEW:
		produce_wait -= delta
		if produce_wait <= 0.0:
			produce_wait += UnitCatalog.DEW_INTERVAL
			action = "water"
		elif not _dew_building and produce_wait <= DEW_BUILDUP:
			_start_dew_buildup()
	elif kind == UnitCatalog.Warden.SEED:
		fire_wait = maxf(0.0, fire_wait - delta)
		if can_shoot and fire_wait <= 0.0:
			fire_wait = UnitCatalog.LOB_INTERVAL
			action = "lob"
	if action == "water" and _dew_building:
		# The drop leaves the leaf now: let the clip run on into its startle
		# and settle tail instead of restarting it.
		_dew_building = false
		_pose_wait = _dew_tail()
		_clip.pulse()
	elif action == "shot" or action == "lob" or action == "water":
		_start_pose(Pose.ACTION)
		_clip.pulse()
	else:
		_carry_pose(delta)
	_show_pose()
	_sync_dew()
	_advance_entry(delta)
	_clip.tick(delta, size)
	return action


## Visual-only step while the wave clock stands still (the pre-Start planting
## window): carries the place hold back to idle and keeps the clip moving,
## without the fire, produce, or action effects of the match tick.
func idle_tick(delta: float) -> void:
	if _dying:
		return
	_carry_pose(delta)
	_show_pose()
	_advance_entry(delta)
	_clip.tick(delta, size)


## The placement beat's phase right now (PaperPop.Phase).
func placement_phase() -> int:
	return int(PaperPop.placement(_entry_t)["phase"])


## The clip's current scale (the placement beat squashes it).
func clip_scale() -> Vector2:
	return _clip.scale if _clip != null else Vector2.ONE


## True once, when the pop starts: the board puffs at the base.
func consume_pop_cue() -> bool:
	if _pop_cue:
		_pop_cue = false
		return true
	return false


## Whether the Dew Dropper is gathering its next drop right now.
func dew_building() -> bool:
	return _dew_building


func _advance_entry(delta: float) -> void:
	if _entry_t >= PaperPop.placement_time():
		return
	_entry_t += delta
	if not _pop_cued and _entry_t >= PaperPop.pop_start():
		_pop_cued = true
		_pop_cue = true
		if not _dying and _pose != Pose.HURT and _pose != Pose.ACTION:
			_start_pose(Pose.PLACE)
			_show_pose()
	_apply_entry()


## The sticker beat: before the pop the flat paper decal shows (the live clip
## hidden); from the pop the live clip squashes and overshoots about the feet.
func _apply_entry() -> void:
	if _clip == null:
		return
	var beat := PaperPop.placement(_entry_t)
	var pivot := _foot if _foot.is_finite() else Vector2(size.x * 0.5, size.y)
	var decal := bool(beat["decal"]) and not _dying and _configure_decal(pivot)
	if _decal != null:
		_decal.visible = decal
		_decal.set_beat(beat if decal else {})
	_clip.visible = not decal
	if _shadow != null:
		_shadow.visible = not decal
	_clip.transform = PaperPop.pivot_transform(beat["scale"], 0.0, pivot, Vector2.ZERO)


## Points the decal at the idle frame, laid out exactly where the live clip
## draws it. False when there is no frame to show (legacy clips).
func _configure_decal(pivot: Vector2) -> bool:
	if _decal == null or _legacy or size.x <= 1.0:
		return false
	var clip_name := _clip_name("idle")
	if clip_name.is_empty():
		return false
	var texture := _frames.get_frame_texture(clip_name, 0)
	if texture == null:
		return false
	var canvas := AnimLibrary.canvas_px(_folder)
	var ground := AnimLibrary.ground_point_px(_folder)
	if not canvas.is_finite() or canvas.y <= 1.0:
		canvas = texture.get_size()
	if not ground.is_finite():
		ground = Vector2(canvas.x * 0.5, canvas.y)
	var fitted := minf(size.x / canvas.x, size.y / canvas.y)
	_decal.configure(texture, ground * texture.get_size() / canvas, pivot, fitted * canvas.x / texture.get_size().x)
	return true


## Whether the flat sticker is showing right now (before the pop).
func sticker_showing() -> bool:
	return _decal != null and _decal.visible


func sticker() -> StickerDecal:
	return _decal


## Starts the produce clip early, at the fill frame that lands the leaf's tip
## exactly on the match's water tick.
func _start_dew_buildup() -> void:
	if _pose == Pose.HURT or _pose == Pose.DEATH or _legacy:
		return
	var clip_name := _clip_name("action")
	if clip_name.is_empty() or _frames.get_frame_count(clip_name) <= DEW_POP_FRAME:
		return
	_dew_building = true
	_pose = Pose.ACTION
	_pose_wait = produce_wait + _dew_tail()
	_show_pose()
	_seek_dew_frame()


## Seconds of the produce clip after the drop leaves (startle and settle).
func _dew_tail() -> float:
	var clip_name := _clip_name("action")
	if clip_name.is_empty():
		return 0.0
	return float(_frames.get_frame_count(clip_name) - DEW_POP_FRAME) / DEW_FPS


## Keeps the buildup clip on the frame the match clock calls for (a hurt
## flinch or a damage-state swap can knock it off), and the glow on it.
func _sync_dew() -> void:
	if not _dew_building:
		if _clip != null and _clip.modulate != Color.WHITE:
			_clip.modulate = Color.WHITE
		return
	if _pose == Pose.ACTION:
		_seek_dew_frame()
	var k := clampf(1.0 - produce_wait / DEW_BUILDUP, 0.0, 1.0)
	var glow := 1.0 + DEW_GLOW * k * k
	_clip.modulate = Color(glow, glow, glow * 1.04, 1.0)


func _seek_dew_frame() -> void:
	var sprite := _clip.sprite()
	if sprite == null:
		return
	var want := clampi(DEW_POP_FRAME - int(ceil(produce_wait * DEW_FPS)), 0, DEW_POP_FRAME)
	if absi(sprite.frame - want) > 1:
		sprite.frame = want


## The beat for a Warden doing a one-off job the match just triggered (the Rain
## Catcher scooping a dropped droplet). Plays the action clip with the same
## guards as the shoot beat in tick(): hold for the clip's authored length up
## to ACTION_HOLD_CAP, carry back to idle when the hold ends, and fall back to
## the legacy action names when no action art is authored.
func play_catch() -> void:
	if _dying:
		return
	_start_pose(Pose.ACTION)
	_clip.pulse()


## Starts the death pose. The board keeps the tile occupied, calls tick_death()
## each step until it returns true, then poofs and frees the tile.
func die() -> void:
	if _dying:
		return
	_dying = true
	_dew_building = false
	# A Warden killed mid-sticker skips straight to its live clip.
	_entry_t = PaperPop.placement_time()
	_apply_entry()
	_pose = Pose.DEATH
	_bar.visible = false
	_bar_back.visible = false
	if _label != null:
		_label.visible = false
	var clip_name := _clip_name("death")
	_pose_wait = minf(_hold_for(clip_name, 1.1), DEATH_CAP)
	if not clip_name.is_empty():
		_clip.play(clip_name)


## Advances the death pose. Returns true once it has played out (capped).
func tick_death(delta: float) -> bool:
	_pose_wait -= delta
	_clip.tick(delta, size)
	return _pose_wait <= 0.0


## True while the death pose is playing out before the tile frees.
func is_dying() -> bool:
	return _dying


## The clip view, for probes and screenshots that inspect what is drawn.
func is_flying() -> bool:
	return false


## The art canvas in pixels (frames.json canvas_px), Vector2.INF for legacy clips.
func canvas_px() -> Vector2:
	return AnimLibrary.canvas_px(_folder)


func clip() -> ClipView:
	return _clip


func play(anim_name: String) -> void:
	if _clip != null:
		_clip.play(anim_name)


## Returns true when this Warden is destroyed.
func take_damage(amount: float) -> bool:
	hp -= int(ceil(amount))
	refresh_bar()
	if hp <= 0:
		var dead_state := _display_state()
		if dead_state != _hp_state:
			_hp_state = dead_state
			_retarget_pose_clip()
		return true
	var next_state := _display_state()
	if next_state != _hp_state:
		_hp_state = next_state
		_retarget_pose_clip()
	_clip.flash()
	if kind == UnitCatalog.Warden.BARK:
		# The wall has no attack; its action clip is the brace, so it reacts to
		# chews with the brace instead of the hurt flinch.
		if _pose != Pose.ACTION:
			_start_pose(Pose.ACTION)
	elif _pose != Pose.HURT:
		_start_pose(Pose.HURT)
	return false


## Whether a health bar shows under this Warden (never, since pass 4).
func health_bar_shown() -> bool:
	return _bar != null and _bar.visible


func refresh_bar() -> void:
	if _clip != null:
		_clip.tick(0.0, size)
	if _bar == null:
		return
	var fraction := 0.0 if max_hp <= 0 else clampf(float(hp) / float(max_hp), 0.0, 1.0)
	if _foot != Vector2.INF:
		RailStand.layout(_shadow, _bar_back, _bar, _foot, _rail_cell, is_flying(), fraction)
		_apply_entry()
	else:
		var width := size.x
		var height := maxf(5.0, size.y * 0.08)
		_bar_back.position = Vector2(0.0, size.y - height)
		_bar_back.size = Vector2(width, height)
		_bar.position = _bar_back.position
		_bar.size = Vector2(width * fraction, height)
	_bar.color = FlatStyle.CLAY if fraction < 0.35 else Color("7dce4a")


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


## Lets a hurt (or brace) hold finish before returning to the interrupted pose.
func _carry_pose(delta: float) -> void:
	if _pose == Pose.IDLE:
		return
	_pose_wait -= delta
	if _pose_wait > 0.0:
		return
	if _pose == Pose.HURT:
		_pose = _return_pose
		_pose_wait = _return_wait
	else:
		_pose = Pose.IDLE
		_pose_wait = 0.0


func _start_pose(next: Pose) -> void:
	if next == Pose.HURT and _pose != Pose.HURT:
		_return_pose = _pose
		_return_wait = _pose_wait
	_pose = next
	var clip_name := _clip_name(_pose_base(next))
	match next:
		Pose.PLACE:
			_pose_wait = _hold_for(clip_name, 0.8)
		Pose.ACTION:
			_pose_wait = minf(_hold_for(clip_name, 1.0), ACTION_HOLD_CAP)
		Pose.HURT:
			_pose_wait = _hold_for(clip_name, 0.5)
		_:
			_pose_wait = 0.0


func _show_pose() -> void:
	var clip_name := _clip_name(_pose_base(_pose))
	if not clip_name.is_empty():
		_clip.play(clip_name)


func _pose_base(pose: Pose) -> String:
	match pose:
		Pose.PLACE:
			return "place"
		Pose.ACTION:
			return "action"
		Pose.HURT:
			return "hurt"
		Pose.DEATH:
			return "death"
		_:
			return "idle"


## Resolves the clip name for one lifecycle pose against the current damage
## state, falling back to the legacy bare names when the manifest is absent.
func _clip_name(base: String) -> String:
	var clip_name := AnimLibrary.animation_name(_frames, base, _hp_state)
	if not clip_name.is_empty():
		return clip_name
	if base == "action":
		for legacy_base in ["attack", "produce", "hurt"]:
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
