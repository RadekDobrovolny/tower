shader_type canvas_item;

// Potrubí ze zásobníku k čerpadlu (na Line2D s texturou v režimu TILE, takže UV.x roste
// o 1 na každou šířku trubky a UV.y jde napříč). Měděná trubka se stínováním válce,
// mosazné objímky v pravidelných rozestupech a růžový puls galaxínu, když teče.

uniform vec4 copper : source_color = vec4(0.62, 0.34, 0.2, 1.0);
uniform vec4 brass : source_color = vec4(0.78, 0.62, 0.32, 1.0);
uniform vec4 galaxin : source_color = vec4(1.0, 0.24, 0.55, 1.0);
// Rozestup objímek v šířkách trubky.
uniform float band_spacing = 7.0;
// 0 = galaxín neteče, 1 = teče (puls běží od zásobníku k čerpadlu).
uniform float flow = 0.0;

void fragment() {
	float y = UV.y * 2.0 - 1.0;
	float shade = sqrt(max(0.0, 1.0 - y * y));
	vec3 color = copper.rgb * (0.3 + 0.8 * shade);
	// Odlesk na horní straně trubky.
	color += vec3(1.0, 0.85, 0.7) * pow(max(0.0, 1.0 - abs(y + 0.4) * 3.0), 3.0) * 0.35;
	// Měděná patina a špína podél trubky.
	color *= 0.9 + 0.1 * sin(UV.x * 3.7) * sin(UV.x * 1.3);
	float band = step(fract(UV.x / band_spacing), 0.14);
	color = mix(color, brass.rgb * (0.35 + 0.85 * shade), band);
	float pulse = smoothstep(0.8, 1.0, fract(UV.x * 0.22 - TIME * 1.6));
	color += galaxin.rgb * pulse * flow * shade * 0.9;
	float alpha = 1.0 - smoothstep(0.82, 1.0, abs(y));
	COLOR = vec4(color, alpha);
}
