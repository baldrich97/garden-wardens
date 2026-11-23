## The drifting sky over the lawn band (GW-AW-6b): stick clouds, one sun
## per match, and rain when the seed says so. Every cloud hangs from a white
## stick that runs up off the top of the screen and bobs up and down with a
## slight tilt, as if a stagehand above the set were moving it along. Pure presentation: it never
## reads or changes match state, and every choice comes from SkyLook given
## the match seed, so a seeded match always shows the same sky.
class_name SkyLayer
extends Control

## Target heights, in screen pixels.
const SUN_TARGET_H := 64.0
const RAIN_CLOUD_TARGET_H := 44.0
const DROP_TARGET_H := 14.0
const SPLASH_TARGET_H := 20.0
const CLOUD_BODY_TARGETS := [36.0, 48.0, 60.0]

## The stick always reaches past the top edge by at least this much, even at
## the top of a bob, so its end is never seen.
const STICK_OVERSHOOT := 8.0
## The rain cloud's hand-made stick: the white stick tile, drawn this wide.
const RAIN_STICK_TEXTURE := "res://assets/art/sky/clouds/sticks/white_stick_tile_medium.png"
const RAIN_STICK_W := 6.0
## Sun bob (hand-held, gentle): pixels and degrees, and their cycles.
const SUN_BOB_PX := 3.0
const SUN_BOB_PERIOD := 5.5
const SUN_TILT_DEG := 2.0
const SUN_TILT_PERIOD := 7.0

## Pools and pacing for the rain effect.
const DROP_POOL := 10
const SPLASH_POOL := 6
const SPLASH_TIME := 0.35
const RAIN_CLOUD_SPEED_MIN := 6.0
const RAIN_CLOUD_SPEED_MAX := 12.0
const DROP_SPEED_MIN := 80.0
const DROP_SPEED_MAX := 140.0
const SPAWN_INTERVAL_MIN := 0.1
const SPAWN_INTERVAL_MAX := 0.16

var _band := Rect2()
var _seed := 0
var _mood := 0
var _sun_index := 0
var _sun_x_frac := 0.5
var _rain := false
var _rain_cloud_index := 0
var _rain_cloud_x_frac := 0.5
var _rain_cloud_speed := 8.0
var _cloud_specs: Array[Dictionary] = []
var _cloud_speeds: Array[float] = []
var _cloud_bobs: Array[Dictionary] = []
## Each cloud's drift position and resting height; the bob rides on top.
var _drift_x: Array[float] = []
var _rest_y: Array[float] = []
var _bob_px: Array[float] = []
var _time := 0.0
var _sun_rest := Vector2.ZERO
var _rain_rest_y := 0.0
var _rain_drift_x := 0.0
var _rain_stick: TextureRect

var _sun: TextureRect
var _rain_cloud: TextureRect
var _clouds: Array[TextureRect] = []
var _drops: Array[TextureRect] = []
var _splash_nodes: Array[TextureRect] = []
var _splash_t: Array[float] = []
var _fx_rng: RandomNumberGenerator
var _spawn_acc := 0.0
var _drop_speed := 110.0
var _spawn_interval := 0.13
var _ground_y := 0.0


## Builds the sprite pools up front, so the layer is usable as soon as it
## exists (the test harness constructs it outside a running frame).
func _init() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sun = _make_sprite()
	add_child(_sun)
	for _i in SkyLook.CLOUD_MAX:
		var cloud := _make_sprite()
		add_child(cloud)
		_clouds.append(cloud)
		_cloud_speeds.append(0.0)
		_drift_x.append(0.0)
		_rest_y.append(0.0)
		_bob_px.append(0.0)
	_rain_stick = TextureRect.new()
	_rain_stick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rain_stick.texture = load(RAIN_STICK_TEXTURE) as Texture2D
	_rain_stick.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rain_stick.stretch_mode = TextureRect.STRETCH_SCALE
	_rain_stick.visible = false
	add_child(_rain_stick)
	_rain_cloud = _make_sprite()
	add_child(_rain_cloud)
	for _i in DROP_POOL:
		var drop := _make_sprite()
		_fit(drop, SkyCatalog.RAIN_DROP, DROP_TARGET_H)
		add_child(drop)
		_drops.append(drop)
	for _i in SPLASH_POOL:
		var splash := _make_sprite()
		_fit(splash, SkyCatalog.RAIN_SPLASH, SPLASH_TARGET_H)
		add_child(splash)
		_splash_nodes.append(splash)
		_splash_t.append(0.0)


