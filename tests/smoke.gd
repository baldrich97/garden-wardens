extends SceneTree

## Loads the visual prototype and checks the mock roster after the scene is ready.

var _board: Node
var _phase := 0


func _process(_delta: float) -> bool:
	if _phase == 0:
		var packed := load("res://src/prototype/garden_board.tscn") as PackedScene
		if packed == null:
			push_error("SMOKE failed to load garden_board.tscn")
			quit(1)
			return true
		_board = packed.instantiate()
		root.add_child(_board)
		_phase = 1
		return false
	var failures := _check(_board)
	if failures.is_empty():
		print("SMOKE_OK")
		quit(0)
		return true
	for failure in failures:
		push_error("SMOKE %s" % failure)
	quit(1)
	return true


func _check(board: Node) -> PackedStringArray:
	var failures: PackedStringArray = []
	_check_texts(board, failures)
	_check_cards(board, failures)
	_check_textures(board, failures)
	var roster := board.find_child("WaveRoster", true, false) as WaveRoster
	if roster == null or not roster.visible or roster.card_count() != _wave_types():
		failures.append("wave roster did not show one card per vermin type")
	var grid := board.find_child("RosterGrid", true, false) as GridContainer
	if grid == null or grid.columns != _wave_types():
		failures.append("wave roster was not a single row strip")
	var start := board.find_child("StartButton", true, false) as Button
	if start == null or start.text != "Start":
		failures.append("Start button missing before the wave")
	var lawn := board.find_child("Lawn", true, false) as LawnView
	if lawn == null or lawn.column_count() != LawnView.COLUMNS or lawn.tile_count() != LawnView.COLUMNS * LawnView.ROWS:
		failures.append("lawn was not 5 by 12")
	if lawn != null and not lawn.uses_board_art():
		failures.append("lawn did not draw the locked felt board (board v1)")
	var frame := board.find_child("BoardFrame", true, false) as TextureRect
	if frame == null or frame.texture == null or frame.size.x <= 0.0:
		failures.append("felt board frame missing from the lawn")
	var icon := board.find_child("WaterIcon", true, false) as TextureRect
	if icon == null or icon.texture != FxArt.WATER_DROP_SMALL:
		failures.append("top-bar water icon is not the origami small drop")
	var ring := board.find_child("LeafRing", true, false) as TextureRect
	if ring == null or ring.texture != FxArt.LEAF_RING:
		failures.append("placement leaf ring missing from the lawn")
	var backdrop := board.find_child("BackdropButton", true, false) as Button
	if backdrop == null or backdrop.text.is_empty():
		failures.append("backdrop button missing")
	var board_script := board as GardenBoard
	if board_script == null:
		failures.append("board was not a GardenBoard")
	# Option B (GW-AA pass 3): the painted porch and compost in the backdrop
	# frame the lawn; the separate cutouts are parked and never drawn.
	if board.find_child("PlayerEnd", true, false) != null or board.find_child("VerminEnd", true, false) != null:
		failures.append("parked porch/compost cutouts are still on the board")
	_check_no_texture(board, "player_end_porch", failures)
	_check_no_texture(board, "vermin_end_compost_eyes", failures)
	if frame != null and not (frame.material is ShaderMaterial):
		failures.append("felt board frame lost its perspective shader")
	if board_script != null:
		_check_layouts(board_script, failures)
	var seed_text := ""
	var seed_panel := board.find_child("SeedLabel", true, false)
	if seed_panel != null:
		for child in seed_panel.get_children():
			if child is Label:
				seed_text = (child as Label).text
	if board_script != null and not seed_text.contains("Seed %d" % board_script.visual_seed()):
		failures.append("debug label did not show the visual seed")
	var ability := board.find_child("AbilityButton", true, false) as Button
	if ability == null or not ability.disabled:
		failures.append("Ability button should stay disabled")
	if board_script != null:
		_check_pass4(board_script, failures)
	return failures


## GW-AA pass 4: layer slots, framing, health bars gone, tooltip state
## machine, paper entrance beats, slow dew.
func _check_pass4(board: GardenBoard, failures: PackedStringArray) -> void:
	_check_slots(board, failures)
	_check_tooltip(board, failures)
	_check_space_pause(board, failures)
	_check_beats(board, failures)
	_check_pass5(board, failures)


