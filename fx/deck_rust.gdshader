shader_type canvas_item;

// Rez podél hrany paluby. Kreslí se na Line2D, která vede po obvodu: UV.y je poloha napříč čárou,
// vnější polovina čáry je průhledná, vnitřní se od hrany postupně vytrácí v nepravidelných skvrnách.

uniform vec3 dark_rust : source_color = vec3(0.11, 0.06, 0.04);
uniform vec3 light_rust : source_color = vec3(0.38, 0.18, 0.08);
uniform float strength : hint_range(0.0, 1.0) = 0.38;
// Na které straně čáry je paluba: 1 nebo -1.
uniform float inner_side = 1.0;

varying vec2 deck_position;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), u.x),
			mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	deck_position = VERTEX;
}

void fragment() {
	float inward = (UV.y - 0.5) * 2.0 * inner_side;
	// Velké skvrny určují, jak hluboko rez sahá, drobný šum jí dává rozežraný okraj.
	float patches = noise(deck_position * 0.03) * 0.65 + noise(deck_position * 0.09) * 0.35;
	float grain = noise(deck_position * 0.45);
	float reach = smoothstep(0.3, 0.75, patches) * 0.85 + 0.15;
	float rust = 1.0 - smoothstep(reach * 0.45, reach, inward + (grain - 0.5) * 0.35);
	vec3 color = mix(dark_rust, light_rust, grain * patches * 1.6);
	COLOR = vec4(color, inward < 0.0 ? 0.0 : rust * strength);
}
