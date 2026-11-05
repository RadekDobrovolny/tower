class_name Plot
extends Node2D

## Parcela na stanici, na které jde postavit budovu. Prázdná je vidět jen jako jemný obrys
## a jde na ni kliknout, jen když na ní jde něco postavit (jinak ji stanice skryje).
## Po kliknutí nabídne, co tu jde postavit. Běžné parcely jsou pro sloty a budovy,
## menší místa na krajích paluby jsou jen pro obranné věže. Mimo palubu jsou místa pro její
## rozšíření a pro parkoviště.

enum Kind { BUILDING, TOWER, EXTENSION, PARKING }

## Jak výrazný je obrys míst mimo palubu, kde by jinak nebyl na tmavém vesmíru vidět. Na černém
## pozadí je asi dvakrát kontrastnější než obrys parcel na palubě (víc už bilo do očí).
const OUTSIDE_OUTLINE_ALPHA := 0.25

@export var kind := Kind.BUILDING
@export var size := Vector2(170, 120)
## Z které strany čerpadla stojí android, když tu bude čerpací slot: -1 vlevo, 1 vpravo.
## Čerpadlo stojí na opačné straně než android. Horní parcely mají android natočený k sobě, aby
## obsloužil oba sloty najednou. Dolní mají čerpadlo u zásobníku, aby potrubí nevedlo pod plošinou.
@export_enum("Vlevo:-1", "Vpravo:1") var service_side := -1

## Kde vůči parcele stojí přístavba budovy (skladiště u obchodu).
@export var annex_offset := Vector2(0, 66)
## Parcela na rozšířené části paluby: jde na ni stavět, až je plošina rozšířená.
@export var needs_extension := false

var building: Building
var station: Station

@onready var _outline: Line2D = $Outline
@onready var _highlight: ColorRect = $Highlight


func _ready() -> void:
	var half := size / 2.0
	_outline.points = PackedVector2Array([-half, Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)])
	_highlight.position = -half
	_highlight.size = size
	if kind == Kind.EXTENSION or kind == Kind.PARKING:
		_outline.default_color.a = OUTSIDE_OUTLINE_ALPHA
	# Obrys zapne až stanice, když tu jde stavět. Úvodní rozhovor by ho jinak ukázal všude.
	_outline.hide()


func is_empty() -> bool:
	return building == null


## Obdélník parcely v souřadnicích stanice.
func rect() -> Rect2:
	return Rect2(position - size / 2.0, size)


func place(new_building: Building) -> void:
	building = new_building
	add_child(new_building)


## Odstraní budovu. Rozšíření plošiny po dostavění splyne s palubou.
func clear() -> void:
	building.queue_free()
	building = null


func set_outline_visible(value: bool) -> void:
	_outline.visible = value


## Rozsvítí parcelu jako vybranou.
func set_highlighted(value: bool) -> void:
	_highlight.visible = value


func info_title() -> String:
	match kind:
		Kind.TOWER:
			return "Místo pro obrannou věž"
		Kind.EXTENSION:
			return "Místo pro rozšíření plošiny"
		Kind.PARKING:
			return "Místo pro parkoviště"
	return "Prázdná parcela"


func info_lines() -> PackedStringArray:
	var lines := PackedStringArray([
		"Tady zatím nic nestojí. Vyber, co tu postavit. Stavba se platí po částech a staví ji %s."
				% station.drone.display_name,
	])
	lines.append_array(station.build_price_lines(self))
	return lines


func info_actions() -> Array[ShopItem]:
	return station.build_options(self)
