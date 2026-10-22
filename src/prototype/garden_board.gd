## The playable demo. Select a card, place a Warden, and stop the wave.
class_name GardenBoard
extends Control

const CACTUS: Texture2D = preload("res://assets/sprites/wardens/cactus.png")
const BARK_BLOCK: Texture2D = preload("res://assets/sprites/wardens/bark_block.png")
const FLY: Texture2D = preload("res://assets/sprites/vermin/fly.png")
const BEE: Texture2D = preload("res://assets/sprites/vermin/bee.png")
const LADYBUG: Texture2D = preload("res://assets/sprites/vermin/ladybug.png")
const WATER_ICON: Texture2D = preload("res://assets/sprites/board/water.png")

@onready var _margin: MarginContainer = %SafeMargin
@onready var _top: TopBar = %TopBar
@onready var _lawn: LawnView = %Lawn
@onready var _bottom: BottomBar = %BottomBar

var _wallet := WaterWallet.new(UnitCatalog.STARTING_WATER)
var _grid := LawnGrid.new(LawnView.COLUMNS, LawnView.ROWS)
var _cooldowns: Array[Cooldown] = []
var _wardens: Array[WardenActor] = []
var _vermin: Array[VerminActor] = []
var _shots: Array[ShotActor] = []
var _selected := -1
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
var _result_layer: Control
var _play_shot := ""


func _ready() -> void:
	_bind_slot_keys()
	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)
	_lawn.resized.connect(_layout_actors)
	_lawn.cell_pressed.connect(_on_cell_pressed)
	_lawn.cell_hovered.connect(_on_cell_hovered)
	_top.pause_toggled.connect(_on_pause_toggled)
	_top.set_water_icon(WATER_ICON)
	for card in _bottom.cards():
		card.chosen.connect(_on_card_chosen.bind(card))
	for _index in UnitCatalog.WARDEN_NAMES.size():
		_cooldowns.append(Cooldown.new())
	_build_hint()
	_build_result()
	_present_cards()
	_refresh_hud()
	_read_shot_args()


func _process(delta: float) -> void:
	advance(delta)
	_refresh_hud()
	_refresh_cursor()
	if not _play_shot.is_empty() and _time >= 1.2:
		_save_shot(_play_shot)
		_play_shot = ""


## Steps the match forward. Headless tests call this directly.
func advance(delta: float) -> void:
	if _result != MatchOutcome.Result.ONGOING or _paused:
		return
	_time += delta
	for cooldown in _cooldowns:
		cooldown.tick(delta)
	_spawn_due()
	_tick_wardens(delta)
	_tick_shots(delta)
	_tick_vermin(delta)
	_result = MatchOutcome.evaluate(_breached, _vermin.size(), _pending_spawns())
	if _result != MatchOutcome.Result.ONGOING:
		_show_result()
	_layout_actors()


## Places the Warden for a card index. Returns false when the cell, water, or cooldown refuses.
func try_place(card_index: int, column: int, row: int) -> bool:
	if _result != MatchOutcome.Result.ONGOING:
		return false
	if not _can_place(card_index, column, row):
		return false
	var kind: UnitCatalog.Warden = card_index
	if not _wallet.try_spend(UnitCatalog.WARDEN_COST[kind]):
		return false
	var id := _next_id
	_next_id += 1
	if not _grid.try_place(column, row, id):
		_wallet.add(UnitCatalog.WARDEN_COST[kind])
		_next_id -= 1
		return false
	var actor := WardenActor.new()
	actor.setup(kind, column, row, id, _warden_texture(kind))
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
	actor.setup(kind, row, column_pos, _vermin_texture(kind))
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


func result() -> MatchOutcome.Result:
	return _result


func _can_place(card_index: int, column: int, row: int) -> bool:
	if card_index < 0 or card_index >= _cooldowns.size():
		return false
	if not _cooldowns[card_index].is_ready():
		return false
	if not _wallet.can_afford(UnitCatalog.WARDEN_COST[card_index]):
		return false
	return _grid.is_inside(column, row) and _grid.occupant(column, row) == 0


func _spawn_due() -> void:
	while _next_spawn < UnitCatalog.WAVE.size():
		var entry := UnitCatalog.WAVE[_next_spawn]
		if _time < entry.x:
			return
		spawn_vermin(int(entry.y), int(entry.z), 8.85)
		_next_spawn += 1


