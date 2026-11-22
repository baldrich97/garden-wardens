## The drifting sky over the lawn band (GW-AW-6b): stick clouds, one sun
## per match, and rain when the seed says so. Pure presentation: it never
## reads or changes match state, and every choice comes from SkyLook given
## the match seed, so a seeded match always shows the same sky.
class_name SkyLayer
extends Control

## Target heights, in screen pixels.
const SUN_TARGET_H := 52.0
const RAIN_CLOUD_TARGET_H := 32.0
const DROP_TARGET_H := 12.0
const SPLASH_TARGET_H := 18.0
const CLOUD_BODY_TARGETS := [24.0, 30.0, 44.0]

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
	_reset_pool()
	_layout()


## Advances drift and rain by one step. Also runs from _process.
func tick(delta: float) -> void:
	if _band.size.x <= 0.0:
		return
	for i in _clouds.size():
		var cloud := _clouds[i]
		if not cloud.visible:
			continue
		cloud.position.x -= _cloud_speeds[i] * delta
		if cloud.position.x + cloud.size.x < _band.position.x:
			cloud.position.x = _band.end.x
	if _rain:
		_rain_cloud.position.x -= _rain_cloud_speed * delta
		if _rain_cloud.position.x + _rain_cloud.size.x < _band.position.x:
			_rain_cloud.position.x = _band.end.x
		_update_rain(delta)


## Whether the sun shows for the current mood.
func sun_visible() -> bool:
	return _mood != SkyLook.MOOD_OVERCAST


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
	# Sun: one per match, hidden on the overcast mood.
	if _mood == SkyLook.MOOD_OVERCAST:
		_sun.visible = false
	else:
		var sun_ok := _fit(_sun, SkyCatalog.SUNS[_sun_index], SUN_TARGET_H)
		if sun_ok:
			_sun.position = Vector2(
				_band.position.x + _band.size.x * _sun_x_frac - _sun.size.x * 0.5,
				_band.position.y + (_band.size.y - _sun.size.y) * 0.5
			)
			_sun.visible = true
		else:
			_sun.visible = false
	# Clouds: mixed sizes drifting across the band. Stick composites rise out
	# of the body, so a prop taller than the band is shrunk to fit it.
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
		if not _fit(cloud, entry["path"], CLOUD_BODY_TARGETS[spec["size"]], float(entry["body_h"])):
			cloud.visible = false
			_cloud_speeds[i] = 0.0
			continue
		if cloud.size.y > _band.size.y:
			cloud.size *= _band.size.y / cloud.size.y
		var bottom_y := lerpf(_band.position.y + _band.size.y * 0.15, _band.end.y, spec["height"])
		# Keep the whole prop inside the band.
		var top := _band.position.y
		var bottom := maxf(_band.end.y - cloud.size.y, top)
		cloud.position = Vector2(
			lerpf(_band.position.x - cloud.size.x, _band.end.x, spec["phase"]),
			clampf(bottom_y - cloud.size.y, top, bottom)
		)
		_cloud_speeds[i] = spec["speed"]
		cloud.visible = true
	# Rain cloud: floats high in the band so drops are visibly falling from
	# it down to the grass.
	if _rain:
		var rain_ok := _fit(_rain_cloud, SkyCatalog.RAIN_CLOUDS[_rain_cloud_index], RAIN_CLOUD_TARGET_H)
		if rain_ok:
			_rain_cloud.position = Vector2(
				lerpf(_band.position.x, _band.end.x - _rain_cloud.size.x, _rain_cloud_x_frac),
				_band.position.y + _band.size.y * 0.1
			)
			_rain_cloud.visible = true
		else:
			_rain_cloud.visible = false
	else:
		_rain_cloud.visible = false


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
