## Named SpriteFrames for the demo units. The match and the preview both use these.
class_name UnitClips
extends RefCounted

const BUSH: Texture2D = preload("res://assets/sprites/wardens/bush.png")
const CACTUS: Texture2D = preload("res://assets/sprites/wardens/cactus.png")
const BARK: Texture2D = preload("res://assets/sprites/wardens/bark_block.png")
const FLY_REST: Texture2D = preload("res://assets/sprites/vermin/fly_rest.png")
const FLY_A: Texture2D = preload("res://assets/sprites/vermin/fly_a.png")
const FLY_B: Texture2D = preload("res://assets/sprites/vermin/fly_b.png")
const BEE_REST: Texture2D = preload("res://assets/sprites/vermin/bee_rest.png")
const BEE_A: Texture2D = preload("res://assets/sprites/vermin/bee_a.png")
const BEE_B: Texture2D = preload("res://assets/sprites/vermin/bee_b.png")
const LADYBUG_REST: Texture2D = preload("res://assets/sprites/vermin/ladybug_rest.png")
const LADYBUG_A: Texture2D = preload("res://assets/sprites/vermin/ladybug_walk_a.png")
const LADYBUG_B: Texture2D = preload("res://assets/sprites/vermin/ladybug_walk_b.png")
const SNAIL_REST: Texture2D = preload("res://assets/sprites/vermin/snail_rest.png")
const SNAIL_A: Texture2D = preload("res://assets/sprites/vermin/snail_walk_a.png")
const SNAIL_B: Texture2D = preload("res://assets/sprites/vermin/snail_walk_b.png")
const GRUB_REST: Texture2D = preload("res://assets/sprites/vermin/grub_rest.png")
const GRUB_A: Texture2D = preload("res://assets/sprites/vermin/grub_a.png")
const GRUB_B: Texture2D = preload("res://assets/sprites/vermin/grub_b.png")

static var _wardens: Array[SpriteFrames] = []
static var _vermin: Array[SpriteFrames] = []


static func warden(kind: UnitCatalog.Warden) -> SpriteFrames:
	_ensure_wardens()
	return _wardens[kind]


static func vermin(kind: UnitCatalog.Vermin) -> SpriteFrames:
	_ensure_vermin()
	return _vermin[kind]


static func warden_animations(kind: UnitCatalog.Warden) -> PackedStringArray:
	if kind == UnitCatalog.Warden.BARK or kind == UnitCatalog.Warden.RAIN:
		return PackedStringArray(["idle", "hurt"])
	if kind == UnitCatalog.Warden.DEW:
		return PackedStringArray(["idle", "produce", "hurt"])
	return PackedStringArray(["idle", "attack", "hurt"])


## Rain Catcher and Seed Lobber have no drawing yet, so the lawn labels them.
static func needs_label(kind: UnitCatalog.Warden) -> bool:
	return kind == UnitCatalog.Warden.RAIN or kind == UnitCatalog.Warden.SEED


static func vermin_animations() -> PackedStringArray:
	return PackedStringArray(["idle", "walk", "chew", "hurt"])


static func portrait(frames: SpriteFrames) -> Texture2D:
	return frames.get_frame_texture("idle", 0)


static func _ensure_wardens() -> void:
	if not _wardens.is_empty():
		return
	_wardens = [
		_make([
			["idle", [BUSH], 4.0],
			["produce", [BUSH], 4.0],
			["hurt", [BUSH], 4.0],
		]),
		_make([
			["idle", [CACTUS], 4.0],
			["attack", [CACTUS], 4.0],
			["hurt", [CACTUS], 4.0],
		]),
		_make([
			["idle", [BARK], 4.0],
			["hurt", [BARK], 4.0],
		]),
		_make([
			["idle", [_swatch(Color("3a7ca5"))], 4.0],
			["hurt", [_swatch(Color("3a7ca5"))], 4.0],
		]),
		_make([
			["idle", [_swatch(Color("c9842a"))], 4.0],
			["attack", [_swatch(Color("e0a106"))], 4.0],
			["hurt", [_swatch(Color("c9842a"))], 4.0],
		]),
	]


static func _ensure_vermin() -> void:
	if not _vermin.is_empty():
		return
	_vermin = [
		_make([
			["idle", [FLY_REST], 4.0],
			["walk", [FLY_A, FLY_B], 8.0],
			["chew", [FLY_REST], 4.0],
			["hurt", [FLY_REST], 4.0],
		]),
		_make([
			["idle", [BEE_REST], 4.0],
			["walk", [BEE_A, BEE_B], 8.0],
			["chew", [BEE_REST], 4.0],
			["hurt", [BEE_REST], 4.0],
		]),
		_make([
			["idle", [LADYBUG_REST], 4.0],
			["walk", [LADYBUG_A, LADYBUG_B], 8.0],
			["chew", [LADYBUG_REST], 4.0],
			["hurt", [LADYBUG_REST], 4.0],
		]),
		_make([
			["idle", [SNAIL_REST], 4.0],
			["walk", [SNAIL_A, SNAIL_B], 8.0],
			["chew", [SNAIL_REST], 4.0],
			["hurt", [SNAIL_REST], 4.0],
		]),
		_make([
			["idle", [GRUB_REST], 4.0],
			["walk", [GRUB_A, GRUB_B], 8.0],
			["chew", [GRUB_REST], 4.0],
			["hurt", [GRUB_REST], 4.0],
		]),
	]


static func _swatch(fill: Color) -> Texture2D:
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(fill)
	var ink := Color("243028")
	for i in 128:
		for thickness in 8:
			image.set_pixel(i, thickness, ink)
			image.set_pixel(i, 127 - thickness, ink)
			image.set_pixel(thickness, i, ink)
			image.set_pixel(127 - thickness, i, ink)
	return ImageTexture.create_from_image(image)


static func _make(specs: Array) -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	for spec in specs:
		var anim_name: String = spec[0]
		var textures: Array = spec[1]
		var fps: float = spec[2]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, fps)
		frames.set_animation_loop(anim_name, true)
		for texture in textures:
			frames.add_frame(anim_name, texture)
	return frames
