class_name PirateSpawner
extends Node

## Posílá na stanici piráty, když je mise zapne. Zpočátku chodí jednotliví nájezdníci,
## časem občas dva naráz a těžké dělové lodě, nakonec i bandy tří až čtyř lodí. Každý pirát si vybere volné místo kolem
## stanice (PirateTargets ve stanici) a přiletí k němu z bližšího okraje obrazovky.

const PIRATE_SCENE := preload("res://pirates/pirate.tscn")
## Za jak dlouho po zapnutí přiletí první pirát (s).
const FIRST_DELAY := 20.0
## Od kdy (s od zapnutí) občas přiletí dva piráti naráz a s jakou šancí.
const PAIR_FROM := 180.0
const PAIR_CHANCE := 0.35
## Od kdy (s od zapnutí) občas přiletí celá banda tří až čtyř pirátů a s jakou šancí.
const SQUAD_FROM := 420.0
const SQUAD_CHANCE := 0.3
## Od kdy přilétají i těžké dělové lodě a s jakou šancí.
const GUNSHIP_FROM := 240.0
const GUNSHIP_CHANCE := 0.3
## Jak daleko za okrajem obrazovky se pirát objeví.
const SPAWN_MARGIN := 90.0

@export var station: Station
@export var pirates_parent: Node2D

## Rozmezí v sekundách mezi útoky (nastavuje kampaň podle mise).
var min_interval := 40.0
var max_interval := 70.0
var enabled := false:
	set(value):
		if value and not enabled:
			_cooldown = FIRST_DELAY
		enabled = value

var _cooldown := 0.0
var _time := 0.0


func _process(delta: float) -> void:
	if not enabled:
		return
	_time += delta
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_cooldown = randf_range(min_interval, max_interval) * station.pirate_interval_factor
	var count := 1
	if _time > SQUAD_FROM and randf() < SQUAD_CHANCE:
		count = randi_range(3, 4)
	elif _time > PAIR_FROM and randf() < PAIR_CHANCE:
		count = 2
	for i in count:
		_spawn()


func _spawn() -> void:
	var free_points := _free_attack_points()
	if free_points.is_empty():
		return
	var pirate: Pirate = PIRATE_SCENE.instantiate()
	pirate.kind = "gunship" if _time > GUNSHIP_FROM and randf() < GUNSHIP_CHANCE else "raider"
	pirate.station = station
	pirate.attack_point = free_points.pick_random()
	pirate.global_position = _spawn_position(pirate.attack_point)
	pirates_parent.add_child(pirate)


func _free_attack_points() -> Array[Vector2]:
	var taken: Array[Vector2] = []
	for pirate in get_tree().get_nodes_in_group("pirates"):
		taken.append(pirate.attack_point)
	var result: Array[Vector2] = []
	for point in station.pirate_targets():
		if not taken.has(point):
			result.append(point)
	return result


## Místo za levým nebo pravým okrajem obrazovky, podle toho, ke kterému má cíl blíž.
func _spawn_position(target: Vector2) -> Vector2:
	var screen := station.get_viewport_rect()
	var x := screen.position.x - SPAWN_MARGIN if target.x < screen.get_center().x else screen.end.x + SPAWN_MARGIN
	return Vector2(x, clampf(target.y + randf_range(-200.0, 200.0), 0.0, screen.end.y))
