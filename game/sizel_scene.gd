class_name SizelScene
extends Node

## Příběh Sizela v Misi 8. První dvě dodávky přiveze a něco k tomu řekne. Třetí cisterna přiletí
## poškozená a hořící, nouzově přistane na plošině a Bzučák ji opraví. Sizel pak zlevní a dá
## nám schéma na filtr level 3, bez kterého mise nejde splnit. Cisterna potom dokončí dodávku.

## Kolikátá dodávka přiletí poškozená (počítají se ty, které dorazily k zásobníku).
const DELIVERIES_BEFORE_ACCIDENT := 2
const REPAIR_TIME := 10.0
const SCHEMATIC_FILTER_LEVEL := 3
## Jak daleko od okraje obrazovky musí být hořící cisterna, aby se Sizel ozval.
const HELP_CALL_MARGIN := 90.0

@export var station: Station
@export var hud: Hud

## Jestli příběh v téhle misi běží. Nastavuje kampaň.
var active := false

var _deliveries := 0
var _tanker: Tanker
var _slot: FuelSlot
var _called_for_help := false


func _ready() -> void:
	station.supply.tanker_sent.connect(_on_tanker_sent)
	station.supply.tanker_docked.connect(_on_tanker_docked)


## Sizel se ozve, jakmile je hořící cisterna vidět.
func _process(_delta: float) -> void:
	if _tanker == null or _called_for_help:
		return
	if Game.visible_world_rect(station).grow(-HELP_CALL_MARGIN).has_point(_tanker.global_position):
		_called_for_help = true
		Sfx.play("alarm")
		hud.dialogue.closed.connect(_on_help_promised, CONNECT_ONE_SHOT)
		hud.dialogue.play(Story.SIZEL_MAYDAY)


func _on_tanker_sent(tanker: Tanker) -> void:
	if active and _deliveries == DELIVERIES_BEFORE_ACCIDENT:
		_tanker = tanker
		_tanker.set_damaged()


## Počítají se jen Sizelovy dodávky, cisterna od jiného dodavatele může být na cestě ještě z Mise 7.
func _on_tanker_docked(supplier: Dictionary) -> void:
	if not active or supplier != Supply.SUPPLIERS[Supply.BLACK_MARKET]:
		return
	_deliveries += 1
	if _deliveries == 1:
		hud.dialogue.play(Story.SIZEL_FIRST_DELIVERY)
	elif _deliveries == DELIVERIES_BEFORE_ACCIDENT:
		hud.dialogue.play(Story.SIZEL_SECOND_DELIVERY)


## Pumpík Sizela navede na plošinu. Kdo na ní stojí, musí uhnout.
func _on_help_promised() -> void:
	_slot = station.close_slot_for_emergency()
	_tanker.landed.connect(_on_tanker_landed, CONNECT_ONE_SHOT)
	_tanker.land_at(_tanker.get_parent().to_local(_slot.global_position))


func _on_tanker_landed() -> void:
	Sfx.play("ship_land")
	station.queue_job(_tanker, "Oprava cisterny", {"name": "Hašení a oprava", "duration": REPAIR_TIME},
			_on_tanker_repaired, true)


func _on_tanker_repaired() -> void:
	_tanker.repair()
	Sfx.play("repaired")
	hud.dialogue.closed.connect(_on_friendship_sealed, CONNECT_ONE_SHOT)
	hud.dialogue.play(Story.SIZEL_THANKS)


func _on_friendship_sealed() -> void:
	active = false
	station.supply.sizel_friend = true
	station.max_filter_level = SCHEMATIC_FILTER_LEVEL
	station.reopen_slot(_slot)
	_tanker.return_to_dock()
