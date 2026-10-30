class_name Supply
extends Node2D

## Objednávky galaxínu od dodavatelů. Hráč zaplatí cisternu předem, ta po čase přiletí
## k zásobníku a přečerpá galaxín. Za to, co nedoveze nebo co se nevejde, vrátí peníze.

enum State { IDLE, ORDERED, ARRIVING, UNLOADING }

const TANKER_SCENE := preload("res://economy/tanker.tscn")
## Jak rychle cisterna přečerpává do zásobníku (jednotky/s).
const UNLOAD_RATE := 150.0
const REFUND_COLOR := Color(0.45, 0.95, 0.85)

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

## Kde cisterna zakotví a odkud přilétá (souřadnice stanice).
@export var dock_position := Vector2(-230, 85)
@export var spawn_position := Vector2(-780, 60)

## Zásobník, do kterého se přečerpává. Nastaví ho stanice.
var tank: GalaxinTank
## Index vybraného dodavatele v SUPPLIERS.
var selected := 1
var state := State.IDLE

var _supplier: Dictionary
var _ordered_units := 0
var _units_to_deliver := 0.0
var _delivered := 0.0
var _time_left := 0.0
var _expected_left := 0.0
var _late := false
var _tanker: Tanker


func _process(delta: float) -> void:
	match state:
		State.ORDERED:
			_time_left -= delta
			_expected_left -= delta
			if _time_left <= 0.0:
				_send_tanker()
		State.UNLOADING:
			var units := minf(UNLOAD_RATE * delta, _units_to_deliver - _delivered)
			var accepted := tank.fill(units, _supplier.low_quality)
			_delivered += accepted
			if accepted < units or _delivered >= _units_to_deliver:
				_finish_delivery()


func selected_supplier() -> Dictionary:
	return SUPPLIERS[selected]


## Kolik jednotek by šlo teď objednat (velikost cisterny, ale nejvýš volné místo v zásobníku).
func order_units() -> int:
	return mini(selected_supplier().units, floori(tank.free_space()))


func order_cost() -> int:
	return roundi(order_units() * selected_supplier().price)


func can_order() -> bool:
	return state == State.IDLE and order_units() > 0 and Game.credits >= order_cost()


## Objedná a předem zaplatí cisternu u vybraného dodavatele. Vrátí, jestli se to povedlo.
func order() -> bool:
	if not can_order():
		return false
	_supplier = selected_supplier()
	_ordered_units = order_units()
	Game.spend_credits(order_cost())
	_units_to_deliver = _ordered_units
	if randf() < _supplier.short_chance:
		_units_to_deliver *= randf_range(_supplier.short_min, _supplier.short_max)
	_delivered = 0.0
	_expected_left = _supplier.lead_time
	_time_left = _supplier.lead_time
	_late = randf() < _supplier.delay_chance
	if _late:
		_time_left += randf_range(_supplier.delay_min, _supplier.delay_max)
	state = State.ORDERED
	return true


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
	return "Žádná cisterna na cestě"


func _send_tanker() -> void:
	_tanker = TANKER_SCENE.instantiate()
	_tanker.position = spawn_position
	_tanker.dock_position = dock_position
	_tanker.exit_position = spawn_position
	_tanker.hose_target = tank.position
	_tanker.tank_color = _supplier.color
	_tanker.docked.connect(_on_tanker_docked)
	add_child(_tanker)
	state = State.ARRIVING


func _on_tanker_docked() -> void:
	if _units_to_deliver < _ordered_units:
		_tanker.say(Lines.pick(Lines.TANKER_SHORT))
	elif _late:
		_tanker.say(Lines.pick(Lines.TANKER_LATE))
	else:
		_tanker.say(Lines.pick(Lines.TANKER_ARRIVAL))
	state = State.UNLOADING


func _finish_delivery() -> void:
	var refund := roundi((_ordered_units - _delivered) * _supplier.price)
	if refund > 0:
		Game.add_credits(refund)
		FloatingText.spawn(self, _tanker.position + Vector2(0, -40), "+%d kr vráceno" % refund, REFUND_COLOR)
	_tanker.leave()
	_tanker = null
	state = State.IDLE
