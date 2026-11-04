shader_type canvas_item;
render_mode unshaded;

// Vržený stín (DropShadow): tvar spritu ztmavený a s rozmazaným okrajem. Uzel kreslí
// obdélník o kus větší než snímek, aby se rozmazání vešlo; co leží mimo snímek, je prázdno.

uniform vec4 shadow_color : source_color = vec4(0.02, 0.01, 0.04, 1.0);
uniform float opacity = 0.54;
// Poloměr rozmazání v pixelech obrazovky.
uniform float softness = 6.0;
// Snímek, ze kterého se stín bere (UV: x, y, šířka, výška).
uniform vec4 frame_rect = vec4(0.0, 0.0, 1.0, 1.0);

const int RING = 8;

// Kolik pixelů textury připadá na jeden pixel obrazovky (sprity mají různé měřítko).
varying float texels;
// Průhlednost zděděná z modulate rodičů (stín mizí spolu s objektem).
varying float fade;

void vertex() {
	texels = 1.0 / max(length(MODEL_MATRIX[0].xy), 0.0001);
	fade = COLOR.a;
}

// 1 uvnitř snímku, 0 mimo (za okrajem snímku je prázdno, i v pásu animace).
float inside(vec2 uv) {
	vec2 within = step(frame_rect.xy, uv) * step(uv, frame_rect.xy + frame_rect.zw);
	return within.x * within.y;
}

void fragment() {
	vec2 reach = TEXTURE_PIXEL_SIZE * texels * softness;
	float sum = texture(TEXTURE, UV).a * inside(UV) * 2.0;
	float weight = 2.0;
	for (int i = 0; i < RING; i++) {
		float angle = TAU * float(i) / float(RING);
		vec2 direction = vec2(cos(angle), sin(angle));
		vec2 rotated = vec2(cos(angle + PI / float(RING)), sin(angle + PI / float(RING)));
		vec2 near = UV + direction * reach * 0.5;
		vec2 far = UV + rotated * reach;
		sum += texture(TEXTURE, near).a * inside(near) * 1.5;
		sum += texture(TEXTURE, far).a * inside(far);
		weight += 2.5;
	}
	COLOR = vec4(shadow_color.rgb, sum / weight * opacity * fade);
}
