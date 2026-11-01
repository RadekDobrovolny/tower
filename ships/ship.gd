class_name Ship
extends Node2D

## Malá loď, která si přiletí natankovat galaxín. Když je slot obsazený, čeká ve frontě,
## a když čeká příliš dlouho, odletí bez placení. Když dojde galaxín, zaplatí jen to, co dostala.

signal landed(ship: Ship)
signal gave_up(ship: Ship)
## Loď z příběhu dotankovala a místo placení čeká, co s ní udělá scéna.
signal skipped_payment(ship: Ship)

enum State { QUEUED, TO_SLOT, LANDED, DEPARTING, TO_PARKING, PARKED }
## Běžná loď, velká nákladní loď (2× větší nádrž) a turistická loď (o 30 % větší nádrž,
## v obchodě utratí 20× víc, přilétá jen ke stanici s hotovým obchodem).
enum Kind { REGULAR, FREIGHTER, TOURIST }

## Běžné rakety: vzhled a povaha. Každá loď dostane náhodně jednu z těch, které mise už odemkla.
## - `name`, `about`: název a popis do Pumpíkova zápisníku
## - `from`: od které mise létá (výchozí 1)
## - `lines`: vlastní hlášky při přistání (bez nich mluví jako každá loď)
## - `patience`: násobek trpělivosti
## - `tank`: násobek velikosti nádrže
## - `tip`: násobek šance na dýško, `tip_size`: násobek jeho výše
## - `full_tank`: nikdy neobjednává za částku, vždy plnou
## - `motel_pay`: kolik platí v motelu místo běžné ceny
## - `brightness`: zjasnění (černá závodní raketa by jinak v temném vesmíru zanikla), `scale`: měřítko
const HULLS := [
	{"name": "Obyčejná raketa", "about": "Každodenní chleba stanice. Přiletí, natankuje a zaplatí.",
			"texture": preload("res://assets/sprites/ships/rocket.png")},
	{"name": "Kufrová raketa", "about": "Malý tahoun s nákladem na zádech. Nikdy si nestěžuje.",
			"texture": preload("res://assets/sprites/ships/rocket_cargo.png")},
	{"name": "Závodní raketa", "about": "Černá a rychlá, v temnotě ji skoro nevidíš.",
			"texture": preload("res://assets/sprites/ships/rocket_racer.png"), "brightness": 1.7},
	{"name": "Stará dříčka", "about": "Pamatuje lepší časy a drží jen ze zvyku.",
			"texture": preload("res://assets/sprites/ships/rocket_workhorse.png"), "brightness": 1.1},
	# Spěchá a má malou nádrž, zato dává dýško častěji.
	{"name": "Žluté taxi", "about": "Taxametr běží, tak spěchá. Pasažér je ale štědrý.",
			"texture": preload("res://assets/sprites/ships/rocket_taxi.png"), "lines": Lines.SHIP_TAXI,
			"patience": 0.7, "tank": 0.7, "tip": 1.5},
	# Zamilovaným nevadí čekat a před partnerkou nešetří.
	{"name": "Romantická raketa", "about": "Dva zamilovaní a okno ve tvaru srdce. Čekání jim nevadí.",
			"texture": preload("res://assets/sprites/ships/rocket_date.png"), "lines": Lines.SHIP_DATE, "from": 2,
			"patience": 1.6, "tank": 0.8, "tip": 2.0},
	# Velká nádrž, ale s dětmi na palubě dlouho nevydrží.
	{"name": "Rodinná raketa", "about": "Velká nádrž a děti na palubě, takže dlouho nevydrží.",
			"texture": preload("res://assets/sprites/ships/rocket_family.png"), "lines": Lines.SHIP_FAMILY, "from": 2,
			"patience": 0.75, "tank": 1.3, "motel_pay": 40, "scale": 0.42},
	# Malá nádrž a velký spěch, dýško skoro nedává.
	{"name": "Kurýrní služba", "about": "Balík měl být doručený včera. Bere jen málo galaxínu.",
			"texture": preload("res://assets/sprites/ships/rocket_courier.png"), "lines": Lines.SHIP_COURIER, "from": 3,
			"patience": 0.55, "tank": 0.6, "tip": 0.5},
	# Pracovní dodávka: velká nádrž, běžná trpělivost.
	{"name": "Dodávka", "about": "Pracovní loď na střední náklady s velkou nádrží.",
			"texture": preload("res://assets/sprites/ships/rocket_van.png"), "lines": Lines.SHIP_VAN, "from": 3,
			"tank": 1.5, "scale": 0.42},
	# Nikam nespěchá, dýško ale nedá nikdy.
	{"name": "Nomádská raketa", "about": "Vozí celý domov s sebou a nikam nespěchá. Dýško nečekej.",
			"texture": preload("res://assets/sprites/ships/rocket_nomad.png"), "lines": Lines.SHIP_NOMAD, "from": 4,
			"patience": 2.0, "tank": 1.2, "tip": 0.0, "scale": 0.42},
	# Veselý obchodník, dobře se s ním vychází.
	{"name": "Zmrzlinářská raketa", "about": "Veselý obchodník, dobře se s ním vychází.",
			"texture": preload("res://assets/sprites/ships/rocket_icecream.png"), "lines": Lines.SHIP_ICECREAM, "from": 4,
			"patience": 1.2, "tank": 0.8, "tip": 1.5},
	# Odtahovka pomáhá ostatním, takže spěchá a nádrž má větší.
	{"name": "Odtahovka", "about": "Pomáhá lodím bez galaxínu, takže sama nemá čas.",
			"texture": preload("res://assets/sprites/ships/rocket_tow.png"), "lines": Lines.SHIP_TOW, "from": 3,
			"patience": 0.8, "tank": 1.3, "scale": 0.42},
	# Pohřební raketa má času dost, jen dýško nedá skoro nikdy.
	{"name": "Pohřební raketa", "about": "Pasažér počká. Řidič je tichý a dýška moc nedává.",
			"texture": preload("res://assets/sprites/ships/rocket_hearse.png"), "lines": Lines.SHIP_HEARSE, "from": 4,
			"patience": 2.0, "tip": 0.3, "scale": 0.42},
	# Císařská hlídka je tu pánem: čekat nebude a dýško nedává.
	{"name": "Císařská hlídka", "about": "Tváří se, že jí patří celá galaxie. Na čekání není zvyklá.",
			"texture": preload("res://assets/sprites/ships/rocket_imperial_patrol.png"), "lines": Lines.SHIP_PATROL, "from": 5,
			"patience": 0.6, "tip": 0.0, "full_tank": true, "scale": 0.42},
	# Velká dýška, ale čekat nebude. Vždy plnou nádrž.
	{"name": "Luxusní limuzína", "about": "Velká dýška, ale čekat nebude. Bere jen plnou nádrž.",
			"texture": preload("res://assets/sprites/ships/rocket_limo.png"), "lines": Lines.SHIP_LIMO, "from": 5,
			"patience": 0.45, "tank": 1.2, "tip": 4.0, "tip_size": 2.5, "full_tank": true, "motel_pay": 50,
			"brightness": 1.3, "scale": 0.5},
	# Má čas i velkou nádrž, šetří každý kredit.
	{"name": "Redneck", "about": "Sudy, rez a paroží. Šetří každý kredit.",
			"texture": preload("res://assets/sprites/ships/rocket_redneck.png"), "lines": Lines.SHIP_REDNECK, "from": 5,
			"patience": 1.3, "tank": 1.3, "tip": 0.3, "scale": 0.42},
]
## Tah motoru, když loď jen visí ve vzduchu (ve frontě). S rychlostí roste až na 1.
const HOVER_THROTTLE := 0.3
## Jak často přiletí nákladní a turistická loď, jejich vzhled a měřítko spritu.
const FREIGHTER_CHANCE := 0.1
const TOURIST_CHANCE := 0.08
const FREIGHTER_TANK := 2.0
const TOURIST_TANK := 1.3
const TOURIST_SHOPPING := 20.0
const FREIGHTER_TEXTURE := preload("res://assets/sprites/ships/freighter.png")
const TOURIST_TEXTURE := preload("res://assets/sprites/ships/tourist.png")
const FREIGHTER_SCALE := 0.5
const TOURIST_SCALE := 0.45

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
## Rychlost lodi z příběhu: pomalé odlétání bez placení a útěk.
const SNEAK_SPEED := 45.0
const DASH_SPEED := 1500.0
const DASH_ACCELERATION := 3500.0
## Jak dlouho (s) a jak silně se loď po zásahu třese.
const SHAKE_TIME := 0.5
const SHAKE_SIZE := 4.0
## Jak dlouho (s) nejvýš loď stojí u prázdné pumpy, když k ní žádná cisterna neletí.
const EMPTY_PUMP_WAIT := 12.0
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
## Když stanice má zábavní systém, jak často loď místo stížnosti komentuje, co běží na plátně.
const TV_COMMENT_CHANCE := 0.5
## Jak často loď nechá dýško (bez zábavního systému) a kolik to je z ceny
## (náhodně v tomhle rozmezí).
const TIP_CHANCE := 0.1
const TIP_SHARE_MIN := 0.1
const TIP_SHARE_MAX := 0.2
const TIP_COLOR := Color(0.45, 0.95, 0.85)
## Mince s dýškem cinkne výš.
const TIP_COIN_PITCH := 1.26
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
var kind := Kind.REGULAR
var fuel: float
## Za kolik kreditů chce loď natankovat. 0 znamená plnou nádrž.
var order_amount := 0

