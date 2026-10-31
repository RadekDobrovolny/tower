class_name PatrolScene
extends StoryScene

## Scéna Mise 7: přiletí císařská hlídka a ptá se na Zoru. Hráč si vybere, jestli ji prozradí.
## Výběr si pamatuje `Game.zora_reported`.

const HULL := {
	"texture": preload("res://assets/sprites/ships/rocket_imperial_patrol.png"),
	"scale": 0.42, "patience": INF, "full_tank": true, "story": true,
}


func _hull() -> Dictionary:
	return HULL


func _on_landed(_landed_ship: Ship) -> void:
	hud.dialogue.chose.connect(_on_chose, CONNECT_ONE_SHOT)
	hud.dialogue.closed.connect(_on_talk_over, CONNECT_ONE_SHOT)
	hud.dialogue.play(Story.PATROL_ARRIVES)


func _on_chose(choice_id: String) -> void:
	Game.zora_reported = choice_id == Story.REPORT_ZORA


func _on_talk_over() -> void:
	_ship.take_off()
	_finish()
