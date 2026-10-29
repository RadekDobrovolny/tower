class_name Ship
extends Node2D

## Malá loď, která přiletí k čerpacímu slotu, natankuje, zaplatí a odletí.

enum State { ARRIVING, FUELING, DEPARTING }

const MAX_SPEED := 260.0
const ACCELERATION := 220.0
const TURN_SPEED := 4.0
## Na jakou vzdálenost od plošiny loď začne zpomalovat a „klesat“.
const APPROACH_RADIUS := 240.0
## Zvětšení lodi ve vzduchu. Na plošině má měřítko 1, takže to vypadá, že přistává.
const FLIGHT_SCALE := 1.35
## Jak daleko za okrajem obrazovky se odlétající loď smaže.
const OFFSCREEN_MARGIN := 100.0
## Kolik kreditů stojí jedna jednotka paliva.
const FUEL_PRICE := 2.0

## Slot, ke kterému loď letí. Nastaví ho spawner před přidáním do scény.
var slot: FuelSlot
## Bod daleko za okrajem obrazovky, kam loď po natankování odletí.
var exit_point: Vector2

var state := State.ARRIVING
var tank_capacity: float
var fuel: float

var _fuel_on_arrival: float
var _speed := 0.0
var _takeoff_point: Vector2

@onready var _body: Node2D = $Body
@onready var _hull: Polygon2D = $Body/Hull
@onready var _engine_flame: Polygon2D = $Body/EngineFlame
@onready var _fuel_bar: ProgressBar = $FuelBar


func _ready() -> void:
	tank_capacity = randf_range(40.0, 100.0)
	fuel = tank_capacity * randf_range(0.05, 0.3)
	_hull.color = Color.from_hsv(randf(), 0.35, 0.95)
	_fuel_bar.max_value = tank_capacity
	_fuel_bar.value = fuel
	_body.rotation = global_position.direction_to(slot.global_position).angle()
	_body.scale = Vector2.ONE * FLIGHT_SCALE


func _process(delta: float) -> void:
	match state:
		State.ARRIVING:
			_approach_slot(delta)
		State.FUELING:
			_refuel(delta)
		State.DEPARTING:
			_fly_away(delta)


func _approach_slot(delta: float) -> void:
	var to_slot := slot.global_position - global_position
	var distance := to_slot.length()
	var closeness := clampf(distance / APPROACH_RADIUS, 0.0, 1.0)
	var step := minf(MAX_SPEED * maxf(closeness, 0.1) * delta, distance)
	global_position += to_slot.normalized() * step
	_body.scale = Vector2.ONE * lerpf(1.0, FLIGHT_SCALE, closeness)
	if distance - step < 0.5:
		_land()


func _land() -> void:
	global_position = slot.global_position
	_body.scale = Vector2.ONE
	_engine_flame.hide()
	_fuel_bar.show()
	_fuel_on_arrival = fuel
	state = State.FUELING


func _refuel(delta: float) -> void:
	fuel = minf(fuel + slot.pump_rate * delta, tank_capacity)
	_fuel_bar.value = fuel
	if fuel >= tank_capacity:
		_pay_and_leave()


func _pay_and_leave() -> void:
	var price := roundi((tank_capacity - _fuel_on_arrival) * FUEL_PRICE)
	Game.add_credits(price)
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -40), "+%d kr" % price)
	slot.release()
	_fuel_bar.hide()
	_engine_flame.show()
	_takeoff_point = global_position
	state = State.DEPARTING


func _fly_away(delta: float) -> void:
	var target_angle := global_position.direction_to(exit_point).angle()
	_body.rotation = lerp_angle(_body.rotation, target_angle, minf(TURN_SPEED * delta, 1.0))
	_speed = minf(_speed + ACCELERATION * delta, MAX_SPEED)
	global_position += Vector2.from_angle(_body.rotation) * _speed * delta
	var lift := clampf(global_position.distance_to(_takeoff_point) / APPROACH_RADIUS, 0.0, 1.0)
	_body.scale = Vector2.ONE * lerpf(1.0, FLIGHT_SCALE, lift)
	if not get_viewport_rect().grow(OFFSCREEN_MARGIN).has_point(global_position):
		queue_free()