var _target: Vector2
var _patience_left := PATIENCE
var _complained := false
## Loď postavy z příběhu (stejné klíče jako HULLS). Neuteče, nezaplatí a čeká, co s ní udělá scéna.
var story_hull := {}
## Druh běžné rakety z HULLS. Nákladní a turistická loď ho nemají.
var _hull := {}
var _fuel_on_arrival: float
var _target_fuel: float
## Kolik z natankovaného galaxínu bylo nekvalitního.
var _low_quality_fuel := 0.0
## Jestli loď v tomhle snímku dostala nějaký galaxín.
var _got_fuel := false
var _speed := 0.0
var _speed_limit := MAX_SPEED
var _acceleration := ACCELERATION
var _shake_left := 0.0
var _departure_delay := 0.0
var _takeoff_point: Vector2
var _takeoff_scale := 1.0
## Rychlost v posledním snímku, podle ní táhne motor.
var _current_speed := 0.0
## Kolik plateb za motel posádka ještě pošle a za jak dlouho (s) přijde další.
var _motel_payments := 0
var _motel_pay_left := 0.0

@onready var _body: Node2D = $Body
@onready var _sprite: Sprite2D = $Body/Sprite
@onready var _engine: EngineFlame = $Body/EngineFlame
@onready var _fuel_bar: ProgressBar = $FuelBar
@onready var _patience_bar: ProgressBar = $PatienceBar
@onready var _bubble: SpeechBubble = $SpeechBubble


