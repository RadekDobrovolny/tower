class_name Pirate
extends Node2D

## Pirátská loď. Přiletí k jednomu z míst kolem stanice a každou chvíli vystřelí: dokud
## je android (Pumpík) v provozu, střílí po něm, a když je rozbitý, střílí po zásobníku
## a ukradne část kreditů z pokladny. Po několika krádežích odletí. Sestřelit ji může
## obranná věž i android.
## Pozice jsou globální (piráti jsou ve světě, ne ve stanici).

enum State { ARRIVING, ATTACKING, LEAVING, DESTROYED }

## Druhy pirátů: vzhled, výdrž (počet zásahů po 1) a rychlost.
const KINDS := {
	"raider": {
		"texture": preload("res://assets/sprites/pirates/raider.png"), "scale": 0.34,
		"hp": 4, "speed": 230.0,
	},
	"gunship": {
		"texture": preload("res://assets/sprites/pirates/gunship.png"), "scale": 0.42,
		"hp": 15, "speed": 170.0,
	},
}
const TURN_SPEED := 3.5
## Na jakou vzdálenost od místa útoku pirát začne zpomalovat.
const APPROACH_RADIUS := 200.0
const STEAL_INTERVAL := 2.5
## Kolik procent kreditů z pokladny ukradne jedna rána po zásobníku.
const STEAL_SHARE_MIN := 0.03
const STEAL_SHARE_MAX := 0.08
## Po tolika krádežích pirát odletí.
const MAX_STEALS := 5
const BOLT_LENGTH := 64.0
## Mezera mezi trupem a ukazatelem životů nad lodí.
const HEALTH_BAR_GAP := 12.0
const HEALTH_BAR_HEIGHT := 5.0
const HIT_FLASH_TIME := 0.12
const OFFSCREEN_MARGIN := 140.0
const STEAL_COLOR := Color(1.0, 0.35, 0.35)
const DOWN_COLOR := Color(1.0, 0.8, 0.4)
## Za jak dlouho po výbuchu zmizí (dohoří jiskry).
const WRECK_TIME := 1.2

var kind := "raider"
var station: Station
## Kde pirát visí při útoku (globální souřadnice).
var attack_point: Vector2
## Android, který proti pirátovi bojuje, nebo null.
var fought_by: Node
var state := State.ARRIVING

var _hp := 0
var _speed := 0.0
var _steal_timer := 1.2
var _steals := 0
var _hit_flash := 0.0
var _time := randf() * 10.0
var _leave_angle := 0.0

@onready var _body: Node2D = $Body
@onready var _sprite: Sprite2D = $Body/Sprite
@onready var _engine: EngineFlame = $Body/EngineFlame
@onready var _health_bar: ProgressBar = $HealthBar
@onready var _hit_sparks: CPUParticles2D = $HitSparks
@onready var _explosion: CPUParticles2D = $Explosion
@onready var _blast_light: PointLight2D = $BlastLight
@onready var _bubble: SpeechBubble = $SpeechBubble


func _ready() -> void:
	add_to_group("pirates")
	var data: Dictionary = KINDS[kind]
	_hp = data.hp
	_sprite.texture = data.texture
	_sprite.scale = Vector2.ONE * data.scale
	var half_length: float = data.texture.get_width() * data.scale / 2.0
	_engine.position.x = -half_length + 6.0
	_health_bar.max_value = data.hp
	_health_bar.value = data.hp
	_health_bar.size = Vector2(half_length * 1.6, HEALTH_BAR_HEIGHT)
	_health_bar.position = Vector2(-half_length * 0.8, -half_length - HEALTH_BAR_GAP)
	_body.rotation = global_position.direction_to(attack_point).angle()


func _process(delta: float) -> void:
	_time += delta
	_hit_flash -= delta
	_sprite.modulate = Color(2.0, 1.6, 1.6) if _hit_flash > 0.0 else Color.WHITE
	match state:
		State.ARRIVING:
			if _fly_to_attack_point(delta):
				state = State.ATTACKING
				_bubble.say(Lines.pick(Lines.PIRATE_ARRIVAL), true)
				station.on_pirate_attack()
		State.ATTACKING:
			_attack(delta)
		State.LEAVING:
			_fly_away(delta)


func is_attacking() -> bool:
	return state == State.ATTACKING


## Jestli na něj jde střílet: je ve hře a na obrazovce.
func is_targetable() -> bool:
	return state != State.DESTROYED and Game.visible_world_rect(self).has_point(global_position)