func _process(delta: float) -> void:
	tick(delta)


## Sets the band the sky lays out in (board-local coordinates).
func set_band(rect: Rect2) -> void:
	_band = rect
	_ground_y = rect.position.y + rect.size.y - 4.0
	_layout()


## Applies the seeded look for the current mood: which sun, whether it
## rains, and the cloud spec.
func apply_look(seed_value: int, mood_index: int) -> void:
	_seed = seed_value
	_mood = mood_index
	_sun_index = SkyLook.sun_index(_seed, SkyCatalog.SUNS.size())
	_sun_x_frac = SkyLook.sun_x_frac(_seed)
	_rain = SkyLook.rain_active(_seed, _mood)
	_rain_cloud_index = SkyLook.rain_cloud_index(_seed, SkyCatalog.RAIN_CLOUDS.size())
	_rain_cloud_x_frac = SkyLook.rain_cloud_x_frac(_seed)
	_rain_cloud_speed = MatchSeed.with_value(_seed).rng("sky_rain_cloud_move").randf_range(
		RAIN_CLOUD_SPEED_MIN, RAIN_CLOUD_SPEED_MAX
	)
	_fx_rng = MatchSeed.with_value(_seed).rng("sky_rain_fx")
	_drop_speed = _fx_rng.randf_range(DROP_SPEED_MIN, DROP_SPEED_MAX)
	_spawn_interval = _fx_rng.randf_range(SPAWN_INTERVAL_MIN, SPAWN_INTERVAL_MAX)
	_spawn_acc = 0.0
	var class_counts: Array[int] = [
		SkyCatalog.class_count(0),
		SkyCatalog.class_count(1),
		SkyCatalog.class_count(2),
	]
	_cloud_specs = SkyLook.cloud_specs(_seed, class_counts)
	_cloud_bobs = SkyLook.cloud_bobs(_seed, _cloud_specs.size())
	_time = 0.0
	_reset_pool()
	_layout()


## Advances drift and rain by one step. Also runs from _process.
func tick(delta: float) -> void:
	if _band.size.x <= 0.0:
		return
	_time += delta
	for i in _clouds.size():
		var cloud := _clouds[i]
		if not cloud.visible:
			continue
		_drift_x[i] -= _cloud_speeds[i] * delta
		if _drift_x[i] + cloud.size.x < _band.position.x:
			_drift_x[i] = _band.end.x
		_pose_cloud(i)
	if _sun.visible:
		_sun.position = _sun_rest + Vector2(0.0, SUN_BOB_PX * sin(TAU * _time / SUN_BOB_PERIOD))
		_sun.rotation = deg_to_rad(SUN_TILT_DEG) * sin(TAU * _time / SUN_TILT_PERIOD)
	if _rain:
		_rain_drift_x -= _rain_cloud_speed * delta
		if _rain_drift_x + _rain_cloud.size.x < _band.position.x:
			_rain_drift_x = _band.end.x
		_pose_rain_cloud()
		_update_rain(delta)


## How far cloud i currently sits from its resting height (negative is up).
## Exposed so tests and probes can confirm the clouds really bob.
func cloud_bob_offset(index: int) -> float:
	if index < 0 or index >= _cloud_specs.size():
		return 0.0
	return _clouds[index].position.y - _rest_y[index]


## The bob amplitude of cloud i, in screen pixels.
func cloud_bob_amplitude(index: int) -> float:
	if index < 0 or index >= _cloud_specs.size():
		return 0.0
	return _bob_px[index]


## Whether every visible cloud's stick runs past the top of the screen.
func sticks_reach_top() -> bool:
	for i in _cloud_specs.size():
		if _clouds[i].visible and _clouds[i].position.y > -STICK_OVERSHOOT * 0.5:
			return false
	return true


## The vertical bob for a cloud at the current time: a slow main swing plus a
## small off-beat wobble, so it reads as a hand rather than a machine.
func _bob_wave(phase: float, period: float) -> float:
	var w := TAU * _time / period
	return 0.75 * sin(w + phase) + 0.25 * sin(2.3 * w + 2.0 * phase)