func _ready() -> void:
	var roll := randf()
	if not story_hull.is_empty():
		_hull = story_hull
	elif roll < FREIGHTER_CHANCE:
		kind = Kind.FREIGHTER
	elif roll < FREIGHTER_CHANCE + TOURIST_CHANCE and station.shop_products() >= 0:
		kind = Kind.TOURIST
	else:
		_hull = _random_hull()
	tank_capacity = randf_range(40.0, 100.0) * _tank_factor()
	fuel = tank_capacity * randf_range(0.05, 0.3)
	if kind == Kind.REGULAR and not _hull.get("full_tank", false):
		_choose_order()
	_setup_hull()
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
		State.TO_PARKING:
			_fly_to_parking(delta)
		State.PARKED:
			_stay_in_motel(delta)
	_shake(delta)
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


## Jestli stojí u čerpadla a ještě zaplatí za to, co natankovala. Loď z příběhu sama neplatí.
func owes_payment() -> bool:
	return not is_story() and state == State.LANDED and fuel > _fuel_on_arrival


## Jestli už má loď natankováno, kolik chtěla.
func is_refueled() -> bool:
	return fuel >= _target_fuel


## Zaplatí za natankovaný galaxín, občas přidá dýško a odletí. Vrátí výši dýška (0 = žádné).
func leave_paid() -> int:
	if is_story():
		skipped_payment.emit(self)
		return 0
	var bought := fuel - _fuel_on_arrival
	var price := fuel_price()
	var fined := bought > 0.0 and randf() < _low_quality_fuel / bought * MAX_FINE_CHANCE
	var tip := 0
	if not fined and randf() < (TIP_CHANCE + station.tip_bonus()) * _hull.get("tip", 1.0):
		tip = maxi(1, roundi(price * randf_range(TIP_SHARE_MIN, TIP_SHARE_MAX) * _hull.get("tip_size", 1.0)))
	Game.record_ship_served()
	Game.add_credits(price + tip - (FINE if fined else 0))
	Sfx.play("coin", TIP_COIN_PITCH if tip > 0 else 1.0)
	if fined:
		Sfx.play("fine")
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
	if not station.try_motel_stay(self):
		_depart(PAID_DEPARTURE_DELAY)
	return tip


