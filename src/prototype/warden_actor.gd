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
var _label: Label
var _folder := ""
var _frames: SpriteFrames
var _legacy := false
var _pose := Pose.IDLE
var _pose_wait := 0.0
var _return_pose := Pose.IDLE
var _return_wait := 0.0
var _hp_state := "100"
var _dying := false


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
	add_child(_clip)
	_bar_back = ColorRect.new()
	_bar_back.color = Color(0.08, 0.1, 0.08, 0.85)
	_bar_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_back.z_index = 1
	add_child(_bar_back)
	_bar = ColorRect.new()
	_bar.color = Color("7dce4a")
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.z_index = 1
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
	_start_pose(Pose.PLACE)


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
	elif kind == UnitCatalog.Warden.SEED:
		fire_wait = maxf(0.0, fire_wait - delta)
		if can_shoot and fire_wait <= 0.0:
			fire_wait = UnitCatalog.LOB_INTERVAL
			action = "lob"
	if action == "shot" or action == "lob" or action == "water":
		_start_pose(Pose.ACTION)
		_clip.pulse()
	else:
		_carry_pose(delta)
	_show_pose()
	_clip.tick(delta, size)
	return action


## Starts the death pose. The board keeps the tile occupied, calls tick_death()
## each step until it returns true, then poofs and frees the tile.
func die() -> void:
	if _dying:
		return
	_dying = true
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


func play(anim_name: String) -> void:
	if _clip != null:
		_clip.play(anim_name)


## Returns true when this Warden is destroyed.
func take_damage(amount: float) -> bool:
	hp -= int(ceil(amount))
	refresh_bar()
	if hp <= 0:
		var dead_state := AnimLibrary.state_for_hp(0.0)
		if dead_state != _hp_state:
			_hp_state = dead_state
			_retarget_pose_clip()
		return true
	var next_state := AnimLibrary.state_for_hp(float(hp) / float(max_hp))
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


func refresh_bar() -> void:
	if _clip != null:
		_clip.tick(0.0, size)
	if _bar == null:
		return
	var width := size.x
	var height := maxf(5.0, size.y * 0.08)
	_bar_back.position = Vector2(0.0, size.y - height)
	_bar_back.size = Vector2(width, height)
	var fraction := 0.0 if max_hp <= 0 else clampf(float(hp) / float(max_hp), 0.0, 1.0)
	_bar.position = _bar_back.position
	_bar.size = Vector2(width * fraction, height)
	_bar.color = FlatStyle.CLAY if fraction < 0.35 else Color("7dce4a")


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
