class_name Tanker
extends Node2D

## Cisterna dodavatele: přiletí k zásobníku, přečerpá galaxín a zase odletí.
## Pozice jsou v souřadnicích rodiče (uzlu Supply ve stanici).

signal docked

enum State { ARRIVING, UNLOADING, LEAVING }

const MAX_SPEED := 240.0
const ACCELERATION := 200.0
## Na jakou vzdálenost od místa vykládky cisterna začne zpomalovat.
const APPROACH_RADIUS := 220.0

var dock_position: Vector2
var exit_position: Vector2
## Kam vede hadice při přečerpávání (zásobník).
var hose_target: Vector2
var tank_color := Color.WHITE

var state := State.ARRIVING

var _speed := 0.0

@onready var _sprite: Sprite2D = $Body/Sprite
@onready var _hose: Line2D = $Hose
@onready var _bubble: SpeechBubble = $SpeechBubble


func _ready() -> void:
	# Barva dodavatele se do cisterny jen jemně promítne, aby šly dodavatele rozeznat.
	_sprite.modulate = Color.WHITE.lerp(tank_color, 0.35)


func _process(delta: float) -> void:
	match state:
		State.ARRIVING:
			var to_dock := dock_position - position
			var distance := to_dock.length()
			var step := minf(MAX_SPEED * clampf(distance / APPROACH_RADIUS, 0.15, 1.0) * delta, distance)
			position += to_dock.normalized() * step
			if distance - step < 0.5:
				position = dock_position
				_hose.points = PackedVector2Array([Vector2(0, -16), hose_target - position])
				_hose.show()
				state = State.UNLOADING
				docked.emit()
		State.LEAVING:
			_speed = minf(_speed + ACCELERATION * delta, MAX_SPEED)
			position = position.move_toward(exit_position, _speed * delta)
			if position.is_equal_approx(exit_position):
				queue_free()


func say(text: String) -> void:
	_bubble.say(text)


func leave() -> void:
	_hose.hide()
	state = State.LEAVING
