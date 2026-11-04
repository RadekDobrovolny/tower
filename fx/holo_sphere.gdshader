shader_type canvas_item;
render_mode blend_add, unshaded;

// Holografická koule nad holokinem: otáčející se mřížka a přelévající se obraz, světlejší
// okraj a běžící řádky. Při výpadku koule zazrní, řádky se posunou do stran a ztmavne.
// Od levelu 5 kolem ní obíhají neonové prstence. Čas, jas a výpadek posílá skript.

uniform float phase = 0.0;
uniform float brightness = 0.8;
// 0 = čistý obraz, 1 = plný výpadek.
uniform float glitch = 0.0;
// Mění se s každým výpadkem, aby se pokaždé posunuly jiné řádky.
uniform float seed = 0.0;
// Kolik neonových prstenců kolem koule obíhá (0–2).
uniform float rings = 0.0;
// Poloměr koule v UV (zbytek obdélníku je místo pro prstence).
uniform float radius = 0.62;
uniform vec3 tint : source_color = vec3(0.35, 0.95, 0.9);
uniform vec3 accent : source_color = vec3(1.0, 0.24, 0.55);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Neonový prstenec: elipsa nakloněná o `tilt`, `front` = 1 pro přední polovinu, 0 pro zadní.
float ring(vec2 p, float tilt, float speed, out float front) {
	float c = cos(tilt);
	float s = sin(tilt);
	vec2 q = vec2(c * p.x + s * p.y, -s * p.x + c * p.y);
	vec2 axes = vec2(0.95, 0.26);
	float d = abs(length(q / axes) - 1.0);
	front = step(0.0, q.y);
	float line = smoothstep(0.06, 0.0, d);
	// Světélko, které po prstenci obíhá.
	float angle = atan(q.y / axes.y, q.x / axes.x);
	float spark = pow(max(cos(angle - phase * speed), 0.0), 24.0);
	return line * (0.45 + 1.6 * spark);
}

void fragment() {
	vec2 uv = UV;
	float band = floor(uv.y * 22.0);
	uv.x += glitch * (hash(vec2(band, seed)) - 0.5) * 0.18 * step(0.55, hash(vec2(seed, band)));
	vec2 p = (uv * 2.0 - 1.0) / radius;
	float r = length(p);
	float z = sqrt(max(1.0 - r * r, 0.0));

	// Souřadnice na kouli, zeměpisná délka se otáčí.
	float lon = atan(p.x, max(z, 0.001)) + phase * 0.45;
	float lat = asin(clamp(p.y, -1.0, 1.0));
	float grid = max(smoothstep(0.94, 1.0, abs(cos(lon * 5.0))), smoothstep(0.94, 1.0, abs(cos(lat * 6.0))));
	float wave = 0.5 + 0.5 * sin(lon * 3.0 + sin(lat * 4.0 + phase * 0.7) * 2.0 - phase * 1.3);
	vec3 picture = mix(tint, accent, smoothstep(0.62, 0.95, wave) * 0.7);
	float rim = pow(1.0 - z, 2.5);
	float scan = 0.72 + 0.28 * sin(uv.y * 150.0 - phase * 7.0);
	float flicker = 0.92 + 0.08 * sin(phase * 23.0 + sin(phase * 7.0) * 2.0);
	vec3 sphere = picture * (0.18 + 0.32 * wave) + tint * (grid * 0.45 + rim * 1.1);
	sphere *= scan * flicker * smoothstep(1.0, 0.94, r);

	// Výpadek: zrno a problikávání.
	float grain = hash(floor(UV * vec2(64.0, 64.0)) + floor(phase * 40.0));
	sphere = mix(sphere, tint * grain * 1.2 * step(r, 1.0), glitch * 0.75);
	sphere *= 1.0 - glitch * 0.6 * step(0.5, hash(vec2(floor(phase * 30.0), seed)));

	vec3 color = sphere;
	if (rings > 0.0) {
		float front;
		float first = ring(uv * 2.0 - 1.0, 0.28, 1.6, front);
		// Zadní polovinu prstence koule zakrývá.
		float hidden = (1.0 - front) * step(r, 1.0);
		color += accent * first * (1.0 - 0.8 * hidden);
		if (rings > 1.0) {
			float second = ring(uv * 2.0 - 1.0, -0.42, -1.1, front);
			hidden = (1.0 - front) * step(r, 1.0);
			color += mix(accent, tint, 0.5) * second * (1.0 - 0.8 * hidden);
		}
	}
	COLOR = vec4(color * brightness, 1.0);
}