## GW-AA pass 5: packet cards, the paper roster, felt tiles, paper matte,
## lawn decor.
func _check_pass5(board: GardenBoard, failures: PackedStringArray) -> void:
	var bottom := board.find_child("BottomBar", true, false) as BottomBar
	for card in bottom.cards():
		var rects := card.label_rects()
		var face: Rect2 = rects["face"]
		if face.size.x <= 0.0 or absf(face.size.x / face.size.y - WardenCard.PACKET_ASPECT) > 0.08:
			failures.append("card %d packet does not fill the card at the packet aspect (%s)" % [card.kind, face.size])
		if card.lip_text() != UnitCatalog.WARDEN_NAMES[card.kind]:
			failures.append("card lip reads '%s'" % card.lip_text())
		var cost_r: Rect2 = rects["cost"]
		var name_r: Rect2 = rects["name"]
		if name_r.end.y > face.size.y * 0.16 or cost_r.position.x < face.size.x * 0.33 or cost_r.position.y < face.size.y * 0.68:
			failures.append("card %d name/cost are not on the lip / price tag" % card.kind)
	var first := bottom.cards()[0]
	first.set_state(false, false, 2.0)
	if first.tag_text() != "2.0s" or first.cooldown_share() <= 0.0:
		failures.append("a cooling card does not show its seconds on the tag with a dim sweep")
	first.set_state(false, false, 0.0)
	if first.tag_text() != str(UnitCatalog.WARDEN_COST[first.kind]):
		failures.append("card tag reads '%s', want the water cost" % first.tag_text())
	# The roster shows Asset Gen's paper-cutout portraits (no cartoon art).
	var roster := board.find_child("WaveRoster", true, false) as WaveRoster
	if roster != null:
		for face_rect in roster.portraits():
			if face_rect.texture == null or not bool(face_rect.get_meta("from_slot", false)):
				failures.append("a roster portrait is not from the paper-cutout slot")
	for kind in UnitCatalog.Vermin.size():
		if RosterPortraits.portrait(kind)["texture"] == null:
			failures.append("vermin %d has no roster portrait" % kind)
	# Sand and stone draw Asset Gen's felt tiles instead of the washes.
	var lawn := board.find_child("Lawn", true, false) as LawnView
	var soil := 0
	for column in lawn.column_count():
		for row in LawnView.ROWS:
			if SoilMap.kind_at(column, row, lawn.column_count()) != SoilMap.Kind.REGULAR:
				soil += 1
	if soil > 0 and lawn.tiled_cell_count() != soil:
		failures.append("%d of %d sand/stone cells draw felt tiles" % [lawn.tiled_cell_count(), soil])
	var paper := board.find_child("MattePaper", true, false) as TextureRect
	if paper == null or paper.texture == null or paper.stretch_mode != TextureRect.STRETCH_TILE:
		failures.append("the matte is not the tiled paper")
	# Decor props sit on the grass, never on the felt.
	var layers := board.stage_layers()
	var quad := lawn.geometry.frame_quad()
	for prop in layers.decor:
		var foot := prop.global_position + Vector2(prop.size.x * 0.5, prop.size.y) * prop.get_global_transform().get_scale()
		var local := lawn.get_global_transform().affine_inverse() * foot
		if Geometry2D.is_point_in_polygon(local, quad):
			failures.append("decor %s sits on the felt" % prop.name)
	if layers.decor.size() < 4:
		failures.append("lawn decor props missing (%d)" % layers.decor.size())


