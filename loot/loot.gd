class_name Loot
extends Node2D

## Kořist ze sestřeleného piráta: trosky (prodají se za kredity) nebo truhla s artefaktem.
## Vznáší se na místě, kde pirát vybuchl, dokud pro ni nedoletí stavební dron a nesebere ji.
## Pozice je globální (kořist je ve světě, ne ve stanici).

enum Kind { WRECKAGE, CHEST }

const TEXTURES := {
	Kind.WRECKAGE: preload("res://assets/sprites/loot/wreckage.png"),
	Kind.CHEST: preload("res://assets/sprites/loot/chest.png"),
}
const SCALE := 0.36
## Jak dlouho dron kořist sbírá (s).
const COLLECT_TIME := 2.0
const CREDITS_COLOR := Color(1.0, 0.85, 0.3)
const ARTIFACT_COLOR := Color(0.45, 0.95, 0.85)

var kind := Kind.WRECKAGE
## Kolik kreditů trosky vynesou (u truhly se použije cena artefaktu).
var credits := 0
## Artefakt v truhle (slovník z Station.ARTIFACTS), nebo prázdný.
var artifact := {}
var station: Station
## Zakázka drona na sebrání, nebo null.
var job: ConstructionJob

var _time := randf() * 10.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _glow: Sprite2D = $Glow


func _ready() -> void:
	_sprite.texture = TEXTURES[kind]
	_sprite.scale = Vector2.ONE * SCALE
	_glow.modulate = Color(0.4, 1.0, 0.9) if kind == Kind.CHEST else Color(1.0, 0.6, 0.3)
	station.queue_job(self, "Sběr: %s" % info_title(), [{"name": "Sbírání", "duration": COLLECT_TIME}],
			Callable(), collect)


func _process(delta: float) -> void:
	_time += delta
	_sprite.position.y = sin(_time * 2.0) * 3.0
	_sprite.rotation = sin(_time * 0.7) * 0.25
	_glow.modulate.a = 0.45 + 0.25 * sin(_time * 3.0)


func info_title() -> String:
	return "truhla" if kind == Kind.CHEST else "trosky"


## Dron kořist sebral: hráč dostane kredity, případně artefakt a jeho účinek.
func collect() -> void:
	var at := station.to_local(global_position) + Vector2(0, -36)
	Sfx.play("loot" if artifact.is_empty() else "artifact")
	if artifact.is_empty():
		Game.add_credits(credits)
		FloatingText.spawn(station, at, "+%d kr trosky" % credits, CREDITS_COLOR)
	else:
		var stored := station.add_artifact(artifact)
		var reward: String = "do skladiště" if stored else "+%s kr" % Game.format_number(artifact.credits)
		FloatingText.spawn(station, at, "%s: %s" % [artifact.name, reward], ARTIFACT_COLOR)
	queue_free()
