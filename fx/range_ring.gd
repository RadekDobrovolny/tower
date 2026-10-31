class_name RangeRing
extends Node2D

## Jemný okruh kolem věže, kam až dostřelí: slabá výplň a pomalu obíhající čárkovaný kruh.

const COLOR := Color(1.0, 0.8, 0.32)
const FILL_ALPHA := 0.035
const LINE_ALPHA := 0.4
const LINE_WIDTH := 2.0
const DASHES := 72
## Jaká část dílku je čárka (zbytek je mezera).
const DASH_SHARE := 0.6
## Jak rychle kruh obíhá (rad/s).
const SPIN_SPEED := 0.08

var radius := 0.0:
	set(value):
		radius = value
		queue_redraw()


func _process(delta: float) -> void:
	rotation += SPIN_SPEED * delta


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(COLOR, FILL_ALPHA))
	var step := TAU / DASHES
	for i in DASHES:
		var start := i * step
		draw_arc(Vector2.ZERO, radius, start, start + step * DASH_SHARE, 6, Color(COLOR, LINE_ALPHA), LINE_WIDTH, true)
