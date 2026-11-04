shader_type canvas_item;

// Obrys trupu lodi ze strany, odkud přichází světlo (vlevo dole na obrazovce, stejně jako
// u vržených stínů DropShadow a odlesků RimLight).
// Díky němu jsou vidět i tmavé rakety proti černému vesmíru. Směr světla se přepočítá
// do souřadnic spritu, takže obrys zůstává na stejné straně, i když se loď otáčí.

uniform vec4 rim_color : source_color = vec4(0.72, 0.82, 1.0, 1.0);
uniform float rim_strength = 0.42;
// Šířka obrysu v pixelech textury.
uniform float rim_width = 6.0;
// Směr, odkud světlo přichází (souřadnice obrazovky, y dolů): opačný než DropShadow.DIRECTION.
uniform vec2 light_dir = vec2(-0.78, 0.62);

varying vec2 local_light;

void vertex() {
	mat2 rotation_scale = mat2(MODEL_MATRIX[0].xy, MODEL_MATRIX[1].xy);
	local_light = normalize(inverse(rotation_scale) * light_dir);
}

void fragment() {
	vec4 color = COLOR;
	float outside = 1.0 - texture(TEXTURE, UV + local_light * TEXTURE_PIXEL_SIZE * rim_width).a;
	color.rgb += rim_color.rgb * color.a * outside * rim_strength;
	COLOR = color;
}
