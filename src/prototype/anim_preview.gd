## Browses every unit's animation clips from AnimLibrary: the five wardens,
## the five vermin, and the death poof. Pick a unit, an animation, and a
## damage state, then play, pause, loop, and step frames to QA the art set.
##
## The animation and state buttons are built from the clip names AnimLibrary
## reports, so the list follows each unit's frames.json. When a unit folder is
## missing, AnimLibrary hands back the legacy UnitClips and this screen
## browses those bare-named clips instead.
class_name AnimPreview
extends Control

const CELL := 180.0
## Unit slots: the five wardens, then the five vermin, then the poof (slot 10).
## Kept as a literal because .size() on another script's const array is not a
## constant expression.
const POOF_UNIT := 10

var _unit := 0
var _anim := ""
var _state := ""
var _loop := true
## A local copy of the selected unit's clips, so the loop toggle can never
## mutate the SpriteFrames AnimLibrary shares with the match.
var _frames: SpriteFrames
var _unit_row: GridContainer
var _anim_row: GridContainer
var _state_row: HBoxContainer
var _play_button: Button
var _loop_button: Button
var _status_label: Label
var _clip: ClipView
var _shot_path := ""
var _shot_delay := 0.0
var _last_status := ""


## Source SpriteFrames behind a unit slot. The poof slot is null when its
## manifest is missing; the unit slots always fall back to the legacy clips.
static func _source_frames(index: int) -> SpriteFrames:
	if index < UnitCatalog.WARDEN_NAMES.size():
		return AnimLibrary.warden(index as UnitCatalog.Warden)
	if index < POOF_UNIT:
		return AnimLibrary.vermin((index - UnitCatalog.WARDEN_NAMES.size()) as UnitCatalog.Vermin)
	return AnimLibrary.poof()


## The clip name currently selected ("<anim>_<state>", or a bare legacy name).
func clip_name() -> String:
	return _selected_clip()


## Splits a clip name into [base animation, state suffix]. Legacy clips and
## the poof ship bare names, so their state suffix is empty.
static func split_clip(name: String) -> PackedStringArray:
	var index := name.rfind("_")
	if index > 0 and name.substr(index + 1) in AnimLibrary.DAMAGE_STATES:
		return PackedStringArray([name.left(index), name.substr(index + 1)])
	return PackedStringArray([name, ""])


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var sky := ColorRect.new()
	sky.color = FlatStyle.SKY
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 24.0
	column.offset_top = 24.0
	column.offset_right = -24.0
	column.offset_bottom = -24.0
	column.add_theme_constant_override("separation", 16)
	add_child(column)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 16)
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(120, 64)
	FlatStyle.apply_button(back)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://src/prototype/garden_board.tscn"))
	title_row.add_child(back)
	var title := Label.new()
	title.text = "Animation preview"
	title.add_theme_color_override("font_color", FlatStyle.INK)
	title.add_theme_font_size_override("font_size", 28)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(title)
	var help := Label.new()
	help.text = "Q/E unit · A/D anim · W/S state · , . frame · Space play · L loop"
	help.add_theme_color_override("font_color", FlatStyle.INK)
	help.add_theme_font_size_override("font_size", 18)
	help.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	help.size_flags_horizontal = Control.SIZE_EXPAND
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title_row.add_child(help)
	column.add_child(title_row)

	_unit_row = GridContainer.new()
	_unit_row.name = "Units"
	_unit_row.columns = 6
	_unit_row.add_theme_constant_override("h_separation", 8)
	_unit_row.add_theme_constant_override("v_separation", 8)
	for index in POOF_UNIT + 1:
		_unit_row.add_child(_button(_unit_name(index), Vector2(148, 64), 20, _show_unit.bind(index)))
	column.add_child(_unit_row)

	_anim_row = GridContainer.new()
	_anim_row.name = "Anims"
	_anim_row.columns = 5
	_anim_row.add_theme_constant_override("h_separation", 8)
	_anim_row.add_theme_constant_override("v_separation", 8)
	column.add_child(_anim_row)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 12)
	_state_row = HBoxContainer.new()
	_state_row.name = "States"
	_state_row.add_theme_constant_override("separation", 8)
	controls.add_child(_state_row)
	_play_button = _button("Play", Vector2(120, 64), 20, _toggle_play)
	controls.add_child(_play_button)
	_loop_button = _button("Loop on", Vector2(140, 64), 20, _toggle_loop)
	controls.add_child(_loop_button)
	controls.add_child(_button("Prev", Vector2(100, 64), 20, _step_frame.bind(-1)))
	controls.add_child(_button("Next", Vector2(100, 64), 20, _step_frame.bind(1)))
	_status_label = Label.new()
	_status_label.add_theme_color_override("font_color", FlatStyle.INK)
	_status_label.add_theme_font_size_override("font_size", 20)
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls.add_child(_status_label)
	column.add_child(controls)

	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, 200)
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(stage)
	var grass := TextureRect.new()
	grass.texture = preload("res://assets/sprites/board/grass.png")
	grass.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grass.stretch_mode = TextureRect.STRETCH_SCALE
	grass.anchor_left = 0.0
	grass.anchor_top = 1.0
	grass.anchor_right = 0.0
	grass.anchor_bottom = 1.0
	grass.offset_left = 0.0
	grass.offset_top = -CELL
	grass.offset_right = CELL
	grass.offset_bottom = -20.0
	stage.add_child(grass)
	var host := Control.new()
	host.anchor_left = 0.0
	host.anchor_top = 1.0
	host.anchor_right = 0.0
	host.anchor_bottom = 1.0
	host.offset_left = 0.0
	host.offset_top = -CELL
	host.offset_right = CELL
	host.offset_bottom = -20.0
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(host)
	_clip = ClipView.new()
	host.add_child(_clip)
	_clip.set_motion_enabled(false)

	_show_unit(0)
	_read_shot_args()


