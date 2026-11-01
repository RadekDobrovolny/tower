class_name ConstructionJob
extends RefCounted

## Jedna zakázka pro stavebního drona: část stavby, vylepšení, oprava nebo sběr kořisti.
## Po dokončení volá zadanou funkci.

## Kam dron letí: budova, zásobník, android nebo kořist.
var target: Node2D
## Např. „Stavba, část 1/4“.
var title: String
## Co dron dělá: {"name": String, "duration": float (s)}.
var phase: Dictionary
var phase_time := 0.0
## () -> void
var on_done: Callable


func _init(job_target: Node2D, job_title: String, job_phase: Dictionary) -> void:
	target = job_target
	title = job_title
	phase = job_phase


## Odpracuje `delta` sekund. Vrátí true, když je zakázka hotová.
func work(delta: float) -> bool:
	phase_time += delta
	if phase_time < phase.duration:
		return false
	if on_done.is_valid():
		on_done.call()
	return true


## Jak daleko je rozpracovaná zakázka (0–1).
func phase_fraction() -> float:
	return phase_time / phase.duration


func phase_name() -> String:
	return phase.name


## Stav zakázky pro info panel.
func status_text(drone: ConstructionDrone) -> String:
	if drone.is_waiting(self):
		return "%s: čeká na %s" % [title, drone.accusative]
	return "%s: %s (%d %%)" % [title, phase_name(), roundi(phase_fraction() * 100.0)]
