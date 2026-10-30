class_name EngineFlame
extends Node2D

## Plamen raketového motoru: plápolající plamen (shader), jiskry a oranžové světlo, které
## osvětlí loď i palubu kolem. `target_throttle` (0–1) říká, jak moc motor táhne;
## plamen se k němu plynule přiblíží (naskočí a zhasne během zlomku sekundy).

## Jak rychle plamen naskočí nebo zhasne (změna tahu za sekundu).
const THROTTLE_RESPONSE := 4.0
const LIGHT_ENERGY := 1.2
## Pod tímhle tahem motor nepouští jiskry.
const EMBERS_THRESHOLD := 0.45

var target_throttle := 0.0
var throttle := 0.0

var _time := randf() * 100.0

@onready var _flame: Sprite2D = $Flame
@onready var _glow: Sprite2D = $Glow
@onready var _light: PointLight2D = $Light
@onready var _embers: CPUParticles2D = $Embers
@onready var _flame_material: ShaderMaterial = _flame.material


func _ready() -> void:
	_flame_material.set_shader_parameter("seed", randf() * 10.0)
	_apply(0.0)


func _process(delta: float) -> void:
	throttle = move_toward(throttle, target_throttle, THROTTLE_RESPONSE * delta)
	_time += delta
	_apply(0.88 + 0.12 * sin(_time * 31.0) * sin(_time * 17.0 + 1.3))


func _apply(flicker: float) -> void:
	visible = throttle > 0.01
	_flame_material.set_shader_parameter("throttle", throttle)
	_light.energy = LIGHT_ENERGY * throttle * flicker
	_glow.modulate.a = throttle * flicker
	_embers.emitting = throttle > EMBERS_THRESHOLD
