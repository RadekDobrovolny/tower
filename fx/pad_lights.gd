class_name PadLights
extends Node2D

## Světelné značky v rozích přistávací plochy: pulzují a svítí do okolí.
## Volná plocha pomalu „dýchá“, když se blíží loď, značky rychle obíhají dokola (navádění),
## a když loď stojí na ploše, svítí klidně a slaběji.
## Světlo do okolí dává jediné PointLight2D s texturou čtyř skvrn (šetří limit světel na objekt).

enum Mode { OFF, IDLE, APPROACH, LANDED }

## Pozice značek vůči středu plochy (px ve hře) po směru hodinových ručiček, kvůli obíhání.
const MARKERS: Array[Vector2] = [Vector2(-34, -33), Vector2(34, -33), Vector2(34, 33), Vector2(-34, 33)]
const COLOR := Color(1.0, 0.6, 0.18)
const LIGHT_ENERGY := 1.1
const GLOW_SCALE := 0.2
## Textura světla (v poloviční velikosti, světlo ji 2× zvětší) a poloměr útlumu skvrn v px ve hře.
const LIGHT_TEXTURE_SIZE := 80
const LIGHT_TEXTURE_SCALE := 2.0
const SPOT_RADIUS := 22.0
const IDLE_SPEED := 2.4
const CHASE_SPEED := 9.0
const LANDED_BRIGHTNESS := 0.45

const SOFT_LIGHT := preload("res://fx/soft_light.tres")
const ADDITIVE := preload("res://fx/additive.tres")

static var _light_texture: ImageTexture

var mode := Mode.OFF

var _time := randf() * 10.0
var _glows: Array[Sprite2D] = []
var _light: PointLight2D


func _ready() -> void:
	for marker in MARKERS:
		var glow := Sprite2D.new()
		glow.texture = SOFT_LIGHT
		glow.material = ADDITIVE
		glow.modulate = COLOR
		glow.scale = Vector2.ONE * GLOW_SCALE
		glow.position = marker
		add_child(glow)
		_glows.append(glow)
	_light = PointLight2D.new()
	_light.texture = _spots_texture()
	_light.texture_scale = LIGHT_TEXTURE_SCALE
	_light.color = COLOR
	add_child(_light)


func _process(delta: float) -> void:
	visible = mode != Mode.OFF
	if not visible:
		return
	_time += delta
	var total := 0.0
	for i in _glows.size():
		var brightness := _marker_brightness(i)
		_glows[i].modulate.a = brightness
		total += brightness
	_light.energy = LIGHT_ENERGY * total / _glows.size()


func _marker_brightness(index: int) -> float:
	match mode:
		Mode.IDLE:
			return 0.45 + 0.55 * (0.5 + 0.5 * sin(_time * IDLE_SPEED))
		Mode.APPROACH:
			return 0.25 + 0.75 * pow(0.5 + 0.5 * cos(_time * CHASE_SPEED - index * PI / 2.0), 3.0)
		Mode.LANDED:
			return LANDED_BRIGHTNESS
	return 0.0


## Textura světla: měkké skvrny na místech značek. Stejná pro všechny plochy, počítá se jednou.
static func _spots_texture() -> ImageTexture:
	if _light_texture:
		return _light_texture
	var image := Image.create(LIGHT_TEXTURE_SIZE, LIGHT_TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	var center := Vector2.ONE * LIGHT_TEXTURE_SIZE / 2.0
	for y in LIGHT_TEXTURE_SIZE:
		for x in LIGHT_TEXTURE_SIZE:
			var value := 0.0
			for marker in MARKERS:
				var offset := (Vector2(x, y) - center) * LIGHT_TEXTURE_SCALE - marker
				var distance := offset.length() / SPOT_RADIUS
				value += exp(-distance * distance)
			value = minf(value, 1.0)
			image.set_pixel(x, y, Color(value, value, value, value))
	_light_texture = ImageTexture.create_from_image(image)
	return _light_texture
