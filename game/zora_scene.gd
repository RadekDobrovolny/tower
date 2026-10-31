class_name ZoraScene
extends StoryScene

## Scéna Mise 6: přiletí Zora, nechá si natankovat plnou nádrž, odmítne zaplatit a pomalu odlétá.
## Pumpík po ní vystřelí, raketa se jen otřese a zmizí, ale vypadne z ní truhla s medailonem.

## Za jak dlouho (s) si Pumpík všimne, že Zora odlétá bez placení.
const NOTICE_DELAY := 2.5
## Za jak dlouho (s) po útěku se Pumpík ozve.
const REPORT_DELAY := 1.4
const HULL := {
	"texture": preload("res://assets/sprites/ships/rocket_zora.png"),
	"scale": 0.42, "patience": INF, "full_tank": true, "story": true,
}


func _ready() -> void:
	station.artifact_stored.connect(_on_artifact_stored)


func _hull() -> Dictionary:
	return HULL


func _on_landed(_landed_ship: Ship) -> void:
	_ship.skipped_payment.connect(_on_skipped_payment)
	hud.dialogue.play(Story.ZORA_ARRIVES)


## Pumpík chce zaplatit, Zora ho odbude a začne odlétat, jakmile hráč rozhovor odklikne.
func _on_skipped_payment(_paying_ship: Ship) -> void:
	var lines := Story.ZORA_BILL.duplicate(true)
	lines[0].text = lines[0].text % Game.format_number(_ship.fuel_price())
	hud.dialogue.closed.connect(_on_bill_refused, CONNECT_ONE_SHOT)
	hud.dialogue.play(lines)


func _on_bill_refused() -> void:
	_ship.sneak_away()
	get_tree().create_timer(NOTICE_DELAY, false).timeout.connect(_on_noticed)


func _on_noticed() -> void:
	station.get_androids()[0].warning_shot(_ship, _on_shot_hit)


## Střela Zoře neublíží: raketa se otřese, zmizí a vypadne z ní truhla.
func _on_shot_hit() -> void:
	station.drop_story_loot(_ship.global_position, Station.MEDALLION)
	_ship.dash_away()
	get_tree().create_timer(REPORT_DELAY, false).timeout.connect(hud.dialogue.play.bind(Story.ZORA_ESCAPED))


func _on_artifact_stored(artifact: Dictionary) -> void:
	if artifact.id != Station.MEDALLION.id:
		return
	hud.dialogue.play(Story.ZORA_MEDALLION)
	_finish()
