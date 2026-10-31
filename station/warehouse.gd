class_name Warehouse
extends Building

## Skladiště přistavěné k obchodu. Je to inventář: artefakty fungují, jen když jsou v něm.
## Po kliknutí ukáže, co v něm je a co to dělá, a artefakty jde prodat.
## Stojí na místě, které určuje parcela obchodu (`Plot.annex_offset`), ne na parcele.

## Části stavby: název, cena (dohromady 3 000 kr) a doba stavby (s).
const PHASES := [
	{"name": "Základy", "cost": 800, "duration": 3.0},
	{"name": "Ocelová konstrukce", "cost": 1200, "duration": 4.0},
	{"name": "Stěny a vrata", "cost": 1000, "duration": 4.0},
]
const SIZE := Vector2(88, 72)
const SLOTS := 6

@onready var _base: Sprite2D = $Base
@onready var _frame: Sprite2D = $Frame
@onready var _body: Sprite2D = $Body


func build_phases() -> Array:
	return PHASES


func display_name() -> String:
	return "Skladiště"


func rect() -> Rect2:
	return Rect2(position - SIZE / 2.0, SIZE)


func info_lines() -> PackedStringArray:
	if is_operational():
		return PackedStringArray(["Skladiště je hotové. Kliknutím na něj se otevře inventář artefaktů."])
	return PackedStringArray([construction_line(), "Bez skladiště se artefakty jen prodají. V hotovém skladišti zůstanou a budou fungovat."])


func _update_construction_looks() -> void:
	super()
	_base.visible = built_phases == 1
	_frame.visible = built_phases == 2
	_body.visible = is_operational()
