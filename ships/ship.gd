class_name Ship
extends Node2D

## Malá loď, která si přiletí natankovat galaxín. Když je slot obsazený, čeká ve frontě,
## a když čeká příliš dlouho, odletí bez placení.

signal landed(ship: Ship)
signal gave_up(ship: Ship)

enum State { QUEUED, TO_SLOT, LANDED, DEPARTING }

## Vzhledy raket zákazníků. Každá loď dostane náhodně jeden z nich.
const HULL_TEXTURES := [
	preload("res://assets/sprites/ships/rocket.png"),
	preload("res://assets/sprites/ships/rocket_cargo.png"),
	preload("res://assets/sprites/ships/rocket_racer.png"),
	preload("res://assets/sprites/ships/rocket_workhorse.png"),
]
## Zjasnění jednotlivých vzhledů (stejné pořadí). Černá závodní raketa by jinak v temném vesmíru zanikla.
const HULL_BRIGHTNESS := [1.0, 1.0, 1.7, 1.1]
## Tah motoru, když loď jen visí ve vzduchu (ve frontě). S rychlostí roste až na 1.
const HOVER_THROTTLE := 0.3

const MAX_SPEED := 260.0
const ACCELERATION := 220.0
const TURN_SPEED := 4.0
## Na jakou vzdálenost od cíle loď začne zpomalovat a „klesat“.
const APPROACH_RADIUS := 240.0
## Zvětšení lodi ve vzduchu. Na plošině má měřítko 1, takže to vypadá, že přistává.
const FLIGHT_SCALE := 1.35
## Jak daleko za okrajem obrazovky se odlétající loď smaže.
const OFFSCREEN_MARGIN := 100.0
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
## Když stanice má zábavní systém, jak často loď místo stížnosti komentuje televizi.
const TV_COMMENT_CHANCE := 0.5
## Jak často loď nechá dýško (bez zábavního systému) a kolik to je z ceny
## (náhodně v tomhle rozmezí).
const TIP_CHANCE := 0.1
const TIP_SHARE_MIN := 0.1
const TIP_SHARE_MAX := 0.2
const TIP_COLOR := Color(0.45, 0.95, 0.85)
## Pokuta za nekvalitní galaxín. Šance na ni roste s podílem nekvalitního galaxínu v nádrži.
const FINE := 400
const MAX_FINE_CHANCE := 0.2
const FINE_COLOR := Color(1.0, 0.35, 0.3)
## Jak dlouho loď před odletem ještě visí na místě, aby šla přečíst její hláška.
const PAID_DEPARTURE_DELAY := 0.6
const ANGRY_DEPARTURE_DELAY := 1.2

## Bod daleko za okrajem obrazovky, kam loď nakonec odletí.
var exit_point: Vector2
## Stanice, u které loď tankuje. Nastaví ji stanice, když loď přijme.
var station: Station

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
## Kolik z natankovaného galaxínu bylo nekvalitního.
var _low_quality_fuel := 0.0
## Jestli loď v tomhle snímku dostala nějaký galaxín.
var _got_fuel := false
var _speed := 0.0
var _departure_delay := 0.0
var _takeoff_point: Vector2
var _takeoff_scale := 1.0
## Rychlost v posledním snímku, podle ní táhne motor.
var _current_speed := 0.0

@onready var _body: Node2D = $Body
@onready var _sprite: Sprite2D = $Body/Sprite
@onready var _engine: EngineFlame = $Body/EngineFlame
@onready var _fuel_bar: ProgressBar = $FuelBar
@onready var _patience_bar: ProgressBar = $PatienceBar
@onready var _bubble: SpeechBubble = $SpeechBubble


func _ready() -> void:
	tank_capacity = randf_range(40.0, 100.0)
	fuel = tank_capacity * randf_range(0.05, 0.3)
	_choose_order()
	var hull := randi() % HULL_TEXTURES.size()
	_sprite.texture = HULL_TEXTURES[hull]
	# Jemně jiný jas, aby dvě stejné rakety nevypadaly úplně stejně.
	var brightness: float = HULL_BRIGHTNESS[hull] * randf_range(0.92, 1.05)
	_sprite.modulate = Color(brightness, brightness, brightness)
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
		State.LANDED:
			_wait_at_slot(delta)
		State.DEPARTING:
			_fly_away(delta)
	var waiting_for_fuel := state == State.LANDED and _patience_left < PATIENCE
	_patience_bar.visible = state == State.QUEUED or waiting_for_fuel
	_fuel_bar.visible = state == State.LANDED and not waiting_for_fuel
	_engine.target_throttle = _engine_throttle()


## Pošle loď na její místo ve frontě, kde počká, až na ni přijde řada.
func go_to_queue(point: Vector2) -> void:
	_target = point
	state = State.QUEUED


func go_to_slot(fuel_slot: FuelSlot) -> void:
	slot = fuel_slot
	_target = fuel_slot.global_position
	state = State.TO_SLOT


## Kolik galaxínu lodi ještě chybí do toho, co chce natankovat.
func fuel_missing() -> float:
	return maxf(_target_fuel - fuel, 0.0)


## Přidá galaxín. `low_quality_share` je podíl nekvalitního galaxínu v něm (0–1).
func add_fuel(amount: float, low_quality_share := 0.0) -> void:
	var added := minf(amount, fuel_missing())
	fuel += added
	_low_quality_fuel += added * low_quality_share
	_fuel_bar.value = fuel
	if added > 0.0:
		_got_fuel = true
		# Když loď zase tankuje, trpělivost u slotu se obnoví.
		_patience_left = PATIENCE


