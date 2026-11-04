shader_type canvas_item;
render_mode blend_add, unshaded;

// Odlesk světla (RimLight): rozsvítí úzký pruh na hraně spritu, která míří ke světlu.
// Směr se přepočítá do souřadnic spritu, takže odlesk zůstává na stejné straně i u
// otáčejících se objektů. Barva se ztlumí s modulate spritu (rozestavěné budovy).

uniform vec4 rim_color : source_color = vec4(0.72, 0.82, 1.0, 1.0);
uniform float strength = 0.3;
// Šířka odlesku v pixelech obrazovky.
uniform float width = 1.6;
// Směr ke světlu (souřadnice obrazovky, y dolů). RimLight ho nastaví podle DropShadow.DIRECTION.
uniform vec2 light_dir = vec2(-0.78, 0.62);
// Snímek, ze kterého se tvar bere (UV: x, y, šířka, výška).
uniform vec4 frame_rect = vec4(0.0, 0.0, 1.0, 1.0);

varying vec2 local_light;
varying float texels;
varying vec4 tint;

void vertex() {
	mat2 rotation_scale = mat2(MODEL_MATRIX[0].xy, MODEL_MATRIX[1].xy);
	local_light = normalize(inverse(rotation_scale) * light_dir);
	texels = 1.0 / max(length(MODEL_MATRIX[0].xy), 0.0001);
	tint = COLOR;
}

// 1 uvnitř snímku, 0 mimo.
float inside(vec2 uv) {
	vec2 within = step(frame_rect.xy, uv) * step(uv, frame_rect.xy + frame_rect.zw);
	return within.x * within.y;
}

void fragment() {
	float here = texture(TEXTURE, UV).a * inside(UV);
	vec2 reach = local_light * TEXTURE_PIXEL_SIZE * texels * width;
	vec2 near = UV + reach * 0.5;
	vec2 far = UV + reach;
	// Kolik je směrem ke světlu prázdna: na hraně hodně, uvnitř tvaru nic.
	float open = 1.0 - 0.5 * (texture(TEXTURE, near).a * inside(near) + texture(TEXTURE, far).a * inside(far));
	COLOR = vec4(rim_color.rgb * min(tint.rgb, vec3(1.0)), here * open * strength * tint.a);
}