func _pose_cloud(i: int) -> void:
	var cloud := _clouds[i]
	var bob: Dictionary = _cloud_bobs[i] if i < _cloud_bobs.size() else {"period": 4.5, "phase": 0.0, "tilt_deg": 0.8}
	var period := float(bob["period"])
	var phase := float(bob["phase"])
	var sway := 1.5 * sin(TAU * _time / (period * 1.3) + phase)
	cloud.position = Vector2(_drift_x[i] + sway, _rest_y[i] + _bob_px[i] * _bob_wave(phase, period))
	# Tilt around the stick's top end, where the unseen hand holds it.
	cloud.pivot_offset = Vector2(cloud.size.x * 0.5, 0.0)
	cloud.rotation = deg_to_rad(float(bob["tilt_deg"])) * sin(TAU * _time / (period * 1.7) + phase)


func _pose_rain_cloud() -> void:
	var dy := _rain_cloud.size.y * 0.12 * _bob_wave(1.1, 4.8)
	_rain_cloud.position = Vector2(_rain_drift_x, _rain_rest_y + dy)
	_rain_stick.size = Vector2(RAIN_STICK_W, _rain_cloud.position.y + _rain_cloud.size.y * 0.4 + STICK_OVERSHOOT)
	_rain_stick.position = Vector2(
		_rain_cloud.position.x + (_rain_cloud.size.x - RAIN_STICK_W) * 0.5,
		-STICK_OVERSHOOT
	)


## Whether the sun shows for the current mood.
func sun_visible() -> bool:
	return SkyLook.mood_shows_sun(_mood)


## The sun texture for this match, or null if none was assigned.
func sun_texture() -> Texture2D:
	return _sun.texture


## Whether rain is active for the current mood.
func raining() -> bool:
	return _rain


## How many clouds this match spawned.
func cloud_count() -> int:
	return _cloud_specs.size()


## Whether every spawned cloud has a texture.
func clouds_have_textures() -> bool:
	for i in _cloud_specs.size():
		if _clouds[i].texture == null:
			return false
	return true


## How many drops are falling right now.
func active_drops() -> int:
	var count := 0
	for drop in _drops:
		if drop.visible:
			count += 1
	return count


## How many splashes are fading right now.
func active_splashes() -> int:
	var count := 0
	for t in _splash_t:
		if t > 0.0:
			count += 1
	return count


func _make_sprite() -> TextureRect:
	var sprite := TextureRect.new()
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# KEEP_ASPECT scales the art to the control's size; IGNORE_SIZE lifts the
	# native-pixel minimum so small target heights actually stick.
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.visible = false
	return sprite


## Loads a texture and sizes the sprite so source_h source pixels map to
## target_h screen pixels (for stick clouds, source_h is the cloud body;
## 0 means the whole texture).
func _fit(sprite: TextureRect, path: String, target_h: float, source_h: float = 0.0) -> bool:
	var tex := load(path) as Texture2D
	if tex == null:
		push_error("SkyLayer could not load %s" % path)
		return false
	sprite.texture = tex
	var basis := source_h if source_h > 0.0 else tex.get_size().y
	var scale := target_h / basis
	sprite.size = tex.get_size() * scale
	return true


func _reset_pool() -> void:
	for drop in _drops:
		drop.visible = false
	for splash in _splash_nodes:
		splash.visible = false
	_splash_t.fill(0.0)


