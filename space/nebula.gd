@tool
extends Node2D

## Mlhoviny za hvězdami. Kreslí jeden obdélník přes stejnou plochu jako hvězdy (Starfield)
## a tvar oblaků počítá shader space/nebula.gdshader. Na mlhoviny nesvítí světla stanice.

@export var origin := Vector2(-560, -340)
@export var area := Vector2(2400, 1400)


func _ready() -> void:
	light_mask = 0


func _draw() -> void:
	draw_rect(Rect2(origin, area), Color.WHITE)
