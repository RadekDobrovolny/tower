@tool
extends Node2D

## Hvězdné pozadí. Hvězdy se generují z pevného seedu, takže vypadají pokaždé stejně.
## Pokrývají větší plochu než základních 1280×720, aby nechyběly ani na širokých nebo
## vysokých displejích (obraz se roztahuje podle poměru stran).

@export var star_count := 760
@export var origin := Vector2(-560, -340)
@export var area := Vector2(2400, 1400)
@export var star_seed := 7


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = star_seed
	for i in star_count:
		var pos := origin + Vector2(rng.randf() * area.x, rng.randf() * area.y)
		var radius := rng.randf_range(0.6, 1.8)
		var brightness := rng.randf_range(0.3, 1.0)
		draw_circle(pos, radius, Color(0.8, 0.85, 1.0, brightness))
