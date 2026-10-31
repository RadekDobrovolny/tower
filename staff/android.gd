class_name Android
extends Node2D

## Android na kolech, který jezdí k zakotveným lodím a tankuje je. Zvládne obsluhovat víc lodí
## najednou: postaví se mezi ně a ke každé natáhne hadici.
## Zvlášť se vylepšuje rychlost tankování a rychlost jízdy (okamžitě, bez stavby).
## Piráti střílejí přednostně po něm. Každý zásah ubere bod odolnosti, a když odolnost
## klesne na nulu, je rozbitý: netankuje, nebrání se a čeká, až ho opraví stavební dron.
## Částečně poškozený pracuje dál a zastaví se, až když k němu dron doletí opravovat.
## Když stanice nemá obrannou věž, střílí po pirátech z tankovací pistole (galaxínovým
## laserem). Štíty přidávají odolnost, nanoboti opravují částečné poškození (rozbitého ne).

## Android může vzít další loď (dotankoval nebo má volnou hadici).
signal free_for_ship(android: Android)
signal upgraded(android: Android)

## Levely tankování: rychlost (jednotek/s na každou loď), cena vylepšení na tento level
## a barva, do které se Pumpík s levelem zbarvuje.
const FUEL_LEVELS := [
	{"rate": 8.0, "cost": 0, "color": Color(0.7, 0.75, 0.82)},
	{"rate": 12.0, "cost": 800, "color": Color(0.45, 0.85, 0.75)},
	{"rate": 18.0, "cost": 2000, "color": Color(1.0, 0.8, 0.35)},
	{"rate": 24.0, "cost": 3500, "color": Color(0.75, 0.55, 1.0)},
	{"rate": 30.0, "cost": 5500, "color": Color(1.0, 0.5, 0.6)},
	{"rate": 36.0, "cost": 8000, "color": Color(0.85, 1.0, 1.0)},
]
## Levely jízdy: rychlost (px/s) a cena vylepšení na tento level.
const WALK_LEVELS := [
	{"speed": 80.0, "cost": 0},
	{"speed": 110.0, "cost": 500},
	{"speed": 140.0, "cost": 1000},
	{"speed": 170.0, "cost": 2000},
	{"speed": 200.0, "cost": 3500},
]

## Jak často android odpoví, když dostane novou loď.
const REPLY_CHANCE := 0.5
## Jak moc se barva levelu promítne do chromu.
const LEVEL_TINT := 0.12
## Animace (pásy po 8 snímcích ze SpriteCooku): klid a tankování (zepředu) a jízda do čtyř stran.
const ANIMATIONS := {
	"idle": preload("res://assets/sprites/staff/pumpik_idle.png"),
	"pump": preload("res://assets/sprites/staff/pumpik_pump.png"),
	"drive_down": preload("res://assets/sprites/staff/pumpik_drive_down.png"),
	"drive_up": preload("res://assets/sprites/staff/pumpik_drive_up.png"),
	"drive_left": preload("res://assets/sprites/staff/pumpik_drive_left.png"),
	"drive_right": preload("res://assets/sprites/staff/pumpik_drive_right.png"),
}
const ANIMATION_FRAMES := 8
const IDLE_FPS := 6.0
const PUMP_FPS := 8.0
## Kolik pixelů ujede za jeden cyklus animace jízdy. Rychlejší Pumpík proto rychleji točí koly.
const WALK_STRIDE := 64.0
## Boj s piráty: prodleva mezi výstřely (s), poškození jednoho výstřelu a jak dlouho trvá
## oprava stavebním dronem.
const SHOT_INTERVAL := 0.9
const SHOT_DAMAGE := 1
const REPAIR_TIME := 10.0
## Kolik zásahů od pirátů vydrží bez štítů.
const BASE_HEALTH := 3
## Štíty: kolik zásahů přidají a cena levelu. Nanoboti: za kolik sekund opraví jeden bod
## odolnosti (jen u částečného poškození, rozbitého neopraví) a cena levelu. Level 0 = bez vylepšení.
const SHIELD_LEVELS := [
	{"bonus": 0, "cost": 0},
	{"bonus": 2, "cost": 3000},
	{"bonus": 4, "cost": 6000},
]
const NANOBOT_LEVELS := [
	{"seconds": 0.0, "cost": 0},
	{"seconds": 6.0, "cost": 4000},
	{"seconds": 3.0, "cost": 7000},
]
## Za jak dlouho po posledním zásahu zavolá částečně poškozený android dron na opravu.
const SAFE_AFTER := 4.0
const HIT_FLASH_TIME := 0.15
const BLAST_TIME := 0.12
## Ústí tankovací pistole vůči středu androida (odtud letí laser).
const NOZZLE := Vector2(-25, -13)
## Jak moc poškozený android ztmavne.
const DAMAGED_TINT := Color(0.55, 0.5, 0.5)

