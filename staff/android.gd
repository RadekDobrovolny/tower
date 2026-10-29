class_name Android
extends Node2D

## Android, který chodí k zakotveným lodím a tankuje je.
## Vylepšením se zrychlí jeho chůze i tankování.

signal became_idle(android: Android)
signal upgraded(android: Android)

enum State { IDLE, WALKING_TO_SHIP, FUELING, RETURNING }

## Parametry pro každý level: rychlost chůze (px/s), tankování (jednotek/s),
## cena vylepšení na tento level a barva těla.
const LEVELS := [
	{"walk_speed": 80.0, "fuel_rate": 8.0, "cost": 0, "color": Color(0.7, 0.75, 0.82)},
	{"walk_speed": 110.0, "fuel_rate": 12.0, "cost": 1000, "color": Color(0.45, 0.85, 0.75)},
	{"walk_speed": 140.0, "fuel_rate": 18.0, "cost": 2500, "color": Color(1.0, 0.8, 0.35)},
]

## Jak často android odpoví, když začíná tankovat.
const REPLY_CHANCE := 0.5

@export var display_name := "Pumpík"
## Jméno v 5. pádě, kterým ho oslovují lodě.
@export var vocative := "Pumpíku"

var level := 1
var state := State.IDLE

var _ship: Ship
var _home: Vector2

@onready var _body: Polygon2D = $Body
@onready var _hose: Line2D = $Hose
@onready var _level_label: Label = $LevelLabel
@onready var _bubble: SpeechBubble = $SpeechBubble


func _ready() -> void:
	_home = global_position
	_update_looks()


func _process(delta: float) -> void:
	match state:
		State.WALKING_TO_SHIP:
			if _walk_to(_ship.slot.service_position(), delta):
				_hose.show()
				if randf() < REPLY_CHANCE:
					_bubble.say(Lines.pick(Lines.ANDROID_REPLY))
				state = State.FUELING
		State.FUELING:
			_ship.add_fuel(_stats().fuel_rate * delta)
			_hose.points = PackedVector2Array([Vector2.ZERO, to_local(_ship.global_position)])
			if _ship.is_refueled():
				_finish_ship()
		State.RETURNING:
			if _walk_to(_home, delta):
				state = State.IDLE


## Jestli může android hned vyrazit k další lodi.
func is_available() -> bool:
	return state == State.IDLE or state == State.RETURNING


func serve(ship: Ship) -> void:
	_ship = ship
	state = State.WALKING_TO_SHIP


func is_max_level() -> bool:
	return level >= LEVELS.size()


## Cena vylepšení na další level.
func upgrade_cost() -> int:
	return LEVELS[level].cost


## Vylepší androida, pokud na to hráč má. Vrátí, jestli se to povedlo.
func try_upgrade() -> bool:
	if is_max_level() or not Game.spend_credits(upgrade_cost()):
		return false
	level += 1
	_update_looks()
	_bubble.say(Lines.pick(Lines.ANDROID_UPGRADE))
	upgraded.emit(self)
	return true


func _finish_ship() -> void:
	if _ship.leave_paid() > 0:
		_bubble.say(Lines.pick(Lines.ANDROID_TIP_THANKS))
	_ship = null
	_hose.hide()
	state = State.RETURNING
	became_idle.emit(self)


func _walk_to(target: Vector2, delta: float) -> bool:
	global_position = global_position.move_toward(target, _stats().walk_speed * delta)
	return global_position.is_equal_approx(target)


func _stats() -> Dictionary:
	return LEVELS[level - 1]


func _update_looks() -> void:
	_body.color = _stats().color
	_level_label.text = "%s · L%d" % [display_name, level]
