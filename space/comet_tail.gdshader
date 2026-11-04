shader_type canvas_item;
render_mode blend_add, unshaded;

// Ocasy komety (SkyTraffic.Comet). Kreslí se do jednoho obdélníku za hlavou: UV.x jde od
// hlavy (0) ke konci (1), UV.y napříč. Oba ocasy mají měkký okraj (gaussovský průřez)
// a slábnou ke konci. Tenký tyrkysový iontový ocas je rovný a má podélná vlákna, širší
// růžový prachový ocas se mírně stáčí stranou a je skvrnitý. Vlákna i skvrny pomalu
// odtékají od hlavy; posun má s TIME periodu 4 s (opakovatelný šum), takže při přetočení
// TIME nic neskočí. Průhlednost (modulate) komety ocasy ztlumí.

uniform sampler2D noise : repeat_enable, filter_linear_mipmap;
// Délka iontového ocasu a poloviční výška obdélníku (px).
uniform vec2 size = vec2(160.0, 40.0);
// Délka prachového ocasu vůči iontovému.
uniform float dust_length = 0.65;
// O kolik px se prachový ocas na konci stočí stranou (znaménko = strana).
uniform float curve = 10.0;
// Posun v šumu, aby každá kometa měla jiná vlákna.
uniform float seed = 0.0;
uniform vec4 ion_color : source_color = vec4(0.55, 0.95, 1.0, 1.0);
uniform vec4 dust_color : source_color = vec4(1.0, 0.62, 0.8, 1.0);
uniform float ion_strength = 0.6;
uniform float dust_strength = 0.5;

void fragment() {
	float along = UV.x;
	float y = (UV.y * 2.0 - 1.0) * size.y;
	float flow = TIME * 0.25;

	// Iontový ocas: úzký vějíř paprsků, které se rozbíhají od hlavy (vlákno drží stejný
	// poměr y / šířka), kolem něj slabší širší závoj.
	float ion_width = 1.0 + 7.0 * along;
	float ray = y / ion_width;
	float strands = smoothstep(0.35, 0.85, texture(noise, vec2(along * 0.6 - flow + seed, ray * 0.15)).b);
	float ion = exp(-ray * ray) * (0.3 + 1.3 * strands);
	float veil = ray / 2.6;
	ion += 0.4 * exp(-veil * veil) * strands * strands;
	ion *= pow(max(1.0 - along, 0.0), 1.5);

	// Prachový ocas: širší, stáčí se stranou a je skvrnitý.
	float dust_along = clamp(along / dust_length, 0.0, 1.0);
	float dust_center = curve * dust_along * dust_along;
	float dust_width = 2.0 + 10.0 * dust_along;
	float mottle = smoothstep(0.25, 0.8, texture(noise, vec2(along * 1.8 - flow * 0.5, y / size.y * 0.6 + seed)).r);
	float dust_off = (y - dust_center) / dust_width;
	float dust = exp(-dust_off * dust_off);
	dust *= pow(1.0 - dust_along, 1.3) * (0.3 + 1.1 * mottle);

	vec3 color = ion_color.rgb * ion * ion_strength + dust_color.rgb * dust * dust_strength;
	COLOR = vec4(color, COLOR.a);
}