@export var display_name := "Pumpík"
## Jméno v 5. pádě, kterým ho oslovují lodě.
@export var vocative := "Pumpíku"
## Kolik lodí zvládne tankovat najednou.
@export var max_parallel_ships := 2

var fuel_level := 1
var walk_level := 1
## Nejvyšší level (tankování i chůze), na který jde v aktuální misi vylepšit.
var max_level := FUEL_LEVELS.size()
## Stanice, ze které android čerpá galaxín. Nastaví ji stanice.
var station: Station
## Rozbitý po zásazích pirátů: netankuje, dokud ho dron neopraví.
var damaged := false
var health := BASE_HEALTH
var shield_level := 0
var nanobot_level := 0
## Zakázka stavebního drona na opravu, nebo null.
var job: ConstructionJob

## Lodě, které android právě obsluhuje.
var _ships: Array[Ship] = []
var _home: Vector2
## Jestli už android ohlásil, že došel galaxín (aby to neopakoval každý snímek).
var _reported_empty := false
var _animation := ""
var _animation_time := 0.0
## Jestli se android v tomto snímku pohnul a kterým směrem (pro animaci jízdy).
var _moved := false
var _move_direction := Vector2.ZERO
## Pirát, se kterým android bojuje, nebo null.
var _enemy: Pirate
var _shot_cooldown := 0.0
var _blast_left := 0.0
var _hit_flash := 0.0
var _since_hit := 0.0
var _nanobot_time := 0.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _hoses: Array[Line2D] = [$Hose1, $Hose2]
@onready var _level_label: Label = $LevelLabel
@onready var _bubble: SpeechBubble = $SpeechBubble
@onready var _blaster: Line2D = $Blaster
@onready var _damage_sparks: CPUParticles2D = $DamageSparks
@onready var _health_bar: ProgressBar = $HealthBar


func _ready() -> void:
	_home = global_position
	_update_looks()


func _process(delta: float) -> void:
	_blast_left -= delta
	_blaster.visible = _blast_left > 0.0
	_hit_flash -= delta
	_since_hit += delta
	_heal(delta)
	_update_health_looks()
	if damaged or _enemy or is_being_repaired():
		# Při boji, rozbitý a během opravy netankuje, lodě na plošinách počkají.
		_update_hoses(false)
		_moved = false
		if _enemy:
			_fight(delta)
		_animate(delta)
		return
	if _ships.is_empty():
		_update_hoses(false)
		_walk_to(_home, delta)
		_animate(delta)
		return
	# Tankuje se, až když android stojí na místě, odkud dosáhne ke všem lodím.
	if not _walk_to(_service_position(), delta):
		_update_hoses(false)
		_animate(delta)
		return
	var rate: float = fuel_rate() * delta
	var ran_dry := false
	for ship in _ships.duplicate():
		var requested := minf(rate, ship.fuel_missing())
		var share := station.tank.low_quality_share()
		var drawn := station.tank.draw(requested)
		ran_dry = ran_dry or drawn < requested
		ship.add_fuel(drawn, share)
		if ship.is_refueled():
			_finish_ship(ship)
	if ran_dry and not _reported_empty:
		_bubble.say(Lines.pick(Lines.ANDROID_EMPTY))
	_reported_empty = ran_dry
	_update_hoses(true)
	_animate(delta)


