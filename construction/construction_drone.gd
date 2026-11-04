class_name ConstructionDrone
extends Node2D

## Stavební dron Bzučák. Postupně staví a vylepšuje budovy ze své fronty zakázek:
## doletí k budově, odpracuje zakázku a pokračuje další. Když nemá co dělat,
## vrátí se ke svému stanovišti. Pozice jsou v souřadnicích stanice.
## Naléhavé zakázky (oprava androida) jdou na začátek fronty, rozdělaná práce počká.
## Vylepšuje se rychlost letu a rychlost práce (okamžitě, od mise, která to povolí).

## Levely rychlosti letu (px/s) a rychlosti práce (násobek) s cenou vylepšení na tento level.
const SPEED_LEVELS := [
	{"speed": 170.0, "cost": 0},
	{"speed": 230.0, "cost": 2000},
	{"speed": 300.0, "cost": 4000},
]
const WORK_LEVELS := [
	{"factor": 1.0, "cost": 0},
	{"factor": 1.4, "cost": 2500},
	{"factor": 1.8, "cost": 5000},
]
## Jak vysoko nad budovou dron při práci visí.
const HOVER_OFFSET := Vector2(0, -26)

@export var display_name := "Bzučák"
## Jméno ve 4. pádě („čeká na Bzučáka“).
@export var accusative := "Bzučáka"

var speed_level := 1
var work_level := 1
## Jestli jde dron v aktuální misi vylepšovat (nastavuje kampaň).
var upgrades_available := false

var _jobs: Array[ConstructionJob] = []
## Zakázka, na které dron právě pracuje (je u cíle), nebo null.
var _working_job: ConstructionJob
var _home: Vector2
var _time := 0.0

@onready var _body: Node2D = $Body
@onready var _shadow: DropShadow = $Body/Shadow
@onready var _sparks: Polygon2D = $Body/Sparks
@onready var _beam: Line2D = $Body/Beam
@onready var _beam_light: PointLight2D = $Body/BeamLight


func _ready() -> void:
	_home = position


func _process(delta: float) -> void:
	_time += delta
	_body.position.y = sin(_time * 4.0) * 2.0
	_body.rotation = sin(_time * 2.5) * 0.06
	# Bzučák visí HOVER_OFFSET nad budovou: stín leží na ní a s jeho pohupováním se nehýbe.
	_shadow.ground_offset = -HOVER_OFFSET - _body.position
	var working := false
	_working_job = null
	if _jobs.is_empty():
		position = position.move_toward(_home, speed() * delta)
	else:
		var job := _jobs[0]
		var site := (get_parent() as Node2D).to_local(job.target.global_position) + HOVER_OFFSET
		if position.distance_to(site) < 2.0:
			position = site
			working = true
			_working_job = job
			if job.work(delta * work_factor()):
				_jobs.pop_front()
				_working_job = null
		else:
			position = position.move_toward(site, speed() * delta)
	Sfx.set_loop("weld", working)
	_beam.visible = working
	_sparks.visible = working and fmod(_time, 0.3) < 0.15
	_sparks.rotation = _time * 10.0
	_beam_light.visible = working
	_beam_light.energy = 1.1 if _sparks.visible else 0.6


## Přidá zakázku do fronty. Naléhavá jde na začátek (rozdělaná zakázka si drží postup).
func add_job(job: ConstructionJob, urgent := false) -> void:
	if urgent:
		_jobs.push_front(job)
	else:
		_jobs.append(job)


## Všechna vylepšení na maximum (start mise Z).
func set_maxed() -> void:
	speed_level = SPEED_LEVELS.size()
	work_level = WORK_LEVELS.size()


func speed() -> float:
	return SPEED_LEVELS[speed_level - 1].speed


func work_factor() -> float:
	return WORK_LEVELS[work_level - 1].factor


func next_speed_cost() -> int:
	if not upgrades_available or speed_level >= SPEED_LEVELS.size():
		return -1
	return SPEED_LEVELS[speed_level].cost


func next_work_cost() -> int:
	if not upgrades_available or work_level >= WORK_LEVELS.size():
		return -1
	return WORK_LEVELS[work_level].cost


func sale_items() -> Array[ShopItem]:
	var items: Array[ShopItem] = []
	if speed_level > 1:
		items.append(ShopItem.sale("%s: rychlost letu, level %d" % [display_name, speed_level],
				SPEED_LEVELS[speed_level - 1].cost, func() -> void: speed_level -= 1))
	if work_level > 1:
		items.append(ShopItem.sale("%s: rychlost práce, level %d" % [display_name, work_level],
				WORK_LEVELS[work_level - 1].cost, func() -> void: work_level -= 1))
	return items


func upgrade_speed() -> bool:
	var cost := next_speed_cost()
	if cost < 0 or not Game.spend_credits(cost):
		return false
	speed_level += 1
	return true


func upgrade_work() -> bool:
	var cost := next_work_cost()
	if cost < 0 or not Game.spend_credits(cost):
		return false
	work_level += 1
	return true


## Jestli dron na téhle zakázce právě pracuje (je u cíle).
func is_working_on(job: ConstructionJob) -> bool:
	return job != null and _working_job == job


## Jestli zakázka čeká ve frontě (dron zatím pracuje na jiné).
func is_waiting(job: ConstructionJob) -> bool:
	return _jobs.find(job) > 0


func info_title() -> String:
	return display_name


func info_lines() -> PackedStringArray:
	var lines := PackedStringArray([
		"Stavební dron. Staví budovy po částech, vylepšuje je, opravuje Pumpíka a sbírá kořist po pirátech.",
	])
	if _jobs.is_empty():
		lines.append("Teď nemá práci, odpočívá u zásobníku.")
	else:
		var job := _jobs[0]
		lines.append("Pracuje na: %s, %s" % [job.target.info_title(), job.status_text(self).to_lower()])
		if _jobs.size() > 1:
			lines.append("Ve frontě čeká zakázek: %d" % (_jobs.size() - 1))
	if upgrades_available or speed_level > 1 or work_level > 1:
		lines.append("Let: level %d (%d px/s), práce: level %d (%d %% rychlosti)" % [
			speed_level, roundi(speed()), work_level, roundi(work_factor() * 100.0)])
	return lines


func info_actions() -> Array[ShopItem]:
	var actions: Array[ShopItem] = [
		ShopItem.new(func() -> String: return "Rychlejší let: level %d" % (speed_level + 1),
				next_speed_cost, upgrade_speed, ShopItem.Kind.UPGRADE),
		ShopItem.new(func() -> String: return "Rychlejší práce: level %d" % (work_level + 1),
				next_work_cost, upgrade_work, ShopItem.Kind.UPGRADE),
	]
	return actions
