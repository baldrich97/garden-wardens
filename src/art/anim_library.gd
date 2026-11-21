## Engine-ready SpriteFrames built from each unit's frames.json manifest
## (assets/sprites/anim/...). Clips are built lazily per unit folder and cached,
## so the ~1,900 animation PNGs never load at startup.
##
## Every animation ships per damage state, so a clip holds one animation named
## `<anim>_<state>` (for example `move_66`) for each state the manifest carries.
## The cast anims (idle/move/action/hurt) carry all three states; `place` ships
## only `100` and `death` only `33`, so state variants are a subset, never all
## three by assumption. The three states are authored index-for-index: frame N
## of `idle_100` and frame N of `idle_66` are the same beat of the animation, so
## a mid-animation damage swap can keep the current frame. The swap path is:
## `state_for_hp(hp_ratio)` -> `animation_name(frames, anim, state)` ->
## `swap_keep_frame(sprite, name)`.
##
## When a unit folder or its frames.json is missing or malformed, `warden()` and
## `vermin()` fall back to the legacy hand-built UnitClips instead of crashing.
## Legacy clips use bare animation names (`idle`, not `idle_100`);
## `animation_name()` accounts for that.
class_name AnimLibrary
extends RefCounted

const ROOT := "res://assets/sprites/anim"
## Damage-state keys, best first. `animation_name()` falls back along this order.
const DAMAGE_STATES: Array[String] = ["100", "66", "33"]
## Index-aligned with UnitCatalog.Warden.
const WARDEN_FOLDERS: Array[String] = [
	ROOT + "/wardens/dew_dropper",
	ROOT + "/wardens/needle_spitter",
	ROOT + "/wardens/stubborn_cone",
	ROOT + "/wardens/rain_catcher",
	ROOT + "/wardens/seed_lobber",
]
## Index-aligned with UnitCatalog.Vermin.
const VERMIN_FOLDERS: Array[String] = [
	ROOT + "/vermin/fly",
	ROOT + "/vermin/bee",
	ROOT + "/vermin/ladybug",
	ROOT + "/vermin/snail",
	ROOT + "/vermin/grub",
]
const POOF_FOLDER := ROOT + "/fx/poof"
const POOF_ANIM := "poof"

static var _manifests: Dictionary = {}
static var _clips: Dictionary = {}
static var _poof: SpriteFrames = null
static var _poof_pivot := Vector2.INF


## Folder holding the frames.json for one warden kind.
static func warden_folder(kind: UnitCatalog.Warden) -> String:
	return WARDEN_FOLDERS[kind]


## Folder holding the frames.json for one vermin kind.
static func vermin_folder(kind: UnitCatalog.Vermin) -> String:
	return VERMIN_FOLDERS[kind]


## Clips for a warden; falls back to UnitClips.warden() when the manifest is
## missing or malformed. Never returns null.
static func warden(kind: UnitCatalog.Warden) -> SpriteFrames:
	var frames := clip_for_folder(warden_folder(kind))
	if frames == null:
		return UnitClips.warden(kind)
	return frames


## Clips for a vermin; falls back to UnitClips.vermin() when the manifest is
## missing or malformed. Never returns null.
static func vermin(kind: UnitCatalog.Vermin) -> SpriteFrames:
	var frames := clip_for_folder(vermin_folder(kind))
	if frames == null:
		return UnitClips.vermin(kind)
	return frames


## Cached SpriteFrames for one unit folder, built on first call. Returns null
## when the folder or its frames.json is missing or malformed (callers that can
## tolerate it should go through warden()/vermin() for the legacy fallback).
static func clip_for_folder(folder: String) -> SpriteFrames:
	if _clips.has(folder):
		return _clips[folder]
	var frames := _build_clip(folder)
	_clips[folder] = frames
	return frames


## Cached parsed frames.json for one folder (unit or fx). Empty Dictionary
## means the manifest is missing or unparsable. Raw keys worth knowing:
## `fps`, `canvas_px`, `anchor`, `damage`, `faces`, `notes`, `animations`
## (units) or `frames`/`pivot_px` (fx).
static func manifest_for_folder(folder: String) -> Dictionary:
	if not _manifests.has(folder):
		var manifest: Variant = {}
		var manifest_path := folder + "/frames.json"
		if FileAccess.file_exists(manifest_path):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
			if parsed is Dictionary:
				manifest = parsed
		_manifests[folder] = manifest
	return _manifests[folder]


## Feet/ground point in canvas pixels from `anchor.ground_point_px`, for
## aligning tall canvas art on a tile. Returns Vector2.INF when the manifest
## has no ground point.
static func ground_point_px(folder: String) -> Vector2:
	var anchor: Variant = manifest_for_folder(folder).get("anchor")
	if anchor is Dictionary:
		return _vec2_from(anchor.get("ground_point_px"))
	return Vector2.INF


## Drawing canvas size in pixels from `canvas_px`. Vector2.INF when absent.
static func canvas_px(folder: String) -> Vector2:
	return _vec2_from(manifest_for_folder(folder).get("canvas_px"))


## Damage-state key for a current/max health ratio.
static func state_for_hp(hp_ratio: float) -> String:
	if hp_ratio > 0.66:
		return "100"
	if hp_ratio > 0.33:
		return "66"
	return "33"


