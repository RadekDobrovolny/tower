class_name Campaign
extends Node2D

## Kontinuální hra. Stanice běží pořád dál a mise (úkoly) jdou jedna za druhou.
## Když hráč splní cíle mise, hra se zastaví, ukáže shrnutí a další misi a po potvrzení
## pokračuje se vším, co hráč do té doby postavil a vydělal. Po poslední misi je volná hra.
## Hra může začít od kterékoli mise (výběr v menu); pak se použije startovní stav té mise.
## Mise Z začíná rovnou volnou hrou se vším na maximu.

signal mission_started(number: int)
signal mission_completed(number: int)

## Aktuální mise, nebo null ve volné hře po splnění všech misí.
var mission: Mission
var mission_index := 0
## Herní čas od začátku aktuální mise v sekundách.
var mission_elapsed := 0.0

## Mise je splněná a hra čeká, až hráč potvrdí okno se shrnutím.
var _completed := false
var _dual_hose_told := false

@onready var station: Station = $Station
@onready var spawner: ShipSpawner = $ShipSpawner
@onready var pirate_spawner: PirateSpawner = $PirateSpawner
@onready var junk_dealer: JunkDealer = $JunkDealer
@onready var zora_scene: ZoraScene = $ZoraScene
@onready var hud: Hud = $HUD


func _ready() -> void:
	var free_play := Game.start_mission == Missions.FREE_PLAY_INDEX
	var start_index := clampi(Game.start_mission, 0, Missions.ALL.size() - 1)
	var start: Mission = Missions.FREE_PLAY if free_play else Missions.ALL[start_index]
	_apply_start_state(start)
	# Odloženě, aby se cíle vyhodnotily až po všech změnách v daném snímku
	# (např. loď nejdřív zaplatí a teprve pak se započítá jako obsloužená).
	Game.credits_changed.connect(_check_goals.unbind(1), CONNECT_DEFERRED)
	station.state_changed.connect(_check_goals, CONNECT_DEFERRED)
	station.state_changed.connect(_check_dual_hose_story, CONNECT_DEFERRED)
	zora_scene.finished.connect(_check_goals, CONNECT_DEFERRED)
	Game.stats_changed.connect(_check_goals, CONNECT_DEFERRED)
	hud.setup(self)
	junk_dealer.arrived.connect(hud.show_junk_dealer.bind(junk_dealer))
	if free_play:
		_apply_rules(start)
		_begin_free_play()
		hud.dialogue.play(Story.FREE_PLAY_INTRO)
		return
	_begin_mission(start_index)
	hud.dialogue.play(Story.MISSION_INTROS[start_index])


func _exit_tree() -> void:
	Sfx.stop_loops()


func _process(delta: float) -> void:
	mission_elapsed += delta


## Pořadové číslo aktuální mise (od 1), ve volné hře 0.
func number() -> int:
	return mission_index + 1 if mission else 0


## Zavře, co je zrovna otevřené (rozhovor, nebo okno se shrnutím mise), a pokračuje ve hře,
## případně další misí s jejím úvodem.
func continue_game() -> void:
	if hud.dialogue.is_open():
		hud.dialogue.close()
		return
	hud.hide_mission_popup()
	get_tree().paused = false
	if not _completed:
		return
	_completed = false
	if mission_index + 1 < Missions.ALL.size():
		_begin_mission(mission_index + 1)
		hud.dialogue.play(Story.MISSION_INTROS[mission_index])
	else:
		_begin_free_play()


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
	if station.warehouse:
		items.append_array(station.warehouse.info_actions())
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
		var built_only := mission.goal_entertainment_level == 1
		goals.append(_goal("Postavit zábavní systém" if built_only else "Zábavní systém na levelu %d" % mission.goal_entertainment_level,
				station.entertainment_level(), mission.goal_entertainment_level))
	if mission.goal_tank_level > 0:
		goals.append(_goal("Zásobník na levelu %d" % mission.goal_tank_level,
				station.tank.level, mission.goal_tank_level))
	if mission.goal_slots > 0:
		goals.append(_goal("Čerpací sloty: %d" % mission.goal_slots, station.get_slots().size(), mission.goal_slots))
	if mission.goal_shop:
		goals.append(_goal("Postavit obchod", 1 if station.shop_products() >= 0 else 0, 1))
	if mission.goal_shop_products > 0:
		goals.append(_goal("Přidat do obchodu %s" % Shop.kinds_text(mission.goal_shop_products),
				maxi(station.shop_products(), 0), mission.goal_shop_products))
	if mission.goal_dispatch:
		goals.append(_goal("Automatický dispečink", 1 if station.has_dispatch() else 0, 1))
	if mission.goal_warehouse:
		goals.append(_goal("Postavit skladiště u obchodu", 1 if station.has_warehouse() else 0, 1))
	if mission.goal_pirates_shot > 0:
		goals.append(_goal("Sestřelit %d pirátů" % mission.goal_pirates_shot,
				Game.pirates_shot, mission.goal_pirates_shot))
	if mission.goal_tower_level > 0:
		var tower_label := "Postavit obrannou věž" if mission.goal_tower_level == 1 \
				else "Obranná věž na levelu %d" % mission.goal_tower_level
		goals.append(_goal(tower_label, station.best_tower_level(), mission.goal_tower_level))
	if mission.goal_towers > 0:
		goals.append(_goal("Obranné věže: %d" % mission.goal_towers, station.get_towers().size(), mission.goal_towers))
	if mission.goal_reliability > 0:
		var level: int = station.control_center.levels.reliability if station.control_center else 0
		goals.append(_goal("Spolehlivé dodávky na levelu %d" % mission.goal_reliability, level, mission.goal_reliability))
	if mission.goal_drone_speed > 0:
		goals.append(_goal("%s: rychlost letu na levelu %d" % [station.drone.display_name, mission.goal_drone_speed],
				station.drone.speed_level, mission.goal_drone_speed))
	if mission.goal_drone_work > 0:
		goals.append(_goal("%s: rychlost práce na levelu %d" % [station.drone.display_name, mission.goal_drone_work],
				station.drone.work_level, mission.goal_drone_work))
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
	if start.start_maxed:
		station.setup_maxed()
		return
	for android in station.get_androids():
		android.set_levels(start.start_fuel_level, start.start_walk_level)
		android.set_dual_hose(start.start_dual_hose)
	station.setup_start_buildings(start.start_slots, start.start_entertainment_level,
			start.start_shop_products, start.start_control_center, start.start_tower_level)
	if start.start_warehouse:
		station.place_warehouse_ready()
	if start.start_towers > 1:
		station.place_second_tower(start.start_tower_level)
	station.tank.set_level(start.start_tank_level)