func _tick_wardens(delta: float) -> void:
	var spots := _vermin_spots()
	for warden in _wardens:
		var ahead := RowTarget.first_ahead(warden.row, float(warden.column) + 0.8, spots)
		var action := warden.tick(delta, ahead >= 0)
		if action == "shot":
			_add_shot(warden)
		elif action == "water":
			_wallet.add(UnitCatalog.DEW_AMOUNT)


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
		if hit or shot.column_pos > LawnView.COLUMNS + 0.4:
			shot.queue_free()
		else:
			kept.append(shot)
	_shots = kept
	_drop_dead_vermin()


func _tick_vermin(delta: float) -> void:
	for vermin in _vermin:
		var columns := _warden_columns(vermin.row)
		var blocking := RowTarget.reached_column(vermin.column_pos, columns)
		if blocking >= 0:
			vermin.column_pos = float(blocking) + 1.0
			var warden := _warden_at(blocking, vermin.row)
			if warden != null and warden.take_damage(vermin.chew_damage() * delta):
				_remove_warden(warden)
		else:
			vermin.column_pos -= vermin.speed() * delta
			if vermin.column_pos <= 0.0:
				_breached = true


func _add_shot(warden: WardenActor) -> void:
	var shot := ShotActor.new()
	shot.row = warden.row
	shot.column_pos = float(warden.column) + 0.85
	shot.damage = UnitCatalog.NEEDLE_DAMAGE
	_lawn.add_child(shot)
	_shots.append(shot)


func _drop_dead_vermin() -> void:
	var kept: Array[VerminActor] = []
	for vermin in _vermin:
		if vermin.hp <= 0:
			vermin.queue_free()
		else:
			kept.append(vermin)
	_vermin = kept


func _remove_warden(warden: WardenActor) -> void:
	_grid.remove(warden.column, warden.row)
	_wardens.erase(warden)
	warden.queue_free()


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
	return UnitCatalog.WAVE.size() - _next_spawn


func _layout_actors() -> void:
	var cell := _lawn.cell_size_px()
	if cell <= 0.0:
		return
	var origin := _lawn.grid_origin()
	for warden in _wardens:
		_place_box(warden, origin, cell, float(warden.column) + 0.5, warden.row, 0.64)
		warden.refresh_bar()
	for vermin in _vermin:
		_place_box(vermin, origin, cell, vermin.column_pos, vermin.row, 0.7)
		vermin.refresh_bar()
	for shot in _shots:
		_place_box(shot, origin, cell, shot.column_pos, shot.row, 0.28)


func _place_box(node: Control, origin: Vector2, cell: float, column_pos: float, row: int, scale: float) -> void:
	var box := cell * scale
	var center := origin + Vector2(column_pos * cell, (float(row) + 0.5) * cell)
	node.size = Vector2(box, box)
	node.position = center - node.size * 0.5


func _present_cards() -> void:
	var cards := _bottom.cards()
	for index in cards.size():
		var kind: UnitCatalog.Warden = index
		var texture := _warden_texture(kind)
		var gap := "No sprite in this pack" if texture == null else ""
		cards[index].present(UnitCatalog.WARDEN_NAMES[kind], UnitCatalog.WARDEN_COST[kind], texture, false, false, gap)


func _refresh_hud() -> void:
	_top.show_status(_wallet.amount, 1, _vermin.size() + _pending_spawns())
	var cards := _bottom.cards()
	for index in cards.size():
		var cooling := not _cooldowns[index].is_ready()
		var poor := not _wallet.can_afford(UnitCatalog.WARDEN_COST[index])
		cards[index].set_state(index == _selected, poor and not cooling, _cooldowns[index].remaining)


func _refresh_cursor() -> void:
	var aim := _key_aim if _aim_from_keys else _hover
	if _selected < 0 or aim.x < 0 or _result != MatchOutcome.Result.ONGOING:
		_lawn.show_aim(Vector2i(-1, -1), false)
		return
	_lawn.show_aim(aim, _can_place(_selected, aim.x, aim.y))


func _on_card_chosen(card: WardenCard) -> void:
	var index := _bottom.cards().find(card)
	_toggle_card(index)


