shader_type canvas_item;

// Endless patchwork countryside seen from above, with a river or a coast.
// World y grows upward; `scroll` is how far the stage has travelled.
// land_dist() must stay in step with Themes.land_distance() in GDScript.

uniform float scroll = 0.0;
uniform vec2 screen_size = vec2(480.0, 640.0);
uniform int mode = 0;
uniform vec4 field_a : source_color;
uniform vec4 field_b : source_color;
uniform vec4 field_c : source_color;
uniform vec4 field_d : source_color;
uniform vec4 hedge : source_color;
uniform vec4 water_deep : source_color;
uniform vec4 water_shallow : source_color;
uniform vec4 sand : source_color;
uniform vec4 haze : source_color;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amplitude * noise(p);
		p *= 2.03;
		amplitude *= 0.5;
	}
	return value;
}

float river_x(float wy) {
	return 240.0 + 120.0 * sin(wy * 0.0019) + 45.0 * sin(wy * 0.0053 + 1.3);
}

float river_w(float wy) {
	return 34.0 + 10.0 * sin(wy * 0.004 + 0.7);
}

float land_dist(vec2 w) {
	if (mode == 0) {
		return abs(w.x - river_x(w.y)) - river_w(w.y);
	}
	float left = 150.0 + 55.0 * sin(w.y * 0.0023) + 25.0 * sin(w.y * 0.0071 + 2.0);
	float right = 330.0 + 55.0 * sin(w.y * 0.0021 + 1.7) + 25.0 * sin(w.y * 0.0067);
	return -min(w.x - left, right - w.x);
}

vec3 field_color(vec2 w) {
	vec2 cell_size = vec2(104.0, 84.0);
	vec2 p = w / cell_size;
	p.x += floor(p.y) * 0.37;
	vec2 id = floor(p);
	vec2 f = fract(p);

	float pick = hash(id);
	vec3 color = field_a.rgb;
	color = mix(color, field_b.rgb, step(0.3, pick));
	color = mix(color, field_c.rgb, step(0.55, pick));
	color = mix(color, field_d.rgb, step(0.8, pick));

	// Crop rows run one of two ways per field.
	float along = hash(id + 7.3) > 0.5 ? f.x * cell_size.x : f.y * cell_size.y;
	float rows = 0.5 + 0.5 * sin(along * 0.7);
	color *= 0.95 + 0.07 * rows * step(0.35, hash(id + 3.1));

	// Hedgerows on field borders, with a soft bevel.
	float edge = min(min(f.x, 1.0 - f.x) * cell_size.x, min(f.y, 1.0 - f.y) * cell_size.y);
	edge += (noise(w * 0.3) - 0.5) * 2.0;
	color = mix(hedge.rgb, color, smoothstep(2.0, 5.0, edge));
	color = mix(color * 0.9, color, smoothstep(5.0, 9.0, edge));

	// Grain so nothing looks flat.
	color *= 0.9 + 0.16 * fbm(w * 0.06);
	return color;
}

void fragment() {
	vec2 sp = UV * screen_size;
	vec2 w = vec2(sp.x, scroll + screen_size.y - sp.y);

	float d = land_dist(w) + (fbm(w * 0.022) - 0.5) * 18.0;
	vec3 color = field_color(w);

	// Sandy bank.
	color = mix(sand.rgb * (0.94 + 0.08 * noise(w * 0.4)), color, smoothstep(5.0, 12.0, d));

	// Water: deeper toward the middle, with drifting glints and foam at the shore.
	float depth = clamp(-d / 40.0, 0.0, 1.0);
	vec3 water = mix(water_shallow.rgb, water_deep.rgb, depth);
	float ripple = sin(w.x * 0.11 + w.y * 0.05 + TIME * 1.6 + fbm(w * 0.035 + TIME * 0.05) * 9.0);
	water += vec3(0.35) * smoothstep(0.93, 1.0, ripple) * (0.4 + 0.6 * depth);
	water *= 0.93 + 0.1 * fbm(w * 0.05 + vec2(0.0, TIME * 0.2));
	float foam = smoothstep(-7.0, -1.5, d) * (0.6 + 0.4 * sin(TIME * 2.5 + w.y * 0.08));
	water = mix(water, vec3(1.0), foam * 0.55);
	color = mix(water, color, smoothstep(-0.5, 1.5, d));

	// Atmospheric haze toward the top of the screen, gentle vignette at the sides.
	float top = 1.0 - UV.y;
	color = mix(color, haze.rgb, top * top * 0.28);
	float side = abs(UV.x - 0.5) * 2.0;
	color *= 1.0 - side * side * 0.12;

	COLOR = vec4(color, 1.0);
}
