class_name Station
extends Node2D

## Čerpací stanice. Přiděluje lodím sloty a místa ve frontě a posílá k nim androidy.

## Kolik slotů je odemčených. Odemykají se v pořadí, v jakém jsou pod uzlem Slots.
@export var unlocked_slots := 3

## Lodě čekající ve frontě, první je na řadě.
var _queue: Array[Ship] = []
## Zakotvené lodě, které čekají, až k nim dojde android.
var _awaiting_service: Array[Ship] = []

@onready var _slots: Node2D = $Slots
@onready var _queue_points: Node2D = $QueuePoints
@onready var _staff: Node2D = $Staff


func _ready() -> void:
	var slots := get_slots()
	for i in slots.size():
		slots[i].unlocked = i < unlocked_slots
		slots[i].freed.connect(_on_slot_freed)
	for android in get_androids():
		android.became_idle.connect(_on_android_became_idle)


func get_slots() -> Array[FuelSlot]:
	var result: Array[FuelSlot] = []
	result.assign(_slots.get_children())
	return result


func get_androids() -> Array[Android]:
	var result: Array[Android] = []
	result.assign(_staff.get_children())
	return result


## Jestli se ke stanici vejde další loď, ať už do volného slotu, nebo do fronty.
func has_room() -> bool:
	return _free_slot() != null or _queue.size() < _queue_points.get_child_count()


## Přijme novou loď: pošle ji rovnou k volnému slotu, nebo ji zařadí do fronty.
func admit(ship: Ship) -> void:
	ship.landed.connect(_on_ship_landed)
	ship.gave_up.connect(_on_ship_gave_up)
	var androids := get_androids()
	if not androids.is_empty():
		ship.attendant_vocative = androids[0].vocative
	var slot := _free_slot()
	if slot:
		_send_to_slot(ship, slot)
	else:
		_queue.append(ship)
		ship.go_to_queue(_queue_position(_queue.size() - 1))


func _free_slot() -> FuelSlot:
	for slot in get_slots():
		if slot.is_free():
			return slot
	return null


func _send_to_slot(ship: Ship, slot: FuelSlot) -> void:
	slot.reserve(ship)
	ship.go_to_slot(slot)


func _queue_position(index: int) -> Vector2:
	return (_queue_points.get_child(index) as Node2D).global_position


## Posune čekající lodě na místa odpovídající jejich pořadí ve frontě.
func _advance_queue() -> void:
	for i in _queue.size():
		_queue[i].go_to_queue(_queue_position(i))


func _on_slot_freed(slot: FuelSlot) -> void:
	if _queue.is_empty():
		return
	_send_to_slot(_queue.pop_front(), slot)
	_advance_queue()


func _on_ship_gave_up(ship: Ship) -> void:
	_queue.erase(ship)
	_advance_queue()


func _on_ship_landed(ship: Ship) -> void:
	for android in get_androids():
		if android.is_available():
			android.serve(ship)
			return
	_awaiting_service.append(ship)


func _on_android_became_idle(android: Android) -> void:
	if not _awaiting_service.is_empty():
		android.serve(_awaiting_service.pop_front())