## Kolik loď dluží za natankovaný galaxín.
func fuel_price() -> int:
	return order_amount if order_amount > 0 else roundi((fuel - _fuel_on_arrival) * station.sell_price)


func is_story() -> bool:
	return not story_hull.is_empty()


## Pomalu odlétá bez placení.
func sneak_away() -> void:
	_speed_limit = SNEAK_SPEED
	_depart(PAID_DEPARTURE_DELAY)


## Posádka si vzala pokoj v motelu: loď přeletí na stání `bay` a pošle `payments` plateb.
func park_at(bay: Vector2, payments: int) -> void:
	_release_slot()
	_target = bay
	_motel_payments = payments
	_motel_pay_left = Motel.PAY_INTERVAL
	_takeoff_point = global_position
	_departure_delay = PAID_DEPARTURE_DELAY
	state = State.TO_PARKING


## Loď z příběhu odletí bez tankování.
func take_off() -> void:
	gave_up.emit(self)
	_depart(PAID_DEPARTURE_DELAY)


## Po zásahu se otřese a velmi rychle zmizí.
func dash_away() -> void:
	_speed_limit = DASH_SPEED
	_acceleration = DASH_ACCELERATION
	_shake_left = SHAKE_TIME
	Sfx.play("metal_hit")
	Sfx.play("ship_takeoff", 1.5)
	_say(Lines.ZORA_ESCAPE)


func _shake(delta: float) -> void:
	if _shake_left <= 0.0:
		return
	_shake_left -= delta
	_body.position = Vector2.ONE.rotated(randf() * TAU) * SHAKE_SIZE if _shake_left > 0.0 else Vector2.ZERO


func _tank_factor() -> float:
	match kind:
		Kind.FREIGHTER:
			return FREIGHTER_TANK
		Kind.TOURIST:
			return TOURIST_TANK
	return _hull.get("tank", 1.0)


func _random_hull() -> Dictionary:
	return HULLS.filter(func(hull: Dictionary) -> bool: return hull.get("from", 1) <= station.ship_tier).pick_random()


func _choose_order() -> void:
	if randf() >= AMOUNT_ORDER_CHANCE:
		return
	var full_tank_price := (tank_capacity - fuel) * station.sell_price
	var affordable := AMOUNT_ORDERS.filter(func(amount: int) -> bool: return amount < full_tank_price)
	if not affordable.is_empty():
		order_amount = affordable.pick_random()


