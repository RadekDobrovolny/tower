extends Node2D

## Psychedelický obraz na obrazovce zábavního systému: soustředné elipsy, které se
## přelévají barvami a vnitřní se pomalu točí. Vyšší level = jasnější a rychlejší obraz.
## Obrazovka svítí do okolí v barvě, která na ní zrovna převládá.

## Poloosy obrazovky (vnější elipsy se do ní musí vejít).
@export var radius := Vector2(36, 21)

var level := 1

var _time := 0.0

@onready var _light: PointLight2D = $Light


func _process(delta: float) -> void:
	_time += delta * (0.8 + 0.2 * level)
	_light.color = Color.from_hsv(fmod(_time * 0.07 + 0.3, 1.0), 0.6, 1.0)
	_light.energy = 1.2 + 0.3 * level
	queue_redraw()


func _draw() -> void:
	draw_colored_polygon(_ellipse(radius, 0.0), Color(0.06, 0.02, 0.08))
	var rings := 6
	for i in rings:
		var t := 1.0 - float(i) / rings
		var hue := fmod(_time * 0.07 + i * 0.12, 1.0)
		var color := Color.from_hsv(hue, 0.75, 0.35 + 0.1 * level)
		# Vnější kruhy se netočí, aby nepřesáhly obrazovku; vnitřní se kroutí.
		var angle := 0.0 if t > 0.55 else sin(_time * 0.6 + i) * 0.6
		draw_colored_polygon(_ellipse(radius * t * 0.95, angle), color)


func _ellipse(r: Vector2, angle: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		points.append(Vector2(cos(a) * r.x, sin(a) * r.y).rotated(angle))
	return points
