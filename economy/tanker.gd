class_name Tanker
extends Node2D

## Cisterna dodavatele: přiletí k zásobníku, přečerpá galaxín a zase odletí. Při odletu si
## vybere náhodný směr pryč od stanice, natočí se do něj a odletí přídí napřed.
## Pozice jsou v souřadnicích rodiče (uzlu Supply ve stanici).

signal docked

enum State { ARRIVING, UNLOADING, LEAVING }

const MAX_SPEED := 240.0
const ACCELERATION := 200.0
## Na jakou vzdálenost od místa vykládky cisterna začne zpomalovat.
const APPROACH_RADIUS := 220.0
## Tah motoru, když cisterna skoro stojí. S rychlostí roste až na 1.
const IDLE_THROTTLE := 0.3
const TURN_SPEED := 2.0
## Rozsah směrů odletu (úhel, 0 = doprava, PI/2 = dolů): někam dolů od stanice, ne přes ni.
const EXIT_ANGLE_MIN := 0.15 * PI
const EXIT_ANGLE_MAX := 0.9 * PI
## Jak daleko za okrajem obrazovky se odlétající cisterna smaže.
const OFFSCREEN_MARGIN := 120.0

var dock_position: Vector2
## Kam vede hadice při přečerpávání (zásobník).
var hose_target: Vector2
var tank_color := Color.WHITE

var state := State.ARRIVING

var _speed := 0.0
var _current_speed := 0.0
var _exit_angle := 0.0

@onready var _body: Node2D = $Body
@onready var _sprite: Sprite2D = $Body/Sprite
@onready var _engine: EngineFlame = $Body/EngineFlame
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
			_current_speed = step / delta if delta > 0.0 else 0.0
			if distance - step < 0.5:
				position = dock_position
				_hose.points = PackedVector2Array([Vector2(0, -16), hose_target - position])
				_hose.show()
				state = State.UNLOADING
				docked.emit()
		State.LEAVING:
			_body.rotation = lerp_angle(_body.rotation, _exit_angle, minf(TURN_SPEED * delta, 1.0))
			_speed = minf(_speed + ACCELERATION * delta, MAX_SPEED)
			_current_speed = _speed
			position += Vector2.from_angle(_body.rotation) * _speed * delta
			if not Game.visible_world_rect(self).grow(OFFSCREEN_MARGIN).has_point(global_position):
				queue_free()
	_engine.target_throttle = 0.0 if state == State.UNLOADING \
			else IDLE_THROTTLE + (1.0 - IDLE_THROTTLE) * clampf(_current_speed / MAX_SPEED, 0.0, 1.0)


func say(text: String) -> void:
	_bubble.say(text)


func leave() -> void:
	_hose.hide()
	_exit_angle = randf_range(EXIT_ANGLE_MIN, EXIT_ANGLE_MAX)
	_current_speed = 0.0
	state = State.LEAVING
