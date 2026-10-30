class_name ConstructionJob
extends RefCounted

## Jedna zakázka pro stavebního drona: stavba nové budovy nebo vylepšení. Skládá se z fází,
## každá trvá nějakou dobu. Po dokončení fáze a celé zakázky volá zadané funkce.

## Kam dron letí: budova nebo zásobník (uzel ve stanici).
var target: Node2D
## Např. „Stavba: Zábavní systém“.
var title: String
## Fáze: [{"name": String, "duration": float (s)}].
var phases: Array
## Index právě rozpracované fáze (== phases.size() znamená hotovo).
var phase := 0
var phase_time := 0.0
## (počet hotových fází: int) -> void
var on_phase_done: Callable
## () -> void
var on_done: Callable


func _init(job_target: Node2D, job_title: String, job_phases: Array) -> void:
	target = job_target
	title = job_title
	phases = job_phases


func is_done() -> bool:
	return phase >= phases.size()


## Odpracuje `delta` sekund. Vrátí true, když je celá zakázka hotová.
func work(delta: float) -> bool:
	if is_done():
		return true
	phase_time += delta
	if phase_time >= phases[phase].duration:
		phase_time = 0.0
		phase += 1
		if on_phase_done.is_valid():
			on_phase_done.call(phase)
		if is_done():
			if on_done.is_valid():
				on_done.call()
			return true
	return false


## Jak daleko je rozpracovaná fáze (0–1).
func phase_fraction() -> float:
	if is_done():
		return 1.0
	return phase_time / phases[phase].duration


func phase_name() -> String:
	return "" if is_done() else phases[phase].name


## Stav zakázky pro info panel.
func status_text(drone: ConstructionDrone) -> String:
	if drone.is_waiting(self):
		return "%s: čeká na %s" % [title, drone.accusative]
	if phases.size() == 1:
		return "%s: %s (%d %%)" % [title, phase_name(), roundi(phase_fraction() * 100.0)]
	return "%s, fáze %d/%d: %s (%d %%)" % [
		title, phase + 1, phases.size(), phase_name(), roundi(phase_fraction() * 100.0),
	]
