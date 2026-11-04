shader_type canvas_item;
render_mode unshaded;

// Mrkající hvězdy. Starfield každé hvězdě uloží vlastnosti do barvy: R fáze mrkání,
// G jak moc mrká (0 = svítí klidně), B teplota (nad 0.8 teplá), A jas. Hvězdy se tak
// nakreslí jen jednou a mrkání počítá grafická karta.

uniform vec4 cool : source_color = vec4(0.8, 0.85, 1.0, 1.0);
uniform vec4 warm : source_color = vec4(1.0, 0.83, 0.72, 1.0);

void fragment() {
	vec4 star = COLOR;
	float speed = mix(0.7, 2.4, fract(star.r * 7.31));
	float t = TIME * speed + star.r * TAU;
	// Dvě vlny s různou rychlostí, aby mrkání nebylo pravidelné.
	float dip = (0.5 + 0.5 * sin(t)) * (0.55 + 0.45 * sin(t * 2.3 + 1.7));
	vec3 tint = mix(cool.rgb, warm.rgb, step(0.8, star.b));
	COLOR = vec4(tint, star.a * (1.0 - star.g * dip));
}
