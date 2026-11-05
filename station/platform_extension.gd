class_name PlatformExtension
extends Building

## Rozšíření plošiny doprava: vzniknou na něm 2 nové parcely. Staví se jako budova na místě pro
## rozšíření. V 1. části jsou vidět nosníky. Jakmile jsou položené plechy (`has_plates`), stanice
## už nový kus kreslí jako součást paluby (zubatá hrana, bok), jen ztmavený. Po dostavění
## rozšíření zmizí a parcely na novém kusu se otevřou.

## Části stavby: název, cena (dohromady 8 000 kr) a doba stavby (s).
const PHASES := [
	{"name": "Nosníky", "cost": 3000, "duration": 6.0},
	{"name": "Plechy paluby", "cost": 3000, "duration": 6.0},
	{"name": "Rozvody a osvětlení", "cost": 2000, "duration": 5.0},
]
## Po které části jsou položené plechy paluby.
const PLATES_PHASE := 2

@onready var _girders: Node2D = $Girders


func build_phases() -> Array:
	return PHASES


func display_name() -> String:
	return "Rozšíření plošiny"


func info_lines() -> PackedStringArray:
	return PackedStringArray([construction_line(), "Až bude hotové, přibudou na nové části paluby 2 parcely."])


## Jestli jsou už položené plechy paluby (pak je nový kus součástí obrysu paluby).
func has_plates() -> bool:
	return built_phases >= PLATES_PHASE


func _update_construction_looks() -> void:
	super()
	# Části stavby: nosníky -> plechy (paluba stanice, ztmavená) -> hotová paluba.
	_girders.visible = built_phases == 1
	station.update_deck()