func _process(delta: float) -> void:
	_clip.tick(delta, Vector2(CELL, CELL))
	_update_status()
	if not _shot_path.is_empty():
		_shot_delay += delta
		if _shot_delay >= 0.4:
			var path := _shot_path
			_shot_path = ""
			_save_shot(path)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_SPACE:
			_toggle_play()
		KEY_L:
			_toggle_loop()
		KEY_Q:
			_show_unit(posmod(_unit - 1, POOF_UNIT + 1))
		KEY_E:
			_show_unit(posmod(_unit + 1, POOF_UNIT + 1))
		KEY_A:
			_cycle_anim(-1)
		KEY_D:
			_cycle_anim(1)
		KEY_W:
			_cycle_state(-1)
		KEY_S:
			_cycle_state(1)
		KEY_COMMA:
			_step_frame(-1)
		KEY_PERIOD:
			_step_frame(1)


## Unit slot name; the poof sits after the five vermin.
static func _unit_name(index: int) -> String:
	if index < UnitCatalog.WARDEN_NAMES.size():
		return UnitCatalog.WARDEN_NAMES[index]
	if index < POOF_UNIT:
		return UnitCatalog.VERMIN_NAMES[index - UnitCatalog.WARDEN_NAMES.size()]
	return "Poof"


func _show_unit(index: int) -> void:
	_unit = index
	var source := _source_frames(index)
	if source == null:
		_frames = null
		_anim = ""
		_state = ""
		_clear_row(_anim_row)
		_clear_row(_state_row)
		_clip.clear()
		_update_status()
		return
	_frames = source.duplicate(true)
	_clip.use(_frames)
	_clip.set_motion_enabled(false)
	var anims := _base_anims(_frames.get_animation_names())
	_rebuild_anim_row(anims)
	# Default to idle when the unit has one; otherwise the first animation.
	var wanted := anims[0]
	for anim in anims:
		if anim == "idle":
			wanted = anim
			break
	_select_anim(wanted)


func _select_anim(anim: String) -> void:
	_anim = anim
	var states := _states_for(anim)
	_state = states[0]
	_rebuild_state_row(states)
	_apply_clip()


func _cycle_anim(direction: int) -> void:
	if _frames == null:
		return
	var anims := _base_anims(_frames.get_animation_names())
	var index := anims.find(_anim)
	if index < 0:
		return
	_select_anim(anims[posmod(index + direction, anims.size())])


func _cycle_state(direction: int) -> void:
	var states := _states_for(_anim)
	var index := states.find(_state)
	if index < 0 or states.size() <= 1:
		return
	_state = states[posmod(index + direction, states.size())]
	_apply_clip()


func _selected_clip() -> String:
	if _state.is_empty():
		return _anim
	return "%s_%s" % [_anim, _state]


func _apply_clip() -> void:
	var name := _selected_clip()
	if _frames == null or not _frames.has_animation(name):
		_status("missing clip: %s" % name)
		return
	_loop = _frames.get_animation_loop(name)
	_frames.set_animation_loop(name, _loop)
	_clip.play(name)
	_update_status()


func _toggle_play() -> void:
	var sprite := _clip.sprite()
	if sprite == null or _clip.animation_name().is_empty():
		return
	if sprite.is_playing():
		sprite.pause()
	else:
		_clip.resume()
	_update_status()


