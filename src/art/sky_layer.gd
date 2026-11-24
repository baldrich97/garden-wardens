## The drifting sky over the lawn band (GW-AW-6b): stick clouds, one sun
## per match, and rain when the seed says so. Every cloud hangs from a white
## stick that runs up off the top of the screen and bobs up and down with a
## slight tilt, as if a stagehand above the set were moving it along. Pure presentation: it never
## reads or changes match state, and every choice comes from SkyLook given
## the match seed, so a seeded match always shows the same sky.
class_name SkyLayer
extends Control

## Target heights, in screen pixels.
## Main's paper sun (GW-AA pass 4): the big layered Golden Hour sun, centred
## this far below the band's top, with its soft paper shadow nudged down-right.
const SUN_TARGET_H := 116.0
## The paper moon on both Dusk looks: height, where it hangs (share of the
## band's width, px below the band's top), and a slow sway.
const MOON_TARGET_H := 104.0
const MOON_X_FRAC := 0.27
const MOON_TOP := 10.0
const MOON_BOB_PX := 2.5
const MOON_BOB_PERIOD := 7.5
## Dusk Moonlit's stars: how many, the band share they fill, size, twinkle.
const STAR_COUNT := 24
const STAR_BAND_SHARE := 0.62
const STAR_SIZE_MIN := 1.6
const STAR_SIZE_MAX := 3.4
const STAR_COLOR := Color(1.0, 0.96, 0.8)
## Asset Gen's paper star sprites (batch2), used when installed: fewer and
## larger than the drawn ones, with a slow, gentle twinkle (alpha and a
## slight scale breath), kept clear of the moon.
const STAR_SPRITE_COUNT := 16
const STAR_SPRITE_H_MIN := 9.0
const STAR_SPRITE_H_MAX := 17.0
const STAR_TWINKLE_SPEED := 1.1
const STAR_MOON_CLEARANCE := 26.0
## No sprite stars over the porch (they would show through its opening).
const STAR_KEEP_OUT := Rect2(0.0, 0.0, 185.0, 380.0)
const SUN_CENTER_DROP := 40.0
const SUN_SHADOW_OFFSET := Vector2(7.0, 9.0)
## The rain cloud's body is sized like a large drifting cloud (same family);
## its baked strands hang below and tuck behind the fence layer.
const RAIN_CLOUD_BODY_TARGET := 60.0
## Falling rain is a quiet backdrop effect: small, see-through drops that land
## behind the fence (the sky props slot draws under the fence slot).
const DROP_TARGET_H := 8.0
const DROP_ALPHA := 0.55
const SPLASH_TARGET_H := 12.0
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
var _sun_shadow: TextureRect
var _moon: TextureRect
var _moon_rest := Vector2.ZERO
var _stars: Node2D
var _star_points: Array[Vector3] = []
var _star_phase: Array[float] = []
var _star_textures: Array[Texture2D] = []
var _star_kind: Array[int] = []
var _family := ""
var _tint := Color.WHITE
var _rain_cloud_path := ""
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
	_sun_shadow = _make_sprite()
	add_child(_sun_shadow)
	_sun = _make_sprite()
	add_child(_sun)
	_moon = _make_sprite()
	_moon.name = "Moon"
	add_child(_moon)
	_stars = Node2D.new()
	_stars.name = "Stars"
	_stars.visible = false
	_stars.draw.connect(_draw_stars)
	add_child(_stars)
	move_child(_stars, 0)
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
	_rain_stick.texture = BackdropCatalog.cached(RAIN_STICK_TEXTURE)
	_rain_stick.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rain_stick.stretch_mode = TextureRect.STRETCH_SCALE
	_rain_stick.visible = false
	add_child(_rain_stick)
	_rain_cloud = _make_sprite()
	add_child(_rain_cloud)
	for _i in DROP_POOL:
		var drop := _make_sprite()
		_fit(drop, SkyCatalog.RAIN_DROP, DROP_TARGET_H)
		drop.modulate = Color(0.92, 0.95, 1.0, DROP_ALPHA)
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
##
## [param rain_floor_y] (optional) is where rain lands when it should fall
## past the band (the Option B lawn's far edge); by default rain lands at the
## band's bottom edge.
func set_band(rect: Rect2, rain_floor_y: float = NAN) -> void:
	_band = rect
	_ground_y = (rect.position.y + rect.size.y if is_nan(rain_floor_y) else rain_floor_y) - 4.0
	_layout()


