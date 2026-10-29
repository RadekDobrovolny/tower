class_name FuelSlot
extends Node2D

## Přistávací plošina s čerpadlem. Najednou obslouží jednu loď.

signal freed(slot: FuelSlot)

const FREE_COLOR := Color(0.3, 0.9, 0.4)
const BUSY_COLOR := Color(1.0, 0.55, 0.2)
const LOCKED_COLOR := Color(0.25, 0.25, 0.28)
const LOCKED_MODULATE := Color(1, 1, 1, 0.3)

## Zamčený slot je vidět, ale lodě k němu nelétají.
var unlocked := true:
	set(value):
		unlocked = value
		modulate = Color.WHITE if unlocked else LOCKED_MODULATE
		if is_node_ready():
			_update_light()
var occupant: Ship = null

@onready var _light: Polygon2D = $Light
@onready var _service_point: Marker2D = $ServicePoint


func _ready() -> void:
	_update_light()


func is_free() -> bool:
	return unlocked and occupant == null


## Místo u čerpadla, kde stojí android, když tankuje.
func service_position() -> Vector2:
	return _service_point.global_position


func reserve(ship: Ship) -> void:
	occupant = ship
	_update_light()


func release() -> void:
	occupant = null
	_update_light()
	freed.emit(self)


func _update_light() -> void:
	if not unlocked:
		_light.color = LOCKED_COLOR
	elif occupant == null:
		_light.color = FREE_COLOR
	else:
		_light.color = BUSY_COLOR
