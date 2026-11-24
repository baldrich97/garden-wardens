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
	# Slots in order, then the lawn (felt and units) on top of them all.
	var order: Array[Node] = [sky_backdrop, sky_props, fence_layer, shack_layer, compost_layer, lawn_layer]
	for i in order.size():
		stage.move_child(order[i], i)
	stage.move_child(lawn, order.size())


## Applies a look's light: [param look] is a BackdropCatalog index, or -1 for
## Golden Hour.
func apply_look(look: int) -> void:
	var tint := BackdropCatalog.set_tint(look)
	for plate in [fence_layer, shack_layer, compost_pile, lawn_layer]:
		if plate != null:
			plate.self_modulate = tint
	if compost_eyes != null:
		compost_eyes.visible = compost_eyes.texture != null and BackdropCatalog.eyes_on(look)


## Breathes the compost eyes' glow (presentation only).
func tick(delta: float) -> void:
	_time += delta
	if compost_eyes != null and compost_eyes.visible:
		var glow := 1.0 + EYES_PULSE * (0.5 + 0.5 * sin(TAU * _time / EYES_PERIOD))
		compost_eyes.self_modulate = Color(glow, glow, glow, 1.0)


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
