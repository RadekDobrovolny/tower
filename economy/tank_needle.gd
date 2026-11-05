class_name TankNeedle
extends Node2D

## Ručička budíku na zásobníku. Ukazuje, jak je zásobník plný (`value` 0–1, nastavuje ji
## GalaxinTank): k nové hodnotě se plynule dotočí a jemně se chvěje jako tlakoměr. Kreslí se
## přes prázdný ciferník v obrázku zásobníku, uzel stojí ve středu ciferníku. Vzhled (tmavá
## ocel, měkké okraje, lesk ke světlu, stín na ciferník, mosazný střed) počítá shader
## economy/tank_needle.gdshader, aby ručička zapadla do malované grafiky.

const SHADER := preload("res://economy/tank_needle.gdshader")
## Jak daleko od ručičky padá její stín na ciferník (px).
const SHADOW_DISTANCE := 1.2
## Okraj kreslené plochy kolem ručičky kvůli měkkým okrajům a stínu (px).
const MARGIN := 3.0

## Úhel ručičky u prázdného a plného zásobníku (rad, 0 = doprava, kladné po směru hodinových
## ručiček). Plný zásobník je v růžovém poli ciferníku.
@export var empty_angle := deg_to_rad(135.0)
@export var full_angle := deg_to_rad(405.0)
## Délka ručičky od středu (px) a jak daleko za střed přečnívá.
@export var length := 9.0
@export var tail := 2.5
## Šířka ručičky u kořene (px). Ke špičce se zúží zhruba na polovinu.
@export var width := 1.6
## Poloměr mosazného středu ručičky (px).
@export var hub := 2.2
## Jak rychle se ručička dotočí k nové hodnotě (1/s) a jak moc se chvěje (rad).
@export var speed := 3.0
@export var tremble := deg_to_rad(0.8)

## Jak je zásobník plný (0–1).
var value := 1.0

var _shown := -1.0
var _time := 0.0


func _ready() -> void:
	var needle := ShaderMaterial.new()
	needle.shader = SHADER
	needle.set_shader_parameter("needle_length", length)
	needle.set_shader_parameter("tail", tail)
	needle.set_shader_parameter("half_width", width * 0.5)
	needle.set_shader_parameter("hub_radius", hub)
	needle.set_shader_parameter("light_dir", -DropShadow.DIRECTION)
	needle.set_shader_parameter("shadow_offset", DropShadow.DIRECTION * SHADOW_DISTANCE)
	material = needle


func _process(delta: float) -> void:
	_time += delta
	var target := clampf(value, 0.0, 1.0)
	_shown = target if _shown < 0.0 else lerpf(_shown, target, 1.0 - exp(-speed * delta))
	rotation = lerpf(empty_angle, full_angle, _shown) + tremble * sin(_time * 23.0) * sin(_time * 7.0)


func _draw() -> void:
	var reach := maxf(width * 0.5, hub) + MARGIN
	draw_rect(Rect2(-tail - MARGIN, -reach, length + tail + MARGIN * 2.0, reach * 2.0), Color.WHITE)
