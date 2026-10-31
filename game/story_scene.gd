class_name StoryScene
extends Node

## Scéna s postavou z příběhu: chvíli po začátku mise přiletí její loď a po přistání se stane, co
## určí potomek. Proběhne jen jednou a mise skončí až po ní.

signal finished

## Za jak dlouho (s) po začátku mise loď přiletí.
const ARRIVAL_DELAY := 45.0

@export var station: Station
@export var spawner: ShipSpawner
@export var hud: Hud

## Jestli má scéna v téhle misi proběhnout. Nastavuje kampaň.
var active := false
var done := false

var _ship: Ship
var _arrived := false
var _time := 0.0


func _process(delta: float) -> void:
	if not active or _arrived:
		return
	_time += delta
	if _time >= ARRIVAL_DELAY and station.has_room() and not station.under_attack():
		_arrived = true
		_ship = spawner.spawn_story_ship(_hull())
		_ship.landed.connect(_on_landed)


## Loď postavy (stejné klíče jako `Ship.HULLS`).
func _hull() -> Dictionary:
	return {}


func _on_landed(_landed_ship: Ship) -> void:
	pass


func _finish() -> void:
	done = true
	finished.emit()
