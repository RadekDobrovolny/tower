shader_type canvas_item;
render_mode unshaded;

// Mlhoviny ve vesmíru: slabá vínová a fialová oblaka se vlákny a tmavými prachovými pásy,
// v nejhustších místech se jemně rozsvítí neonem galaxínu. Jsou jen v jednom širokém šikmém
// pruhu, který se trhá do cárů, zbytek vesmíru zůstává temný. Tvar se počítá z polohy ve
// světě, takže nezávisí na velikosti obrazovky. Oblaka se velmi pomalu přelévají: posun
// běží po kružnici s periodou, která dělí 3600 s, aby se při přetočení TIME nic neskočilo.

// Opakovatelný šum (tools/generate_nebula_noise.gd): R oblaka, G zvlnění a barva, B vlákna.
uniform sampler2D noise : repeat_enable, filter_linear_mipmap;
// Kolik pixelů světa zabere jedno opakování šumu.
uniform float scale = 1500.0;
uniform vec4 wine : source_color = vec4(0.29, 0.059, 0.122, 1.0);
uniform vec4 violet : source_color = vec4(0.2, 0.08, 0.32, 1.0);
uniform vec4 neon : source_color = vec4(1.0, 0.239, 0.545, 1.0);
// Celková síla mlhovin (0–1). Paleta je temná, svítit má jen galaxín.
uniform float strength = 0.5;
// Kolik je kolem prázdna: čím víc, tím menší a řidší oblaka.
uniform float coverage = 0.38;
// Pruh, ve kterém mlhovina je: bod na jeho ose (px světa), sklon osy (rad, y dolů)
// a poloviční šířka (px). Okraj pruhu se vlní podle šumu.
uniform vec2 band_origin = vec2(640.0, 360.0);
uniform float band_angle = -0.42;
uniform float band_width = 260.0;
// Jak dlouho trvá jedno kolo přelévání (s). Musí dělit 3600.
uniform float drift_period = 900.0;

varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float angle = TIME * TAU / drift_period;
	vec2 drift = vec2(cos(angle), sin(angle)) * 0.05;
	vec2 p = world / scale;
	vec2 warp = texture(noise, p * 0.7 + drift).gb - 0.5;
	// Široký opar, ve kterém oblaka leží: odliší kraje vesmíru, aby nebyly všude stejné.
	float haze = smoothstep(0.25, 0.8, texture(noise, p * 0.33 + vec2(0.37, 0.11)).g);
	float clouds = texture(noise, p + warp * 0.4 - drift * 0.6).r;
	float detail = texture(noise, p * 2.6 + warp * 0.5 - drift.yx * 0.4).r;
	float wisps = texture(noise, p * 1.9 + warp * 0.7 + drift.yx).b;
	float hue = texture(noise, p * 0.45 - drift * 0.3).g;

	float body = smoothstep(coverage, coverage + 0.5, clouds * 0.8 + detail * 0.2);
	float filaments = pow(wisps, 4.0) * smoothstep(coverage - 0.15, coverage + 0.3, clouds);
	float density = body * (0.55 + 0.45 * detail) + filaments * 0.35 + haze * 0.12;

	vec2 across = vec2(-sin(band_angle), cos(band_angle));
	float offset = dot(world - band_origin, across) + (haze - 0.5) * band_width * 1.2;
	density *= 1.0 - smoothstep(band_width * 0.2, band_width, abs(offset));

	vec3 color = mix(wine.rgb, violet.rgb, smoothstep(0.35, 0.65, hue));
	color = mix(color, violet.rgb * 0.8, haze * (1.0 - body) * 0.6);
	color += neon.rgb * 0.12 * smoothstep(0.6, 1.0, body * detail * 1.4);
	COLOR = vec4(color, clamp(density * strength, 0.0, 1.0));
}
