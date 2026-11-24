// Draws the locked felt board (board_v1_compost_eyes.png) through the lawn's
// projective homography (GW-AA pass 3, Option B). Each fragment maps its stage
// pixel back to the source PNG with the exact inverse homography, so felt
// lines stay straight and crisp with no affine (per-triangle) distortion.
// Four sub-pixel taps antialias the frame edge and the minified far rows.
shader_type canvas_item;

uniform mat3 stage_to_source;
uniform vec2 stage_size = vec2(1280.0, 720.0);
uniform vec4 frame_src = vec4(149.0, 334.0, 1104.0, 688.0);
uniform vec2 texture_px = vec2(1280.0, 720.0);
// The felt PNG (same as the TextureRect's texture; sampled by hand here).
uniform sampler2D felt : filter_linear, repeat_disable;

// The node's modulate (vertex colour) only. In fragment(), COLOR already
// holds the node's own TEXTURE sampled flat at UV; multiplying by it laid the
// unwarped felt grid over the warped one (the pass 3 "double grid" bug).
varying vec4 modulate_color;

void vertex() {
	modulate_color = COLOR;
}

vec4 felt_at(vec2 p) {
	vec3 s = stage_to_source * vec3(p, 1.0);
	vec2 src = s.xy / s.z;
	if (src.x < frame_src.x || src.y < frame_src.y || src.x > frame_src.z || src.y > frame_src.w) {
		return vec4(0.0);
	}
	return textureLod(felt, src / texture_px, 0.0);
}

void fragment() {
	vec2 p = UV * stage_size;
	vec2 ex = dFdx(p);
	vec2 ey = dFdy(p);
	vec4 c = felt_at(p + ex * -0.375 + ey * -0.125)
		+ felt_at(p + ex * 0.125 + ey * -0.375)
		+ felt_at(p + ex * 0.375 + ey * 0.125)
		+ felt_at(p + ex * -0.125 + ey * 0.375);
	COLOR = c * 0.25 * modulate_color;
}