## Zásah za `damage`. Vrátí true, když ho tenhle zásah sestřelil.
func hit(damage: int) -> bool:
	if state == State.DESTROYED:
		return false
	_hp -= damage
	_health_bar.value = _hp
	_hit_flash = HIT_FLASH_TIME
	_hit_sparks.restart()
	if _hp > 0:
		return false
	_destroy()
	return true


func _fly_to_attack_point(delta: float) -> bool:
	var to_target := attack_point - global_position
	var distance := to_target.length()
	if distance > 4.0:
		_body.rotation = lerp_angle(_body.rotation, to_target.angle(), minf(TURN_SPEED * delta, 1.0))
	var max_speed: float = KINDS[kind].speed
	var step := minf(max_speed * clampf(distance / APPROACH_RADIUS, 0.15, 1.0) * delta, distance)
	global_position += to_target.normalized() * step
	_engine.target_throttle = 0.3 + 0.7 * clampf(step / delta / max_speed, 0.0, 1.0) if delta > 0.0 else 0.3
	return distance - step < 0.5


func _attack(delta: float) -> void:
	var target := _android_target()
	var aim: Vector2 = target.global_position if target else station.tank.global_position
	_body.rotation = lerp_angle(_body.rotation, (aim - global_position).angle(), minf(TURN_SPEED * delta, 1.0))
	_body.position.y = sin(_time * 3.0) * 2.0
	_engine.target_throttle = 0.3
	_steal_timer -= delta
	if _steal_timer > 0.0:
		return
	_steal_timer = STEAL_INTERVAL
	if target:
		_fire_at(target, target.take_hit)
		return
	_steal()
	if _steals >= MAX_STEALS:
		_leave()


## Android v provozu, po kterém pirát střílí, nebo null (všichni jsou rozbití).
func _android_target() -> Android:
	for android in station.get_androids():
		if not android.damaged:
			return android
	return null


func _fire_at(target: Node2D, on_hit: Callable) -> void:
	var nose := _body.to_global(Vector2(_sprite.texture.get_width() * _sprite.scale.x * 0.45, 0.0))
	LaserBolt.fire(station, nose, target, LaserBolt.RED, on_hit, BOLT_LENGTH)


## Vystřelí po zásobníku. Když střela dopadne, ukradne část kreditů z pokladny.
func _steal() -> void:
	_steals += 1
	_fire_at(station.tank, _rob_credits)
	if _steals == 2:
		_bubble.say(Lines.pick(Lines.PIRATE_TAUNT), true)


func _rob_credits() -> void:
	var amount := roundi(maxi(Game.credits, 0) * randf_range(STEAL_SHARE_MIN, STEAL_SHARE_MAX))
	if amount > 0:
		Game.add_credits(-amount)
		Sfx.play("theft")
		FloatingText.spawn(station, station.tank.position + Vector2(0, -60), "-%d kr ukradeno" % amount, STEAL_COLOR)


func _leave() -> void:
	state = State.LEAVING
	_speed = 0.0
	# Pryč od stanice.
	_leave_angle = (global_position - station.global_position).angle() + randf_range(-0.4, 0.4)


func _fly_away(delta: float) -> void:
	var max_speed: float = KINDS[kind].speed * 1.3
	_body.rotation = lerp_angle(_body.rotation, _leave_angle, minf(TURN_SPEED * delta, 1.0))
	_speed = minf(_speed + 260.0 * delta, max_speed)
	global_position += Vector2.from_angle(_body.rotation) * _speed * delta
	_engine.target_throttle = 0.4 + 0.6 * _speed / max_speed
	if not Game.visible_world_rect(self).grow(OFFSCREEN_MARGIN).has_point(global_position):
		queue_free()


func _destroy() -> void:
	state = State.DESTROYED
	remove_from_group("pirates")
	Game.record_pirate_shot()
	_body.hide()
	_health_bar.hide()
	_explosion.restart()
	Sfx.play("explosion", 0.75 if kind == "gunship" else 1.0)
	_blast_light.show()
	create_tween().tween_property(_blast_light, "energy", 0.0, 0.6).from(3.0)
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -40), "Pirát sestřelen!", DOWN_COLOR)
	station.spawn_loot(global_position, kind == "gunship")
	get_tree().create_timer(WRECK_TIME, false).timeout.connect(queue_free)
