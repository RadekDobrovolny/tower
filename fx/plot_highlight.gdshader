shader_type canvas_item;
render_mode blend_add, unshaded;

// Vybraná prázdná parcela: světelné pole, které houstne k okrajům, s pomalu stoupajícími
// vlnami a pulzováním. Parcela nemá sprite, takže jí nejde rozsvítit obrys.

uniform vec4 glow_color : source_color = vec4(1.0, 0.8, 0.32, 1.0);
// Na jakou vzdálenost od okraje (px) záře slábne.
uniform float edge_fade = 16.0;
uniform float wave_spacing = 14.0;
uniform float wave_speed = 26.0;
uniform float pulse_speed = 3.5;

void fragment() {
	vec2 pixels = 1.0 / fwidth(UV);
	vec2 to_edge = (0.5 - abs(UV - 0.5)) * pixels;
	// Zaoblené rohy: vzdálenost od okraje se v rohu počítá po oblouku.
	vec2 corner = max(vec2(edge_fade) - to_edge, vec2(0.0));
	float inside = edge_fade - length(corner);
	float edge = exp(-max(inside, 0.0) / (edge_fade * 0.4));
	float mask = smoothstep(0.0, 2.0, inside);
	float wave = 0.5 + 0.5 * sin((UV.y * pixels.y + TIME * wave_speed) * TAU / wave_spacing);
	float pulse = 0.8 + 0.2 * sin(TIME * pulse_speed);
	float glow = (edge * 0.75 + 0.05 + wave * wave * 0.07) * mask * pulse;
	COLOR = vec4(glow_color.rgb * glow, 1.0);
}
