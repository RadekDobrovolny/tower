class_name SpriteCopy
extends Node2D

## Základ uzlů, které kreslí tvar jiného spritu vlastním shaderem: vržený stín (DropShadow)
## a odlesk světla (RimLight). Bere texturu, snímek pásu, převrácení, region i viditelnost
## spritu `source` a překreslí se, jen když se něco z toho změní. Obdélník kreslí o kus
## větší než snímek (`_margin`), aby se do něj vešlo rozmazání; shader dostane `frame_rect`
## (snímek v UV) a co leží mimo něj, bere jako prázdno.
## Světla stanice ho neosvětlují (light_mask = 0, kvůli výkonu na webu) a má vlastní materiál,
## takže ho přeskočí zlatá záře výběru (ta dává materiál jen spritům bez něj).

## Sprite, jehož tvar se kreslí. Prázdný = rodič.
@export var source: Sprite2D

var _material: ShaderMaterial
## Čím byl tvar naposledy nakreslený (textura, snímek…), aby se překreslil jen po změně.
var _drawn := []


func _ready() -> void:
	if source == null:
		source = get_parent() as Sprite2D
	assert(source != null, "%s potřebuje Sprite2D: rodiče, nebo nastavený source" % name)
	light_mask = 0
	_material = ShaderMaterial.new()
	_material.shader = _shader()
	material = _material
	_follow_source()


func _process(_delta: float) -> void:
	var shown := source.is_visible_in_tree()
	if source != get_parent():
		visible = shown
	if not shown:
		return
	_follow_source()
	var state := [
		source.texture, source.frame, source.hframes, source.vframes, source.flip_h,
		source.flip_v, source.offset, source.centered, source.region_enabled,
		source.region_rect, snappedf(_texels(), 0.05),
	]
	if state != _drawn:
		_drawn = state
		queue_redraw()


func _draw() -> void:
	var texture := source.texture
	if texture == null:
		return
	var texture_size := texture.get_size()
	var base := source.region_rect if source.region_enabled else Rect2(Vector2.ZERO, texture_size)
	var frame_size := base.size / Vector2(source.hframes, source.vframes)
	var frame_coords := Vector2(source.frame % source.hframes, source.frame / source.hframes)
	var frame := Rect2(base.position + frame_coords * frame_size, frame_size)
	_material.set_shader_parameter("frame_rect", Vector4(frame.position.x / texture_size.x,
			frame.position.y / texture_size.y, frame.size.x / texture_size.x, frame.size.y / texture_size.y))
	var target := Rect2(source.offset - (frame_size / 2.0 if source.centered else Vector2.ZERO), frame_size)
	# Obdélník se zvětší o okraj (v pixelech textury) a souřadnice textury s ním.
	var margin := ceilf(_margin() * _texels()) + 1.0
	frame = frame.grow(margin)
	target = target.grow(margin)
	# Stejně jako Sprite2D: záporná šířka nebo výška obrázek převrátí na místě.
	if source.flip_h:
		target.size.x = -target.size.x
	if source.flip_v:
		target.size.y = -target.size.y
	draw_texture_rect_region(texture, target, frame, Color.WHITE, false, false)


## Shader, kterým potomek tvar kreslí.
func _shader() -> Shader:
	return null


## Jak daleko za okraj snímku kreslení sahá (px světa).
func _margin() -> float:
	return 0.0


## Poloha a natočení: přesně jako sprite. Potomci můžou posunout.
func _follow_source() -> void:
	global_transform = source.global_transform


## Kolik pixelů textury připadá na pixel světa.
func _texels() -> float:
	return 1.0 / maxf(absf(global_transform.get_scale().x), 0.0001)
