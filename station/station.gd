class_name Station
extends Node2D

## Čerpací stanice. Spravuje parcely a budovy na nich (stavby a vylepšení dělá stavební
## dron), přiděluje lodím sloty a místa ve frontě, posílá k nim androidy, řídí výběr
## objektů kliknutím a prodejní cenu galaxínu. Když útočí piráti a stanice nemá hotovou
## obrannou věž, pošle proti nim androida.

## Hráč kliknutím vybral objekt (android, zásobník, budova, prázdná parcela) nebo nic (null).
signal selection_changed(object: Node)
## Něco se postavilo, vylepšilo nebo koupilo (pro cíle misí).
signal state_changed

## Běžná cena galaxínu (kr/j). Bez ekonomiky galaxínu se nedá měnit.
const BASE_PRICE := 6
const MIN_PRICE := 3
const MAX_PRICE := 12
const BUILDING_SCENES := {
	"fuel_slot": preload("res://station/fuel_slot.tscn"),
	"entertainment": preload("res://station/entertainment_system.tscn"),
	"shop": preload("res://station/shop.tscn"),
	"tower": preload("res://defense/defense_tower.tscn"),
}
## Názvy budov a text tlačítka, kterým se stavba začíná.
const BUILDING_NAMES := {
	"fuel_slot": "Čerpací slot", "entertainment": "Zábavní systém", "shop": "Obchod", "tower": "Obranná věž",
}
const BUILD_LABELS := {
	"fuel_slot": "Začít stavět čerpací slot", "entertainment": "Začít stavět zábavní systém",
	"shop": "Začít stavět obchod", "tower": "Začít stavět obrannou věž",
}
const CONTROL_CENTER_SCENE := preload("res://economy/control_center.tscn")
## Od jakého levelu zásobníku jde k němu přistavět řídící centrum.
const CONTROL_CENTER_TANK_LEVEL := 3
## Na které parcely (indexy) se ve startovním stavu mise staví čerpací sloty, zábavní systém,
## obchod a obranná věž.
const START_SLOT_PLOTS := [0, 1, 2]
const START_SHOP_PLOT := 3
const START_ENTERTAINMENT_PLOT := 4
const START_TOWER_PLOT := 5
const PIPE_COLOR := Color(0.55, 0.32, 0.16)
## Jak blízko (px) k androidovi nebo zásobníku musí hráč kliknout, aby je vybral.
const ANDROID_PICK_RADIUS := 28.0
const TANK_PICK_RADIUS := 50.0
const DRONE_PICK_RADIUS := 18.0

## Pravidla aktuální mise (nastavuje kampaň).
var max_slots := 1
var entertainment_available := false
var shop_available := false
var tower_available := false
var control_center_available := false
var galaxin_economy := false
## Řídící centrum u zásobníku (i rozestavěné), nebo null.
var control_center: ControlCenter

## Prodejní cena galaxínu (kr/j).
var sell_price := BASE_PRICE
## Vybraný objekt, nebo null.
var selected: Node

## Lodě čekající ve frontě v pořadí, jak přiletěly (první je na řadě).
var _queue: Array[Ship] = []
## Na kterém místě fronty (index v QueuePoints) která loď čeká. Loď na svém místě zůstává,
## dokud nejde tankovat nebo neodletí, fronta se nepřeskládává.
var _queue_spots := {}
## Zakotvené lodě, které čekají, až se jich ujme android.
var _awaiting_service: Array[Ship] = []

@onready var tank: GalaxinTank = $Tank
@onready var supply: Supply = $Supply
@onready var drone: ConstructionDrone = $Drone
@onready var _plots: Node2D = $Plots
@onready var _pipes: Node2D = $Pipes
@onready var _queue_points: Node2D = $QueuePoints
@onready var _staff: Node2D = $Staff
@onready var _control_center_spot: Marker2D = $ControlCenterSpot
@onready var _selection_marker: Line2D = $SelectionMarker


