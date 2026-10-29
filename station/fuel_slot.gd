class_name FuelSlot
extends Node2D

## Přistávací plošina s čerpadlem. Najednou obslouží jednu loď.

const FREE_COLOR := Color(0.3, 0.9, 0.4)
const BUSY_COLOR := Color(1.0, 0.55, 0.2)

## Kolik jednotek paliva za sekundu čerpadlo načerpá.
@export var pump_rate := 12.0

var occupant: Ship = null

@onready var _light: Polygon2D = $Light


func _ready() -> void:
	_update_light()


func is_free() -> bool:
	return occupant == null


func reserve(ship: Ship) -> void:
	occupant = ship
	_update_light()


func release() -> void:
	occupant = null
	_update_light()


func _update_light() -> void:
	_light.color = FREE_COLOR if is_free() else BUSY_COLOR
