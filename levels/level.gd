class_name Level
extends Node2D

## Jeden level hry. Hlídá cíle levelu a po jejich splnění hru zastaví a ohlásí vítězství.

signal completed

## Kolik kreditů musí mít hráč zároveň na účtu.
@export var goal_credits := 10000
## Na jaký level musí hráč vylepšit androida.
@export var goal_android_level := 3

## Herní čas od začátku levelu v sekundách.
var elapsed := 0.0

var _completed := false

@onready var station: Station = $Station
@onready var hud: Hud = $HUD


func _ready() -> void:
	Game.reset()
	# Odloženě, aby se cíle vyhodnotily až po všech změnách v daném snímku
	# (např. loď nejdřív zaplatí a teprve pak se započítá jako obsloužená).
	Game.credits_changed.connect(_check_goals.unbind(1), CONNECT_DEFERRED)
	for android in station.get_androids():
		android.upgraded.connect(_check_goals.unbind(1), CONNECT_DEFERRED)
	hud.setup(self)


func _process(delta: float) -> void:
	elapsed += delta


func is_credits_goal_met() -> bool:
	return Game.credits >= goal_credits


func best_android_level() -> int:
	var best := 0
	for android in station.get_androids():
		best = maxi(best, android.level)
	return best


func is_android_goal_met() -> bool:
	return best_android_level() >= goal_android_level


func _check_goals() -> void:
	if _completed or not (is_credits_goal_met() and is_android_goal_met()):
		return
	_completed = true
	get_tree().paused = true
	completed.emit()
