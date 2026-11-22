## The Golden Hour boss backdrop composed from its layered art. The ray wheels
## turn slowly around the ray pivot, faded by the screen-space mask, under the sun.
class_name GoldenHourBackdrop
extends Control

const SPEC_PATH := "res://assets/art/environment/golden_hour/golden_hour_layers.json"

## The layer names golden_hour_layers.json draws, mapped to their art.
const LAYER_PATHS := {
	"sky_base": "res://assets/art/environment/golden_hour/golden_hour_sky_base.png",
	"rays_shadow_wheel": "res://assets/art/environment/golden_hour/golden_hour_rays_shadow_wheel_2600.png",
	"rays_wheel": "res://assets/art/environment/golden_hour/golden_hour_rays_wheel_2600.png",
	"rays_fade_mask": "res://assets/art/environment/golden_hour/golden_hour_rays_fade_mask.png",
	"foreground": "res://assets/art/environment/golden_hour/golden_hour_foreground.png",
	"sun_shadow": "res://assets/art/environment/golden_hour/golden_hour_sun_shadow.png",
	"sun_sprite": "res://assets/art/environment/golden_hour/golden_hour_sun_sprite.png",
}

## Every wheel pixel times the fade mask, sampled in canvas (frame) space.
## The wheel's canvas transform arrives as uniforms, so the shader needs no
## built-ins and reads the same on the Compatibility and dummy renderers.
const _MASK_SHADER := """
shader_type canvas_item;

uniform sampler2D fade_mask : filter_linear;
uniform vec2 frame_origin = vec2(0.0, 0.0);
uniform vec2 frame_size = vec2(1280.0, 720.0);
uniform vec2 wheel_origin = vec2(249.0, 116.0);
uniform float wheel_angle = 0.0;
uniform float wheel_scale = 1.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float s = sin(wheel_angle);
	float c = cos(wheel_angle);
	vec2 p = VERTEX * wheel_scale;
	vec2 canvas_pos = wheel_origin + vec2(p.x * c - p.y * s, p.x * s + p.y * c);
	vec2 mask_uv = clamp((canvas_pos - frame_origin) / frame_size, vec2(0.0), vec2(1.0));
	base.a *= texture(fade_mask, mask_uv).r;
	COLOR = base;
}
"""

## Screen-space nudge of the shadow wheel, from golden_hour_layers.json draw_order.
const _SHADOW_OFFSET := Vector2(6.0, 10.0)

var _canvas := Vector2(1280.0, 720.0)
var _ray_pivot := Vector2(249.0, 116.0)
var _sun_topleft := Vector2(187.0, 14.0)
## Spec-driven turn rate; the shipped art spins at 1.25 degrees a second.
var _rotation_rate := 1.25
var _spin := 0.0
var _rays: Sprite2D
var _rays_shadow: Sprite2D
var _sun: Sprite2D
var _rays_material: ShaderMaterial
var _shadow_material: ShaderMaterial


## Builds the composition over its parent and returns it. Free the node to undo.
static func compose(parent: Node) -> GoldenHourBackdrop:
	var layer := GoldenHourBackdrop.new()
	layer.name = "GoldenHour"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(layer)
	return layer


func _ready() -> void:
	if not _read_spec():
		return
	_add_fullframe("sky_base")
	_rays_shadow = _add_wheel("rays_shadow_wheel")
	_rays = _add_wheel("rays_wheel")
	_add_fullframe("foreground")
	_add_fullframe("sun_shadow")
	var sun := load(LAYER_PATHS["sun_sprite"]) as Texture2D
	if sun == null:
		push_error("Golden Hour is missing its sun sprite.")
		return
	_sun = Sprite2D.new()
	_sun.name = "sun_sprite"
	_sun.texture = sun
	_sun.centered = true
	add_child(_sun)
	_layout()
	resized.connect(_layout)


func _process(delta: float) -> void:
	_spin += deg_to_rad(_rotation_rate) * delta
	if _rays != null:
		_rays.rotation = _spin
	if _rays_shadow != null:
		_rays_shadow.rotation = _spin
	if _rays_material != null:
		_rays_material.set_shader_parameter("wheel_angle", _spin)
	if _shadow_material != null:
		_shadow_material.set_shader_parameter("wheel_angle", _spin)


func _read_spec() -> bool:
	var text := FileAccess.get_file_as_string(SPEC_PATH)
	var spec: Variant = JSON.parse_string(text)
	if spec == null or not spec is Dictionary:
		push_error("Golden Hour layer spec did not parse: %s" % SPEC_PATH)
		return false
	_canvas = Vector2(spec["canvas"][0], spec["canvas"][1])
	_ray_pivot = Vector2(spec["ray_pivot_px"][0], spec["ray_pivot_px"][1])
	_sun_topleft = Vector2(spec["sun_sprite_topleft"][0], spec["sun_sprite_topleft"][1])
	_rotation_rate = float(spec["rotation_deg_per_s"])
	return true


func _add_fullframe(key: String) -> void:
	var texture := load(LAYER_PATHS[key]) as Texture2D
	if texture == null:
		push_error("Golden Hour is missing layer %s." % key)
		return
	var rect := TextureRect.new()
	rect.name = key
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(rect)


func _add_wheel(key: String) -> Sprite2D:
	var texture := load(LAYER_PATHS[key]) as Texture2D
	if texture == null:
		push_error("Golden Hour is missing layer %s." % key)
		return null
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = _MASK_SHADER
	material.shader = shader
	material.set_shader_parameter("fade_mask", load(LAYER_PATHS["rays_fade_mask"]))
	if key == "rays_shadow_wheel":
		_shadow_material = material
	else:
		_rays_material = material
	var wheel := Sprite2D.new()
	wheel.name = key
	wheel.texture = texture
	wheel.centered = true
	wheel.material = material
	add_child(wheel)
	return wheel


## Maps the 1280x720 design frame onto the live rect the way the Background
## texture does (cover and centre), then hangs every layer off that frame.
func _layout() -> void:
	if size.x < 8.0 or size.y < 8.0:
		return
	var scale := maxf(size.x / _canvas.x, size.y / _canvas.y)
	var offset := (size - _canvas * scale) * 0.5
	if _rays != null:
		_rays.position = offset + _ray_pivot * scale
		_rays.scale = Vector2(scale, scale)
	if _rays_shadow != null:
		_rays_shadow.position = offset + (_ray_pivot + _SHADOW_OFFSET) * scale
		_rays_shadow.scale = Vector2(scale, scale)
	if _sun != null:
		var half := (_sun.texture.get_size() * 0.5)
		_sun.position = offset + (_sun_topleft + half) * scale
		_sun.scale = Vector2(scale, scale)
	_feed_mask_uniforms(_rays_material, _rays, offset, scale)
	_feed_mask_uniforms(_shadow_material, _rays_shadow, offset, scale)


## Tells a wheel shader where the design frame and the wheel itself live.
## frame_size is the design frame scaled, not the Control's size: under the
## expand aspect stretch a non-16:9 window makes those differ, and the mask
## must map the 1280x720 design frame exactly as _layout maps its layers.
func _feed_mask_uniforms(material: ShaderMaterial, wheel: Sprite2D, offset: Vector2, scale: float) -> void:
	if material == null or wheel == null:
		return
	material.set_shader_parameter("frame_origin", offset)
	material.set_shader_parameter("frame_size", _canvas * scale)
	material.set_shader_parameter("wheel_origin", wheel.position)
	material.set_shader_parameter("wheel_scale", scale)
