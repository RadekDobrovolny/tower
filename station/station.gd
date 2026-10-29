class_name Station
extends Node2D

## Čerpací stanice. Drží čerpací sloty, ke kterým kotví lodě.

@onready var _slots: Node2D = $Slots


## Vrátí první volný slot, nebo null, když jsou všechny obsazené.
func get_free_slot() -> FuelSlot:
	for child in _slots.get_children():
		var slot := child as FuelSlot
		if slot and slot.is_free():
			return slot
	return null