func _ready() -> void:
	for plot in get_plots():
		plot.station = self
	for android in get_androids():
		android.station = self
		android.free_for_ship.connect(_on_android_free_for_ship)
		android.upgraded.connect(func(_android: Android) -> void: state_changed.emit())
	tank.station = self
	supply.tank = tank
	supply.station = self
	_apply_galaxin_economy()


func _process(_delta: float) -> void:
	_update_selection_marker()
	_defend_with_androids()


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	select(_pick(get_local_mouse_position()))
	get_viewport().set_input_as_handled()


func select(object: Node) -> void:
	selected = object
	selection_changed.emit(object)


func get_plots() -> Array[Plot]:
	var result: Array[Plot] = []
	result.assign(_plots.get_children())
	return result


## Hotové čerpací sloty, ke kterým můžou lodě přistávat.
func get_slots() -> Array[FuelSlot]:
	var result: Array[FuelSlot] = []
	for plot in get_plots():
		var slot := plot.building as FuelSlot
		if slot and slot.is_operational():
			result.append(slot)
	return result


## Počet čerpacích slotů včetně těch ve stavbě.
func slot_count() -> int:
	var count := 0
	for plot in get_plots():
		if plot.building is FuelSlot:
			count += 1
	return count


## Zábavní systém (i rozestavěný), nebo null.
func entertainment() -> EntertainmentSystem:
	for plot in get_plots():
		if plot.building is EntertainmentSystem:
			return plot.building
	return null


## Level fungujícího zábavního systému (0 = žádný nebo ještě nefunguje).
func entertainment_level() -> int:
	var system := entertainment()
	return system.level if system else 0


## Obchod (i rozestavěný), nebo null.
func shop() -> Shop:
	for plot in get_plots():
		if plot.building is Shop:
			return plot.building
	return null


## Kolik druhů zboží navíc obchod prodává (-1 = obchod není hotový).
func shop_products() -> int:
	var store := shop()
	return store.products.size() if store and store.is_operational() else -1


## Hotové obranné věže.
func get_towers() -> Array[DefenseTower]:
	var result: Array[DefenseTower] = []
	for plot in get_plots():
		var tower := plot.building as DefenseTower
		if tower and tower.is_operational():
			result.append(tower)
	return result


## Nejvyšší level hotové obranné věže (0 = žádná).
func best_tower_level() -> int:
	var best := 0
	for tower in get_towers():
		best = maxi(best, tower.level)
	return best


## Jestli řídící centrum objednává cisterny samo.
func has_dispatch() -> bool:
	return control_center != null and control_center.value("dispatch")


## Jak rychle ubývá trpělivost lodím ve frontě (1 = normálně). Zpomaluje ji zábavní systém i obchod.
func patience_drain() -> float:
	var system := entertainment()
	var store := shop()
	return (system.patience_drain() if system else 1.0) * (store.patience_drain() if store else 1.0)


## O kolik zábavní systém zvyšuje šanci na dýško.
func tip_bonus() -> float:
	var system := entertainment()
	return system.tip_bonus() if system else 0.0


## První prázdná parcela daného druhu, nebo null.
func first_empty_plot(kind := Plot.Kind.BUILDING) -> Plot:
	for plot in get_plots():
		if plot.is_empty() and plot.kind == kind:
			return plot
	return null


func get_androids() -> Array[Android]:
	var result: Array[Android] = []
	result.assign(_staff.get_children())
	return result


## Jméno androida v 5. pádě, kterým lodě oslovují obsluhu. Prázdné, když stanice žádného nemá.
func attendant_vocative() -> String:
	var androids := get_androids()
	return androids[0].vocative if not androids.is_empty() else ""


## Co jde postavit na prázdné parcele (položky pro info panel).
func build_options(plot: Plot) -> Array[ShopItem]:
	var options: Array[ShopItem] = []
	for type in _building_types(plot):
		options.append(ShopItem.new(func() -> String: return BUILD_LABELS[type],
				_build_cost.bind(type), build.bind(type, plot)))
	return options


