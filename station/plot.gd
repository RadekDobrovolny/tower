class_name Plot
extends Node2D

## Parcela na stanici, na které jde postavit budovu. Prázdná je skoro neviditelná,
## po kliknutí nabídne, co tu jde postavit.

const SIZE := Vector2(170, 120)

## Z které strany čerpadla stojí android, když tu bude čerpací slot: -1 vlevo, 1 vpravo.
## Sousední parcely mají stranu natočenou k sobě, aby android obsloužil oba sloty najednou.
@export_enum("Vlevo:-1", "Vpravo:1") var service_side := -1

var building: Building
var station: Station

@onready var _outline: Line2D = $Outline


func is_empty() -> bool:
	return building == null


## Obdélník parcely v souřadnicích stanice.
func rect() -> Rect2:
	return Rect2(position - SIZE / 2.0, SIZE)


func place(new_building: Building) -> void:
	building = new_building
	add_child(new_building)


func set_outline_visible(value: bool) -> void:
	_outline.visible = value


func info_title() -> String:
	return "Prázdná parcela"


func info_lines() -> PackedStringArray:
	var price_lines := station.build_price_lines()
	if price_lines.is_empty():
		return PackedStringArray(["Tady zatím nic nestojí a zatím tu nejde nic postavit."])
	var lines := PackedStringArray([
		"Tady zatím nic nestojí. Vyber, co tu postavit. Stavba se platí po částech a staví ji %s."
				% station.drone.display_name,
	])
	lines.append_array(price_lines)
	return lines


func info_actions() -> Array[ShopItem]:
	return station.build_options(self)
