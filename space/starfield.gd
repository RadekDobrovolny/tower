@tool
extends Node2D

## Hvězdné pozadí. Hvězdy se generují z pevného seedu, takže vypadají pokaždé stejně.
## Pokrývají větší plochu než základních 1280×720, aby nechyběly ani na širokých nebo
## vysokých displejích (obraz se roztahuje podle poměru stran).
## Část hvězd mrká a pár jich je teplejších. Mrkání počítá shader space/starfield.gdshader,
## vlastnosti hvězdy dostane v barvě (viz shader).

const SHADER := preload("res://space/starfield.gdshader")

@export var star_count := 760
@export var origin := Vector2(-560, -340)
@export var area := Vector2(2400, 1400)
@export var star_seed := 7
## Kolik hvězd mrká (0–1).
@export_range(0.0, 1.0) var twinkling := 0.4


func _ready() -> void:
	light_mask = 0
	var shader_material := ShaderMaterial.new()
	shader_material.shader = SHADER
	material = shader_material


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = star_seed
	# Mrkání má vlastní generátor, aby hvězdy zůstaly na stejných místech jako dřív.
	var looks := RandomNumberGenerator.new()
	looks.seed = star_seed + 1
	for i in star_count:
		var pos := origin + Vector2(rng.randf() * area.x, rng.randf() * area.y)
		var radius := rng.randf_range(0.6, 1.8)
		var brightness := rng.randf_range(0.3, 1.0)
		var phase := looks.randf()
		var twinkle := looks.randf_range(0.35, 0.85) if looks.randf() < twinkling else 0.0
		var warmth := looks.randf()
		draw_circle(pos, radius, Color(phase, twinkle, warmth, brightness))
