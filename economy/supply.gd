class_name Supply
extends Node2D

## Objednávky galaxínu od dodavatelů. Hráč zaplatí cisternu předem, ta po čase přiletí
## k zásobníku a přečerpá galaxín. Za to, co nedoveze nebo co se nevejde, vrátí peníze.
## Řídící centrum u zásobníku dodávky vylepšuje a s dispečinkem objednává cisterny samo.
## Když útočí piráti, cisterny nelétají: objednávka se zruší a cisterna u stanice odletí.
## Při císařském embargu prodává jen šmelinář Lojza, a to dráž.

enum State { IDLE, ORDERED, ARRIVING, UNLOADING }

const TANKER_SCENE := preload("res://economy/tanker.tscn")
## Jak rychle cisterna přečerpává do zásobníku (jednotky/s).
const UNLOAD_RATE := 150.0
const REFUND_COLOR := Color(0.45, 0.95, 0.85)
const DISPATCH_COLOR := Color(0.55, 0.85, 1.0)
## Menší dávku vypije jedna loď a z toho se stanice nevzpamatuje.
const USEFUL_UNITS := 50

## Dodavatelé: cena za jednotku, velikost cisterny, doba dodání (s), šance a délka
## zpoždění (s), šance a rozsah poloprázdné cisterny (podíl objednaného), kvalita a barva.
const SUPPLIERS := [
	{
		"name": "Šmelinář Lojza", "short_name": "Lojza", "price": 2.0, "units": 400,
		"lead_time": 12.0, "delay_chance": 0.35, "delay_min": 10.0, "delay_max": 20.0,
		"short_chance": 0.3, "short_min": 0.3, "short_max": 0.6,
		"low_quality": true, "color": Color(0.6, 0.42, 0.28),
		"info": "Levný, ale nekvalitní galaxín: hrozí pokuty. Často mešká a doveze méně.",
	},
	{
		"name": "Galaxis Distribuce", "short_name": "Galaxis", "price": 3.0, "units": 400,
		"lead_time": 10.0, "delay_chance": 0.2, "delay_min": 6.0, "delay_max": 12.0,
		"short_chance": 0.15, "short_min": 0.5, "short_max": 0.5,
		"low_quality": false, "color": Color(0.35, 0.55, 0.9),
		"info": "Kvalitní galaxín. Občas se zpozdí nebo přiveze poloprázdnou cisternu.",
	},
	{
		"name": "Orion Premium", "short_name": "Orion", "price": 4.0, "units": 600,
		"lead_time": 8.0, "delay_chance": 0.0, "delay_min": 0.0, "delay_max": 0.0,
		"short_chance": 0.0, "short_min": 1.0, "short_max": 1.0,
		"low_quality": false, "color": Color(0.95, 0.9, 0.75),
		"info": "Prémiová kvalita. Vždy včas a s plnou velkou cisternou.",
	},
]

## Index šmelináře Lojzy v SUPPLIERS: jediný, kdo embargo obchází, a kolik si při něm řekne.
const BLACK_MARKET := 0
const EMBARGO_PRICE := 6.0
const EMBARGO_INFO := "Císařské embargo: zbyl jen Lojza a zdražil. Jeho galaxín je nekvalitní, hrozí pokuty."

## Kde cisterna zakotví a odkud přilétá (souřadnice stanice).
@export var dock_position := Vector2(-230, 85)
@export var spawn_position := Vector2(-780, 60)

## Zásobník, do kterého se přečerpává, a stanice (kvůli řídícímu centru). Nastaví je stanice.
var tank: GalaxinTank
var station: Station
## Index vybraného dodavatele v SUPPLIERS.
var selected := 1
var state := State.IDLE
var embargo := false

var _supplier: Dictionary
## Cena za jednotku v aktuální objednávce, podle ní se vrací peníze.
var _unit_price := 0.0
var _ordered_units := 0
var _units_to_deliver := 0.0
var _delivered := 0.0
var _time_left := 0.0
var _expected_left := 0.0
var _late := false
var _tanker: Tanker


func _process(delta: float) -> void:
	match state:
		State.IDLE:
			_dispatch()
		State.ORDERED:
			_time_left -= delta
			_expected_left -= delta
			if _time_left <= 0.0:
				_send_tanker()
		State.UNLOADING:
			var units := minf(UNLOAD_RATE * _modifier("unloading") * delta, _units_to_deliver - _delivered)
			# Filtry v řídícím centru odstraní část nekvalitního galaxínu.
			var low_quality_share: float = _modifier("purification") if _supplier.low_quality else 0.0
			var accepted := tank.fill(units, low_quality_share)
			_delivered += accepted
			if accepted < units or _delivered >= _units_to_deliver:
				_finish_delivery()


func selected_supplier() -> Dictionary:
	return SUPPLIERS[selected]


## Zapne nebo vypne embargo. Při něm jde objednávat jen od Lojzy.
func set_embargo(value: bool) -> void:
	embargo = value
	if embargo:
		selected = BLACK_MARKET


func is_available(index: int) -> bool:
	return not embargo or index == BLACK_MARKET


## Cena za jednotku u dodavatele s tímhle indexem.
func unit_price(index: int) -> float:
	return EMBARGO_PRICE if embargo and index == BLACK_MARKET else SUPPLIERS[index].price


