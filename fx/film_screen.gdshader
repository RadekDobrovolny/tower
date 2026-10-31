shader_type canvas_item;

// Film na plátně autokina: psychedelické vlny, které se přelévají barvami, slabší okraje
// a blikání promítačky. Čas i jas posílá skript, aby šly řídit levelem.

uniform float phase = 0.0;
uniform float brightness = 0.6;
// Poměr stran plátna, aby vlny zůstaly kulaté.
uniform float aspect = 2.7;

vec3 hsv(float h, float s, float v) {
	vec3 rgb = clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	return v * mix(vec3(1.0), rgb, s);
}

void fragment() {
	vec2 p = (UV - 0.5) * vec2(aspect, 1.0);
	float dist = length(p + 0.15 * vec2(sin(phase * 0.5), cos(phase * 0.37)));
	float wave = sin(dist * 15.0 - phase * 2.0 + sin(atan(p.y, p.x) * 3.0 + phase * 0.6) * 1.6);
	float hue = fract(phase * 0.07 + dist * 0.4 + wave * 0.04);
	vec3 film = hsv(hue, 0.75, 0.6 + 0.4 * wave);
	vec2 edge = abs(UV - 0.5) * 2.0;
	float vignette = 1.0 - 0.6 * smoothstep(0.6, 1.0, max(edge.x, edge.y));
	float flicker = 0.95 + 0.05 * sin(phase * 37.0);
	COLOR = vec4(film * brightness * vignette * flicker, 1.0);
}
