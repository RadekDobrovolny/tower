extends Node2D

## Občasný provoz daleko za stanicí: malé tmavé siluety lodí, které pomalu proletí přes
## obraz, a vzácně kometa. Všechno je pod stanicí i za planetou, nejde na to kliknout
## a nesvítí na to světla stanice. Trasy se počítají z viditelné části světa
## (Game.visible_world_rect), takže lodě vylétají a mizí za okrajem obrazovky.
## Ocas komety míří od světla (doprava nahoru jako stíny, DropShadow.DIRECTION), kometa
## proto letí zhruba ke světlu, aby ocas zůstal za ní.

const HULLS: Array[Texture2D] = [
	preload("res://assets/sprites/ships/rocket.png"),
	preload("res://assets/sprites/ships/rocket_cargo.png"),
	preload("res://assets/sprites/ships/rocket_workhorse.png"),
	preload("res://assets/sprites/ships/rocket_taxi.png"),
	preload("res://assets/sprites/ships/rocket_van.png"),
	preload("res://assets/sprites/ships/freighter.png"),
	preload("res://assets/sprites/ships/tourist.png"),
	preload("res://assets/sprites/ships/tanker.png"),
]
const GLOW := preload("res://fx/soft_light.tres")
const ADDITIVE := preload("res://fx/additive.tres")

## Za jak dlouho přiletí další loď a další kometa (s, od–do). Na obrazovce 1280×720 jsou
## pak v průměru vidět dvě lodě najednou (někdy žádná, nanejvýš asi čtyři).
const SHIP_INTERVAL := Vector2(8.0, 18.0)
const COMET_INTERVAL := Vector2(70.0, 150.0)
## Kdy se objeví první (s od začátku scény, od–do).
const FIRST_SHIP := Vector2(2.0, 7.0)
const FIRST_COMET := Vector2(15.0, 40.0)
const SHIP_SPEED := Vector2(16.0, 36.0)
## Délka siluety lodi (px světa): čím menší, tím je dál.
const SHIP_LENGTH := Vector2(12.0, 22.0)
## Lodě v dálce jsou tmavé, svítí jen jejich motor.
const SHIP_TINT := Color(0.5, 0.47, 0.58)
const ENGINE_COLOR := Color(1.0, 0.58, 0.38, 0.9)
## Lodě létají v pruzích zhruba vodorovně, nanejvýš o tolik šikmo (rad).
const SHIP_TILT := 0.55
const COMET_SPEED := Vector2(26.0, 46.0)
## O kolik se kometa odchýlí od směru ke světlu (rad).
const COMET_SPREAD := 0.4
## Jak daleko za okrajem obrazovky provoz začíná a končí (px).
const MARGIN := 70.0

var _ship_wait := 0.0
var _comet_wait := 0.0


func _ready() -> void:
	light_mask = 0
	_ship_wait = randf_range(FIRST_SHIP.x, FIRST_SHIP.y)
	_comet_wait = randf_range(FIRST_COMET.x, FIRST_COMET.y)


func _process(delta: float) -> void:
	_ship_wait -= delta
	if _ship_wait <= 0.0:
		_ship_wait = randf_range(SHIP_INTERVAL.x, SHIP_INTERVAL.y)
		launch_ship()
	_comet_wait -= delta
	if _comet_wait <= 0.0:
		_comet_wait = randf_range(COMET_INTERVAL.x, COMET_INTERVAL.y)
		launch_comet()


func launch_ship() -> void:
	var angle := randf_range(-SHIP_TILT, SHIP_TILT) + (PI if randf() < 0.5 else 0.0)
	var ship := Traveler.new()
	var length := randf_range(SHIP_LENGTH.x, SHIP_LENGTH.y)
	var hull: Texture2D = HULLS.pick_random()
	var sprite := Sprite2D.new()
	sprite.texture = hull
	sprite.scale = Vector2.ONE * length / hull.get_width()
	sprite.modulate = SHIP_TINT
	ship.add_child(sprite)
	var engine := Sprite2D.new()
	engine.texture = GLOW
	engine.material = ADDITIVE
	engine.modulate = ENGINE_COLOR
	engine.position = Vector2(-length * 0.5, 0.0)
	engine.scale = Vector2.ONE * length * 0.6 / GLOW.get_width()
	ship.add_child(engine)
	_send(ship, Vector2.from_angle(angle), randf_range(SHIP_SPEED.x, SHIP_SPEED.y))


func launch_comet() -> void:
	var toward_light := -DropShadow.DIRECTION.normalized()
	var direction := toward_light.rotated(randf_range(-COMET_SPREAD, COMET_SPREAD))
	_send(Comet.new(), direction, randf_range(COMET_SPEED.x, COMET_SPEED.y))


