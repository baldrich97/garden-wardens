// Fills whatever the 16:9 stage does not cover (very wide or tall windows,
// the strip above a scaled stage) with a soft extension of the backdrop: the
// stage's own texture sampled with clamped edges and blurred, so the sky
// simply continues past the stage edge instead of showing a duplicate scene.
shader_type canvas_item;

uniform sampler2D backdrop : filter_linear, repeat_disable;
uniform vec2 fill_size = vec2(1280.0, 720.0);
uniform vec4 stage_rect = vec4(0.0, 0.0, 1280.0, 720.0);
uniform float dim = 0.82;

void fragment() {
	vec2 p = UV * fill_size;
	vec2 uv = (p - stage_rect.xy) / stage_rect.zw;
	vec2 inside = clamp(uv, vec2(0.0), vec2(1.0));
	float away = length((uv - inside) * stage_rect.zw);
	float radius = clamp(away * 0.15, 0.0, 40.0) / max(stage_rect.z, 1.0);
	vec4 c = vec4(0.0);
	float w = 0.0;
	for (int i = -3; i <= 3; i++) {
		for (int j = -3; j <= 3; j++) {
			vec2 o = vec2(float(i), float(j)) * radius;
			c += texture(backdrop, clamp(inside + o, vec2(0.001), vec2(0.999)));
			w += 1.0;
		}
	}
	c /= w;
	COLOR = vec4(c.rgb * mix(1.0, dim, clamp(away / 120.0, 0.0, 1.0)), 1.0);
}
