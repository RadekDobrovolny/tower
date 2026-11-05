shader_type canvas_item;

// Bok paluby (DeckSide): pás pod spodními hranami paluby. UV.x je x na palubě posunuté stejně
// jako textura paluby, takže spáry plechů boku leží pod spárami desek. UV.y jde od horní hrany
// boku (0) ke spodní (1). Barva vrcholů nese nasvícení podle natočení plochy.
// Bok je složený z plechů širokých jako deska paluby. Textura (assets/sprites/station/deck_side.png)
// má vedle sebe varianty plechu a každá deska si náhodně vybere jednu. Plechy začínají
// a končí spárou, takže na sebe navazují v libovolném pořadí. Okénka jsou nakreslená
// v textuře, shader je rozsvítí teplým světlem (část je zhasnutá a pár jich občas problikne).

uniform float thickness = 16.0;
// Kolik variant plechu je v textuře vedle sebe.
uniform int variants = 1;
// Šířka jednoho plechu (= desky paluby) v px světa.
uniform float plate_length = 64.0;
// Okénko každé varianty: x, y středu v plechu (0–1) a z = 1, když tam okénko je.
uniform vec3 portholes[8];
// Poloměr skla okénka vůči výšce boku.
uniform float glass_radius = 0.165;
// Šířka skla vůči výšce: plechy jsou při zmenšení na šířku desky trochu zúžené.
uniform float glass_aspect = 1.0;
uniform vec4 window_color : source_color = vec4(1.0, 0.72, 0.38, 1.0);

varying vec3 shade;

void vertex() {
	// Ve fragmentu je COLOR už vynásobený texturou, nasvícení se proto bere tady.
	shade = COLOR.rgb;
}

float hash(float n) {
	return fract(sin(n * 127.1 + 311.7) * 43758.5453);
}

void fragment() {
	float plate = floor(UV.x / plate_length);
	float within = UV.x / plate_length - plate;
	float variant = floor(hash(plate * 1.37 + 5.0) * float(variants));
	vec2 uv = vec2((variant + within) / float(variants), clamp(UV.y, 0.02, 0.98));
	// Mipmapa podle spojitých souřadnic, jinak by na hranici plechů vznikla čára.
	vec2 smooth_uv = vec2(UV.x / plate_length / float(variants), UV.y);
	vec3 metal = textureGrad(TEXTURE, uv, dFdx(smooth_uv), dFdy(smooth_uv)).rgb;
	vec3 color = metal * shade;

	vec3 hole = portholes[int(variant)];
	if (hole.z > 0.5) {
		float radius = glass_radius * thickness;
		float d = length(vec2((within - hole.x) * plate_length / glass_aspect, (UV.y - hole.y) * thickness));
		float lit = step(0.28, hash(plate + 7.0));
		if (hash(plate + 13.0) > 0.85) {
			lit *= step(0.3, hash(floor(TIME * 9.0) + plate * 3.1));
		}
		float glass = 1.0 - smoothstep(radius - 0.7, radius, d);
		float brightness = dot(metal, vec3(0.3, 0.59, 0.11));
		color = mix(color, window_color.rgb * (0.75 + 1.5 * brightness), glass * lit * 0.9);
		color += window_color.rgb * lit * 0.22 * exp(-max(d - radius, 0.0) / 2.0) * (1.0 - glass);
	}
	COLOR = vec4(color, 1.0);
}