## Applies the seeded look for the current mood: which sun, whether it
## rains, and the cloud spec.
func apply_look(seed_value: int, mood_index: int) -> void:
	_seed = seed_value
	_mood = mood_index
	_sun_index = SkyLook.sun_index(_seed, SkyCatalog.SUNS.size())
	_sun_x_frac = SkyLook.sun_x_frac(_seed)
	_rain = SkyLook.rain_active(_seed, _mood)
	_rain_cloud_index = SkyLook.rain_cloud_index(_seed, SkyCatalog.OVERCAST_RAIN_CLOUDS.size())
	_rain_cloud_path = SkyCatalog.OVERCAST_RAIN_CLOUDS[_rain_cloud_index]
	_family = SkyLook.cloud_family(_mood)
	_tint = SkyLook.cloud_tint(_mood)
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
	if _moon.visible:
		_moon.position = _moon_rest + Vector2(0.0, MOON_BOB_PX * sin(TAU * _time / MOON_BOB_PERIOD))
		_moon.rotation = deg_to_rad(1.2) * sin(TAU * _time / (MOON_BOB_PERIOD * 1.4))
	if _stars.visible:
		_stars.queue_redraw()
	if _sun.visible:
		_sun.position = _sun_rest + Vector2(0.0, SUN_BOB_PX * sin(TAU * _time / SUN_BOB_PERIOD))
		_sun.rotation = deg_to_rad(SUN_TILT_DEG) * sin(TAU * _time / SUN_TILT_PERIOD)
		_pose_sun_shadow()
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
	_rain_stick.size = Vector2(RAIN_STICK_W, _rain_cloud.position.y + _rain_body_bottom() * 0.5 + STICK_OVERSHOOT)
	_rain_stick.position = Vector2(
		_rain_cloud.position.x + (_rain_cloud.size.x - RAIN_STICK_W) * 0.5,
		-STICK_OVERSHOOT
	)


## Where the rain cloud's body ends, in pixels below its top edge.
func _rain_body_bottom() -> float:
	if _rain_cloud.texture == null:
		return 0.0
	var tex_h := _rain_cloud.texture.get_size().y
	var body: float = SkyCatalog.RAIN_CLOUD_BODY_H.get(_rain_cloud_path, tex_h * 0.85)
	return _rain_cloud.size.y * minf(body / tex_h, 1.0)


## Whether the sun shows for the current mood.
func sun_visible() -> bool:
	return SkyLook.mood_shows_sun(_mood)


## The sun texture for this match, or null if none was assigned.
func sun_texture() -> Texture2D:
	return _sun.texture


## The cloud family the current mood draws ("cotton", "felt", or "" for none).
func cloud_family() -> String:
	return _family


## The tint laid over the current mood's clouds.
func cloud_tint() -> Color:
	return _tint


## Texture paths of the clouds showing right now.
func cloud_paths() -> Array[String]:
	var out: Array[String] = []
	for i in _cloud_specs.size():
		if _clouds[i].visible and _clouds[i].texture != null:
			out.append(_clouds[i].texture.resource_path)
	return out


## The rain cloud's sprite (hidden when it is not raining), for tests.
func rain_cloud() -> TextureRect:
	return _rain_cloud


## The rain cloud's on-screen body height (0 when hidden).
func rain_cloud_body_height() -> float:
	if not _rain_cloud.visible or _rain_cloud.texture == null:
		return 0.0
	var body: float = SkyCatalog.RAIN_CLOUD_BODY_H.get(_rain_cloud_path, _rain_cloud.texture.get_size().y)
	return body * _rain_cloud.size.y / _rain_cloud.texture.get_size().y


## The drop sprites' on-screen height, for tests.
func drop_height() -> float:
	return _drops[0].size.y if not _drops.is_empty() else 0.0


## The sun's on-screen height (0 when hidden).
func sun_height() -> float:
	return _sun.size.y if _sun.visible else 0.0


## Whether the sun has its paper drop shadow showing.
func sun_has_shadow() -> bool:
	return _sun.visible and _sun_shadow.visible and _sun_shadow.texture != null


## The moon's on-screen height (0 when hidden).
func moon_height() -> float:
	return _moon.size.y if _moon.visible else 0.0


## How many stars twinkle (Dusk Moonlit only).
func star_count() -> int:
	return _star_points.size() if _stars.visible else 0


## Scatters Moonlit's stars from a local generator (never the match seed's
## channels: the sky must not shift any rule roll).
func _layout_stars() -> void:
	_star_points.clear()
	_star_phase.clear()
	_stars.visible = _mood == SkyLook.MOOD_DUSK_MOONLIT
	if not _stars.visible:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("stars_%d" % _seed)
	_star_textures.clear()
	_star_kind.clear()
	for path in SkyCatalog.star_paths():
		var texture := BackdropCatalog.cached(path)
		if texture != null:
			_star_textures.append(texture)
	var sprites := not _star_textures.is_empty()
	var moon_rect := Rect2(_moon.position, _moon.size).grow(STAR_MOON_CLEARANCE) if _moon.visible else Rect2()
	var want := STAR_SPRITE_COUNT if sprites else STAR_COUNT
	var tries := 0
	while _star_points.size() < want and tries < want * 20:
		tries += 1
		var x := _band.position.x + rng.randf() * _band.size.x
		var y := _band.position.y + rng.randf() * _band.size.y * STAR_BAND_SHARE
		var size := rng.randf_range(STAR_SPRITE_H_MIN, STAR_SPRITE_H_MAX) if sprites else rng.randf_range(STAR_SIZE_MIN, STAR_SIZE_MAX)
		var phase := rng.randf() * TAU
		var kind := rng.randi_range(0, maxi(_star_textures.size(), 1) - 1)
		if sprites and (moon_rect.has_point(Vector2(x, y)) or STAR_KEEP_OUT.has_point(Vector2(x, y))):
			continue
		_star_points.append(Vector3(x, y, size))
		_star_phase.append(phase)
		_star_kind.append(kind)
	_stars.queue_redraw()


