## The stage's six layer slots (GW-AA pass 4), built as siblings inside the
## 1280x720 Stage control, back to front:
##
##   SkyBackdrop   (sky_backdrop)  holds the look's backdrop TextureRect, and
##                                 the composed Golden Hour sky when it is on
##   SkyProps      (sky_props)     holds the SkyLayer: clouds, rain cloud, sun
##   FenceLayer    (fence_layer)   fence + sunflowers + grass strip plate
##   ShackLayer    (shack_layer)   porch plate, left
##   CompostLayer  (compost_layer) heap plate + CompostEyes overlay, right
##   LawnLayer     (lawn_layer)    lawn ground plate; the Lawn (felt, units)
##                                 draws right after it
##
## Every slot is in stage pixels, so a look switch only swaps the sky backdrop
## and the sky props' mood; the set plates stay put and only take the look's
## light (tint). A slot whose art is missing simply draws nothing.
class_name StageLayers
extends RefCounted

const SLOT_NAMES: Array[String] = [
	"SkyBackdrop", "SkyProps", "FenceLayer", "ShackLayer", "CompostLayer", "LawnLayer",
]
## The eyes breathe slowly so the heap reads alive (brightness swing, period).
const EYES_PULSE := 0.16
const EYES_PERIOD := 2.6

var sky_backdrop: Control
var sky_props: Control
var fence_layer: TextureRect
var shack_layer: TextureRect
var compost_layer: Control
var compost_pile: TextureRect
var compost_eyes: TextureRect
var lawn_layer: TextureRect
var _time := 0.0
var _own := {}
## The look's string lights over its fence (stage/<mood>/stage_fence_lights.png,
## Asset Gen batch 1 for Dusk: bulbs, wire and glow on the fence canvas).
## Added on top (additive blend), untinted so the bulbs still glow when the
## night light dims the fence, with a slow overall shimmer: two incommensurate
## waves, so it never reads as a metronome. Presentation only.
var fence_lights: TextureRect
const LIGHTS_BASE := 0.42
const LIGHTS_SHIMMER := 0.16
const LIGHTS_PERIOD := 3.1
const LIGHTS_PERIOD_B := 1.37
## Subtle felt props (Asset Gen extras) dressing the grass around the felt,
## never on a cell: [file, stage position of the prop's bottom centre, height].
const PROP_DIR := "res://assets/art/environment/props/"
const DECOR := [
	["prop_grass_tuft_2.png", Vector2(62.0, 476.0), 30.0],
	["prop_flower_yellow.png", Vector2(38.0, 540.0), 20.0],
	["prop_pebble_tan.png", Vector2(70.0, 420.0), 12.0],
	["prop_grass_tuft_1.png", Vector2(1214.0, 470.0), 28.0],
	["prop_flower_white.png", Vector2(1246.0, 548.0), 19.0],
	["prop_pebble_slate.png", Vector2(1200.0, 420.0), 11.0],
	["prop_grass_tuft_3.png", Vector2(24.0, 650.0), 30.0],
	["prop_pebble_grey.png", Vector2(1258.0, 640.0), 12.0],
]
var decor: Array[TextureRect] = []


## Builds the slots inside [param stage], moving [param background] into the
## sky backdrop slot, and leaves [param lawn] directly after the lawn slot.
func build(stage: Control, background: TextureRect, lawn: Control) -> void:
	sky_backdrop = _holder("SkyBackdrop")
	stage.add_child(sky_backdrop)
	stage.move_child(sky_backdrop, 0)
	background.reparent(sky_backdrop, false)
	sky_props = _holder("SkyProps")
	stage.add_child(sky_props)
	fence_layer = _plate("FenceLayer", BackdropCatalog.FENCE_PLATE)
	stage.add_child(fence_layer)
	fence_lights = TextureRect.new()
	fence_lights.name = "FenceLights"
	fence_lights.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fence_lights.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fence_lights.stretch_mode = TextureRect.STRETCH_SCALE
	fence_lights.visible = false
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fence_lights.material = add
	fence_layer.add_child(fence_lights)
	shack_layer = _plate("ShackLayer", BackdropCatalog.SHACK_PLATE)
	stage.add_child(shack_layer)
	compost_layer = _holder("CompostLayer")
	stage.add_child(compost_layer)
	compost_pile = _plate("CompostPile", BackdropCatalog.COMPOST_PLATE)
	compost_layer.add_child(compost_pile)
	compost_eyes = _plate("CompostEyes", BackdropCatalog.COMPOST_EYES)
	compost_layer.add_child(compost_eyes)
	lawn_layer = _plate("LawnLayer", BackdropCatalog.LAWN_GROUND_PLATE)
	stage.add_child(lawn_layer)
	_build_decor()
	# Slots in order, then the lawn (felt and units) on top of them all.
	var order: Array[Node] = [sky_backdrop, sky_props, fence_layer, shack_layer, compost_layer, lawn_layer]
	for i in order.size():
		stage.move_child(order[i], i)
	stage.move_child(lawn, order.size())


