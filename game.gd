extends Node

## Globální stav hry (autoload `Game`).

signal credits_changed(credits: int)

var credits := 0


func add_credits(amount: int) -> void:
	credits += amount
	credits_changed.emit(credits)
