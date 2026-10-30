shader_type canvas_item;
render_mode blend_add, unshaded;

// Plamen raketového motoru. Kreslí se do obdélníku za tryskou: UV.x = 1 u trysky, 0 na konci.
// Uprostřed bílé jádro, kolem oranžová, konec plamene přechází do růžového neonu galaxínu.
// Délka plamene se třese (šum) a okraje se vlní.

uniform float throttle : hint_range(0.0, 1.0) = 1.0;
uniform float seed = 0.0;
uniform vec4 core_color : source_color = vec4(1.0, 0.97, 0.85, 1.0);
uniform vec4 mid_color : source_color = vec4(1.0, 0.55, 0.18, 1.0);
uniform vec4 tail_color : source_color = vec4(1.0, 0.2, 0.5, 1.0);

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

float noise(float x) {
	float i = floor(x);
	float f = fract(x);
	return mix(hash(i), hash(i + 1.0), f * f * (3.0 - 2.0 * f));
}

void fragment() {
	float d = 1.0 - UV.x;
	float y = abs(UV.y - 0.5) * 2.0;
	float t = TIME * 16.0 + seed * 37.0;
	float flame_length = throttle * (0.72 + 0.28 * noise(t));
	float along = d / max(flame_length, 0.001);
	float wobble = 0.12 * sin(d * 22.0 - t * 1.9) * along;
	float width = mix(0.95, 0.08, along);
	float body = 1.0 - smoothstep(width * 0.45, width, y + wobble);
	body *= 1.0 - smoothstep(0.7, 1.0, along);
	float core = (1.0 - smoothstep(0.0, width * 0.4, y)) * (1.0 - smoothstep(0.0, 0.5, along));
	vec3 color = mix(mid_color.rgb, tail_color.rgb, smoothstep(0.25, 0.95, along));
	color = mix(color, core_color.rgb, core);
	float alpha = clamp(body * (1.0 - 0.5 * along) + core, 0.0, 1.0) * step(along, 1.0);
	COLOR = vec4(color, alpha);
}