## Applies a look: its own plates where it has them (per-mood plate map,
## GW-AA pass 5), the shared plates elsewhere, and its light. [param look]
## is a BackdropCatalog index, or -1 for Golden Hour.
func apply_look(look: int) -> void:
	var tint := BackdropCatalog.set_tint(look)
	var own_tint := BackdropCatalog.backdrop_tint(look)
	var plates := {"fence": fence_layer, "shack": shack_layer, "compost": compost_pile, "lawn_ground": lawn_layer}
	_own.clear()
	for slot in BackdropCatalog.PLATE_SLOTS:
		var plate: TextureRect = plates[slot]
		if plate == null:
			continue
		var spec := BackdropCatalog.plate_for(look, slot)
		var texture: Texture2D = spec["texture"]
		plate.texture = texture
		plate.position = spec["offset"]
		if texture != null:
			plate.size = texture.get_size()
		plate.visible = texture != null
		plate.self_modulate = own_tint if bool(spec["own"]) else tint
		_own[slot] = String(spec["path"]) if bool(spec["own"]) else ""
	if compost_eyes != null:
		compost_eyes.visible = compost_eyes.texture != null and BackdropCatalog.eyes_on(look)
	for prop in decor:
		prop.self_modulate = tint
	if fence_lights != null:
		var lights := BackdropCatalog.fence_lights(look)
		fence_lights.texture = lights
		fence_lights.visible = lights != null and fence_layer.visible
		if lights != null:
			fence_lights.position = Vector2.ZERO
			fence_lights.size = lights.get_size()


## The props sit in the lawn slot (under the felt, which draws after it).
func _build_decor() -> void:
	for entry in DECOR:
		var texture := BackdropCatalog.optional(PROP_DIR + String(entry[0]))
		if texture == null:
			continue
		var rect := TextureRect.new()
		rect.name = "Decor_" + String(entry[0]).get_basename()
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		var h: float = entry[2]
		var w := h * texture.get_width() / maxf(texture.get_height(), 1.0)
		rect.texture = texture
		rect.size = Vector2(w, h)
		var foot: Vector2 = entry[1]
		rect.position = foot - Vector2(w * 0.5, h) - lawn_layer.position
		lawn_layer.add_child(rect)
		decor.append(rect)


## The string lights' strength right now (alpha of the additive layer).
func lights_level() -> float:
	var wave := 0.6 * sin(TAU * _time / LIGHTS_PERIOD) + 0.4 * sin(TAU * _time / LIGHTS_PERIOD_B + 1.1)
	return clampf(LIGHTS_BASE + LIGHTS_SHIMMER * wave, 0.0, 1.0)


## Which slots show the look's own plate (path) rather than the shared one.
func own_plates() -> Dictionary:
	return _own.duplicate()


## Breathes the compost eyes' glow (presentation only).
func tick(delta: float) -> void:
	_time += delta
	if compost_eyes != null and compost_eyes.visible:
		var glow := 1.0 + EYES_PULSE * (0.5 + 0.5 * sin(TAU * _time / EYES_PERIOD))
		compost_eyes.self_modulate = Color(glow, glow, glow, 1.0)
	if fence_lights != null and fence_lights.visible:
		fence_lights.self_modulate = Color(1.0, 1.0, 1.0, lights_level())


## The slot nodes in back-to-front order (for tests and docs).
func slots() -> Array[Node]:
	return [sky_backdrop, sky_props, fence_layer, shack_layer, compost_layer, lawn_layer]


func _holder(slot_name: String) -> Control:
	var holder := Control.new()
	holder.name = slot_name
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	return holder


func _plate(slot_name: String, spec: Dictionary) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = slot_name
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	var texture := BackdropCatalog.cached(String(spec["path"]))
	rect.texture = texture
	rect.position = spec["offset"]
	if texture != null:
		rect.size = texture.get_size()
	rect.visible = texture != null
	return rect
