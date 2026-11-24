## Startup preload and GPU warmup (GW-AA pass 4).
##
## Brandon: "initial switching of backgrounds is extremely slow, as is the
## initial click to place a warden... every action takes a long time the
## first time". Root causes, all lazy first-use work on the main thread:
##   * AnimLibrary built each unit's SpriteFrames on first use: the first
##     placement of a kind (or first spawn of a vermin) loaded its 150-400
##     frame PNGs one by one inside the click (~1,900 frames in all).
##   * Look switches loaded the next backdrop on demand; the Golden Hour stop
##     loaded two 2600 px ray wheels and compiled a fresh mask Shader per
##     wheel; the sky loaded each cloud, sun and rain texture as it appeared.
##   * FxArt loaded the smoke/lob sequences on the first shot, and ClipView
##     compiled a new overlay Shader for every Needle Spitter.
##   * The GL Compatibility renderer compiles each canvas shader variant and
##     finishes texture uploads the first time something draws with them.
##
## begin() loads every one of those files on four worker threads at startup
## (so the first frame is not held up); poll() runs a few milliseconds a
## frame on the main thread to collect the finished threads and keep strong
## references (the resource cache alone is weak, so an
## unreferenced texture would reload), then builds every unit clip from the
## already-loaded frames. GpuWarmup then draws each texture and custom
## material once, near-invisibly under the matte, on the next two frames.
## A click that lands before the preload finishes still works: its load()
## just waits for the in-flight file instead of starting from scratch.
class_name StartupPreload
extends RefCounted

## Background loader threads (one slice of the file list each). More threads
## finish sooner but fight the render thread for the GL upload lock, so
## frames stutter while they run; `--preload-threads=N` overrides for tuning.
const THREADS := 2

## Strong references to everything preloaded.
static var _held: Array = []
static var _threads: Array[Thread] = []
static var _cancel := false
static var _begun := false
static var _done := false
static var _clips_built := 0
static var _begin_usec := 0
static var _main_usec := 0
## Milliseconds: wall time from begin() to done, main-thread time spent in
## begin()/poll(), and file counts (for probes and the report).
static var timings: Dictionary = {}


static func is_done() -> bool:
	return _done


static func begun() -> bool:
	return _begun


## True when the renderer can take texture uploads from worker threads.
## The headless dummy renderer cannot, so there the preload loads on the main
## thread (only tests run headless; nobody is waiting on a first frame).
static func threaded_ok() -> bool:
	return DisplayServer.get_name() != "headless"


## Every file the preload loads: unit frames, the poof, effect sequences,
## look plates, Golden Hour layers and sky art.
static func all_paths() -> Array[String]:
	var paths: Array[String] = []
	for folder in AnimLibrary.WARDEN_FOLDERS:
		paths.append_array(AnimLibrary.frame_paths(folder))
	for folder in AnimLibrary.VERMIN_FOLDERS:
		paths.append_array(AnimLibrary.frame_paths(folder))
	paths.append_array(AnimLibrary.poof_paths())
	paths.append_array(FxArt.sequence_paths())
	paths.append_array(BackdropCatalog.all_paths())
	paths.append_array(GoldenHourBackdrop.all_paths())
	paths.append_array(SkyCatalog.all_paths())
	paths.append(SkyLayer.RAIN_STICK_TEXTURE)
	# GW-AA pass 5: confetti, felt tiles, roster portraits, props, paper matte.
	paths.append_array(ConfettiBurst.PIECES)
	for kind in LawnView.SOIL_TILE_NAMES:
		for shade in ["light", "dark"]:
			paths.append(LawnView.BOARD_DIR + "%s_%s.png" % [LawnView.SOIL_TILE_NAMES[kind], shade])
	for kind in UnitCatalog.Vermin.size():
		paths.append(RosterPortraits.slot_path(kind))
	for entry in StageLayers.DECOR:
		paths.append(StageLayers.PROP_DIR + String(entry[0]))
	paths.append(GardenBoard.MATTE_PAPER_TILE)
	var out: Array[String] = []
	var seen := {}
	for path in paths:
		# No ResourceLoader.exists() here: on Windows it costs ~0.2 ms a file
		# on the main thread; the loader threads check instead.
		if seen.has(path):
			continue
		seen[path] = true
		out.append(path)
	return out


## Starts loading every file on THREADS worker threads (plain load() per
## file; Godot's loader shares any file the main thread asks for meanwhile).
## Safe to call more than once. [param threaded] false loads on the main
## thread inside poll() instead.
static func begin(threaded: bool = true) -> void:
	if _begun:
		return
	_begun = true
	_cancel = false
	_begin_usec = Time.get_ticks_usec()
	var paths := all_paths()
	timings["files"] = paths.size()
	timings["threaded"] = threaded and threaded_ok()
	if not timings["threaded"]:
		_held.append_array(paths)  # Strings: loaded in poll().
		_main_usec += Time.get_ticks_usec() - _begin_usec
		return
	var count := THREADS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--preload-threads="):
			count = clampi(int(arg.get_slice("=", 1)), 1, 8)
	timings["threads"] = count
	for k in count:
		var slice: Array[String] = []
		for i in range(k, paths.size(), count):
			slice.append(paths[i])
		var thread := Thread.new()
		thread.start(StartupPreload._load_slice.bind(slice))
		_threads.append(thread)
	_main_usec += Time.get_ticks_usec() - _begin_usec