func _check_slots(board: GardenBoard, failures: PackedStringArray) -> void:
	var layers := board.stage_layers()
	if layers == null:
		failures.append("stage layer slots were not built")
		return
	var stage := board.find_child("Stage", true, false) as Control
	var slots := layers.slots()
	var last := -1
	for i in slots.size():
		var slot := slots[i]
		if slot == null or slot.name != StageLayers.SLOT_NAMES[i] or slot.get_parent() != stage:
			failures.append("stage slot %d is not %s on the Stage" % [i, StageLayers.SLOT_NAMES[i]])
			return
		if slot.get_index() <= last:
			failures.append("stage slot %s is out of back-to-front order" % slot.name)
		last = slot.get_index()
	var lawn := board.find_child("Lawn", true, false)
	if lawn == null or lawn.get_parent() != stage or lawn.get_index() <= last:
		failures.append("the lawn does not draw above every stage slot")
	for plate in [layers.fence_layer, layers.shack_layer, layers.compost_pile, layers.lawn_layer]:
		if plate == null or plate.texture == null or not plate.visible:
			failures.append("set plate missing: %s" % (plate.name if plate != null else "?"))
	var eyes := layers.compost_eyes
	if eyes == null or eyes.texture == null or not eyes.visible:
		failures.append("the compost eyes are not showing")
	else:
		var center := eyes.position + eyes.size * 0.5
		if center.distance_to(BackdropCatalog.COMPOST_EYES["hollow"]) > 3.0:
			failures.append("compost eyes sit at %s, not over the heap's hollow" % center)
		var pile := Rect2(layers.compost_pile.position, layers.compost_pile.size)
		if not pile.encloses(Rect2(eyes.position, eyes.size)):
			failures.append("compost eyes spill outside the heap")
		if eyes.size.x > 120.0:
			failures.append("compost eyes overlay is a second pile, not just the eyes")
	if board.find_child("Background", true, false).get_parent() != layers.sky_backdrop:
		failures.append("the look backdrop is not in the SkyBackdrop slot")
	if board.sky_layer() == null or board.sky_layer().get_parent() != layers.sky_props:
		failures.append("the sky props are not in the SkyProps slot")
	# A look switch changes only the sky backdrop and the set light. Start
	# from Main: the seeded opening look may be Dusk, which has its own fence.
	board.use_backdrop(0)
	var fence_before := layers.fence_layer.get_global_rect()
	var tex_before := layers.fence_layer.texture
	# A look with no plates of its own keeps the shared set, just relit.
	board.use_backdrop(BackdropCatalog.NAMES.find("Overcast"))
	if layers.fence_layer.get_global_rect() != fence_before or layers.fence_layer.texture != tex_before:
		failures.append("switching to Overcast moved or swapped the shared fence plate")
	if layers.fence_layer.self_modulate == Color.WHITE:
		failures.append("Overcast did not tint the set plates")
	# GW-AA pass 5: both Dusks show the Dusk string-light fence (per-mood
	# plate map), lined up on the fence slot, with its lights over it.
	for dusk_name in ["Dusk Twilight", "Dusk Moonlit"]:
		board.use_backdrop(BackdropCatalog.NAMES.find(dusk_name))
		var own := layers.own_plates()
		if String(own.get("fence", "")).find("/stage/dusk/") < 0:
			failures.append("%s does not show the Dusk fence plate (own plates %s)" % [dusk_name, own])
		if layers.fence_layer.get_global_rect() != fence_before:
			failures.append("%s fence plate is off the fence slot" % dusk_name)
		if layers.fence_lights == null or not layers.fence_lights.visible:
			failures.append("%s fence string lights are not showing" % dusk_name)
		if board.sky_layer().moon_height() <= 0.0:
			failures.append("%s has no moon" % dusk_name)
	var moonlit_tint := (board.find_child("Background", true, false) as TextureRect).self_modulate
	if not (moonlit_tint.b > moonlit_tint.r and moonlit_tint.r < 0.8):
		failures.append("Dusk Moonlit sky is not in night light (%s)" % moonlit_tint)
	if not board.sky_layer().cloud_paths().is_empty() or board.sky_layer().star_count() == 0:
		failures.append("Dusk Moonlit should be clear with stars")
	var look_name := (board.find_child("BackdropButton", true, false) as Button)
	if look_name != null and look_name.text != "Dusk Moonlit":
		failures.append("look button reads '%s' on Dusk Moonlit" % look_name.text)
	# Wide-screen side plates: none shipped (clean matte); an injected one
	# anchors to the stage edge at the stage's scale.
	board.use_backdrop(0)
	for plate in board.side_plates():
		if plate.visible:
			failures.append("a side plate shows with no art in the slot")
	var probe_tex := ImageTexture.create_from_image(Image.create(64, 720, false, Image.FORMAT_RGBA8))
	var left_path := BackdropCatalog.STAGE_DIR + "main/side_left.png"
	BackdropCatalog.inject(left_path, probe_tex)
	board.use_backdrop(0)
	var left := board.side_plates()[0] if not board.side_plates().is_empty() else null
	var stage_r := board.stage_rect()
	if left == null or not left.visible or absf(left.position.x + left.size.x - stage_r.position.x) > 1.0 or absf(left.size.y - stage_r.size.y) > 1.0:
		failures.append("an injected side_left plate does not anchor to the stage's left edge")
	BackdropCatalog.inject(left_path, null)
	board.use_backdrop(0)
	if not board.side_plates().is_empty() and board.side_plates()[0].visible:
		failures.append("side plate stayed after its art went away")
	board.use_golden_hour(true)
	var look_button := board.find_child("BackdropButton", true, false) as Button
	if look_button == null or look_button.text != GardenBoard.GOLDEN_HOUR_NAME:
		failures.append("look button reads '%s' on Golden Hour" % (look_button.text if look_button else "?"))
	board.use_golden_hour(false)
	board.use_backdrop(0)
	# Framing: flat dark matte, clipped stage, no smear shader.
	if stage == null or not stage.clip_contents:
		failures.append("the stage does not clip its contents")
	var matte := board.find_child("StageFill", true, false) as ColorRect
	if matte == null or matte.material != null or matte.color != GardenBoard.MATTE_COLOR:
		failures.append("the side matte is not the flat forest-green fill")
	if ResourceLoader.exists("res://src/prototype/stage_fill.gdshader"):
		failures.append("the StageFill smear shader is still in the project")