## Trpělivost ubývá rychleji, když je galaxín drahý, a pomaleji, když běží autokino.
func _patience_drain(delta: float) -> float:
	return delta * station.patience_drain() * station.price_patience_factor() / _hull.get("patience", 1.0)


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
## Když žádná cisterna neletí, nemá na co čekat a zábava ani obchod ji tu nezdrží.
func _wait_at_slot(delta: float) -> void:
	if _got_fuel or not station.tank.is_empty():
		_got_fuel = false
		return
	var no_tanker := station.supply.state == Supply.State.IDLE and not is_story()
	_patience_left -= maxf(_patience_drain(delta), delta * PATIENCE / EMPTY_PUMP_WAIT if no_tanker else 0.0)
	_patience_bar.value = _patience_left
	_patience_bar.modulate = PATIENCE_EMPTY_COLOR.lerp(PATIENCE_FULL_COLOR, _patience_left / PATIENCE)
	if _patience_left <= 0.0:
		station.send_ships_away_no_fuel()


## Zásobník je prázdný: loď odletí, a kdo už tankoval, zaplatí jen to, co dostal.
func leave_without_fuel() -> void:
	if is_story():
		return
	_pay_for_partial_fill()
	Game.record_ship_lost()
	Sfx.play("ship_angry")
	_bubble.say_now(Lines.pick(Lines.SHIP_NO_FUEL), true)
	gave_up.emit(self)
	_depart(ANGRY_DEPARTURE_DELAY)


## Galaxín došel dřív, než byla nádrž plná: loď zaplatí, co dostala, ale dýško nedá.
func _pay_for_partial_fill() -> void:
	if state != State.LANDED:
		return
	var price := roundi((fuel - _fuel_on_arrival) * station.sell_price)
	if price > 0:
		Game.add_credits(price)
		Sfx.play("coin")
		FloatingText.spawn(get_parent(), global_position + Vector2(70, -6), "+%d kr" % price)


func _give_up() -> void:
	Game.record_ship_lost()
	Sfx.play("ship_angry")
	_say(Lines.ANGRY_LEAVE, true)
	gave_up.emit(self)
	_depart(ANGRY_DEPARTURE_DELAY)


## Uteče ze stanice, protože útočí piráti: z fronty i od čerpadla, a to, co natankovala,
## nezaplatí (počítá se jako loď, která odletěla bez placení).
func flee() -> void:
	if is_story():
		return
	Game.record_ship_lost()
	Sfx.play("ship_angry")
	_bubble.say_now(Lines.pick(Lines.SHIP_SCARED), true)
	gave_up.emit(self)
	_depart(0.3)


## Uvolní plošinu pro nouzové přistání: zaplatí, co natankovala, a uhne.
func make_way() -> void:
	_pay_for_partial_fill()
	_bubble.say_now(Lines.pick(Lines.SHIP_MAKE_WAY), true)
	gave_up.emit(self)
	_depart(0.3)


func _setup_hull() -> void:
	var brightness := randf_range(0.92, 1.05)
	match kind:
		Kind.FREIGHTER:
			_sprite.texture = FREIGHTER_TEXTURE
			_sprite.scale = Vector2.ONE * FREIGHTER_SCALE
		Kind.TOURIST:
			_sprite.texture = TOURIST_TEXTURE
			_sprite.scale = Vector2.ONE * TOURIST_SCALE
		_:
			_sprite.texture = _hull.texture
			_sprite.scale = Vector2.ONE * _hull.get("scale", _sprite.scale.x)
			# Jemně jiný jas, aby dvě stejné rakety nevypadaly úplně stejně.
			brightness *= _hull.get("brightness", 1.0)
	_sprite.modulate = Color(brightness, brightness, brightness)
	_engine.position.x = -_sprite.texture.get_width() * _sprite.scale.x / 2.0 + 2.0