## Jestli android může vzít další loď.
func is_available() -> bool:
	return not damaged and _enemy == null and not is_being_repaired() and _ships.size() < max_parallel_ships


## Jestli se může postavit pirátovi (není poškozený a s nikým jiným nebojuje).
func can_fight() -> bool:
	return not damaged and _enemy == null and not is_being_repaired()


## Jestli u něj už je dron a opravuje ho (pak stojí). Dokud dron letí, pracuje dál.
func is_being_repaired() -> bool:
	return station != null and station.drone.is_working_on(job)


func max_health() -> int:
	return BASE_HEALTH + SHIELD_LEVELS[shield_level].bonus


## Zásah od piráta. Když odolnost klesne na nulu, android je rozbitý.
func take_hit() -> void:
	if damaged:
		return
	health -= 1
	_hit_flash = HIT_FLASH_TIME
	_since_hit = 0.0
	if health <= 0:
		_break_down()


func engage(pirate: Pirate) -> void:
	_enemy = pirate
	_shot_cooldown = SHOT_INTERVAL * 0.5
	_bubble.say(Lines.pick(Lines.ANDROID_FIGHT))


## Dron dokončil opravu: plná odolnost a zpátky do práce. Stanice se dozví, že může
## zase dostávat lodě (i ty, které mezitím přistály a čekají).
func finish_repair() -> void:
	health = max_health()
	damaged = false
	_update_looks()
	_bubble.say(Lines.pick(Lines.ANDROID_REPAIRED))
	# Až po snímku: dokud dron dokončuje zakázku, ještě „pracuje“ na androidovi.
	free_for_ship.emit.call_deferred(self)


## Cena dalšího levelu štítů nebo nanobotů, nebo -1 (maximum, nebo je mise ještě nenabízí).
func next_shield_cost() -> int:
	if not station.tower_available or shield_level + 1 >= SHIELD_LEVELS.size():
		return -1
	return SHIELD_LEVELS[shield_level + 1].cost


func next_nanobot_cost() -> int:
	if not station.tower_available or nanobot_level + 1 >= NANOBOT_LEVELS.size():
		return -1
	return NANOBOT_LEVELS[nanobot_level + 1].cost


func upgrade_shields() -> bool:
	var cost := next_shield_cost()
	if cost < 0 or not Game.spend_credits(cost):
		return false
	shield_level += 1
	health += SHIELD_LEVELS[shield_level].bonus - SHIELD_LEVELS[shield_level - 1].bonus
	_on_upgraded()
	return true


func upgrade_nanobots() -> bool:
	var cost := next_nanobot_cost()
	if cost < 0 or not Game.spend_credits(cost):
		return false
	nanobot_level += 1
	_on_upgraded()
	return true


## Přestane obsluhovat loď (např. když to vzdala a odlétá).
func release_ship(ship: Ship) -> void:
	if _ships.has(ship):
		_ships.erase(ship)
		free_for_ship.emit(self)


func serve(ship: Ship) -> void:
	_ships.append(ship)
	if randf() < REPLY_CHANCE:
		_bubble.say(Lines.pick(Lines.ANDROID_REPLY))


## Nastaví levely bez placení (startovní stav mise).
func set_levels(fuel: int, walk: int) -> void:
	fuel_level = clampi(fuel, 1, FUEL_LEVELS.size())
	walk_level = clampi(walk, 1, WALK_LEVELS.size())
	_update_looks()


func fuel_rate() -> float:
	return FUEL_LEVELS[fuel_level - 1].rate


func walk_speed() -> float:
	return WALK_LEVELS[walk_level - 1].speed


## Cena vylepšení tankování, nebo -1, když teď vylepšit nejde.
func next_fuel_cost() -> int:
	if fuel_level >= mini(max_level, FUEL_LEVELS.size()):
		return -1
	return FUEL_LEVELS[fuel_level].cost