## Worker: loads one slice, stopping early if cancel() was called.
static func _load_slice(slice: Array[String]) -> Array:
	var out: Array = []
	for path in slice:
		if _cancel:
			break
		if ResourceLoader.exists(path):
			out.append([path, load(path)])
	return out


## Collects finished loader threads, then builds every unit clip (one per
## call) from the loaded frames, for up to [param budget_ms] of main-thread
## time (<= 0: block until done). Returns true once everything is ready.
static func poll(budget_ms: float = 4.0) -> bool:
	if _done:
		return true
	if not _begun:
		begin()
	var start := Time.get_ticks_usec()
	var budget_usec := int(budget_ms * 1000.0)
	var over := func() -> bool:
		return budget_ms > 0.0 and Time.get_ticks_usec() - start > budget_usec
	# Main-thread mode: the queued paths sit in _held as Strings.
	var i := 0
	while i < _held.size():
		if _held[i] is String:
			var path: String = _held[i]
			_held[i] = _keep(path, load(path) if ResourceLoader.exists(path) else null)
			if over.call():
				_main_usec += Time.get_ticks_usec() - start
				return false
		i += 1
	for thread in _threads.duplicate():
		if budget_ms > 0.0 and thread.is_alive():
			continue
		for pair in thread.wait_to_finish():
			_held.append(_keep(pair[0], pair[1]))
		_threads.erase(thread)
	if not _threads.is_empty():
		_main_usec += Time.get_ticks_usec() - start
		return false
	# Every file is in: build the clips (each load() is now a cache hit), one
	# unit per call so no single frame takes the whole build.
	var folders: Array[String] = []
	folders.append_array(AnimLibrary.WARDEN_FOLDERS)
	folders.append_array(AnimLibrary.VERMIN_FOLDERS)
	while _clips_built < folders.size():
		var frames := AnimLibrary.clip_for_folder(folders[_clips_built])
		if frames != null:
			_held.append(frames)
		_clips_built += 1
		if over.call():
			_main_usec += Time.get_ticks_usec() - start
			return false
	_held.append(AnimLibrary.poof())
	_held.append(FxArt.needle_smoke())
	_held.append(FxArt.lobber_spin())
	_held.append(FxArt.lobber_burst())
	_held.append_array([FxArt.WATER_PARACHUTE, FxArt.WATER_DROP_MEDIUM, FxArt.WATER_DROP_SMALL,
		FxArt.SMALL_BURST, FxArt.IMPACT_BURST, FxArt.COLLECT_FLECKS, FxArt.LEAF_RING])
	_held.append(GoldenHourBackdrop.mask_shader())
	_held.append(ClipView.overlay_shader())
	_held.append(LawnView.FELT_SHADER)
	_main_usec += Time.get_ticks_usec() - start
	timings["wall_ms"] = float(Time.get_ticks_usec() - _begin_usec) / 1000.0
	timings["main_thread_ms"] = float(_main_usec) / 1000.0
	timings["textures"] = textures().size()
	_done = true
	return true


## Stops the loader threads early and joins them (quitting mid-preload).
static func cancel() -> void:
	_cancel = true
	for thread in _threads:
		thread.wait_to_finish()
	_threads.clear()


static func _keep(path: String, resource: Variant) -> Variant:
	if resource is Texture2D:
		BackdropCatalog.remember(path, resource as Texture2D)
	return resource


## Loads everything right now, blocking (tests and tools).
static func run(threaded: bool = true) -> Dictionary:
	begin(threaded)
	poll(0.0)
	return timings


## Every preloaded texture (sprite frames included), for the warmup draw.
static func textures() -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	var seen := {}
	for item in _held:
		if item is Texture2D:
			_add(out, seen, item)
		elif item is SpriteFrames:
			var frames := item as SpriteFrames
			for anim in frames.get_animation_names():
				for i in frames.get_frame_count(anim):
					_add(out, seen, frames.get_frame_texture(anim, i))
		elif item is Array:
			for entry in item:
				if entry is Texture2D:
					_add(out, seen, entry)
	return out


## The custom materials to compile up front (one instance of each shader).
static func materials() -> Array[ShaderMaterial]:
	var out: Array[ShaderMaterial] = []
	for shader in [GoldenHourBackdrop.mask_shader(), ClipView.overlay_shader()]:
		var material := ShaderMaterial.new()
		material.shader = shader
		out.append(material)
	return out


static func _add(out: Array[Texture2D], seen: Dictionary, texture: Texture2D) -> void:
	if texture == null or seen.has(texture):
		return
	seen[texture] = true
	out.append(texture)