func _land() -> void:
	global_position = slot.global_position
	Sfx.play("ship_land")
	_body.scale = Vector2.ONE
	_current_speed = 0.0
	_fuel_on_arrival = fuel
	_patience_left = PATIENCE
	_target_fuel = tank_capacity
	if order_amount > 0:
		_target_fuel = minf(fuel + float(order_amount) / station.sell_price, tank_capacity)
	if is_story():
		state = State.LANDED
		landed.emit(self)
		return
	if station.attendant_vocative() and randf() < GREETING_CHANCE:
		_say(Lines.GREETINGS)
	if kind == Kind.TOURIST:
		_say(Lines.TOURISTS)
	elif kind == Kind.FREIGHTER:
		_say(Lines.FREIGHTER_ORDER)
	elif order_amount > 0:
		_say(Lines.ORDER_AMOUNT)
	elif _hull.has("lines"):
		_say(_hull.lines)
	else:
		_say(Lines.ORDER_FULL)
	state = State.LANDED
	landed.emit(self)


func _depart(delay: float) -> void:
	_release_slot()
	_takeoff_point = global_position
	_takeoff_scale = _body.scale.x
	_speed = 0.0
	_departure_delay = delay
	state = State.DEPARTING


func _release_slot() -> void:
	if slot:
		var old_slot := slot
		slot = null
		old_slot.release()


## Přelet na parkoviště: loď se nejdřív zvedne a nad stáním zase klesá.
func _fly_to_parking(delta: float) -> void:
	if _departure_delay > 0.0:
		_departure_delay -= delta
		if _departure_delay <= 0.0:
			Sfx.play("ship_takeoff")
		return
	var arrived := _fly_to(_target, delta, true)
	var lift := clampf(global_position.distance_to(_takeoff_point) / APPROACH_RADIUS, 0.0, 1.0)
	_body.scale = Vector2.ONE * minf(_body.scale.x, lerpf(1.0, FLIGHT_SCALE, lift))
	if arrived:
		global_position = _target
		_body.scale = Vector2.ONE
		_current_speed = 0.0
		Sfx.play("ship_land")
		state = State.PARKED


## Za pobyt se platí průběžně. Po poslední platbě loď uvolní stání a odletí.
func _stay_in_motel(delta: float) -> void:
	_motel_pay_left -= delta
	if _motel_pay_left > 0.0:
		return
	_motel_pay_left += Motel.PAY_INTERVAL
	var price: int = _hull.get("motel_pay", Motel.PAY_AMOUNT)
	station.motel().add_payment(price)
	Game.add_credits(price)
	Sfx.play("coin", Shop.SALE_COIN_PITCH, Shop.SALE_COIN_GAIN_DB)
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -56), "+%d kr motel" % price)
	_motel_payments -= 1
	if _motel_payments <= 0:
		station.parking().release_bay(self)
		_depart(PAID_DEPARTURE_DELAY)


## Na plošině (a před odletem) je motor vypnutý, ve vzduchu táhne podle rychlosti.
func _engine_throttle() -> float:
	if state == State.LANDED or state == State.PARKED or _departure_delay > 0.0:
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
		if _departure_delay <= 0.0:
			Sfx.play("ship_takeoff")
		return
	var target_angle := global_position.direction_to(exit_point).angle()
	_body.rotation = lerp_angle(_body.rotation, target_angle, minf(TURN_SPEED * delta, 1.0))
	_speed = minf(_speed + _acceleration * delta, _speed_limit)
	_current_speed = _speed
	global_position += Vector2.from_angle(_body.rotation) * _speed * delta
	var lift := clampf(global_position.distance_to(_takeoff_point) / APPROACH_RADIUS, 0.0, 1.0)
	_body.scale = Vector2.ONE * lerpf(_takeoff_scale, FLIGHT_SCALE, lift)
	if not Game.visible_world_rect(self).grow(OFFSCREEN_MARGIN).has_point(global_position):
		queue_free()
