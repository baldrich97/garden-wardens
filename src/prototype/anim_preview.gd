## Shows one unit's temporary clips at lawn size. Back returns to the match.
class_name AnimPreview
extends Control

const CELL := 180.0

var _clip: ClipView
var _unit := 0
var _anim := "idle"
var _pulse_wait := 0.0
var _still_label: Label
var _anim_row: HBoxContainer
var _shot_path := ""


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
	column.add_child(title_row)

	column.add_child(_button_row(_unit_names(), _on_unit))
	_anim_row = HBoxContainer.new()
	_anim_row.add_theme_constant_override("separation", 12)
	column.add_child(_anim_row)

	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, 280)
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(stage)
	var grass := TextureRect.new()
	grass.texture = preload("res://assets/sprites/board/grass.png")
	grass.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grass.stretch_mode = TextureRect.STRETCH_SCALE
	grass.custom_minimum_size = Vector2(CELL, CELL)
	grass.position = Vector2(0, 40)
	grass.size = Vector2(CELL, CELL)
	stage.add_child(grass)
	var host := Control.new()
	host.position = grass.position
	host.size = grass.size
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(host)
	_clip = ClipView.new()
	host.add_child(_clip)

	_still_label = Label.new()
	_still_label.text = "still"
	_still_label.add_theme_color_override("font_color", FlatStyle.INK)
	_still_label.add_theme_font_size_override("font_size", 22)
	_still_label.position = Vector2(CELL + 24, 48)
	stage.add_child(_still_label)

	_show_unit(0)
	_read_shot_args()


func _process(delta: float) -> void:
	_pulse_wait -= delta
	if _pulse_wait <= 0.0 and (_anim == "attack" or _anim == "produce" or _anim == "hurt"):
		_pulse_wait = 0.7
		if _anim == "hurt":
			_clip.flash()
		else:
			_clip.pulse()
	_clip.tick(delta, Vector2(CELL, CELL))
	if not _shot_path.is_empty() and _pulse_wait < 0.55:
		var path := _shot_path
		_shot_path = ""
		_save_shot(path)


func _unit_names() -> PackedStringArray:
	var names := UnitCatalog.WARDEN_NAMES.duplicate()
	names.append_array(UnitCatalog.VERMIN_NAMES)
	return names


func _animations_for(unit: int) -> PackedStringArray:
	if unit < UnitCatalog.WARDEN_NAMES.size():
		return UnitClips.warden_animations(unit)
	return UnitClips.vermin_animations()


func _button_row(labels: PackedStringArray, handler: Callable) -> GridContainer:
	var row := GridContainer.new()
	row.columns = 5
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	for index in labels.size():
		var button := Button.new()
		button.text = labels[index]
		button.custom_minimum_size = Vector2(148, 56)
		FlatStyle.apply_button(button)
		button.pressed.connect(handler.bind(index))
		row.add_child(button)
	return row


func _on_unit(index: int) -> void:
	_show_unit(index)


func _on_anim(index: int) -> void:
	var names := _animations_for(_unit)
	_anim = names[index]
	_clip.play(_anim)
	_pulse_wait = 0.0
	_still_label.visible = _clip.is_still()


func _show_unit(index: int) -> void:
	_unit = index
	var frames: SpriteFrames
	if index < UnitCatalog.WARDEN_NAMES.size():
		frames = UnitClips.warden(index)
	else:
		frames = UnitClips.vermin(index - UnitCatalog.WARDEN_NAMES.size())
	_clip.use(frames)
	for child in _anim_row.get_children():
		child.queue_free()
	var names := _animations_for(index)
	for anim_index in names.size():
		var button := Button.new()
		button.text = names[anim_index]
		button.custom_minimum_size = Vector2(120, 64)
		FlatStyle.apply_button(button)
		button.pressed.connect(_on_anim.bind(anim_index))
		_anim_row.add_child(button)
	_on_anim(0)


func _read_shot_args() -> void:
	var args := OS.get_cmdline_user_args()
	var shot_index := args.find("--shot")
	if shot_index < 0 or shot_index + 1 >= args.size():
		return
	_shot_path = args[shot_index + 1]
	var unit_index := args.find("--unit")
	if unit_index >= 0 and unit_index + 1 < args.size():
		_show_unit(int(args[unit_index + 1]))
	var anim_index := args.find("--anim")
	if anim_index >= 0 and anim_index + 1 < args.size():
		var names := _animations_for(_unit)
		var wanted := args[anim_index + 1]
		var found := names.find(wanted)
		if found >= 0:
			_on_anim(found)


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
