class_name Tanker
extends Node2D

## Cisterna dodavatele: přiletí k zásobníku, přečerpá galaxín a zase odletí. Při odletu si
## vybere náhodný směr pryč od stanice, natočí se do něj a odletí přídí napřed.
## Poškozená cisterna hoří, letí pomalu a nouzově přistává na plošině. Po opravě letí k zásobníku.
## Pozice jsou v souřadnicích rodiče (uzlu Supply ve stanici).

signal docked
## Poškozená cisterna přistála na plošině.
signal landed

enum State { ARRIVING, UNLOADING, LEAVING, LANDED }

const MAX_SPEED := 240.0
const ACCELERATION := 200.0
## Na jakou vzdálenost od místa vykládky cisterna začne zpomalovat.
const APPROACH_RADIUS := 220.0
## Tah motoru, když cisterna skoro stojí. S rychlostí roste až na 1.
const IDLE_THROTTLE := 0.3
const TURN_SPEED := 2.0
## Na jakou vzdálenost od cíle se cisterna srovná do polohy pro kotvení.
const LEVEL_OUT_RADIUS := 60.0
## Poškozená cisterna: násobek rychlosti, jak se třese, jak je ztmavená a jak bliká oheň.
const DAMAGED_SPEED := 0.55
const SHAKE_SIZE := 1.5
const DAMAGED_TINT := Color(0.62, 0.56, 0.52)
const FIRE_LIGHT_ENERGY := 1.0
const FIRE_FLICKER := 0.3
## Rozsah směrů odletu (úhel, 0 = doprava, PI/2 = dolů): někam dolů od stanice, ne přes ni.
const EXIT_ANGLE_MIN := 0.15 * PI
const EXIT_ANGLE_MAX := 0.9 * PI
## Jak daleko za okrajem obrazovky se odlétající cisterna smaže.
const OFFSCREEN_MARGIN := 120.0

var dock_position: Vector2
## Kam vede hadice při přečerpávání (zásobník).
var hose_target: Vector2
var tank_color := Color.WHITE
var damaged := false
## Zakázka stavebního drona na opravu, nebo null.
var job: ConstructionJob

var state := State.ARRIVING

## Kde cisterna přečerpává, když kvůli opravě přistála jinde.
var _unload_position: Vector2
var _time := 0.0
var _speed := 0.0
var _current_speed := 0.0
var _exit_angle := 0.0

@onready var _body: Node2D = $Body
@onready var _sprite: Sprite2D = $Body/Sprite
@onready var _engine: EngineFlame = $Body/EngineFlame
@onready var _hose: Line2D = $Hose
@onready var _bubble: SpeechBubble = $SpeechBubble
@onready var _fire: CPUParticles2D = $Body/Fire
@onready var _smoke: CPUParticles2D = $Body/Smoke
@onready var _fire_light: PointLight2D = $Body/FireLight


func _ready() -> void:
	# Barva dodavatele se do cisterny jen jemně promítne, aby šly dodavatele rozeznat.
	_sprite.modulate = Color.WHITE.lerp(tank_color, 0.35)


func _process(delta: float) -> void:
	_time += delta
	match state:
		State.ARRIVING:
			var to_dock := dock_position - position
			var distance := to_dock.length()
			var top_speed := MAX_SPEED * (DAMAGED_SPEED if damaged else 1.0)
			var step := minf(top_speed * clampf(distance / APPROACH_RADIUS, 0.15, 1.0) * delta, distance)
			position += to_dock.normalized() * step
			_current_speed = step / delta if delta > 0.0 else 0.0
			var heading := to_dock.angle() if distance > LEVEL_OUT_RADIUS else 0.0
			_body.rotation = lerp_angle(_body.rotation, heading, minf(TURN_SPEED * delta, 1.0))
			if distance - step < 0.5:
				position = dock_position
				_arrive()
		State.LEAVING:
			_body.rotation = lerp_angle(_body.rotation, _exit_angle, minf(TURN_SPEED * delta, 1.0))
			_speed = minf(_speed + ACCELERATION * delta, MAX_SPEED)
			_current_speed = _speed
			position += Vector2.from_angle(_body.rotation) * _speed * delta
			if not Game.visible_world_rect(self).grow(OFFSCREEN_MARGIN).has_point(global_position):
				queue_free()
	_engine.target_throttle = 0.0 if state == State.UNLOADING or state == State.LANDED \
			else IDLE_THROTTLE + (1.0 - IDLE_THROTTLE) * clampf(_current_speed / MAX_SPEED, 0.0, 1.0)
	_body.position = Vector2.ONE.rotated(randf() * TAU) * SHAKE_SIZE \
			if damaged and state == State.ARRIVING else Vector2.ZERO
	if damaged:
		_fire_light.energy = FIRE_LIGHT_ENERGY + FIRE_FLICKER * sin(_time * 14.0)


## Cisterna začne hořet.
func set_damaged() -> void:
	damaged = true
	_show_fire(true)
	_sprite.modulate *= DAMAGED_TINT


## Místo k zásobníku nouzově přistane na `point` (souřadnice rodiče).
func land_at(point: Vector2) -> void:
	_unload_position = dock_position
	dock_position = point


## Dron cisternu opravil: oheň zhasne a sprite dostane zpátky svoji barvu.
func repair() -> void:
	damaged = false
	_show_fire(false)
	_sprite.modulate = Color.WHITE.lerp(tank_color, 0.35)


## Po opravě doletí k zásobníku a dokončí dodávku.
func return_to_dock() -> void:
	dock_position = _unload_position
	state = State.ARRIVING


func info_title() -> String:
	return "Cisterna"


func say(text: String) -> void:
	_bubble.say(text)


## Hláška při útěku před piráty, přeruší to, co cisterna právě říká.
func say_scared(text: String) -> void:
	_bubble.say_now(text, true)


func _arrive() -> void:
	if damaged:
		_current_speed = 0.0
		state = State.LANDED
		landed.emit()
		return
	_hose.points = PackedVector2Array([Vector2(0, -16), hose_target - position])
	_hose.show()
	state = State.UNLOADING
	docked.emit()


func _show_fire(burning: bool) -> void:
	_fire.emitting = burning
	_smoke.emitting = burning
	_fire_light.visible = burning


func leave() -> void:
	_hose.hide()
	_exit_angle = randf_range(EXIT_ANGLE_MIN, EXIT_ANGLE_MAX)
	# Cisterna, která ještě přilétala (útok pirátů), odlétá bez zastavení.
	_speed = _current_speed if state == State.ARRIVING else 0.0
	_current_speed = 0.0
	state = State.LEAVING