func _layout() -> void:
	if _band.size.x <= 0.0:
		return
	# Sun: one per match, hidden on overcast and on moods that paint their own.
	if not SkyLook.mood_shows_sun(_mood):
		_sun.visible = false
	else:
		var sun_ok := _fit(_sun, SkyCatalog.SUNS[_sun_index], SUN_TARGET_H)
		if sun_ok:
			_sun_rest = Vector2(
				_band.position.x + _band.size.x * _sun_x_frac - _sun.size.x * 0.5,
				_band.position.y + (_band.size.y - _sun.size.y) * 0.5
			)
			_sun.position = _sun_rest
			_sun.pivot_offset = _sun.size * 0.5
			_sun.visible = true
		else:
			_sun.visible = false
	# Clouds: mixed sizes drifting across the band. The cloud body hangs in
	# the band; its stick rises out of the body and always runs past the top
	# of the screen (behind the top bar), like a prop held from above.
	for i in _clouds.size():
		var cloud := _clouds[i]
		if i >= _cloud_specs.size():
			cloud.visible = false
			_cloud_speeds[i] = 0.0
			continue
		var spec := _cloud_specs[i]
		var entry: Dictionary
		if spec["stick"]:
			entry = SkyCatalog.stick_at(spec["size"], spec["variant"])
		else:
			entry = SkyCatalog.plain_at(spec["size"], spec["variant"])
		if entry.get("path", "") == "":
			cloud.visible = false
			_cloud_speeds[i] = 0.0
			continue
		var body_h: float = CLOUD_BODY_TARGETS[spec["size"]]
		if not _fit(cloud, entry["path"], body_h, float(entry["body_h"])):
			cloud.visible = false
			_cloud_speeds[i] = 0.0
			continue
		var bob: Dictionary = _cloud_bobs[i] if i < _cloud_bobs.size() else {"amp": 0.15}
		_bob_px[i] = body_h * float(bob["amp"])
		var stick_h := cloud.size.y - body_h
		# Body top somewhere from just under the band's top edge to low in
		# the band, then capped so the stick still clears the screen top at
		# the highest point of the bob.
		var body_top := lerpf(_band.position.y - body_h * 0.1, _band.end.y - body_h * 0.85, spec["height"])
		body_top = minf(body_top, stick_h - STICK_OVERSHOOT - _bob_px[i])
		_rest_y[i] = body_top - stick_h
		_drift_x[i] = lerpf(_band.position.x - cloud.size.x, _band.end.x, spec["phase"])
		_cloud_speeds[i] = spec["speed"]
		cloud.visible = true
		_pose_cloud(i)
	# Rain cloud: floats high in the band so drops are visibly falling from
	# it down to the grass.
	if _rain:
		var rain_ok := _fit(_rain_cloud, SkyCatalog.RAIN_CLOUDS[_rain_cloud_index], RAIN_CLOUD_TARGET_H)
		if rain_ok:
			_rain_drift_x = lerpf(_band.position.x, _band.end.x - _rain_cloud.size.x, _rain_cloud_x_frac)
			_rain_rest_y = _band.position.y + _band.size.y * 0.05
			_rain_cloud.visible = true
			_rain_stick.visible = _rain_stick.texture != null
			_pose_rain_cloud()
		else:
			_rain_cloud.visible = false
			_rain_stick.visible = false
	else:
		_rain_cloud.visible = false
		_rain_stick.visible = false


func _update_rain(delta: float) -> void:
	_spawn_acc += delta
	while _spawn_acc >= _spawn_interval:
		_spawn_acc -= _spawn_interval
		_spawn_drop()
	for drop in _drops:
		if not drop.visible:
			continue
		drop.position.y += _drop_speed * delta
		if drop.position.y + drop.size.y >= _ground_y:
			drop.visible = false
			_pop_splash(drop.position.x + drop.size.x * 0.5)
	for i in _splash_nodes.size():
		if _splash_t[i] <= 0.0:
			continue
		_splash_t[i] -= delta
		var splash := _splash_nodes[i]
		splash.modulate.a = clampf(_splash_t[i] / SPLASH_TIME, 0.0, 1.0)
		if _splash_t[i] <= 0.0:
			splash.visible = false


func _spawn_drop() -> void:
	var drop: TextureRect = null
	for candidate in _drops:
		if not candidate.visible:
			drop = candidate
			break
	if drop == null:
		return
	var span := _rain_cloud.size.x * 0.7
	drop.position.x = _rain_cloud.position.x + _rain_cloud.size.x * 0.15 + _fx_rng.randf() * span
	var spawn_y := _rain_cloud.position.y + _rain_cloud.size.y * 0.85
	drop.position.y = minf(spawn_y, _ground_y - drop.size.y)
	drop.visible = true


func _pop_splash(center_x: float) -> void:
	for i in _splash_nodes.size():
		if _splash_t[i] > 0.0:
			continue
		var splash := _splash_nodes[i]
		_splash_t[i] = SPLASH_TIME
		splash.modulate.a = 1.0
		splash.position = Vector2(
			center_x - splash.size.x * 0.5,
			_ground_y - splash.size.y * 0.5
		)
		splash.visible = true
		return
