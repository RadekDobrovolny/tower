class_name Campaign
extends Node2D

## Kontinuální hra. Stanice běží pořád dál a mise (úkoly) jdou jedna za druhou.
## Když hráč splní cíle mise, hra se zastaví, ukáže shrnutí a další misi a po potvrzení
## pokračuje se vším, co hráč do té doby postavil a vydělal. Po poslední misi je volná hra.
## Hra může začít od kterékoli mise (výběr v menu); pak se použije startovní stav té mise.

signal mission_started(number: int)
signal mission_completed(number: int)

## Aktuální mise, nebo null ve volné hře po splnění všech misí.
var mission: Mission
var mission_index := 0
## Herní čas od začátku aktuální mise v sekundách.
var mission_elapsed := 0.0

## Mise je splněná a hra čeká, až hráč potvrdí okno se shrnutím.
var _completed := false

@onready var station: Station = $Station
@onready var spawner: ShipSpawner = $ShipSpawner
@onready var pirate_spawner: PirateSpawner = $PirateSpawner
@onready var hud: Hud = $HUD


func _ready() -> void:
	var start_index := clampi(Game.start_mission, 0, Missions.ALL.size() - 1)
	_apply_start_state(Missions.ALL[start_index])
	# Odloženě, aby se cíle vyhodnotily až po všech změnách v daném snímku
	# (např. loď nejdřív zaplatí a teprve pak se započítá jako obsloužená).
	Game.credits_changed.connect(_check_goals.unbind(1), CONNECT_DEFERRED)
	station.state_changed.connect(_check_goals, CONNECT_DEFERRED)
	Game.stats_changed.connect(_check_goals, CONNECT_DEFERRED)
	hud.setup(self)
	_begin_mission(start_index)
	_pause_with_popup("Mise %d: %s" % [number(), mission.title], _briefing(mission), "Začít")


func _process(delta: float) -> void:
	mission_elapsed += delta


## Pořadové číslo aktuální mise (od 1), ve volné hře 0.
func number() -> int:
	return mission_index + 1 if mission else 0


## Zavře okno mise (úvod nebo shrnutí) a pokračuje ve hře, případně další misí.
func continue_game() -> void:
	if _completed:
		_completed = false
		if mission_index + 1 < Missions.ALL.size():
			_begin_mission(mission_index + 1)
		else:
			_begin_free_play()
	hud.hide_mission_popup()
	get_tree().paused = false


## Všechno, co jde teď koupit (vylepšení objektů a stavby na první prázdné parcele).
## Hráč to dělá kliknutím na objekty, tohle používá hlavně robotický hráč v simulaci.
func get_shop_items() -> Array[ShopItem]:
	var items: Array[ShopItem] = []
	for android in station.get_androids():
		items.append_array(android.info_actions())
	items.append_array(station.tank.info_actions())
	for plot in station.get_plots():
		if plot.building:
			items.append_array(plot.building.info_actions())
	items.append_array(station.drone.info_actions())
	if station.control_center:
		items.append_array(station.control_center.info_actions())
	for kind in Plot.Kind.values():
		var empty_plot := station.first_empty_plot(kind)
		if empty_plot:
			items.append_array(station.build_options(empty_plot))
	return items


## Cíle aktuální mise pro HUD: popisek, postup („150 / 2 000“ a 0..1) a jestli je splněný.
func get_goals() -> Array[Dictionary]:
	var goals: Array[Dictionary] = []
	if mission == null:
		return goals
	if mission.goal_credits > 0:
		goals.append(_goal("Naspořit %s kr" % Game.format_number(mission.goal_credits),
				clampi(Game.credits, 0, mission.goal_credits), mission.goal_credits))
	if mission.goal_fuel_level > 0:
		goals.append(_goal("%s: tankování na levelu %d" % [_android_name(), mission.goal_fuel_level],
				_best_fuel_level(), mission.goal_fuel_level))
	if mission.goal_entertainment_level > 0:
		goals.append(_goal("Zábavní systém na levelu %d" % mission.goal_entertainment_level,
				station.entertainment_level(), mission.goal_entertainment_level))
	if mission.goal_tank_level > 0:
		goals.append(_goal("Zásobník na levelu %d" % mission.goal_tank_level,
				station.tank.level, mission.goal_tank_level))
	if mission.goal_shop_products > 0:
		goals.append(_goal("Obchod: %d nové druhy zboží" % mission.goal_shop_products,
				maxi(station.shop_products(), 0), mission.goal_shop_products))
	if mission.goal_dispatch:
		goals.append(_goal("Automatický dispečink", 1 if station.has_dispatch() else 0, 1))
	if mission.goal_tower_level > 0:
		goals.append(_goal("Obranná věž na levelu %d" % mission.goal_tower_level,
				station.best_tower_level(), mission.goal_tower_level))
	if mission.goal_pirates_shot > 0:
		goals.append(_goal("Sestřelit %d pirátů" % mission.goal_pirates_shot,
				Game.pirates_shot, mission.goal_pirates_shot))
	return goals