## Začne stavbu: zaplatí první část a zadá ji stavebnímu dronovi. Další části platí hráč
## postupně v info panelu budovy. Vrátí, jestli se to povedlo.
func build(type: String, plot: Plot) -> bool:
	var cost := _build_cost(type)
	if not plot.is_empty() or not _building_types(plot).has(type) or cost < 0 or Game.credits < cost:
		return false
	var building := _place_building(type, plot)
	building.start_next_phase()
	select(building)
	state_changed.emit()
	return true


## Celé ceny staveb, které jde na prázdné parcele začít (řádky pro info panel parcely).
func build_price_lines(plot: Plot) -> PackedStringArray:
	var lines := PackedStringArray()
	for type in _building_types(plot):
		if _build_cost(type) >= 0:
			var phases := _build_phases(type)
			lines.append("%s: %d části, celkem %s kr" % [
				BUILDING_NAMES[type], phases.size(), Game.format_number(_total_cost(phases)),
			])
	return lines


## Cena první části řídícího centra, nebo -1, když ho teď postavit nejde
## (není povolené misí, zásobník nemá level 3, nebo už stojí).
func control_center_cost() -> int:
	if not control_center_available or not galaxin_economy or control_center != null \
			or tank.level < CONTROL_CENTER_TANK_LEVEL:
		return -1
	return ControlCenter.PHASES[0].cost


## Začne stavět řídící centrum vedle zásobníku. Vrátí, jestli se to povedlo.
func build_control_center() -> bool:
	var cost := control_center_cost()
	if cost < 0 or Game.credits < cost:
		return false
	_place_control_center().start_next_phase()
	select(control_center)
	state_changed.emit()
	return true


## Zadá stavebnímu dronovi zakázku na `target` (budova nebo zásobník; musí mít vlastnost `job`).
func queue_job(target: Node2D, title: String, phases: Array, on_phase_done: Callable,
		on_done: Callable) -> ConstructionJob:
	var job := ConstructionJob.new(target, title, phases)
	job.on_phase_done = on_phase_done
	job.on_done = func() -> void:
		target.set("job", null)
		if on_done.is_valid():
			on_done.call()
		state_changed.emit()
	target.set("job", job)
	drone.add_job(job)
	return job


## Postaví startovní budovy mise hned celé. `shop_products` -1 = bez obchodu,
## `control_center` 0 = bez řídícího centra, 1 = postavené, 2 = i s dispečinkem.
func setup_start_buildings(slots: int, entertainment_level: int, shop_products := -1,
		center := 0, tower_level := 0) -> void:
	var plots := get_plots()
	for i in mini(slots, START_SLOT_PLOTS.size()):
		_place_building("fuel_slot", plots[START_SLOT_PLOTS[i]]).finish_instantly()
	if entertainment_level > 0:
		var system := _place_building("entertainment", plots[START_ENTERTAINMENT_PLOT]) as EntertainmentSystem
		system.set_level(entertainment_level)
	if shop_products >= 0:
		(_place_building("shop", plots[START_SHOP_PLOT]) as Shop).set_products(shop_products)
	if center > 0:
		_place_control_center().set_ready(center >= 2)
	if tower_level > 0:
		(_place_building("tower", plots[START_TOWER_PLOT]) as DefenseTower).set_level(tower_level)


## Natáhne potrubí ze zásobníku k čerpacímu slotu (po poslední fázi stavby slotu).
func connect_pipe(slot: FuelSlot) -> void:
	var pipe_name := "Pipe%d" % slot.get_instance_id()
	if _pipes.has_node(pipe_name):
		return
	var pipe := Line2D.new()
	pipe.name = pipe_name
	pipe.points = PackedVector2Array([slot.pipe_position(), tank.position])
	pipe.width = 6.0
	pipe.default_color = PIPE_COLOR
	_pipes.add_child(pipe)


## Zapne ekonomiku galaxínu (omezený zásobník, dodavatelé, vlastní cena) a naplní zásobník.
func enable_galaxin_economy(initial_amount: float) -> void:
	galaxin_economy = true
	_apply_galaxin_economy()
	tank.amount = minf(initial_amount, tank.capacity())