## Cena vylepšení chůze, nebo -1, když teď vylepšit nejde.
func next_walk_cost() -> int:
	if walk_level >= mini(max_level, WALK_LEVELS.size()):
		return -1
	return WALK_LEVELS[walk_level].cost


func upgrade_fuel() -> bool:
	var cost := next_fuel_cost()
	if cost < 0 or not Game.spend_credits(cost):
		return false
	fuel_level += 1
	_on_upgraded()
	return true


func upgrade_walk() -> bool:
	var cost := next_walk_cost()
	if cost < 0 or not Game.spend_credits(cost):
		return false
	walk_level += 1
	_on_upgraded()
	return true


func info_title() -> String:
	return display_name


func info_lines() -> PackedStringArray:
	var lines := PackedStringArray([
		"Android, který tankuje lodě. Zvládne obsluhovat dvě lodě najednou.",
		"Tankování: level %d (%d j/s)" % [fuel_level, roundi(fuel_rate())],
		"Jízda: level %d (%d px/s)" % [walk_level, roundi(walk_speed())],
		"Právě obsluhuje lodí: %d / %d" % [_ships.size(), max_parallel_ships],
	])
	if station.tower_available or shield_level > 0:
		lines.append("Odolnost: %d / %d zásahů" % [health, max_health()])
	if nanobot_level > 0:
		lines.append("Nanoboti: opraví 1 bod odolnosti za %d s (rozbitého neopraví)" % roundi(NANOBOT_LEVELS[nanobot_level].seconds))
	if _enemy:
		lines.append("Stav: bojuje s piráty!")
	elif damaged:
		lines.append("Stav: rozbitý po zásazích pirátů, netankuje.")
	elif is_being_repaired():
		lines.append("Stav: v opravě, netankuje.")
	if job:
		lines.append(job.status_text(station.drone))
	return lines


func info_actions() -> Array[ShopItem]:
	var actions: Array[ShopItem] = [
		ShopItem.new(_fuel_upgrade_label, next_fuel_cost, upgrade_fuel, ShopItem.Kind.UPGRADE),
		ShopItem.new(_walk_upgrade_label, next_walk_cost, upgrade_walk, ShopItem.Kind.UPGRADE),
		ShopItem.new(_shield_upgrade_label, next_shield_cost, upgrade_shields, ShopItem.Kind.UPGRADE),
		ShopItem.new(func() -> String: return "Nanoboti: level %d (samooprava)" % (nanobot_level + 1),
				next_nanobot_cost, upgrade_nanobots, ShopItem.Kind.UPGRADE),
	]
	return actions


func _shield_upgrade_label() -> String:
	var next: Dictionary = SHIELD_LEVELS[mini(shield_level + 1, SHIELD_LEVELS.size() - 1)]
	return "Štíty: level %d (odolnost %d)" % [shield_level + 1, BASE_HEALTH + next.bonus]


func _fuel_upgrade_label() -> String:
	return "Vylepšit tankování na level %d" % (fuel_level + 1)


func _walk_upgrade_label() -> String:
	return "Vylepšit jízdu na level %d" % (walk_level + 1)


func _on_upgraded() -> void:
	_update_looks()
	_bubble.say(Lines.pick(Lines.ANDROID_UPGRADE))
	upgraded.emit(self)


func _finish_ship(ship: Ship) -> void:
	if ship.leave_paid() > 0:
		_bubble.say(Lines.pick(Lines.ANDROID_TIP_THANKS))
	_ships.erase(ship)
	free_for_ship.emit(self)


## Místo uprostřed mezi obsluhovanými sloty.
func _service_position() -> Vector2:
	var sum := Vector2.ZERO
	for ship in _ships:
		sum += ship.slot.service_position()
	return sum / _ships.size()


func _update_hoses(connected: bool) -> void:
	for i in _hoses.size():
		var hose := _hoses[i]
		hose.visible = connected and i < _ships.size()
		if hose.visible:
			hose.points = PackedVector2Array([NOZZLE, to_local(_ships[i].global_position)])