## Zapne pravidla mise. Stav stanice (kredity, vylepšení, sloty) zůstává.
func _begin_mission(index: int) -> void:
	mission_index = index
	mission = Missions.ALL[index]
	mission_elapsed = 0.0
	_apply_rules(mission)
	zora_scene.active = mission.zora_scene
	station.ship_tier = number()
	hud.refresh_mission()
	mission_started.emit(number())


func _apply_rules(rules: Mission) -> void:
	for android in station.get_androids():
		android.max_level = rules.max_android_level
	station.max_slots = rules.max_slots
	station.dual_hose_available = rules.dual_hose_available
	station.entertainment_available = rules.entertainment_available
	station.shop_available = rules.shop_available
	station.control_center_available = rules.control_center_available
	station.tower_available = rules.tower_available
	station.warehouse_available = rules.warehouse_available
	station.drone.upgrades_available = rules.drone_upgrades
	if rules.galaxin_economy and not station.galaxin_economy:
		station.enable_galaxin_economy(rules.start_galaxin)
	spawner.min_interval = rules.ship_interval_min
	spawner.max_interval = rules.ship_interval_max
	pirate_spawner.min_interval = rules.pirate_interval_min
	pirate_spawner.max_interval = rules.pirate_interval_max
	pirate_spawner.enabled = rules.pirates


func _begin_free_play() -> void:
	mission = null
	station.ship_tier = Missions.ALL.size()
	mission_elapsed = 0.0
	hud.refresh_mission()


func _pause_with_popup(title: String, body: String, button_text: String) -> void:
	get_tree().paused = true
	hud.show_mission_popup(title, body, button_text)


## Když se otevře druhá hadice, Pumpík o ní hráči řekne (jen jednou za hru).
func _check_dual_hose_story() -> void:
	if _dual_hose_told or _completed or hud.dialogue.is_open() or not station.dual_hose_unlocked():
		return
	if station.get_androids().all(func(android: Android) -> bool: return android.has_dual_hose()):
		return
	_dual_hose_told = true
	hud.dialogue.play(Story.DUAL_HOSE_UNLOCKED)


func _android_name() -> String:
	var androids := station.get_androids()
	return androids[0].display_name if not androids.is_empty() else "Android"


func _best_fuel_level() -> int:
	var best := 0
	for android in station.get_androids():
		best = maxi(best, android.fuel_level)
	return best


func _check_goals() -> void:
	if mission == null or _completed or hud.dialogue.is_open():
		return
	if mission.zora_scene and not zora_scene.done:
		return
	for goal in get_goals():
		if not goal.done:
			return
	_completed = true
	Sfx.play("mission_done")
	var seconds := int(mission_elapsed)
	var summary := "Čas mise: %d:%02d" % [seconds / 60, seconds % 60]
	mission_completed.emit(number())
	if mission_index + 1 < Missions.ALL.size():
		var next: Mission = Missions.ALL[mission_index + 1]
		_pause_with_popup("Mise %d splněna!" % number(),
				"%s\n\nDalší mise %d: %s" % [summary, number() + 1, next.title],
				"Pokračovat")
	else:
		_pause_with_popup("Mise %d splněna!" % number(),
				"%s\n\nSplnil jsi všechny mise. Stanice je tvoje, hraj dál, jak dlouho chceš." % summary,
				"Hrát dál")