func _on_cell_pressed(cell: Vector2i) -> void:
	_aim_from_keys = false
	_hover = cell
	if _selected >= 0:
		try_place(_selected, cell.x, cell.y)


func _on_cell_hovered(cell: Vector2i) -> void:
	if not _aim_from_keys:
		_hover = cell


func _on_pause_toggled(paused: bool) -> void:
	if _result == MatchOutcome.Result.ONGOING:
		_paused = paused


func _unhandled_input(event: InputEvent) -> void:
	if _result != MatchOutcome.Result.ONGOING or event.is_echo():
		return
	if event.is_action_pressed("select_slot_1"):
		_toggle_card(UnitCatalog.Warden.DEW)
	elif event.is_action_pressed("select_slot_2"):
		_toggle_card(UnitCatalog.Warden.NEEDLE)
	elif event.is_action_pressed("select_slot_3"):
		_toggle_card(UnitCatalog.Warden.BARK)
	elif event.is_action_pressed("ui_cancel"):
		_selected = -1
	elif event.is_action_pressed("ui_left"):
		_nudge_aim(-1, 0)
	elif event.is_action_pressed("ui_right"):
		_nudge_aim(1, 0)
	elif event.is_action_pressed("ui_up"):
		_nudge_aim(0, -1)
	elif event.is_action_pressed("ui_down"):
		_nudge_aim(0, 1)
	elif event.is_action_pressed("ui_accept") and _selected >= 0:
		try_place(_selected, _key_aim.x, _key_aim.y)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_selected = -1


func _toggle_card(index: int) -> void:
	_selected = -1 if _selected == index else index


func _nudge_aim(column_step: int, row_step: int) -> void:
	_aim_from_keys = true
	_key_aim.x = clampi(_key_aim.x + column_step, 0, LawnView.COLUMNS - 1)
	_key_aim.y = clampi(_key_aim.y + row_step, 0, LawnView.ROWS - 1)


func _warden_texture(kind: UnitCatalog.Warden) -> Texture2D:
	match kind:
		UnitCatalog.Warden.NEEDLE:
			return CACTUS
		UnitCatalog.Warden.BARK:
			return BARK_BLOCK
		_:
			return null


func _vermin_texture(kind: UnitCatalog.Vermin) -> Texture2D:
	match kind:
		UnitCatalog.Vermin.FLY:
			return FLY
		UnitCatalog.Vermin.BEE:
			return BEE
		_:
			return LADYBUG


func _build_hint() -> void:
	_hint = PanelContainer.new()
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hint.add_theme_stylebox_override("panel", FlatStyle.panel(Color(FlatStyle.PANEL, 0.92), FlatStyle.INK, 14, 3))
	var label := Label.new()
	label.text = "Select a card, or press 1, 2, or 3. Then tap a tile, or press Enter."
	label.add_theme_color_override("font_color", FlatStyle.CREAM)
	label.add_theme_font_size_override("font_size", 18)
	_hint.add_child(label)
	var layout := _margin.get_node("Layout") as VBoxContainer
	layout.add_child(_hint)
	layout.move_child(_hint, 1)


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
	again.text = "Play again"
	again.custom_minimum_size = Vector2(180, 64)
	FlatStyle.apply_button(again)
	again.pressed.connect(func() -> void: get_tree().reload_current_scene())
	column.add_child(again)
	box.add_child(column)
	_result_layer.add_child(box)
	add_child(_result_layer)


func _show_result() -> void:
	_lawn.show_aim(Vector2i(-1, -1), false)
	if _hint != null:
		_hint.visible = false
	var message := _result_layer.find_child("Message", true, false) as Label
	if message != null:
		message.text = "The garden holds." if _result == MatchOutcome.Result.WON else "The vermin broke through."
	_result_layer.visible = true


func _bind_slot_keys() -> void:
	_bind_key("select_slot_1", KEY_1)
	_bind_key("select_slot_1", KEY_KP_1)
	_bind_key("select_slot_2", KEY_2)
	_bind_key("select_slot_2", KEY_KP_2)
	_bind_key("select_slot_3", KEY_3)
	_bind_key("select_slot_3", KEY_KP_3)


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
	var play_index := args.find("--play-shot")
	if play_index >= 0 and play_index + 1 < args.size():
		_play_shot = args[play_index + 1]
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