func _walk_to(target: Vector2, delta: float) -> bool:
	var before := global_position
	global_position = global_position.move_toward(target, walk_speed() * delta)
	_moved = global_position != before
	if _moved:
		_move_direction = global_position - before
	return global_position.is_equal_approx(target)


## Jízda ve směru pohybu, když se hýbe; tankování (i střelba z pistole), když má napojenou
## hadici nebo bojuje; jinak klid (poškozený jen pomalu). Stojí vždy čelem k hráči.
func _animate(delta: float) -> void:
	if _moved:
		_play(_drive_animation(), walk_speed() / WALK_STRIDE * ANIMATION_FRAMES, delta)
	elif _hoses[0].visible or _enemy:
		_play("pump", PUMP_FPS, delta)
	else:
		_play("idle", IDLE_FPS * (0.4 if damaged else 1.0), delta)


## Animace jízdy podle toho, kterým směrem se pohybuje víc.
func _drive_animation() -> String:
	if absf(_move_direction.x) > absf(_move_direction.y):
		return "drive_right" if _move_direction.x > 0.0 else "drive_left"
	return "drive_down" if _move_direction.y > 0.0 else "drive_up"


func _fight(delta: float) -> void:
	if not is_instance_valid(_enemy) or not _enemy.is_attacking():
		_enemy = null
		return
	_shot_cooldown -= delta
	if _shot_cooldown > 0.0:
		return
	_shot_cooldown = SHOT_INTERVAL
	_blaster.points = PackedVector2Array([NOZZLE, to_local(_enemy.global_position)])
	_blast_left = BLAST_TIME
	_enemy.hit(SHOT_DAMAGE)


## Odolnost klesla na nulu: android je rozbitý a čeká na opravu (bez nanobotů ho opraví dron).
func _break_down() -> void:
	_enemy = null
	damaged = true
	_update_looks()
	_bubble.say(Lines.pick(Lines.ANDROID_DAMAGED))
	if job == null:
		station.request_repair(self)


## Částečné poškození: nanoboti opravují bod po bodu, bez nich android zavolá dron, až na
## něj chvíli nikdo nestřílí. Rozbitého opraví jen dron (zavolá ho při rozbití).
func _heal(delta: float) -> void:
	if damaged or health >= max_health():
		_nanobot_time = 0.0
		return
	if nanobot_level > 0:
		_nanobot_time += delta
		if _nanobot_time >= NANOBOT_LEVELS[nanobot_level].seconds:
			_nanobot_time = 0.0
			health += 1
	elif job == null and _since_hit > SAFE_AFTER:
		station.request_repair(self)


func _update_health_looks() -> void:
	var label := display_name
	if damaged:
		label = "%s · rozbitý" % display_name
	elif is_being_repaired():
		label = "%s · v opravě" % display_name
	_level_label.text = label
	_health_bar.visible = health < max_health() and not damaged
	_health_bar.max_value = max_health()
	_health_bar.value = health
	if _hit_flash > 0.0:
		_sprite.modulate = Color(2.0, 0.8, 0.8)
	elif _sprite.modulate.r > 1.5:
		_update_looks()


func _play(animation: String, fps: float, delta: float) -> void:
	if animation != _animation:
		_animation = animation
		_animation_time = 0.0
		_sprite.texture = ANIMATIONS[animation]
	_animation_time = fmod(_animation_time + delta * fps, ANIMATION_FRAMES)
	_sprite.frame = int(_animation_time) % ANIMATION_FRAMES


func _update_looks() -> void:
	var tint := Color.WHITE.lerp(FUEL_LEVELS[fuel_level - 1].color, LEVEL_TINT)
	_sprite.modulate = tint * DAMAGED_TINT if damaged else tint
	_damage_sparks.emitting = damaged
	if damaged:
		_level_label.text = "%s · rozbitý" % display_name
	elif is_being_repaired():
		_level_label.text = "%s · v opravě" % display_name
	else:
		_level_label.text = display_name