## Name of the `<anim>_<state>` animation to play, with fallbacks so callers
## never need to know which states shipped: an anim without that state falls
## back along DAMAGE_STATES (so `death` at any state lands on `death_33`), and
## legacy UnitClips names without a state suffix are matched bare. Empty string
## means the clip has nothing usable.
static func animation_name(frames: SpriteFrames, anim: String, state: String) -> String:
	if frames == null:
		return ""
	var exact := anim + "_" + state
	if frames.has_animation(exact):
		return exact
	for fallback_state in DAMAGE_STATES:
		var fallback := anim + "_" + fallback_state
		if frames.has_animation(fallback):
			return fallback
	if frames.has_animation(anim):
		return anim
	return ""


## Switches a sprite to `new_animation` keeping the current frame index and the
## progress made inside that frame. The damage states are authored
## index-for-index, so swapping `idle_100` -> `idle_66` mid-cycle shows the same
## beat in the damaged art with no visible hitch. The index is clamped when the
## new animation is shorter (for example swapping into a 5-frame `hurt`).
## Returns false, leaving the sprite untouched, when the animation does not
## exist. A stopped sprite just switches animation in place (Godot's stop()
## resets its frame to 0, so there is no kept frame there) and never starts
## playback.
static func swap_keep_frame(sprite: AnimatedSprite2D, new_animation: String) -> bool:
	var frames := sprite.sprite_frames
	if frames == null or new_animation.is_empty() or not frames.has_animation(new_animation):
		return false
	var keep_index := sprite.frame
	var keep_progress := sprite.frame_progress
	var was_playing := sprite.is_playing()
	if was_playing:
		sprite.play(new_animation)
	else:
		sprite.animation = new_animation
	if keep_index >= 0:
		sprite.frame = clampi(keep_index, 0, frames.get_frame_count(new_animation) - 1)
		sprite.frame_progress = keep_progress
	return true


## Death poof clips built from fx/poof/frames.json (one animation, POOF_ANIM).
## Returns null if the fx manifest is missing or malformed.
static func poof() -> SpriteFrames:
	if _poof != null:
		return _poof
	var manifest := manifest_for_folder(POOF_FOLDER)
	var paths: Variant = manifest.get("frames")
	var durations: Variant = manifest.get("durations_ms")
	if not (paths is Array) or paths.is_empty() or not _durations_ok(durations, paths.size()):
		return null
	var frames := _new_frames()
	frames.add_animation(POOF_ANIM)
	frames.set_animation_speed(POOF_ANIM, 1.0)
	frames.set_animation_loop(POOF_ANIM, bool(manifest.get("loop", false)))
	if not _add_frames(frames, POOF_ANIM, POOF_FOLDER, paths, durations):
		return null
	var pivot: Variant = manifest.get("pivot_px")
	if pivot is Array and pivot.size() == 2:
		_poof_pivot = Vector2(float(pivot[0]), float(pivot[1]))
	_poof = frames
	return frames


## Poof pivot in frame pixels from `pivot_px` (the puff centre the death hands
## off on). Vector2.INF until poof() has loaded a valid manifest.
static func poof_pivot() -> Vector2:
	if _poof_pivot == Vector2.INF and _poof == null:
		poof()
	return _poof_pivot


static func _build_clip(folder: String) -> SpriteFrames:
	var manifest := manifest_for_folder(folder)
	var animations: Variant = manifest.get("animations")
	if not (animations is Dictionary) or animations.is_empty():
		return null
	var frames := _new_frames()
	for anim_name in animations:
		if not (animations[anim_name] is Dictionary):
			return null
		var anim: Dictionary = animations[anim_name]
		# Godot's JSON parser types integral-looking numbers as floats.
		var frame_count: Variant = anim.get("frame_count")
		if not (frame_count is int or frame_count is float) or int(frame_count) < 1:
			return null
		var durations: Variant = anim.get("durations_ms")
		if not _durations_ok(durations, int(frame_count)):
			return null
		var states: Variant = anim.get("states")
		if not (states is Dictionary) or states.is_empty():
			return null
		for state_key in states:
			var state_dict: Variant = states[state_key]
			var paths: Variant = state_dict.get("frames") if state_dict is Dictionary else null
			if not (paths is Array) or paths.size() != int(frame_count):
				return null
			var clip_name := "%s_%s" % [anim_name, state_key]
			frames.add_animation(clip_name)
			# Speed 1.0 keeps each authored per-frame duration in seconds honest.
			frames.set_animation_speed(clip_name, 1.0)
			frames.set_animation_loop(clip_name, bool(anim.get("loop", true)))
			if not _add_frames(frames, clip_name, folder, paths, durations):
				return null
	return frames


static func _add_frames(frames: SpriteFrames, clip_name: String, folder: String, paths: Array, durations: Array) -> bool:
	for index in paths.size():
		var path := folder + "/" + String(paths[index])
		if not ResourceLoader.exists(path):
			return false
		var texture := load(path) as Texture2D
		if texture == null:
			return false
		frames.add_frame(clip_name, texture, float(durations[index]) / 1000.0)
	return true


static func _durations_ok(durations: Variant, frame_count: int) -> bool:
	if not (durations is Array) or durations.size() != frame_count:
		return false
	for duration in durations:
		if not (duration is int or duration is float) or float(duration) <= 0.0:
			return false
	return true


static func _new_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	return frames


static func _vec2_from(value: Variant) -> Vector2:
	if value is Array and value.size() == 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.INF
