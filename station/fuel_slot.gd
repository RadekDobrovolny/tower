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

## Z které strany čerpadla stojí android: -1 vlevo, 1 vpravo. Nastaví stanice podle parcely.
var service_side := -1
var occupant: Ship = null
## Plošinu zabrala cisterna, která tu nouzově přistává. Žádná loď sem teď nesmí.
var closed := false

@onready var _base: Sprite2D = $Base
@onready var _pad: Sprite2D = $Pad
@onready var _pump: Sprite2D = $Pump
@onready var _service_point: Marker2D = $ServicePoint
@onready var _pad_lights: PadLights = $PadLights


func _ready() -> void:
	_service_point.position.x = absf(_service_point.position.x) * service_side
	_pump.position.x = PUMP_OFFSET_X * -service_side
	super()


func _process(delta: float) -> void:
	super(delta)
	_pad_lights.mode = _pad_lights_mode()


func build_phases() -> Array:
	return PHASES


func display_name() -> String:
	return "Čerpací slot"


func is_free() -> bool:
	return is_operational() and occupant == null and not closed


## Místo u čerpadla, kde stojí android, když tankuje.
func service_position() -> Vector2:
	return _service_point.global_position


## Spodní konec čerpadla, kam vede potrubí ze zásobníku (souřadnice stanice).
func pipe_position() -> Vector2:
	return plot.position + position + _pump.position + PUMP_FOOT


func reserve(ship: Ship) -> void:
	occupant = ship


func release() -> void:
	occupant = null
	freed.emit(self)


func info_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	if not is_operational():
		lines.append(construction_line())
		lines.append("Až bude hotový, budou sem přistávat lodě.")
		return lines
	if closed:
		lines.append("Stav: nouzově tu přistává cisterna")
	elif occupant == null:
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
	if built_phases >= 4:
		station.connect_pipe(self)


## Značky na ploše svítí, až je slot hotový. Podle lodi na něm „dýchají“, navádějí, nebo svítí klidně.
func _pad_lights_mode() -> PadLights.Mode:
	if not is_operational():
		return PadLights.Mode.OFF
	if closed:
		return PadLights.Mode.LANDED
	if occupant == null:
		return PadLights.Mode.IDLE
	if occupant.state == Ship.State.LANDED:
		return PadLights.Mode.LANDED
	return PadLights.Mode.APPROACH