func _goal(label: String, value: int, target: int) -> Dictionary:
	var reached := mini(value, target)
	return {
		"label": label,
		"value": "%s / %s" % [Game.format_number(reached), Game.format_number(target)],
		"progress": float(reached) / target,
		"done": reached >= target,
	}


## Nastaví stanici do stavu, ve kterém má mise začínat, když se hraje rovnou od ní.
func _apply_start_state(start: Mission) -> void:
	Game.reset(start.start_credits)
	for android in station.get_androids():
		android.set_levels(start.start_fuel_level, start.start_walk_level)
	station.setup_start_buildings(start.start_slots, start.start_entertainment_level,
			start.start_shop_products, start.start_control_center, start.start_tower_level)
	station.tank.set_level(start.start_tank_level)


## Zapne pravidla mise. Stav stanice (kredity, vylepšení, sloty) zůstává.
func _begin_mission(index: int) -> void:
	mission_index = index
	mission = Missions.ALL[index]
	mission_elapsed = 0.0
	for android in station.get_androids():
		android.max_level = mission.max_android_level
	station.max_slots = mission.max_slots
	station.entertainment_available = mission.entertainment_available
	station.shop_available = mission.shop_available
	station.control_center_available = mission.control_center_available
	station.tower_available = mission.tower_available
	station.drone.upgrades_available = mission.drone_upgrades
	if mission.galaxin_economy and not station.galaxin_economy:
		station.enable_galaxin_economy(mission.start_galaxin)
	spawner.min_interval = mission.ship_interval_min
	spawner.max_interval = mission.ship_interval_max
	pirate_spawner.min_interval = mission.pirate_interval_min
	pirate_spawner.max_interval = mission.pirate_interval_max
	pirate_spawner.enabled = mission.pirates
	hud.refresh_mission()
	mission_started.emit(number())


func _begin_free_play() -> void:
	mission = null
	mission_elapsed = 0.0
	hud.refresh_mission()


func _pause_with_popup(title: String, body: String, button_text: String) -> void:
	get_tree().paused = true
	hud.show_mission_popup(title, body, button_text)


## Úvodní text mise se seznamem cílů.
func _briefing(briefed: Mission) -> String:
	var lines := PackedStringArray([briefed.description, "", "Cíle:"])
	if briefed.goal_credits > 0:
		lines.append("- Naspořit %s kr" % Game.format_number(briefed.goal_credits))
	if briefed.goal_fuel_level > 0:
		lines.append("- %s: tankování na levelu %d" % [_android_name(), briefed.goal_fuel_level])
	if briefed.goal_entertainment_level > 0:
		lines.append("- Zábavní systém na levelu %d" % briefed.goal_entertainment_level)
	if briefed.goal_tank_level > 0:
		lines.append("- Zásobník na levelu %d" % briefed.goal_tank_level)
	if briefed.goal_shop_products > 0:
		lines.append("- Obchod a v něm %d nové druhy zboží" % briefed.goal_shop_products)
	if briefed.goal_dispatch:
		lines.append("- Řídící centrum s automatickým dispečinkem")
	if briefed.goal_tower_level > 0:
		lines.append("- Obranná věž na levelu %d" % briefed.goal_tower_level)
	if briefed.goal_pirates_shot > 0:
		lines.append("- Sestřelit %d pirátů" % briefed.goal_pirates_shot)
	return "\n".join(lines)


func _android_name() -> String:
	var androids := station.get_androids()
	return androids[0].display_name if not androids.is_empty() else "Android"


func _best_fuel_level() -> int:
	var best := 0
	for android in station.get_androids():
		best = maxi(best, android.fuel_level)
	return best


func _check_goals() -> void:
	if mission == null or _completed:
		return
	for goal in get_goals():
		if not goal.done:
			return
	_completed = true
	var seconds := int(mission_elapsed)
	var summary := "Čas mise: %d:%02d" % [seconds / 60, seconds % 60]
	mission_completed.emit(number())
	if mission_index + 1 < Missions.ALL.size():
		var next: Mission = Missions.ALL[mission_index + 1]
		_pause_with_popup("Mise %d splněna!" % number(),
				"%s\n\nDalší mise %d: %s\n%s" % [summary, number() + 1, next.title, _briefing(next)],
				"Pokračovat")
	else:
		_pause_with_popup("Mise %d splněna!" % number(),
				"%s\n\nSplnil jsi všechny mise. Stanice je tvoje, hraj dál, jak dlouho chceš." % summary,
				"Hrát dál")