func set_sell_price(value: int) -> void:
	sell_price = clampi(value, MIN_PRICE, MAX_PRICE)


## Kolikrát víc lodí přilétá než při běžné ceně. Levný galaxín láká, drahý odrazuje.
func demand_factor() -> float:
	return pow(float(BASE_PRICE) / sell_price, 1.5)


## Kolikrát rychleji lodím ubývá trpělivost kvůli ceně (drahý galaxín = netrpělivější lodě).
func price_patience_factor() -> float:
	return float(sell_price) / BASE_PRICE


## Popis zájmu lodí pro HUD.
func demand_text() -> String:
	var factor := demand_factor()
	if factor >= 1.5:
		return "velmi vysoký"
	if factor > 1.05:
		return "vysoký"
	if factor >= 0.95:
		return "běžný"
	if factor >= 0.6:
		return "nízký"
	return "velmi nízký"


## Jestli se ke stanici vejde další loď, ať už do volného slotu, nebo do fronty.
func has_room() -> bool:
	return _free_slot() != null or _queue.size() < _queue_points.get_child_count()


## Přijme novou loď: pošle ji rovnou k volnému slotu, nebo ji zařadí do fronty.
func admit(ship: Ship) -> void:
	ship.station = self
	ship.landed.connect(_on_ship_landed)
	ship.gave_up.connect(_on_ship_gave_up)
	var slot := _free_slot()
	if slot:
		_send_to_slot(ship, slot)
	else:
		var spot := _free_queue_spot()
		_queue.append(ship)
		_queue_spots[ship] = spot
		ship.go_to_queue(_queue_position(spot))


func _apply_galaxin_economy() -> void:
	tank.unlimited = not galaxin_economy
	supply.process_mode = Node.PROCESS_MODE_INHERIT if galaxin_economy else Node.PROCESS_MODE_DISABLED


func _place_control_center() -> ControlCenter:
	control_center = CONTROL_CENTER_SCENE.instantiate()
	control_center.station = self
	control_center.position = _control_center_spot.position
	add_child(control_center)
	# Pod androidem a dronem, nad zásobníkem.
	move_child(control_center, tank.get_index() + 1)
	return control_center


func _place_building(type: String, plot: Plot) -> Building:
	var building: Building = BUILDING_SCENES[type].instantiate()
	building.station = self
	building.plot = plot
	if building is FuelSlot:
		building.service_side = plot.service_side
		building.freed.connect(_on_slot_freed)
	plot.place(building)
	return building


## Budova je postavená celá: zábavní systém se zapne, nový slot si vezme loď z fronty.
func on_building_finished(building: Building) -> void:
	if building is EntertainmentSystem or building is DefenseTower:
		building.power_on()
	elif building is FuelSlot:
		# Nový slot hned nabídne lodi, která čeká ve frontě.
		_on_slot_freed(building)


## Co jde na parcele daného druhu stavět.
func _building_types(plot: Plot) -> Array:
	return ["tower"] if plot.kind == Plot.Kind.TOWER else ["fuel_slot", "entertainment", "shop"]


func _build_phases(type: String) -> Array:
	match type:
		"fuel_slot":
			return FuelSlot.PHASES
		"entertainment":
			return EntertainmentSystem.PHASES
		"shop":
			return Shop.PHASES
	return DefenseTower.PHASES


## Cena první části stavby, nebo -1, když ji teď začít nejde (pravidla mise, limit slotů,
## zábavní systém a obchod můžou být jen jednou).
func _build_cost(type: String) -> int:
	var allowed := false
	match type:
		"fuel_slot":
			allowed = slot_count() < max_slots
		"entertainment":
			allowed = entertainment_available and entertainment() == null
		"shop":
			allowed = shop_available and shop() == null
		"tower":
			allowed = tower_available
	return _build_phases(type)[0].cost if allowed else -1


func _total_cost(phases: Array) -> int:
	var total := 0
	for phase in phases:
		total += phase.cost
	return total