func _check_tooltip(board: GardenBoard, failures: PackedStringArray) -> void:
	var tip := board.tooltip()
	if tip == null:
		failures.append("board has no lockable tooltip")
		return
	tip.set_manual_time(true)
	var hint := board.hint_banner()
	var at := Vector2(640.0, 300.0)
	if hint != null and hint.visible:
		at = hint.get_global_rect().get_center()
	tip.tick(0.0, at)
	tip.request("smoke", "Smoke tip: a long line of text so the panel has some width to it.")
	tip.tick(0.1, at)
	if tip.state() != GameTooltip.State.DWELL or tip.ring_visible():
		failures.append("tooltip skipped the grace dwell")
	tip.tick(GameTooltip.GRACE, at)
	if tip.state() != GameTooltip.State.CHARGING or not tip.ring_visible():
		failures.append("tooltip ring did not start after %.2f s" % GameTooltip.GRACE)
	if tip.panel_rect() != Rect2():
		failures.append("tooltip opened before its ring finished (it should only open locked)")
	# Moving restarts the dwell (ring and tip close).
	tip.tick(0.05, at + Vector2(20.0, 0.0))
	if tip.state() != GameTooltip.State.DWELL or tip.ring_visible() or tip.panel_rect() != Rect2():
		failures.append("moving did not cancel the charging tooltip")
	at += Vector2(20.0, 0.0)
	tip.tick(GameTooltip.GRACE + 0.01, at)
	tip.tick(GameTooltip.CHARGE * 0.5, at)
	if absf(tip.progress() - 0.5) > 0.1:
		failures.append("tooltip ring fill %.2f at half charge" % tip.progress())
	tip.press_at(at)
	if tip.state() != GameTooltip.State.IDLE:
		failures.append("a click did not cancel the charging tooltip")
	tip.request("smoke", "Smoke tip: a long line of text so the panel has some width to it.")
	tip.tick(GameTooltip.GRACE + 0.01, at)
	tip.tick(GameTooltip.CHARGE + 0.01, at)
	if not tip.is_locked() or tip.panel_rect() == Rect2():
		failures.append("tooltip did not lock at 100%")
	if hint != null and hint.visible and tip.panel_rect().intersects(hint.get_global_rect()):
		failures.append("locked tooltip covers the pre-wave hint")
	tip.press_at(tip.panel_rect().get_center())
	if not tip.is_locked():
		failures.append("clicking the locked tip itself closed it")
	tip.press_at(Vector2(2.0, 2.0))
	if tip.state() != GameTooltip.State.IDLE:
		failures.append("clicking outside did not close the locked tip")
	tip.request("smoke2", "Esc test")
	tip.tick(GameTooltip.GRACE + 0.01, at)
	tip.tick(GameTooltip.CHARGE + 0.01, at)
	var esc := InputEventKey.new()
	esc.physical_keycode = KEY_ESCAPE
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	root.push_input(esc)
	if tip.state() != GameTooltip.State.IDLE:
		failures.append("Esc did not close the locked tip")
	# GW-AA pass 5: no ring while a Warden is selected (or a card is held or
	# dragged); a dwell already running is dropped.
	tip.request("smoke3", "Suppressed")
	tip.tick(GameTooltip.GRACE * 0.5, at)
	board.set("_selected", 0)
	tip.tick(GameTooltip.GRACE + GameTooltip.CHARGE, at)
	if tip.state() != GameTooltip.State.IDLE or tip.ring_visible():
		failures.append("tooltip ring ran while a Warden was selected for placement")
	tip.request("smoke3", "Suppressed")
	if tip.state() != GameTooltip.State.IDLE:
		failures.append("tooltip accepted a request while suppressed")
	board.set("_selected", -1)
	tip.set_manual_time(false)