func _toggle_loop() -> void:
	_loop = not _loop
	if _frames != null and not _clip.animation_name().is_empty():
		_frames.set_animation_loop(_clip.animation_name(), _loop)
	_update_status()


func _step_frame(direction: int) -> void:
	var sprite := _clip.sprite()
	if sprite == null:
		return
	var count := _clip.frame_count()
	if count <= 0:
		return
	sprite.stop()
	sprite.frame = posmod(sprite.frame + direction, count)
	_update_status()


func _on_state(state: String) -> void:
	_state = state
	_apply_clip()


## Base animation names for a clip list, in first-seen order.
func _base_anims(names: PackedStringArray) -> PackedStringArray:
	var anims: PackedStringArray = []
	for name in names:
		var base := split_clip(name)[0]
		if not anims.has(base):
			anims.append(base)
	return anims


## Damage states for one base animation, best health first. A bare legacy
## clip has a single empty state and the state row stays hidden.
func _states_for(anim: String) -> PackedStringArray:
	var states: PackedStringArray = []
	if _frames == null:
		return states
	var present: Dictionary = {}
	for name in _frames.get_animation_names():
		var split := split_clip(name)
		if split[0] == anim:
			present[split[1]] = true
	for state in AnimLibrary.DAMAGE_STATES:
		if present.has(state):
			states.append(state)
	if present.has(""):
		states.append("")
	return states


func _rebuild_anim_row(anims: PackedStringArray) -> void:
	_clear_row(_anim_row)
	for anim in anims:
		_anim_row.add_child(_button(anim, Vector2(230, 64), 18, _select_anim.bind(anim)))


func _rebuild_state_row(states: PackedStringArray) -> void:
	_clear_row(_state_row)
	if states.size() <= 1:
		return
	var hint := Label.new()
	hint.text = "state"
	hint.add_theme_color_override("font_color", FlatStyle.INK)
	hint.add_theme_font_size_override("font_size", 16)
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_state_row.add_child(hint)
	for state in states:
		_state_row.add_child(_button(state, Vector2(88, 64), 20, _on_state.bind(state)))


func _clear_row(row: Control) -> void:
	for child in row.get_children():
		child.free()


func _button(text: String, min_size: Vector2, font_size: int, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	FlatStyle.apply_button(button)
	button.add_theme_font_size_override("font_size", font_size)
	button.pressed.connect(handler)
	button.pressed.connect(button.release_focus)
	return button


## Effective frames per second of a clip: frame count over its total authored
## time, scaled by the animation speed.
func _fps_of(anim: String) -> float:
	var count := _frames.get_frame_count(anim)
	var total := 0.0
	for i in count:
		total += _frames.get_frame_duration(anim, i)
	if total > 0.0:
		return float(count) * _frames.get_animation_speed(anim) / total
	return _frames.get_animation_speed(anim)


func _format_fps(fps: float) -> String:
	if is_equal_approx(fps, roundf(fps)):
		return "%d" % int(roundf(fps))
	return "%.2f" % fps


func _update_status() -> void:
	var sprite := _clip.sprite()
	if sprite == null:
		_play_button.text = "Play"
		_status("no clip")
		return
	var name := _clip.animation_name()
	var count := _clip.frame_count()
	var play_text := "Pause" if sprite.is_playing() else "Play"
	if _play_button.text != play_text:
		_play_button.text = play_text
	var loop_text := "Loop on" if _loop else "Loop off"
	if _loop_button.text != loop_text:
		_loop_button.text = loop_text
	if name.is_empty() or count == 0:
		_status("no clip")
		return
	var text := "frame %d/%d · %s fps · loop %s" % [
		sprite.frame + 1,
		count,
		_format_fps(_fps_of(name)),
		"on" if _loop else "off",
	]
	if count <= 1:
		text += " · still"
	_status(text)


func _status(text: String) -> void:
	if text != _last_status:
		_last_status = text
		_status_label.text = text


func _read_shot_args() -> void:
	var args := OS.get_cmdline_user_args()
	var shot_index := args.find("--shot")
	if shot_index < 0 or shot_index + 1 >= args.size():
		return
	_shot_path = args[shot_index + 1]
	var unit_index := args.find("--unit")
	if unit_index >= 0 and unit_index + 1 < args.size():
		_show_unit(clampi(int(args[unit_index + 1]), 0, POOF_UNIT))
	var anim_index := args.find("--anim")
	if anim_index >= 0 and anim_index + 1 < args.size():
		if _frames == null:
			return
		var wanted := args[anim_index + 1]
		if not _frames.has_animation(wanted):
			return
		var split := split_clip(wanted)
		_anim = split[0]
		_state = split[1]
		_rebuild_state_row(_states_for(_anim))
		_apply_clip()


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
