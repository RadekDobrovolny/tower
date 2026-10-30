class_name FuelSlot
extends Building

## Čerpací slot: přistávací plošina s čerpadlem. Najednou obslouží jednu loď.

signal freed(slot: FuelSlot)

## Části stavby: název, cena (dohromady 8 000 kr) a doba stavby (s).
const PHASES := [
	{"name": "Základová deska", "cost": 1500, "duration": 4.0},
	{"name": "Přistávací plocha", "cost": 2500, "duration": 5.0},
	{"name": "Čerpadlo", "cost": 2500, "duration": 5.0},
	{"name": "Napojení na potrubí", "cost": 1500, "duration": 4.0},
]
## Jak daleko od středu plochy stojí pumpa (na opačné straně, než stojí android).
const PUMP_OFFSET_X := 64.0
## Pata pumpy vůči jejímu středu: odtud vede potrubí do zásobníku.
const PUMP_FOOT := Vector2(0, 28)
const FREE_COLOR := Color(0.3, 0.9, 0.4)
const BUSY_COLOR := Color(1.0, 0.55, 0.2)

## Z které strany čerpadla stojí android: -1 vlevo, 1 vpravo. Nastaví stanice podle parcely.
var service_side := -1
var occupant: Ship = null

@onready var _base: Sprite2D = $Base
@onready var _pad: Sprite2D = $Pad
@onready var _pump: Sprite2D = $Pump
@onready var _light: Polygon2D = $Light
@onready var _service_point: Marker2D = $ServicePoint


func _ready() -> void:
	_service_point.position.x = absf(_service_point.position.x) * service_side
	_pump.position.x = PUMP_OFFSET_X * -service_side
	_light.position.x = _pump.position.x
	super()
	_update_light()


func build_phases() -> Array:
	return PHASES


func display_name() -> String:
	return "Čerpací slot"


func is_free() -> bool:
	return is_operational() and occupant == null


## Místo u čerpadla, kde stojí android, když tankuje.
func service_position() -> Vector2:
	return _service_point.global_position


## Spodní konec čerpadla, kam vede potrubí ze zásobníku (souřadnice stanice).
func pipe_position() -> Vector2:
	return plot.position + position + _pump.position + PUMP_FOOT


func reserve(ship: Ship) -> void:
	occupant = ship
	_update_light()


func release() -> void:
	occupant = null
	_update_light()
	freed.emit(self)


func info_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	if not is_operational():
		lines.append(construction_line())
		lines.append("Až bude hotový, budou sem přistávat lodě.")
		return lines
	if occupant == null:
		lines.append("Stav: volný, čeká na loď")
	elif occupant.state == Ship.State.LANDED:
		lines.append("Stav: loď tankuje (%d / %d j)" % [roundi(occupant.fuel), roundi(occupant.tank_capacity)])
	else:
		lines.append("Stav: loď přilétá")
	lines.append("Na slot přistává jedna loď najednou.")
	return lines


func _update_construction_looks() -> void:
	super()
	# Staveniště je vidět jen v první fázi, pak ho překryje hotová přistávací plocha.
	_base.visible = built_phases == 1
	_pad.visible = built_phases >= 2
	_pump.visible = built_phases >= 3
	_light.visible = built_phases >= 4
	if built_phases >= 4:
		station.connect_pipe(self)


func _update_light() -> void:
	_light.color = FREE_COLOR if occupant == null else BUSY_COLOR