func _check_space_pause(board: GardenBoard, failures: PackedStringArray) -> void:
	var top := board.find_child("TopBar", true, false) as TopBar
	var was := board.is_paused()
	var space := InputEventKey.new()
	space.physical_keycode = KEY_SPACE
	space.keycode = KEY_SPACE
	space.pressed = true
	root.push_input(space)
	if board.is_paused() == was or (top != null and top.pause_shown() != board.is_paused()):
		failures.append("Space did not toggle pause in step with the Pause button")
	var echo := space.duplicate() as InputEventKey
	echo.echo = true
	root.push_input(echo)
	if board.is_paused() == was:
		failures.append("a held Space (key echo) flipped pause back")
	var release := space.duplicate() as InputEventKey
	release.pressed = false
	root.push_input(release)
	root.push_input(space)
	if board.is_paused() != was or (top != null and top.pause_shown() != was):
		failures.append("a second Space did not unpause")


func _check_beats(board: GardenBoard, failures: PackedStringArray) -> void:
	# Warden: press flat, then pop (with a puff cue), then settle; no HP bar.
	if not board.try_place(UnitCatalog.Warden.DEW, 0, 0):
		failures.append("could not plant a Dew Dropper for the beat checks")
		return
	var warden: WardenActor = null
	for child in board.find_child("Lawn", true, false).get_children():
		if child is WardenActor:
			warden = child
	if warden.health_bar_shown():
		failures.append("Warden health bar still shows")
	# GW-AA pass 5: a sticker comes down standing, curls flat from the
	# bottom up, sinks, then the live Warden pops up with confetti.
	if warden.placement_phase() != PaperPop.Phase.DESCEND or not warden.sticker_showing():
		failures.append("a new Warden did not start as a descending sticker")
	var peak := 0.0
	var t := 0.0
	var seen := {}
	var standing_h := 0.0
	var flat_h := INF
	var clip_hidden_ok := true
	while t < PaperPop.placement_time() + 0.2:
		warden.idle_tick(1.0 / 60.0)
		t += 1.0 / 60.0
		seen[warden.placement_phase()] = true
		var decal := warden.sticker()
		if warden.sticker_showing():
			if warden.placement_phase() == PaperPop.Phase.DESCEND:
				standing_h = maxf(standing_h, decal.shown_height())
			elif warden.placement_phase() == PaperPop.Phase.FLAT:
				flat_h = minf(flat_h, decal.shown_height())
			if warden.clip().visible:
				clip_hidden_ok = false
		elif t < PaperPop.pop_start() - 0.02:
			failures.append("the sticker vanished before it sank (%.2f s)" % t)
		if not warden.sticker_showing():
			peak = maxf(peak, warden.clip_scale().y)
	for phase in [PaperPop.Phase.DESCEND, PaperPop.Phase.CURL, PaperPop.Phase.FLAT, PaperPop.Phase.SINK, PaperPop.Phase.POP]:
		if not seen.has(phase):
			failures.append("sticker placement skipped phase %d" % phase)
	if not clip_hidden_ok:
		failures.append("the live clip showed under the sticker")
	if standing_h <= 0.0 or flat_h >= standing_h * 0.45:
		failures.append("the sticker did not go from standing (%.1f px) to flat on the felt (%.1f px)" % [standing_h, flat_h])
	if peak < 1.08 or peak > 1.16:
		failures.append("Warden pop overshoot %.2f, want ~1.12" % peak)
	if warden.placement_phase() != PaperPop.Phase.DONE or not warden.clip_scale().is_equal_approx(Vector2.ONE) or warden.sticker_showing():
		failures.append("Warden did not settle to full size after the pop")
	# The pop is a confetti celebration, not the death poof.
	board._emit_place_puffs()
	if warden.consume_pop_cue():
		failures.append("Warden pop cue fired twice")
	var confetti := board.find_child("PlaceConfetti", true, false)
	if board.find_child("PlacePuff", true, false) != null:
		failures.append("placement still uses the death poof")
	if confetti == null or (confetti as ConfettiBurst).piece_count() < 8:
		failures.append("no confetti burst on placement")
	# Dew: a visible buildup of 1.5-2.5 s before each drop.
	var build_start := -1.0
	var clock := 0.0
	var dropped := false
	while clock < UnitCatalog.DEW_INTERVAL + 1.0:
		var action := warden.tick(0.05, false)
		clock += 0.05
		if warden.dew_building() and build_start < 0.0:
			build_start = clock
		if action == "water":
			dropped = true
			break
	if not dropped or build_start < 0.0:
		failures.append("Dew Dropper never built up and dropped")
	elif clock - build_start < 1.5 or clock - build_start > 2.5:
		failures.append("Dew buildup lasted %.2f s, want 1.5-2.5" % (clock - build_start))
	# Vermin: slide in flat from the right, then flip up; no HP bar.
	board.spawn_vermin(UnitCatalog.Vermin.FLY, 2, 11.5)
	var vermin: VerminActor = null
	for child in board.find_child("Lawn", true, false).get_children():
		if child is VerminActor:
			vermin = child
	if vermin == null:
		failures.append("could not spawn a vermin for the entrance check")
		return
	if vermin.health_bar_shown():
		failures.append("vermin health bar still shows")
	vermin.tick(0.0, VerminActor.Mode.MOVE)
	if not vermin.clip().animation_name().begins_with("idle"):
		failures.append("vermin entrance plays '%s' (the spawn clips hang fliers on a string); want the idle frame" % vermin.clip().animation_name())
	if vermin.entrance_phase() != PaperPop.Phase.SLIDE or vermin.clip_scale().y > 0.2 or vermin.clip_offset().x <= 0.0:
		failures.append("a new vermin did not slide in flat from the right")
	var seen_flip := false
	var top := 0.0
	var e := 0.0
	while e < PaperPop.entrance_time() + 0.2:
		vermin.tick(1.0 / 60.0, VerminActor.Mode.IDLE)
		e += 1.0 / 60.0
		if vermin.entrance_phase() == PaperPop.Phase.FLIP:
			seen_flip = true
		top = maxf(top, vermin.clip_scale().y)
	if not seen_flip or top < 1.05 or top > 1.1:
		failures.append("vermin flip-up missing or off (peak %.2f)" % top)
	if vermin.entrance_phase() != PaperPop.Phase.DONE or not vermin.clip_scale().is_equal_approx(Vector2.ONE) or vermin.clip_offset().length() > 0.01:
		failures.append("vermin did not stand settled after its entrance")
	# Bees glide tile to tile (visual only): eased, arcing, banked.
	board.spawn_vermin(UnitCatalog.Vermin.BEE, 1, 8.5)
	var bee: VerminActor = null
	for child in board.find_child("Lawn", true, false).get_children():
		if child is VerminActor and (child as VerminActor).kind == UnitCatalog.Vermin.BEE:
			bee = child
	if bee == null:
		failures.append("could not spawn a bee for the glide check")
		return
	for step in [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var from_col := bee.column_pos
		var from_row := bee.row
		bee.column_pos += float(step.x)
		bee.row += step.y
		bee.begin_glide(from_col, from_row, step)
		var mid_lift := 0.0
		var mid_tilt := 0.0
		var g := 0.0
		var first := bee.display_column() if step.x != 0 else bee.display_row()
		while g < VerminActor.GLIDE_TIME * 0.5:
			bee.tick(1.0 / 60.0, VerminActor.Mode.MOVE)
			g += 1.0 / 60.0
		mid_lift = bee.glide_lift_cells()
		mid_tilt = bee.glide_tilt()
		var mid := bee.display_column() if step.x != 0 else bee.display_row()
		while g < VerminActor.GLIDE_TIME + 0.1:
			bee.tick(1.0 / 60.0, VerminActor.Mode.MOVE)
			g += 1.0 / 60.0
		if absf(mid - first) < 0.2 or mid_lift <= 0.0:
			failures.append("bee step %s snapped instead of gliding (moved %.2f, lift %.2f)" % [step, absf(mid - first), mid_lift])
		if (step.y < 0 and mid_tilt <= 0.0) or (step.y > 0 and mid_tilt >= 0.0) or (step.x < 0 and mid_tilt >= 0.0):
			failures.append("bee step %s tilt %.2f is not the step's own bank/pitch" % [step, mid_tilt])
		if bee.is_gliding() or not is_equal_approx(bee.display_column(), bee.column_pos):
			failures.append("bee glide did not land on its tile")


## Live switch between the bottom tray and the side bar, and back.
func _check_layouts(board: GardenBoard, failures: PackedStringArray) -> void:
	var bottom := board.find_child("BottomBar", true, false) as BottomBar
	var cards := bottom.cards() if bottom != null else []
	if board.layout_mode() != GardenBoard.LAYOUT_HORIZONTAL:
		failures.append("headless board did not start with the bottom tray")
	board.apply_layout(GardenBoard.LAYOUT_VERTICAL)
	if board.layout_mode() != GardenBoard.LAYOUT_VERTICAL or bottom == null or not bottom.is_vertical():
		failures.append("side bar layout did not apply")
	elif bottom.get_parent().name != "Body":
		failures.append("side bar did not move beside the stage")
	# The stage stays top-aligned so cloud sticks run up behind the top bar.
	if absf(board.stage_rect().position.y) > 0.5:
		failures.append("stage left a gap above it (cloud sticks would stop mid-sky)")
	for card: WardenCard in cards:
		if not card.is_large():
			failures.append("side bar cards were not enlarged")
			break
	board.apply_layout(GardenBoard.LAYOUT_HORIZONTAL)
	if board.layout_mode() != GardenBoard.LAYOUT_HORIZONTAL or bottom.is_vertical() or bottom.get_parent().name != "Layout":
		failures.append("bottom tray layout did not come back")


func _check_no_texture(node: Node, fragment: String, failures: PackedStringArray) -> void:
	if node is TextureRect:
		var texture := (node as TextureRect).texture
		if texture != null and texture.resource_path.contains(fragment):
			failures.append("parked art is drawn: %s" % texture.resource_path)
	for child in node.get_children():
		_check_no_texture(child, fragment, failures)


func _wave_types() -> int:
	var kinds: Array[int] = []
	for entry in LevelCatalog.current().wave:
		var kind := int(entry.y)
		if not kinds.has(kind):
			kinds.append(kind)
	return kinds.size()


func _wave_count() -> int:
	return LevelCatalog.current().wave.size()


func _check_texts(node: Node, failures: PackedStringArray) -> void:
	var texts: PackedStringArray = []
	_collect_text(node, texts)
	for required in ["Garden Wardens", "Dew Dropper", "Needle Spitter", "Stubborn Cone", "200", "Level 1", "Vermin %d" % _wave_count(), "Ability", "Remove", "Speed", "Pause", "Anims"]:
		if not _has_text(texts, required):
			failures.append("missing text: %s" % required)


func _check_cards(node: Node, failures: PackedStringArray) -> void:
	var counts := _count_cards(node)
	if counts.x != 3:
		failures.append("expected 3 warden cards, found %d" % counts.x)
	if counts.y != 0:
		failures.append("expected no card selected yet, found %d" % counts.y)
	if counts.z != 0:
		failures.append("expected every card affordable at the start, found %d unaffordable" % counts.z)


func _check_textures(node: Node, failures: PackedStringArray) -> void:
	if node is TextureRect:
		var rect := node as TextureRect
		if rect.visible and rect.texture == null and rect.is_inside_tree():
			failures.append("visible TextureRect has no texture: %s" % str(rect.get_path()))
	for child in node.get_children():
		_check_textures(child, failures)


func _count_cards(node: Node) -> Vector3i:
	var counts := Vector3i.ZERO
	if node is WardenCard:
		counts.x = 1
		var card := node as WardenCard
		if card.is_selected():
			counts.y = 1
		if card.is_unaffordable():
			counts.z = 1
	for child in node.get_children():
		counts += _count_cards(child)
	return counts


func _collect_text(node: Node, texts: PackedStringArray) -> void:
	if node is Label:
		texts.append((node as Label).text)
	elif node is Button:
		texts.append((node as Button).text)
	for child in node.get_children():
		_collect_text(child, texts)


func _has_text(texts: PackedStringArray, required: String) -> bool:
	for text in texts:
		if text == required:
			return true
	return false