## Popis vybraného dodavatele pro HUD.
func info_text() -> String:
	return EMBARGO_INFO if embargo else selected_supplier().info


## Kolik jednotek by šlo teď objednat: velikost cisterny, ale nejvýš volné místo v zásobníku
## a nejvýš tolik, kolik hráč zaplatí (aby se hra nezasekla, když dojde galaxín i kredity).
func order_units() -> int:
	return mini(max_order_units(), floori(maxi(Game.credits, 0) / unit_price(selected)))


## Kolik jednotek by šlo objednat, kdyby na to hráč měl.
func max_order_units() -> int:
	return mini(roundi(selected_supplier().units * _modifier("capacity")), floori(tank.free_space()))


func order_cost() -> int:
	return roundi(order_units() * unit_price(selected))


## Jestli má hráč aspoň na užitečnou dávku od nejlevnějšího dodavatele.
func can_afford_useful_tanker() -> bool:
	for i in SUPPLIERS.size():
		if is_available(i) and Game.credits >= unit_price(i) * USEFUL_UNITS:
			return true
	return false


func can_order() -> bool:
	return state == State.IDLE and order_units() > 0 and Game.credits >= order_cost() \
			and not station.under_attack()


## Objedná a předem zaplatí cisternu u vybraného dodavatele. Vrátí, jestli se to povedlo.
func order() -> bool:
	if not can_order():
		return false
	_supplier = selected_supplier()
	_unit_price = unit_price(selected)
	_ordered_units = order_units()
	Game.spend_credits(order_cost())
	_units_to_deliver = _ordered_units
	var reliability: float = _modifier("reliability")
	var speed: float = _modifier("speed")
	if randf() < _supplier.short_chance * reliability:
		_units_to_deliver *= randf_range(_supplier.short_min, _supplier.short_max)
	_delivered = 0.0
	_expected_left = _supplier.lead_time * speed
	_time_left = _expected_left
	_late = randf() < _supplier.delay_chance * reliability
	if _late:
		_time_left += randf_range(_supplier.delay_min, _supplier.delay_max) * speed
	state = State.ORDERED
	return true


## Začal útok pirátů: objednávka se zruší a peníze se vrátí. Cisterna, která už je tady,
## odletí a vrátí peníze za to, co nestihla přečerpat.
func abort_delivery() -> void:
	match state:
		State.ORDERED:
			_refund(tank.position + Vector2(0, -60))
			state = State.IDLE
		State.ARRIVING, State.UNLOADING:
			_tanker.say_scared(Lines.pick(Lines.TANKER_SCARED))
			_finish_delivery()


## Stav objednávky pro HUD.
func status_text() -> String:
	match state:
		State.ORDERED:
			if _expected_left > 0.0:
				return "Cisterna přiletí za %d s" % ceili(_expected_left)
			return "Cisterna má zpoždění!"
		State.ARRIVING:
			return "Cisterna přilétá"
		State.UNLOADING:
			return "Přečerpávání: %d / %d j" % [roundi(_delivered), _ordered_units]
	if station and station.under_attack():
		return "Piráti útočí, cisterny nelétají"
	if station and station.has_dispatch():
		return "Dispečink hlídá zásobník"
	return "Žádná cisterna na cestě"


func _send_tanker() -> void:
	_tanker = TANKER_SCENE.instantiate()
	_tanker.position = spawn_position
	_tanker.dock_position = dock_position
	_tanker.hose_target = tank.position
	_tanker.tank_color = _supplier.color
	_tanker.docked.connect(_on_tanker_docked)
	add_child(_tanker)
	state = State.ARRIVING


func _on_tanker_docked() -> void:
	Sfx.play("tanker_dock")
	Sfx.set_loop("unload", true)
	if _units_to_deliver < _ordered_units:
		_tanker.say(Lines.pick(Lines.TANKER_SHORT))
	elif _late:
		_tanker.say(Lines.pick(Lines.TANKER_LATE))
	else:
		_tanker.say(Lines.pick(Lines.TANKER_ARRIVAL))
	state = State.UNLOADING


func _finish_delivery() -> void:
	_refund(_tanker.position + Vector2(0, -84))
	Sfx.set_loop("unload", false)
	_tanker.leave()
	_tanker = null
	state = State.IDLE


## Vrátí peníze za to, co se nepřečerpalo.
func _refund(at: Vector2) -> void:
	var refund := roundi((_ordered_units - _delivered) * _unit_price)
	if refund > 0:
		Game.add_credits(refund)
		FloatingText.spawn(self, at, "+%d kr vráceno" % refund, REFUND_COLOR)


## Účinek vylepšení řídícího centra (bez centra jako bez vylepšení).
func _modifier(id: String) -> Variant:
	if station and station.control_center:
		return station.control_center.value(id)
	return ControlCenter.base_value(id)


## Automatický dispečink: když galaxín v zásobníku klesne pod hranici, objedná cisternu
## u vybraného dodavatele (pokud na to hráč má).
func _dispatch() -> void:
	if not _modifier("dispatch") or tank.amount >= tank.capacity() * ControlCenter.DISPATCH_SHARE:
		return
	if order():
		FloatingText.spawn(self, station.to_local(station.control_center.global_position) + Vector2(0, -50),
				"Dispečink objednal cisternu", DISPATCH_COLOR)
