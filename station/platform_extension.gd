class_name PlatformExtension
extends Building

## Rozšíření plošiny doprava: vzniknou na něm 2 nové parcely. Staví se jako budova na místě pro
## rozšíření. Po dostavění zmizí a stanice si zvětší palubu sama (`Station.EXTENDED_PLATFORM`).

## Části stavby: název, cena (dohromady 8 000 kr) a doba stavby (s).
const PHASES := [
	{"name": "Nosníky", "cost": 3000, "duration": 6.0},
	{"name": "Plechy paluby", "cost": 3000, "duration": 6.0},
	{"name": "Rozvody a osvětlení", "cost": 2000, "duration": 5.0},
]
const SHELL_MODULATE := Color(0.5, 0.5, 0.52)

@onready var _deck: Polygon2D = $Deck
@onready var _girders: Node2D = $Girders


func _ready() -> void:
	# Paluba je v souřadnicích stanice, aby na sebe její textura navazovala.
	_deck.position = -plot.position
	super()


func build_phases() -> Array:
	return PHASES


func display_name() -> String:
	return "Rozšíření plošiny"


func info_lines() -> PackedStringArray:
	return PackedStringArray([construction_line(), "Až bude hotové, přibudou na nové části paluby 2 parcely."])


func _update_construction_looks() -> void:
	super()
	# Části stavby: nosníky -> tmavé plechy -> hotová paluba (tu už kreslí stanice).
	_girders.visible = built_phases == 1
	_deck.visible = built_phases >= 2
	_deck.modulate = SHELL_MODULATE
