// Draws the felt board through the lawn's projective homography (GW-AA pass 3,
// Option B; cleaned up in pass 4). Each fragment maps its stage pixel back to
// board-composite pixels with the exact inverse homography, so felt lines stay
// straight with no per-triangle distortion.
//
// Pass 4 ("felt looks patchy/pixelated on Main"): the felt now samples a
// cleaned 2x texture (felt_board_clean.png: fibre noise smoothed, seams
// re-sharpened, even felt grain) with mipmaps and trilinear filtering, so the
// near rows magnify smoothly and the far rows minify without shimmer. Four
// rotated-grid taps still antialias, and the board's outline is feathered by
// about one stage pixel so it sits on the lawn instead of looking pasted on.
shader_type canvas_item;

uniform mat3 stage_to_source;
uniform vec2 stage_size = vec2(1280.0, 720.0);
// The board frame in board-composite pixels (x0, y0, x1, y1).
uniform vec4 frame_src = vec4(149.0, 334.0, 1104.0, 688.0);
// Where the felt texture's top-left sits in board-composite pixels, and how
// many felt texels one composite pixel spans.
uniform vec2 felt_origin = vec2(145.0, 330.0);
uniform float felt_scale = 2.0;
uniform vec2 texture_px = vec2(1926.0, 724.0);
// Edge feather width, in composite pixels.
uniform float feather_px = 1.1;
uniform sampler2D felt : filter_linear_mipmap, repeat_disable;

// The node's modulate (vertex colour) only. In fragment(), COLOR already
// holds the node's own TEXTURE sampled flat at UV; multiplying by it laid the
// unwarped felt grid over the warped one (the pass 3 "double grid" bug).
varying vec4 modulate_color;

void vertex() {
	modulate_color = COLOR;
}

vec2 source_of(vec2 p) {
	vec3 s = stage_to_source * vec3(p, 1.0);
	return s.xy / s.z;
}

vec2 felt_uv(vec2 src) {
	return (src - felt_origin) * felt_scale / texture_px;
}

// Coverage inside the frame: 1 well inside, ramping to 0 across the feather.
float inside(vec2 src) {
	float d = min(min(src.x - frame_src.x, frame_src.z - src.x), min(src.y - frame_src.y, frame_src.w - src.y));
	return smoothstep(0.0, feather_px, d);
}

void fragment() {
	vec2 p = UV * stage_size;
	vec2 ex = dFdx(p);
	vec2 ey = dFdy(p);
	// Texture-space footprint of one stage pixel, for mip selection. Taken
	// once, outside any branch, so the derivatives are always defined.
	vec2 src0 = source_of(p);
	vec2 uv0 = felt_uv(src0);
	vec2 gx = dFdx(uv0) * 0.5;
	vec2 gy = dFdy(uv0) * 0.5;
	vec4 c = vec4(0.0);
	vec2 taps[4] = vec2[](vec2(-0.375, -0.125), vec2(0.125, -0.375), vec2(0.375, 0.125), vec2(-0.125, 0.375));
	for (int i = 0; i < 4; i++) {
		vec2 src = source_of(p + ex * taps[i].x + ey * taps[i].y);
		vec4 t = textureGrad(felt, felt_uv(src), gx, gy);
		c += t * inside(src);
	}
	COLOR = c * 0.25 * modulate_color;
}