## Jestli už má loď natankováno, kolik chtěla.
func is_refueled() -> bool:
	return fuel >= _target_fuel


## Zaplatí za natankovaný galaxín, občas přidá dýško a odletí. Vrátí výši dýška (0 = žádné).
func leave_paid() -> int:
	var bought := fuel - _fuel_on_arrival
	var price := order_amount if order_amount > 0 else roundi(bought * station.sell_price)
	var fined := bought > 0.0 and randf() < _low_quality_fuel / bought * MAX_FINE_CHANCE
	var tip := 0
	if not fined and randf() < TIP_CHANCE + station.tip_bonus():
		tip = maxi(1, roundi(price * randf_range(TIP_SHARE_MIN, TIP_SHARE_MAX)))
	Game.record_ship_served()
	Game.add_credits(price + tip - (FINE if fined else 0))
	# Vedle lodi, aby se nepřekrýval s bublinou nad ní.
	FloatingText.spawn(get_parent(), global_position + Vector2(70, -6), "+%d kr" % price)
	if fined:
		FloatingText.spawn(get_parent(), global_position + Vector2(70, 18), "-%d kr pokuta" % FINE, FINE_COLOR)
		_say(Lines.QUALITY_COMPLAINT, true)
	elif tip > 0:
		FloatingText.spawn(get_parent(), global_position + Vector2(70, 18), "+%d kr dýško" % tip, TIP_COLOR)
		_say(Lines.TIP)
	elif randf() < THANKS_CHANCE:
		_say(Lines.HAPPY_LEAVE)
	_depart(PAID_DEPARTURE_DELAY)
	return tip


func _choose_order() -> void:
	if randf() >= AMOUNT_ORDER_CHANCE:
		return
	var full_tank_price := (tank_capacity - fuel) * station.sell_price
	var affordable := AMOUNT_ORDERS.filter(func(amount: int) -> bool: return amount < full_tank_price)
	if not affordable.is_empty():
		order_amount = affordable.pick_random()


## Trpělivost ubývá rychleji, když je galaxín drahý, a pomaleji, když běží televize.
func _patience_drain(delta: float) -> float:
	return delta * station.patience_drain() * station.price_patience_factor()


func _wait_in_queue(delta: float) -> void:
	_patience_left -= _patience_drain(delta)
	_patience_bar.value = _patience_left
	_patience_bar.modulate = PATIENCE_EMPTY_COLOR.lerp(PATIENCE_FULL_COLOR, _patience_left / PATIENCE)
	if not _complained and _patience_left < PATIENCE / 2.0:
		_complained = true
		if station.entertainment_level() > 0 and randf() < TV_COMMENT_CHANCE:
			_say(Lines.TV_COMMENTS)
		elif randf() < COMPLAINT_CHANCE:
			_say(Lines.IMPATIENT)
	if _patience_left <= 0.0:
		_give_up()
	else:
		_fly_to(_target, delta, false)


## Zakotvená loď ztrácí trpělivost jen tehdy, když nedostává galaxín (došel v zásobníku).
func _wait_at_slot(delta: float) -> void:
	if _got_fuel or not station.tank.is_empty():
		_got_fuel = false
		return
	_patience_left -= _patience_drain(delta)
	_patience_bar.value = _patience_left
	_patience_bar.modulate = PATIENCE_EMPTY_COLOR.lerp(PATIENCE_FULL_COLOR, _patience_left / PATIENCE)
	if _patience_left <= 0.0:
		_give_up()


func _give_up() -> void:
	Game.record_ship_lost()
	_say(Lines.ANGRY_LEAVE, true)
	gave_up.emit(self)
	_depart(ANGRY_DEPARTURE_DELAY)


func _land() -> void:
	global_position = slot.global_position
	_body.scale = Vector2.ONE
	_current_speed = 0.0
	_fuel_on_arrival = fuel
	_patience_left = PATIENCE
	_target_fuel = tank_capacity
	if order_amount > 0:
		_target_fuel = minf(fuel + float(order_amount) / station.sell_price, tank_capacity)
	if station.attendant_vocative() and randf() < GREETING_CHANCE:
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
	_takeoff_point = global_position
	_takeoff_scale = _body.scale.x
	_speed = 0.0
	_departure_delay = delay
	state = State.DEPARTING


## Na plošině (a před odletem) je motor vypnutý, ve vzduchu táhne podle rychlosti.
func _engine_throttle() -> float:
	if state == State.LANDED or (state == State.DEPARTING and _departure_delay > 0.0):
		return 0.0
	return HOVER_THROTTLE + (1.0 - HOVER_THROTTLE) * clampf(_current_speed / MAX_SPEED, 0.0, 1.0)


func _say(lines: Array, angry := false) -> void:
	_bubble.say(Lines.pick(lines, {"android": station.attendant_vocative(), "amount": order_amount}), angry)


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
	_current_speed = step / delta if delta > 0.0 else 0.0
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
	_current_speed = _speed
	global_position += Vector2.from_angle(_body.rotation) * _speed * delta
	var lift := clampf(global_position.distance_to(_takeoff_point) / APPROACH_RADIUS, 0.0, 1.0)
	_body.scale = Vector2.ONE * lerpf(_takeoff_scale, FLIGHT_SCALE, lift)
	if not get_viewport_rect().grow(OFFSCREEN_MARGIN).has_point(global_position):
		queue_free()
