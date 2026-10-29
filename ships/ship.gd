class_name Ship
extends Node2D

## Malá loď, která si přiletí natankovat galaxín. Když je slot obsazený, čeká ve frontě,
## a když čeká příliš dlouho, odletí bez placení.

signal landed(ship: Ship)
signal gave_up(ship: Ship)

enum State { QUEUED, TO_SLOT, LANDED, DEPARTING }

const MAX_SPEED := 260.0
const ACCELERATION := 220.0
const TURN_SPEED := 4.0
## Na jakou vzdálenost od cíle loď začne zpomalovat a „klesat“.
const APPROACH_RADIUS := 240.0
## Zvětšení lodi ve vzduchu. Na plošině má měřítko 1, takže to vypadá, že přistává.
const FLIGHT_SCALE := 1.35
## Jak daleko za okrajem obrazovky se odlétající loď smaže.
const OFFSCREEN_MARGIN := 100.0
## Kolik kreditů stojí jedna jednotka galaxínu.
const FUEL_PRICE := 6.0
## Jak dlouho (s) loď vydrží čekat ve frontě, než odletí.
const PATIENCE := 20.0
const PATIENCE_FULL_COLOR := Color(1.0, 0.85, 0.3)
const PATIENCE_EMPTY_COLOR := Color(1.0, 0.3, 0.25)
## Jak často loď nechce plnou nádrž, ale galaxín jen za určitou částku.
const AMOUNT_ORDER_CHANCE := 0.35
const AMOUNT_ORDERS := [100, 150, 200, 250]
## Jak často loď při přistání pozdraví androida a po zaplacení poděkuje.
const GREETING_CHANCE := 0.5
const THANKS_CHANCE := 0.5
## Jak často si loď ve frontě postěžuje, když jí dojde půlka trpělivosti.
const COMPLAINT_CHANCE := 0.6
## Jak často loď nechá dýško a kolik to je z ceny (náhodně v tomhle rozmezí).
const TIP_CHANCE := 0.1
const TIP_SHARE_MIN := 0.1
const TIP_SHARE_MAX := 0.2
const TIP_COLOR := Color(0.45, 0.95, 0.85)
## Jak dlouho loď před odletem ještě visí na místě, aby šla přečíst její hláška.
const PAID_DEPARTURE_DELAY := 0.6
const ANGRY_DEPARTURE_DELAY := 1.2

## Bod daleko za okrajem obrazovky, kam loď nakonec odletí.
var exit_point: Vector2
## Jméno androida v 5. pádě, kterým ho loď oslovuje. Nastaví stanice.
var attendant_vocative := ""

var state := State.QUEUED
var slot: FuelSlot
var tank_capacity: float
var fuel: float
## Za kolik kreditů chce loď natankovat. 0 znamená plnou nádrž.
var order_amount := 0

var _target: Vector2
var _patience_left := PATIENCE
var _complained := false
var _fuel_on_arrival: float
var _target_fuel: float
var _speed := 0.0
var _departure_delay := 0.0
var _takeoff_point: Vector2
var _takeoff_scale := 1.0

@onready var _body: Node2D = $Body
@onready var _hull: Polygon2D = $Body/Hull
@onready var _engine_flame: Polygon2D = $Body/EngineFlame
@onready var _fuel_bar: ProgressBar = $FuelBar
@onready var _patience_bar: ProgressBar = $PatienceBar
@onready var _bubble: SpeechBubble = $SpeechBubble


func _ready() -> void:
	tank_capacity = randf_range(40.0, 100.0)
	fuel = tank_capacity * randf_range(0.05, 0.3)
	_choose_order()
	_hull.color = Color.from_hsv(randf(), 0.35, 0.95)
	_fuel_bar.max_value = tank_capacity
	_fuel_bar.value = fuel
	_patience_bar.max_value = PATIENCE
	_body.rotation = global_position.direction_to(_target).angle()
	_body.scale = Vector2.ONE * FLIGHT_SCALE


func _process(delta: float) -> void:
	match state:
		State.QUEUED:
			_wait_in_queue(delta)
		State.TO_SLOT:
			if _fly_to(slot.global_position, delta, true):
				_land()
		State.DEPARTING:
			_fly_away(delta)
	_patience_bar.visible = state == State.QUEUED
	_fuel_bar.visible = state == State.LANDED


## Pošle loď na dané místo ve frontě. Volá se i při posunu fronty.
func go_to_queue(point: Vector2) -> void:
	_target = point
	state = State.QUEUED


func go_to_slot(fuel_slot: FuelSlot) -> void:
	slot = fuel_slot
	_target = fuel_slot.global_position
	state = State.TO_SLOT


func add_fuel(amount: float) -> void:
	fuel = minf(fuel + amount, _target_fuel)
	_fuel_bar.value = fuel


## Jestli už má loď natankováno, kolik chtěla.
func is_refueled() -> bool:
	return fuel >= _target_fuel