func _pick(point: Vector2) -> Node:
	if drone.position.distance_to(point) < DRONE_PICK_RADIUS:
		return drone
	for android in get_androids():
		if android.position.distance_to(point) < ANDROID_PICK_RADIUS:
			return android
	if tank.position.distance_to(point) < TANK_PICK_RADIUS:
		return tank
	if control_center and control_center.rect().has_point(point):
		return control_center
	for plot in get_plots():
		if plot.rect().has_point(point):
			return plot.building if plot.building else plot
	return null


func _update_selection_marker() -> void:
	if not is_instance_valid(selected):
		selected = null
	_selection_marker.visible = selected != null
	if selected == null:
		return
	var rect: Rect2
	if selected is Android:
		rect = Rect2(selected.position - Vector2(22, 32), Vector2(44, 64))
	elif selected == drone:
		rect = Rect2(selected.position - Vector2(24, 24), Vector2(48, 48))
	elif selected == tank:
		rect = Rect2(tank.position - Vector2(54, 54), Vector2(108, 108))
	elif selected is Plot:
		rect = selected.rect()
	elif selected == control_center:
		rect = control_center.rect()
	elif selected is Building:
		rect = selected.plot.rect()
	_selection_marker.points = PackedVector2Array([
		rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y),
	])


func _free_slot() -> FuelSlot:
	for slot in get_slots():
		if slot.is_free():
			return slot
	return null


func _send_to_slot(ship: Ship, slot: FuelSlot) -> void:
	slot.reserve(ship)
	ship.go_to_slot(slot)


func _queue_position(index: int) -> Vector2:
	return (_queue_points.get_child(index) as Node2D).global_position


## První místo ve frontě, kde zrovna nikdo nečeká.
func _free_queue_spot() -> int:
	for i in _queue_points.get_child_count():
		if not _queue_spots.values().has(i):
			return i
	return -1


func _leave_queue(ship: Ship) -> void:
	_queue.erase(ship)
	_queue_spots.erase(ship)


## Na uvolněný slot letí loď, která ve frontě čeká nejdéle. Ostatní zůstávají na svých místech.
func _on_slot_freed(slot: FuelSlot) -> void:
	if _queue.is_empty() or not slot.is_free():
		return
	var ship := _queue[0]
	_leave_queue(ship)
	_send_to_slot(ship, slot)


func _on_ship_gave_up(ship: Ship) -> void:
	_leave_queue(ship)
	_awaiting_service.erase(ship)
	for android in get_androids():
		android.release_ship(ship)


func _on_ship_landed(ship: Ship) -> void:
	var store := shop()
	if store and store.is_operational():
		store.serve_customer(ship)
	for android in get_androids():
		if android.is_available():
			android.serve(ship)
			return
	_awaiting_service.append(ship)


func _on_android_free_for_ship(android: Android) -> void:
	while android.is_available() and not _awaiting_service.is_empty():
		android.serve(_awaiting_service.pop_front())


## Bez hotové obranné věže se pirátům, kteří útočí na stanici, postaví android
## (jeden android na jednoho piráta). Po boji je poškozený a opraví ho stavební dron.
func _defend_with_androids() -> void:
	if not get_towers().is_empty():
		return
	for pirate in get_tree().get_nodes_in_group("pirates"):
		if not pirate.is_attacking() or pirate.fought_by != null:
			continue
		for android in get_androids():
			if android.can_fight():
				android.engage(pirate)
				pirate.fought_by = android
				break


## Místa kolem stanice, kde visí útočící piráti (globální souřadnice).
func pirate_targets() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for marker in $PirateTargets.get_children():
		result.append((marker as Node2D).global_position)
	return result


## Zadá stavebnímu dronovi opravu poškozeného androida.
func request_repair(android: Android) -> void:
	queue_job(android, "Oprava: %s" % android.display_name,
			[{"name": "Oprava", "duration": Android.REPAIR_TIME}], Callable(), android.finish_repair)
