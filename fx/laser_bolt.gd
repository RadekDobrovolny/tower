class_name LaserBolt
extends Node2D

## Krátká světelná střela: blikne u hlavně, proletí k cíli a tam se rozstříkne v jiskry.
## Cestou svítí na okolí. Účinek (`on_hit`) přijde až při dopadu, a jen když cíl pořád existuje.
## Letí v globálních souřadnicích, takže ji neovlivní, co se mezitím stane se střelcem.

const GOLD := Color(1.0, 0.74, 0.2)
const RED := Color(1.0, 0.15, 0.1)
const SPEED := 1300.0
## Jak daleko od středu cíle střela dopadne, aby rány nekončily pořád v jednom bodě.
const HIT_SCATTER := 10.0
const GLOW_WIDTH := 40.0
const CORE_WIDTH := 16.0
## Jak moc je jádro střely vybělené (0 = barva střely, 1 = bílá).
const CORE_WHITENESS := 0.5
const TEXTURE_SIZE := 128.0
const MUZZLE_TIME := 0.1
const IMPACT_TIME := 0.18
## Za jak dlouho po dopadu zmizí (dohoří jiskry).
const FADE_TIME := 0.35

static var _scene: PackedScene

var _target: Node2D
var _on_hit: Callable
var _color: Color
var _length := 60.0
var _aim: Vector2
var _offset := Vector2.ZERO
var _travelled := 0.0
var _landed := false

@onready var _streak: Node2D = $Streak
@onready var _light: PointLight2D = $Light
@onready var _muzzle: Sprite2D = $Muzzle
@onready var _impact: Sprite2D = $Impact
@onready var _sparks: CPUParticles2D = $Sparks


## Vystřelí z `from` na `target` barvou `color`. Střela žije ve stanici, takže přežije střelce.
static func fire(station: Station, from: Vector2, target: Node2D, color: Color, on_hit: Callable,
		length := 60.0) -> void:
	if _scene == null:
		_scene = load("res://fx/laser_bolt.tscn")
	var bolt: LaserBolt = _scene.instantiate()
	bolt._target = target
	bolt._on_hit = on_hit
	bolt._length = length
	bolt._aim = target.global_position
	bolt._offset = Vector2.from_angle(randf() * TAU) * randf() * HIT_SCATTER
	bolt.position = from
	bolt.rotation = (target.global_position - from).angle()
	bolt._color = color
	station.add_child(bolt)
	Sfx.play("laser_gold" if color == GOLD else "laser_red")


func _ready() -> void:
	var core_color := _color.lerp(Color.WHITE, CORE_WHITENESS)
	$Streak/Glow.scale = Vector2(_length * 1.6, GLOW_WIDTH) / TEXTURE_SIZE
	$Streak/Glow.modulate = _color
	$Streak/Core.scale = Vector2(_length * 1.3, CORE_WIDTH) / TEXTURE_SIZE
	$Streak/Core.modulate = core_color
	$Streak/Beam.points = PackedVector2Array([Vector2(-_length / 2.0, 0.0), Vector2(_length / 2.0, 0.0)])
	$Streak/Beam.modulate = core_color
	_impact.modulate = core_color
	_sparks.color = _color
	_light.color = _color
	_show_streak(0.0)
	_muzzle.global_position = position
	_muzzle.modulate = _color
	create_tween().tween_property(_muzzle, "modulate:a", 0.0, MUZZLE_TIME)


func _process(delta: float) -> void:
	if _landed:
		return
	if is_instance_valid(_target):
		_aim = _target.global_position + _offset
	var to_aim := _aim - position
	var step := SPEED * delta
	if step >= to_aim.length():
		position = _aim
		_land()
		return
	position += to_aim.normalized() * step
	rotation = to_aim.angle()
	_travelled += step
	_show_streak(minf(_travelled, _length))


## Střela se u hlavně nejdřív vysune: hlava letí a ocas zůstává u hlavně, dokud nemá plnou délku.
func _show_streak(shown: float) -> void:
	_streak.scale.x = shown / _length
	_streak.position.x = -shown / 2.0


func _land() -> void:
	_landed = true
	_streak.hide()
	_impact.show()
	_sparks.restart()
	Sfx.play("bolt_hit")
	if is_instance_valid(_target) and _on_hit.is_valid():
		_on_hit.call()
	var tween := create_tween().set_parallel()
	tween.tween_property(_impact, "scale", _impact.scale * 2.2, IMPACT_TIME)
	tween.tween_property(_impact, "modulate:a", 0.0, IMPACT_TIME)
	tween.tween_property(_light, "energy", 0.0, IMPACT_TIME)
	tween.chain().tween_interval(FADE_TIME - IMPACT_TIME)
	tween.chain().tween_callback(queue_free)
