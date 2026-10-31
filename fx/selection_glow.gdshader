shader_type canvas_item;

// Zvýraznění vybraného objektu: pulzující zlatý obrys podle tvaru spritu a světelný pruh,
// který přes objekt přejíždí. Pruh se počítá ze souřadnic světa, takže běží plynule přes
// všechny sprity jednoho objektu.

uniform vec4 glow_color : source_color = vec4(1.0, 0.8, 0.32, 1.0);
// Šířka obrysu v pixelech na obrazovce.
uniform float width = 1.5;
// Jak moc obrys překryje okraj spritu zevnitř.
uniform float inner_strength = 0.6;
uniform float pulse_speed = 3.5;
uniform float sweep_speed = 3.0;
uniform float sweep_strength = 0.55;
// Kolik snímků má vodorovný pás animace (Sprite2D.hframes).
uniform float hframes = 1.0;

const int DIRECTIONS = 12;

// Kolik pixelů textury připadá na jeden pixel obrazovky (sprity mají různé měřítko).
varying float texels;
varying vec2 world;

void vertex() {
	texels = 1.0 / length(MODEL_MATRIX[0].xy);
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 reach = TEXTURE_PIXEL_SIZE * texels * width;
	float frame_width = 1.0 / hframes;
	float frame_left = floor(UV.x / frame_width) * frame_width;
	float most = 0.0;
	float least = 1.0;
	for (int i = 0; i < DIRECTIONS; i++) {
		float angle = TAU * float(i) / float(DIRECTIONS);
		vec2 at = UV + vec2(cos(angle), sin(angle)) * reach;
		// Za okrajem snímku je prázdno: sprity vyplňující celou texturu tak mají obrys
		// a v pásu animace se obrys nepřelije ze sousedního snímku.
		vec2 inside = step(vec2(frame_left, 0.0), at) * step(at, vec2(frame_left + frame_width, 1.0));
		float neighbour = texture(TEXTURE, at).a * inside.x * inside.y;
		most = max(most, neighbour);
		least = min(least, neighbour);
	}
	float pulse = 0.75 + 0.25 * sin(TIME * pulse_speed);
	vec4 color = COLOR;
	float sweep = pow(max(sin((world.x + world.y) * 0.018 - TIME * sweep_speed), 0.0), 24.0);
	color.rgb += glow_color.rgb * sweep * sweep_strength;
	color.rgb = mix(color.rgb, glow_color.rgb, (1.0 - least) * pulse * inner_strength);
	// Vně spritu zůstane jen obrys.
	float outside = smoothstep(0.1, 0.6, most) * (1.0 - color.a) * pulse;
	color.rgb = mix(color.rgb, glow_color.rgb, 1.0 - color.a);
	color.a = max(color.a, outside);
	COLOR = color;
}
