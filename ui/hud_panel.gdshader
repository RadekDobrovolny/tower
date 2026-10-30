shader_type canvas_item;

// Efekt panelů HUD: jemné scanlines a zrnění (špinavý noir), mosazné svítící rohy u zkosených hran,
// světelný pruh, který jednou za čas přejede přes celou obrazovku, a odkrytí panelu shora dolů.
// Kreslí se přes StyleBoxFlat panelu (ten dává tvar a barvy, UV pokrývá celý panel).

// Velikost panelu v pixelech (nastavuje HudPanel).
uniform vec2 rect_size = vec2(200.0, 100.0);
// Zkosení levého horního a pravého dolního rohu (stejné jako corner_radius ve stylu panelu).
uniform float chamfer = 12.0;
uniform vec4 accent : source_color = vec4(0.97, 0.74, 0.38, 1.0);
// 0..1: jak velká část panelu (shora) je odkrytá. Nad 1 je panel celý.
uniform float reveal = 1.1;
uniform float sweep_period = 9.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 px = UV * rect_size;
	vec2 inv = rect_size - px;
	vec4 c = COLOR;

	// Horní část panelu je o kousek světlejší, jako by na ni padalo světlo.
	c.rgb += vec3(0.05, 0.035, 0.06) * (1.0 - smoothstep(0.0, 0.55, UV.y));
	// Scanlines po 3 px a zrnění, které se mění několikrát za sekundu.
	c.rgb *= 0.93 + 0.07 * step(1.0, mod(px.y, 3.0));
	c.rgb += (hash(floor(px) + floor(TIME * 8.0) * 17.0) - 0.5) * 0.035;

	// Vzdálenost od okraje panelu (se zkosenými rohy vlevo nahoře a vpravo dole).
	float d = min(min(px.x, px.y), min(inv.x, inv.y));
	d = min(d, (px.x + px.y - chamfer) * 0.7071);
	d = min(d, (inv.x + inv.y - chamfer) * 0.7071);
	float edge = 1.0 - smoothstep(0.6, 1.8, d);

	// Svítící mosazné rohy kolem zkosení.
	float corner = max(
		1.0 - smoothstep(chamfer + 14.0, chamfer + 26.0, px.x + px.y),
		1.0 - smoothstep(chamfer + 14.0, chamfer + 26.0, inv.x + inv.y));
	c.rgb = mix(c.rgb, accent.rgb, edge * corner);
	c.a = max(c.a, edge * corner);
	c.rgb += accent.rgb * exp(-d / 3.5) * 0.3 * corner;

	// Světelný pruh šikmo přes obrazovku: na okrajích panelu výraznější než uvnitř.
	float sweep_pos = fract(TIME / sweep_period) * 3.0 - 0.8;
	float diagonal = SCREEN_UV.x + (1.0 - SCREEN_UV.y) * 0.4;
	float band = 1.0 - smoothstep(0.0, 0.06, abs(diagonal - sweep_pos));
	c.rgb += accent.rgb * band * (0.05 + 0.6 * edge);

	// Odkrytí: pod hranou odkrytí je panel průhledný, na hraně svítí linka.
	float scan_line = 1.0 - smoothstep(0.0, 0.025, abs(UV.y - reveal));
	c.rgb += accent.rgb * scan_line * 0.8;
	c.a *= step(UV.y, reveal + 0.01);
	COLOR = c;
}
