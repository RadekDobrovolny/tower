shader_type canvas_item;

// Ručička budíku na zásobníku (TankNeedle). Kreslí se do jednoho obdélníku kolem ručičky:
// tmavá ocel místo čisté černé, měkké vyhlazené okraje, lesk na hraně ke světlu (vlevo dole
// jako u stínů, přepočítaný podle natočení), drobný rozmazaný stín na ciferník a vystínovaný
// mosazný střed. Ručička míří po ose x, střed otáčení je v počátku.

uniform float needle_length = 8.0;
uniform float tail = 2.5;
uniform float half_width = 2.0;
// Jak široká je špička vůči kořeni.
uniform float tip_ratio = 0.45;
uniform float hub_radius = 2.2;
// Šířka měkkého okraje (px).
uniform float softness = 0.8;
uniform vec4 steel : source_color = vec4(0.13, 0.085, 0.07, 1.0);
uniform vec4 shine : source_color = vec4(0.42, 0.31, 0.24, 1.0);
uniform vec4 brass : source_color = vec4(0.72, 0.55, 0.25, 1.0);
// Směr ke světlu (obrazovka, y dolů) a posun stínu (px obrazovky), nastaví TankNeedle.
uniform vec2 light_dir = vec2(-0.78, 0.62);
uniform vec2 shadow_offset = vec2(0.94, -0.74);
uniform float shadow_strength = 0.4;

varying vec2 pos;
varying vec2 local_light;
varying vec2 local_shadow;

void vertex() {
	pos = VERTEX;
	mat2 rotation = mat2(MODEL_MATRIX[0].xy, MODEL_MATRIX[1].xy);
	mat2 back = inverse(rotation);
	local_light = normalize(back * light_dir);
	local_shadow = back * shadow_offset;
}

// Vzdálenost od kraje ručičky (záporná uvnitř) a podíl napříč (0 osa, 1 kraj).
vec2 needle(vec2 p) {
	float along = clamp((p.x + tail) / (needle_length + tail), 0.0, 1.0);
	float half = mix(half_width, half_width * tip_ratio, along);
	float across = abs(p.y) - half;
	float ends = max(-tail - p.x, p.x - needle_length);
	return vec2(max(across, ends), clamp(abs(p.y) / half, 0.0, 1.0));
}

float cover(float distance, float soft) {
	return 1.0 - smoothstep(-soft * 0.5, soft * 0.5, distance);
}

vec4 over(vec4 top, vec4 bottom) {
	float alpha = top.a + bottom.a * (1.0 - top.a);
	vec3 color = (top.rgb * top.a + bottom.rgb * bottom.a * (1.0 - top.a)) / max(alpha, 0.0001);
	return vec4(color, alpha);
}

void fragment() {
	// Stín: stejný tvar posunutý od světla a víc rozmazaný.
	float shadow = cover(needle(pos - local_shadow).x, softness * 2.5) * shadow_strength;
	shadow = max(shadow, cover(length(pos - local_shadow) - hub_radius, softness * 2.5) * shadow_strength);
	vec4 result = vec4(0.0, 0.0, 0.0, shadow);

	// Ručička: hrana natočená ke světlu se leskne, uprostřed je jemný hřbet.
	vec2 n = needle(pos);
	float lit = clamp(sign(pos.y) * local_light.y, 0.0, 1.0) * n.y * n.y;
	vec3 body = mix(steel.rgb, shine.rgb, lit * 0.55 + (1.0 - n.y) * 0.1);
	result = over(vec4(body, cover(n.x, softness)), result);

	// Mosazný střed: světlejší ke světlu, tmavší okraj.
	float r = length(pos);
	float facing = r > 0.001 ? dot(pos / r, local_light) * (r / hub_radius) : 0.0;
	vec3 hub = brass.rgb * (0.75 + 0.45 * facing) * (1.0 - 0.35 * smoothstep(0.6, 1.0, r / hub_radius));
	result = over(vec4(hub, cover(r - hub_radius, softness)), result);
	COLOR = result;
}
