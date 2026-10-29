@tool
extends Node2D

## Hvězdné pozadí. Hvězdy se generují z pevného seedu, takže vypadají pokaždé stejně.

@export var star_count := 220
@export var area := Vector2(1280, 720)
@export var star_seed := 7


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = star_seed
	for i in star_count:
		var pos := Vector2(rng.randf() * area.x, rng.randf() * area.y)
		var radius := rng.randf_range(0.6, 1.8)
		var brightness := rng.randf_range(0.3, 1.0)
		draw_circle(pos, radius, Color(0.8, 0.85, 1.0, brightness))