## Pošle objekt přímo přes obraz: projde náhodným místem viditelné plochy a začne i skončí
## za jejím okrajem.
func _send(traveler: Traveler, direction: Vector2, speed: float) -> void:
	var rect := Game.visible_world_rect(self).grow(MARGIN)
	var through := rect.position + Vector2(randf(), randf()) * rect.size
	var span := _crossing(rect, through, direction)
	traveler.position = through + direction * span.x
	traveler.rotation = direction.angle()
	traveler.velocity = direction * speed
	traveler.life = (span.y - span.x) / speed
	traveler.light_mask = 0
	add_child(traveler)


## Kde přímka bodem `through` ve směru `direction` vstupuje do obdélníku a kde z něj
## vystupuje (vzdálenosti od `through`).
static func _crossing(rect: Rect2, through: Vector2, direction: Vector2) -> Vector2:
	var enter := -INF
	var leave := INF
	for axis in 2:
		if absf(direction[axis]) < 0.0001:
			continue
		var a := (rect.position[axis] - through[axis]) / direction[axis]
		var b := (rect.end[axis] - through[axis]) / direction[axis]
		enter = maxf(enter, minf(a, b))
		leave = minf(leave, maxf(a, b))
	return Vector2(enter, leave)


## Něco, co letí rovně stálou rychlostí a po `life` sekundách zmizí. Na začátku a na konci
## se plynule objeví a zmizí, kdyby okraj obrazovky mezitím popojel.
class Traveler:
	extends Node2D

	const FADE := 1.5

	var velocity := Vector2.ZERO
	var life := 1.0
	var _age := 0.0

	func _process(delta: float) -> void:
		_age += delta
		position += velocity * delta
		modulate.a = clampf(minf(_age, life - _age) / FADE, 0.0, 1.0)
		if _age >= life:
			queue_free()


## Kometa: jasné jádro v tyrkysově bílém závoji (koma), za ním dlouhý tenký tyrkysový
## ocas s vlákny a kratší širší růžový prachový ocas, který se stáčí stranou. Ocasy mají
## měkké okraje a vlákna z nich pomalu odtékají (space/comet_tail.gdshader). Všechno se
## kreslí přičítáním, takže na tmavém pozadí svítí.
class Comet:
	extends Traveler

	const TAIL_SHADER := preload("res://space/comet_tail.gdshader")
	const NOISE := preload("res://assets/sprites/space/nebula_noise.png")
	const ION_LENGTH := Vector2(120.0, 190.0)
	## Délka prachového ocasu vůči iontovému.
	const DUST_LENGTH := Vector2(0.5, 0.7)
	## O kolik px se prachový ocas na konci stočí stranou.
	const DUST_CURVE := Vector2(5.0, 14.0)
	## Poloviční výška obdélníku s ocasy (px), musí pokrýt stočený prachový ocas.
	const TAIL_HALF_HEIGHT := 40.0
	const COMA_SIZE := 40.0
	const COMA_COLOR := Color(0.7, 0.95, 1.0, 0.45)
	const CORE_SIZE := 9.0

	var _length := 0.0

	func _ready() -> void:
		_length = randf_range(ION_LENGTH.x, ION_LENGTH.y)
		var tail := ShaderMaterial.new()
		tail.shader = TAIL_SHADER
		tail.set_shader_parameter("noise", NOISE)
		tail.set_shader_parameter("size", Vector2(_length, TAIL_HALF_HEIGHT))
		tail.set_shader_parameter("dust_length", randf_range(DUST_LENGTH.x, DUST_LENGTH.y))
		tail.set_shader_parameter("curve", randf_range(DUST_CURVE.x, DUST_CURVE.y) * (1.0 if randf() < 0.5 else -1.0))
		tail.set_shader_parameter("seed", randf())
		material = tail
		_add_glow(COMA_SIZE, COMA_COLOR)
		_add_glow(CORE_SIZE, Color.WHITE)

	func _add_glow(size: float, color: Color) -> void:
		var glow := Sprite2D.new()
		glow.texture = GLOW
		glow.material = ADDITIVE
		glow.modulate = color
		glow.scale = Vector2.ONE * size / GLOW.get_width()
		add_child(glow)

	func _draw() -> void:
		var h := TAIL_HALF_HEIGHT
		draw_polygon(
				PackedVector2Array([Vector2(0, -h), Vector2(-_length, -h), Vector2(-_length, h), Vector2(0, h)]),
				PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]),
				PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]))