## Zaplatí za natankovaný galaxín, občas přidá dýško a odletí. Vrátí výši dýška (0 = žádné).
func leave_paid() -> int:
	var price := order_amount if order_amount > 0 else roundi((fuel - _fuel_on_arrival) * FUEL_PRICE)
	var tip := 0
	if randf() < TIP_CHANCE:
		tip = maxi(1, roundi(price * randf_range(TIP_SHARE_MIN, TIP_SHARE_MAX)))
	Game.record_ship_served()
	Game.add_credits(price + tip)
	# Vedle lodi, aby se nepřekrýval s bublinou nad ní.
	FloatingText.spawn(get_parent(), global_position + Vector2(70, -6), "+%d kr" % price)
	if tip > 0:
		FloatingText.spawn(get_parent(), global_position + Vector2(70, 18), "+%d kr dýško" % tip, TIP_COLOR)
		_say(Lines.TIP)
	elif randf() < THANKS_CHANCE:
		_say(Lines.HAPPY_LEAVE)
	_depart(PAID_DEPARTURE_DELAY)
	return tip


func _choose_order() -> void:
	if randf() >= AMOUNT_ORDER_CHANCE:
		return
	var full_tank_price := (tank_capacity - fuel) * FUEL_PRICE
	var affordable := AMOUNT_ORDERS.filter(func(amount: int) -> bool: return amount < full_tank_price)
	if not affordable.is_empty():
		order_amount = affordable.pick_random()


func _wait_in_queue(delta: float) -> void:
	_patience_left -= delta
	_patience_bar.value = _patience_left
	_patience_bar.modulate = PATIENCE_EMPTY_COLOR.lerp(PATIENCE_FULL_COLOR, _patience_left / PATIENCE)
	if not _complained and _patience_left < PATIENCE / 2.0:
		_complained = true
		if randf() < COMPLAINT_CHANCE:
			_say(Lines.IMPATIENT)
	if _patience_left <= 0.0:
		_give_up()
	else:
		_fly_to(_target, delta, false)


func _give_up() -> void:
	Game.record_ship_lost()
	_say(Lines.ANGRY_LEAVE, true)
	gave_up.emit(self)
	_depart(ANGRY_DEPARTURE_DELAY)


func _land() -> void:
	global_position = slot.global_position
	_body.scale = Vector2.ONE
	_engine_flame.hide()
	_fuel_on_arrival = fuel
	_target_fuel = tank_capacity
	if order_amount > 0:
		_target_fuel = minf(fuel + order_amount / FUEL_PRICE, tank_capacity)
	if attendant_vocative and randf() < GREETING_CHANCE:
		_say(Lines.GREETINGS)
	if order_amount > 0:
		_say(Lines.ORDER_AMOUNT)
	else:
		_say(Lines.ORDER_FULL)
	state = State.LANDED
	landed.emit(self)


func _depart(delay: float) -> void:
	if slot:
		var old_slot := slot
		slot = null
		old_slot.release()
	_engine_flame.show()
	_takeoff_point = global_position
	_takeoff_scale = _body.scale.x
	_speed = 0.0
	_departure_delay = delay
	state = State.DEPARTING


func _say(lines: Array, angry := false) -> void:
	_bubble.say(Lines.pick(lines, {"android": attendant_vocative, "amount": order_amount}), angry)


## Přiblíží loď k cíli, u cíle zpomalí. Když loď přistává, zároveň „klesá“.
## Vrátí true, když loď dorazila.
func _fly_to(target: Vector2, delta: float, landing: bool) -> bool:
	var to_target := target - global_position
	var distance := to_target.length()
	if distance > 4.0:
		_body.rotation = lerp_angle(_body.rotation, to_target.angle(), minf(TURN_SPEED * delta, 1.0))
	var closeness := clampf(distance / APPROACH_RADIUS, 0.0, 1.0)
	var step := minf(MAX_SPEED * maxf(closeness, 0.2) * delta, distance)
	global_position += to_target.normalized() * step
	if landing:
		_body.scale = Vector2.ONE * lerpf(1.0, FLIGHT_SCALE, closeness)
	return distance - step < 0.5


func _fly_away(delta: float) -> void:
	if _departure_delay > 0.0:
		_departure_delay -= delta
		return
	var target_angle := global_position.direction_to(exit_point).angle()
	_body.rotation = lerp_angle(_body.rotation, target_angle, minf(TURN_SPEED * delta, 1.0))
	_speed = minf(_speed + ACCELERATION * delta, MAX_SPEED)
	global_position += Vector2.from_angle(_body.rotation) * _speed * delta
	var lift := clampf(global_position.distance_to(_takeoff_point) / APPROACH_RADIUS, 0.0, 1.0)
	_body.scale = Vector2.ONE * lerpf(_takeoff_scale, FLIGHT_SCALE, lift)
	if not get_viewport_rect().grow(OFFSCREEN_MARGIN).has_point(global_position):
		queue_free()
