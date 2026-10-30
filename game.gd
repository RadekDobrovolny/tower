extends Node

## Globální stav rozehrané hry (autoload `Game`).

signal credits_changed(credits: int)
signal stats_changed

## Od které mise (index v Missions.ALL) hra začne. Nastavuje ho menu.
var start_mission := 0
var credits := 0
var ships_served := 0
var ships_lost := 0


## Vynuluje stav na začátku hry. Hráč může začínat s nějakými kredity.
func reset(start_credits := 0) -> void:
	credits = start_credits
	ships_served = 0
	ships_lost = 0
	credits_changed.emit(credits)
	stats_changed.emit()


func add_credits(amount: int) -> void:
	credits += amount
	credits_changed.emit(credits)


## Odečte kredity, pokud na to hráč má. Vrátí, jestli se platba povedla.
func spend_credits(amount: int) -> bool:
	if amount > credits:
		return false
	credits -= amount
	credits_changed.emit(credits)
	return true


func record_ship_served() -> void:
	ships_served += 1
	stats_changed.emit()


func record_ship_lost() -> void:
	ships_lost += 1
	stats_changed.emit()


## Naformátuje číslo s mezerami mezi tisíci, např. 10000 → „10 000“.
static func format_number(value: int) -> String:
	var digits := str(absi(value))
	var result := ""
	while digits.length() > 3:
		result = " " + digits.right(3) + result
		digits = digits.left(digits.length() - 3)
	return ("-" if value < 0 else "") + digits + result
