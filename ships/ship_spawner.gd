class_name ShipSpawner
extends Node

## Posílá ke stanici nové lodě, dokud je u ní místo (volný slot nebo místo ve frontě).
## Když na stanici útočí piráti nebo je prázdný zásobník, žádná nová loď nepřiletí.

const SHIP_SCENE := preload("res://ships/ship.tscn")
## Jak daleko za okrajem obrazovky se nová loď objeví.
const SPAWN_MARGIN := 60.0
## Jak daleko za okraj obrazovky loď míří, když odlétá.
const EXIT_MARGIN := 300.0

@export var station: Station
@export var ships_parent: Node2D
## Rozmezí v sekundách mezi přílety dvou lodí.
@export var min_interval := 3.0
@export var max_interval := 7.0

var _cooldown := 0.5


func _process(delta: float) -> void:
	_cooldown -= delta
	if _cooldown > 0.0 or not station.has_room() or station.under_attack() or station.tank.is_empty():
		return
	_spawn_ship()
	# Při nízké ceně galaxínu přilétá lodí víc, při vysoké míň.
	_cooldown = randf_range(min_interval, max_interval) / station.demand_factor()


func _spawn_ship() -> void:
	var ship: Ship = SHIP_SCENE.instantiate()
	ship.position = _random_point_outside_screen(SPAWN_MARGIN)
	ship.exit_point = _random_point_outside_screen(EXIT_MARGIN)
	station.admit(ship)
	ships_parent.add_child(ship)


## Náhodný bod za horním, levým nebo pravým okrajem obrazovky. Spodní okraj
## vynecháváme, aby lodě zbytečně nepřelétaly přes celou stanici.
func _random_point_outside_screen(margin: float) -> Vector2:
	var rect := Game.visible_world_rect(station)
	var max_side_y := rect.position.y + rect.size.y * 0.6
	match randi() % 3:
		0:
			return Vector2(randf_range(rect.position.x, rect.end.x), rect.position.y - margin)
		1:
			return Vector2(rect.position.x - margin, randf_range(rect.position.y, max_side_y))
		_:
			return Vector2(rect.end.x + margin, randf_range(rect.position.y, max_side_y))