## Whether Moonlit's stars are Asset Gen's paper sprites (else drawn).
func stars_are_sprites() -> bool:
	return _stars.visible and not _star_textures.is_empty()


func _draw_stars() -> void:
	if not _star_textures.is_empty():
		for i in _star_points.size():
			var p := _star_points[i]
			var texture := _star_textures[_star_kind[i] % _star_textures.size()]
			var wave := sin(_time * STAR_TWINKLE_SPEED + _star_phase[i])
			var h := p.z * (1.0 + 0.06 * wave)
			var w := h * texture.get_width() / maxf(texture.get_height(), 1.0)
			_stars.draw_texture_rect(texture, Rect2(p.x - w * 0.5, p.y - h * 0.5, w, h), false, Color(1, 1, 1, 0.72 + 0.28 * wave))
		return
	for i in _star_points.size():
		var p := _star_points[i]
		var twinkle := 0.55 + 0.45 * sin(_time * 1.7 + _star_phase[i])
		var c := Color(STAR_COLOR, twinkle)
		var r := p.z
		var at := Vector2(p.x, p.y)
		# A little four-point paper star.
		_stars.draw_colored_polygon(PackedVector2Array([
			at + Vector2(0, -r * 1.6), at + Vector2(r * 0.4, -r * 0.4), at + Vector2(r * 1.6, 0), at + Vector2(r * 0.4, r * 0.4),
			at + Vector2(0, r * 1.6), at + Vector2(-r * 0.4, r * 0.4), at + Vector2(-r * 1.6, 0), at + Vector2(-r * 0.4, -r * 0.4),
		]), c)


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
	var tex := BackdropCatalog.cached(path)
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
		_sun_shadow.visible = false
	else:
		var sun_ok := _fit(_sun, SkyCatalog.MAIN_SUN, SUN_TARGET_H)
		if sun_ok:
			_sun_rest = Vector2(
				_band.position.x + _band.size.x * _sun_x_frac - _sun.size.x * 0.5,
				_band.position.y + SUN_CENTER_DROP - _sun.size.y * 0.5
			)
			_sun.position = _sun_rest
			_sun.pivot_offset = _sun.size * 0.5
			_sun.visible = true
			var sprite_size := _sun.texture.get_size()
			var shadow_ok := _fit(_sun_shadow, SkyCatalog.MAIN_SUN_SHADOW, SUN_TARGET_H * (sprite_size.y + 40.0) / sprite_size.y)
			_sun_shadow.visible = shadow_ok
			_pose_sun_shadow()
		else:
			_sun.visible = false
			_sun_shadow.visible = false
	# The paper moon hangs on both Dusk looks; Moonlit adds a few stars.
	if SkyLook.mood_shows_moon(_mood) and _fit(_moon, SkyCatalog.MOON, MOON_TARGET_H):
		_moon_rest = Vector2(_band.position.x + _band.size.x * MOON_X_FRAC - _moon.size.x * 0.5, _band.position.y + MOON_TOP)
		_moon.position = _moon_rest
		_moon.pivot_offset = _moon.size * 0.5
		_moon.visible = true
	else:
		_moon.visible = false
	_layout_stars()
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
		var entry: Dictionary = {}
		if not _family.is_empty():
			var choices := SkyCatalog.family_entries(spec["size"], _family, spec["stick"])
			if not choices.is_empty():
				entry = choices[int(spec["variant"]) % choices.size()]
		cloud.modulate = _tint
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
		var body_src: float = SkyCatalog.RAIN_CLOUD_BODY_H.get(_rain_cloud_path, 0.0)
		var rain_ok := _fit(_rain_cloud, _rain_cloud_path, RAIN_CLOUD_BODY_TARGET, body_src)
		if rain_ok:
			_rain_drift_x = lerpf(_band.position.x, _band.end.x - _rain_cloud.size.x, _rain_cloud_x_frac)
			_rain_rest_y = _band.position.y + _band.size.y * 0.02
			_rain_cloud.visible = true
			_rain_stick.visible = _rain_stick.texture != null
			_pose_rain_cloud()
		else:
			_rain_cloud.visible = false
			_rain_stick.visible = false
	else:
		_rain_cloud.visible = false
		_rain_stick.visible = false


func _pose_sun_shadow() -> void:
	if not _sun_shadow.visible or _sun.texture == null:
		return
	# The shadow PNG pads the sprite by 20 source px on every side.
	var pad := 20.0 * _sun.size.y / _sun.texture.get_size().y
	_sun_shadow.position = _sun.position - Vector2(pad, pad) + SUN_SHADOW_OFFSET
	_sun_shadow.pivot_offset = _sun_shadow.size * 0.5
	_sun_shadow.rotation = _sun.rotation


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
	# Drops leave the bottom of the cloud body (the baked strands hang lower).
	var spawn_y := _rain_cloud.position.y + _rain_body_bottom()
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
