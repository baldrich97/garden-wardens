extends SceneTree

## Startup preload / GPU warmup probe (GW-AA pass 4). Windowed (needs a real
## renderer). Measures, in milliseconds from the call to the frame being
## drawn, the first-use moments Brandon felt:
##   first_frame        instantiate the board -> first frame drawn
##   first_look_switch  use_backdrop(next look)
##   first_golden_hour  use_golden_hour(true)
##   first_place_<kind> try_place of each Warden kind (first of its kind)
##   first_spawn        spawn_vermin (first of its kind)
##   first_shot_frame   the worst frame while the first Needle shots and
##                      smoke puffs appear
## Run normally (preload on), then with `-- --no-preload` for the "before".
## Prints STARTUP_TIMINGS {...} and STARTUP_PROBE_OK, or STARTUP_PROBE_FAIL.

const PRELOAD_LIMIT_S := 20.0

var _out := {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var preload_on := not OS.get_cmdline_user_args().has("--no-preload")
	var t := Time.get_ticks_usec()
	var board := (load("res://src/prototype/garden_board.tscn") as PackedScene).instantiate() as GardenBoard
	root.add_child(board)
	await RenderingServer.frame_post_draw
	_out["first_frame"] = _ms(t)
	_out["preload"] = preload_on
	if preload_on:
		var waited := Time.get_ticks_usec()
		var worst := 0.0
		var frames := 0
		var last := Time.get_ticks_usec()
		while not StartupPreload.is_done() or board.find_child("GpuWarmup", false, false) != null:
			await RenderingServer.frame_post_draw
			worst = maxf(worst, _ms(last))
			last = Time.get_ticks_usec()
			frames += 1
			if _ms(waited) > PRELOAD_LIMIT_S * 1000.0:
				return _fail("preload did not finish in %.0f s" % PRELOAD_LIMIT_S)
		_out["preload_worst_frame"] = worst
		_out["preload_frames"] = frames
		_out["preload_ready_after_start"] = _ms(t)
		_out["preload"] = StartupPreload.timings
		_out["warmup_ms"] = GpuWarmup.last_ms
		_out["warmup_textures"] = GpuWarmup.last_count
		if GpuWarmup.last_count < 1000:
			return _fail("warmup drew only %d textures" % GpuWarmup.last_count)
	else:
		# Same settle time as the preload run, so only the lazy loads differ.
		for _i in 30:
			await process_frame
	t = Time.get_ticks_usec()
	board.use_backdrop(BackdropCatalog.NAMES.find("Dusk"))
	await RenderingServer.frame_post_draw
	_out["first_look_switch"] = _ms(t)
	t = Time.get_ticks_usec()
	board.use_golden_hour(true)
	await RenderingServer.frame_post_draw
	_out["first_golden_hour"] = _ms(t)
	board.use_golden_hour(false)
	await RenderingServer.frame_post_draw
	board.get("_wallet").add(1000)
	var cells := {UnitCatalog.Warden.DEW: Vector2i(0, 0), UnitCatalog.Warden.NEEDLE: Vector2i(1, 2), UnitCatalog.Warden.SEED: Vector2i(0, 4)}
	for kind in cells:
		t = Time.get_ticks_usec()
		if not board.try_place(kind, cells[kind].x, cells[kind].y):
			return _fail("could not place warden kind %d" % kind)
		await RenderingServer.frame_post_draw
		_out["first_place_%s" % UnitCatalog.Warden.keys()[kind].to_lower()] = _ms(t)
	t = Time.get_ticks_usec()
	board.spawn_vermin(UnitCatalog.Vermin.BEE, 1, 11.0)
	await RenderingServer.frame_post_draw
	_out["first_spawn"] = _ms(t)
	board.spawn_vermin(UnitCatalog.Vermin.FLY, 2, 6.0)
	board.start_wave()
	var worst := 0.0
	var watch := Time.get_ticks_usec()
	var last := Time.get_ticks_usec()
	while _ms(watch) < 3500.0:
		await RenderingServer.frame_post_draw
		worst = maxf(worst, _ms(last))
		last = Time.get_ticks_usec()
	_out["first_shot_frame"] = worst
	print("STARTUP_TIMINGS ", JSON.stringify(_out))
	print("STARTUP_PROBE_OK")
	board.queue_free()
	await process_frame
	quit(0)


func _ms(since: int) -> float:
	return snappedf(float(Time.get_ticks_usec() - since) / 1000.0, 0.01)


func _fail(why: String) -> void:
	print("STARTUP_TIMINGS ", JSON.stringify(_out))
	push_error("STARTUP_PROBE_FAIL %s" % why)
	quit(1)
