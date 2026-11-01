class_name Parking
extends Building

## Parkoviště pod plošinou pro čtyři lodě hostů motelu. Stojí na vlastním místě, ne na parcele.

## Části stavby: název, cena (dohromady 4 000 kr) a doba stavby (s).
const PHASES := [
	{"name": "Kotvicí rám", "cost": 1000, "duration": 4.0},
	{"name": "Parkovací stání", "cost": 2000, "duration": 5.0},
	{"name": "Osvětlení a závora", "cost": 1000, "duration": 3.0},
]
## Kde jsou stání vůči středu parkoviště.
const BAYS: Array[Vector2] = [Vector2(-138, -8), Vector2(-26, -8), Vector2(86, -8), Vector2(198, -8)]
const BAY_SCALE := 0.5
const BAY_TEXTURE := preload("res://assets/sprites/motel/parking_bay.png")
const SHELL_MODULATE := Color(0.5, 0.5, 0.52)

## Která loď stojí na kterém stání (null = volné).
var _guests: Array[Ship] = []
var _bay_sprites: Array[Sprite2D] = []

@onready var _frame: Node2D = $Frame
@onready var _plate: Node2D = $Plate
@onready var _deck: Polygon2D = $Plate/Deck
@onready var _lights: Node2D = $Lights
@onready var _label: Label = $Label


func _ready() -> void:
	# Paluba je v souřadnicích stanice, aby na sebe její textura navazovala.
	_deck.position = -plot.position
	for bay in BAYS:
		var sprite := Sprite2D.new()
		sprite.texture = BAY_TEXTURE
		sprite.scale = Vector2.ONE * BAY_SCALE
		sprite.position = bay
		_plate.add_child(sprite)
		_bay_sprites.append(sprite)
		_guests.append(null)
	super()


func _process(delta: float) -> void:
	super(delta)
	_label.text = "Parkoviště · %d / %d" % [guests(), BAYS.size()] if is_operational() else "Parkoviště"


func build_phases() -> Array:
	return PHASES


func display_name() -> String:
	return "Parkoviště"


func guests() -> int:
	return BAYS.size() - _guests.count(null)


func has_free_bay() -> bool:
	return _guests.has(null)


## Vyhradí lodi první volné stání a vrátí jeho polohu (globálně).
func take_bay(ship: Ship) -> Vector2:
	var bay := _guests.find(null)
	_guests[bay] = ship
	return to_global(BAYS[bay])


func release_bay(ship: Ship) -> void:
	_guests[_guests.find(ship)] = null


func info_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	if not is_operational():
		lines.append(construction_line())
		lines.append("Až bude hotové, zaparkují tu lodě hostů motelu.")
		return lines
	lines.append("Obsazená stání: %d / %d" % [guests(), BAYS.size()])
	if not station.has_motel():
		lines.append("Bez motelu tu nikdo nepřespí.")
	return lines


func _update_construction_looks() -> void:
	super()
	# Části stavby: nosníky -> tmavý plech se stáními -> světla a závora. Hotový plech je už
	# součástí paluby stanice.
	_frame.visible = built_phases == 1
	_plate.visible = built_phases >= 2
	_plate.modulate = Color.WHITE if is_operational() else SHELL_MODULATE
	_deck.visible = not is_operational()
	_lights.visible = is_operational()
	_label.visible = built_phases >= 1
