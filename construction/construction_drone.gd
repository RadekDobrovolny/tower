class_name ConstructionDrone
extends Node2D

## Stavební dron Bzučák. Postupně staví a vylepšuje budovy ze své fronty zakázek:
## doletí k budově, odpracuje zakázku a pokračuje další. Když nemá co dělat,
## vrátí se ke svému stanovišti. Pozice jsou v souřadnicích stanice.

const SPEED := 170.0
## Jak vysoko nad budovou dron při práci visí.
const HOVER_OFFSET := Vector2(0, -26)

@export var display_name := "Bzučák"
## Jméno ve 4. pádě („čeká na Bzučáka“).
@export var accusative := "Bzučáka"

var _jobs: Array[ConstructionJob] = []
var _home: Vector2
var _time := 0.0

@onready var _body: Node2D = $Body
@onready var _sparks: Polygon2D = $Body/Sparks
@onready var _beam: Line2D = $Body/Beam
@onready var _beam_light: PointLight2D = $Body/BeamLight


func _ready() -> void:
	_home = position


func _process(delta: float) -> void:
	_time += delta
	_body.position.y = sin(_time * 4.0) * 2.0
	_body.rotation = sin(_time * 2.5) * 0.06
	var working := false
	if _jobs.is_empty():
		position = position.move_toward(_home, SPEED * delta)
	else:
		var job := _jobs[0]
		var site := (get_parent() as Node2D).to_local(job.target.global_position) + HOVER_OFFSET
		if position.is_equal_approx(site):
			working = true
			if job.work(delta):
				_jobs.pop_front()
		else:
			position = position.move_toward(site, SPEED * delta)
	_beam.visible = working
	_sparks.visible = working and fmod(_time, 0.3) < 0.15
	_sparks.rotation = _time * 10.0
	_beam_light.visible = working
	_beam_light.energy = 1.1 if _sparks.visible else 0.6


func add_job(job: ConstructionJob) -> void:
	_jobs.append(job)


## Jestli zakázka čeká ve frontě (dron zatím pracuje na jiné).
func is_waiting(job: ConstructionJob) -> bool:
	return _jobs.find(job) > 0


func info_title() -> String:
	return display_name


func info_lines() -> PackedStringArray:
	var lines := PackedStringArray(["Stavební dron. Staví budovy po částech a vylepšuje je."])
	if _jobs.is_empty():
		lines.append("Teď nemá práci, odpočívá u zásobníku.")
		return lines
	var job := _jobs[0]
	lines.append("Pracuje na: %s, %s" % [job.target.info_title(), job.status_text(self).to_lower()])
	if _jobs.size() > 1:
		lines.append("Ve frontě čeká zakázek: %d" % (_jobs.size() - 1))
	return lines


func info_actions() -> Array[ShopItem]:
	var actions: Array[ShopItem] = []
	return actions
