class_name Building
extends Node2D

## Budova na parcele stanice. Staví se po částech: hráč zaplatí další část a stavební dron
## ji postaví. Budova funguje, až je hotová celá. Stejný dron ji pak i vylepšuje.
## Potomci určují části stavby, vzhled po částech a obsah info panelu
## (info_title, info_lines, info_actions).

## Kde nad středem budovy visí ukazatel rozpracované zakázky.
const OVERLAY_POSITION := Vector2(-70, -84)

var station: Station
## Parcela, na které budova stojí.
var plot: Plot
var built_phases := 0
## Zakázka drona pro tuhle budovu (stavba nebo vylepšení), nebo null.
var job: ConstructionJob

var _overlay: VBoxContainer
var _overlay_label: Label
var _overlay_bar: ProgressBar


func _ready() -> void:
	_create_overlay()
	_update_construction_looks()


func _process(_delta: float) -> void:
	# Ukazatel je vidět, když se na budově pracuje, a u rozestavěné budovy i mezi částmi.
	_overlay.visible = job != null or not is_operational()
	_overlay_bar.visible = job != null
	if job:
		_overlay_label.text = "Čeká na %s" % station.drone.accusative if station.drone.is_waiting(job) else job.phase_name()
		_overlay_bar.value = job.phase_fraction()
	elif not is_operational():
		_overlay_label.text = "Další část: %s" % build_phases()[built_phases].name


## Části stavby: [{"name": String, "cost": int, "duration": float}]. Přepisují potomci.
func build_phases() -> Array:
	return []


func display_name() -> String:
	return ""


func is_operational() -> bool:
	return built_phases >= build_phases().size()


## Nastaví, kolik částí stavby je hotových, a podle toho budovu ukáže.
func complete_phase(count: int) -> void:
	built_phases = count
	_update_construction_looks()


## Celková cena stavby (součet cen všech částí).
func total_cost() -> int:
	var total := 0
	for phase in build_phases():
		total += phase.cost
	return total


## Cena další části stavby, nebo -1, když teď další část postavit nejde
## (budova je hotová, nebo se na ní právě pracuje).
func next_phase_cost() -> int:
	if is_operational() or job != null:
		return -1
	return build_phases()[built_phases].cost


## Zaplatí další část stavby a zadá ji stavebnímu dronovi. Vrátí, jestli se to povedlo.
func start_next_phase() -> bool:
	var cost := next_phase_cost()
	if cost < 0 or not Game.spend_credits(cost):
		return false
	var phase: Dictionary = build_phases()[built_phases]
	station.queue_job(self, "Stavba, část %d/%d" % [built_phases + 1, build_phases().size()],
			[phase], Callable(), _on_phase_built)
	return true


## Postaví budovu hned celou (startovní stav mise).
func finish_instantly() -> void:
	complete_phase(build_phases().size())


## Řádek o rozpracované zakázce pro info panel, nebo prázdný text.
func job_line() -> String:
	return "" if job == null else job.status_text(station.drone)


## Stav rozestavěné budovy pro info panel.
func construction_line() -> String:
	if job:
		return job_line()
	return "Hotovo %d z %d částí. Další část: %s." % [
		built_phases, build_phases().size(), build_phases()[built_phases].name,
	]


func info_title() -> String:
	return display_name()


func info_lines() -> PackedStringArray:
	return PackedStringArray()


## Rozestavěná budova nabízí postavit další část. Hotové budovy přidávají svá vylepšení.
func info_actions() -> Array[ShopItem]:
	var actions: Array[ShopItem] = []
	if not is_operational():
		actions.append(ShopItem.new(_next_phase_label, next_phase_cost, start_next_phase))
	return actions


func _next_phase_label() -> String:
	return "Postavit: %s" % build_phases()[built_phases].name


func _on_phase_built() -> void:
	complete_phase(built_phases + 1)
	if is_operational():
		station.on_building_finished(self)


## Ukáže části budovy podle hotových fází. Potomci rozšiřují (volat super).
func _update_construction_looks() -> void:
	if plot:
		plot.set_outline_visible(built_phases == 0)


func _create_overlay() -> void:
	_overlay = VBoxContainer.new()
	_overlay.position = OVERLAY_POSITION
	_overlay.custom_minimum_size = Vector2(140, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.z_index = 6
	_overlay.add_theme_constant_override("separation", 2)
	_overlay_label = Label.new()
	_overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_label.add_theme_font_size_override("font_size", 12)
	_overlay_label.add_theme_constant_override("outline_size", 3)
	_overlay_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_overlay_bar = ProgressBar.new()
	_overlay_bar.custom_minimum_size = Vector2(140, 6)
	_overlay_bar.max_value = 1.0
	_overlay_bar.step = 0.0
	_overlay_bar.show_percentage = false
	_overlay_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_overlay_label)
	_overlay.add_child(_overlay_bar)
	_overlay.hide()
	add_child(_overlay)
