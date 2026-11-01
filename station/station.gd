class_name Station
extends Node2D

## Čerpací stanice. Spravuje parcely a budovy na nich (stavby a vylepšení dělá stavební
## dron), přiděluje lodím sloty a místa ve frontě, posílá k nim androidy, řídí výběr
## objektů kliknutím a prodejní cenu galaxínu. Když útočí piráti, pošle proti nim androida.

## Hráč kliknutím vybral objekt (android, zásobník, budova, prázdná parcela) nebo nic (null).
signal selection_changed(object: Node)
signal artifact_stored(artifact: Dictionary)
## Něco se postavilo, vylepšilo nebo koupilo (pro cíle misí).
signal state_changed

## Běžná cena galaxínu (kr/j). Bez ekonomiky galaxínu se nedá měnit.
const BASE_PRICE := 6
const MIN_PRICE := 3
const MAX_PRICE := 12
## Kolik lodí přilétá při embargu: posádky se bojí létat a čerpat.
const EMBARGO_DEMAND := 0.5
const BUILDING_SCENES := {
	"fuel_slot": preload("res://station/fuel_slot.tscn"),
	"entertainment": preload("res://station/entertainment_system.tscn"),
	"shop": preload("res://station/shop.tscn"),
	"tower": preload("res://defense/defense_tower.tscn"),
	"motel": preload("res://station/motel.tscn"),
	"parking": preload("res://station/parking.tscn"),
	"extension": preload("res://station/platform_extension.tscn"),
}
## Názvy budov a text tlačítka, kterým se stavba začíná.
const BUILDING_NAMES := {
	"fuel_slot": "Čerpací slot", "entertainment": "Zábavní systém", "shop": "Obchod", "tower": "Obranná věž",
	"motel": "Motel", "parking": "Parkoviště", "extension": "Rozšíření plošiny",
}
const BUILD_LABELS := {
	"fuel_slot": "Začít stavět čerpací slot", "entertainment": "Začít stavět zábavní systém",
	"shop": "Začít stavět obchod", "tower": "Začít stavět obrannou věž",
	"motel": "Začít stavět motel", "parking": "Začít stavět parkoviště", "extension": "Začít rozšiřovat plošinu",
}
const CONTROL_CENTER_SCENE := preload("res://economy/control_center.tscn")
const WAREHOUSE_SCENE := preload("res://station/warehouse.tscn")
const LOOT_SCENE := preload("res://loot/loot.tscn")
## Kořist ze sestřelených pirátů: šance, že něco vypadne, šance na truhlu s artefaktem
## (jinak trosky) a kolik kreditů trosky vynesou. První hodnota platí pro nájezdníka,
## druhá pro dělovou loď.
const LOOT_CHANCE := [0.6, 1.0]
const CHEST_CHANCE := [0.2, 0.45]
const WRECKAGE_CREDITS := [Vector2i(150, 400), Vector2i(400, 900)]
## Artefakty z pirátských truhel: cena při prodeji, obrázek, popis a účinek. Účinek platí,
## jen dokud je artefakt ve skladišti.
const ARTIFACTS := [
	{
		"id": "compass", "name": "Rezavý pirátský kompas", "credits": 1200,
		"icon": preload("res://assets/sprites/artifacts/compass.png"),
		"about": "Nikdy neukazuje na sever, zato spolehlivě na nejbližšího dlužníka.",
		"info": "Sběratelská cennost, nemá žádný účinek.",
	},
	{
		"id": "whisky", "name": "Láhev staré galaxínové whisky", "credits": 1800,
		"icon": preload("res://assets/sprites/artifacts/whisky.png"),
		"about": "Pečeť drží už tři sta let. Chutná prý jako horoucí nebe.",
		"info": "Sběratelská cennost, nemá žádný účinek.",
	},
	{
		"id": "skull", "name": "Zlatá lebka", "credits": 2500,
		"icon": preload("res://assets/sprites/artifacts/skull.png"),
		"about": "Nikdo neví, čí byla. Ani jestli si pro ni někdo nepřijde.",
		"info": "Sběratelská cennost, nemá žádný účinek.",
	},
	{
		"id": "crystal", "name": "Krystal čistého galaxínu", "credits": 1500,
		"icon": preload("res://assets/sprites/artifacts/crystal.png"),
		"about": "Galaxín ztuhlý do krystalu. Svítí i v naprosté tmě.",
		"info": "Dokud je ve skladišti: zásobník pojme o %d j víc." % CRYSTAL_CAPACITY,
	},
	{
		"id": "radio", "name": "Pirátská vysílačka", "credits": 3000,
		"icon": preload("res://assets/sprites/artifacts/radio.png"),
		"about": "Pořád naladěná na pirátskou frekvenci. Sem tam z ní zazní i píseň.",
		"info": "Dokud je ve skladišti: díky odposlechu útočí piráti o 20 % méně často.",
	},
	{
		"id": "map", "name": "Mapa pirátských skrýší", "credits": 3000,
		"icon": preload("res://assets/sprites/artifacts/map.png"),
		"about": "Ohořelá mapa skrýší. Víme teď, kde se trosky nejlíp prodají.",
		"info": "Dokud je ve skladišti: trosky z pirátů vynesou o 50 % víc.",
	},
]
## O kolik víc pojme zásobník, když je krystal ve skladišti, a jak působí vysílačka a mapa.
const CRYSTAL_CAPACITY := 400.0
const RADIO_INTERVAL_FACTOR := 1.25
const MAP_LOOT_BONUS := 1.5
## Medailon, který vypadne ze Zory. Uloží se vždy a nejde prodat.
const MEDALLION := {
	"id": "medallion", "name": "Medailon s císařským orlem", "credits": 0, "story": true,
	"icon": preload("res://assets/sprites/artifacts/medallion.png"),
	"about": "Vypadl z rakety cirkusačky, která odletěla bez placení. Orel, slunce a půlměsíc.",
	"info": "Nejde prodat. Pumpík z něj má divný pocit.",
}
## Od jakého levelu zásobníku jde k němu přistavět řídící centrum.
const CONTROL_CENTER_TANK_LEVEL := 3
const SELECTION_GLOW := preload("res://fx/selection_glow.tres")
## Na které parcely (indexy) se ve startovním stavu mise staví čerpací sloty, zábavní systém,
## obchod a obranná věž.
const START_SLOT_PLOTS := [0, 1, 2]
const START_SHOP_PLOT := 3
const START_ENTERTAINMENT_PLOT := 4
const START_TOWER_PLOT := 5
## Potrubí: navazující dílek trubky (měď je v textuře přesně 32 px vysoká), kolena a T kusy
## pro každý směr ramen (všechny nasvícené zleva shora, proto se neotáčejí), příruba
## u zásobníku, podlahová spojka u čerpadla, průhledítko a tlakoměr.
const PIPE_TEXTURE := preload("res://assets/sprites/station/pipe_tile.png")
const PIPE_FLANGE := preload("res://assets/sprites/station/pipe_flange.png")
const PIPE_FLOOR := preload("res://assets/sprites/station/pipe_floor.png")
const PIPE_SIGHT := preload("res://assets/sprites/station/pipe_sight.png")
const PIPE_GAUGE := preload("res://assets/sprites/station/pipe_gauge.png")
const PIPE_WIDTH := 11.0
## Kolena a T kusy podle ramen (písmena L, R, U, D seřazená abecedně): textura a kde je
## v ní střed spojky (vůči středu textury, trubka v textuře je 32 px tlustá).
const PIPE_FITTINGS := {
	"DL": [preload("res://assets/sprites/station/pipe_elbow_ld.png"), Vector2(18.1, -17.9)],
	"RU": [preload("res://assets/sprites/station/pipe_elbow_ur.png"), Vector2(-22.6, 17.0)],
	"LU": [preload("res://assets/sprites/station/pipe_elbow_ul.png"), Vector2(22.3, 19.4)],
	"DR": [preload("res://assets/sprites/station/pipe_elbow_rd.png"), Vector2(-17.7, -18.6)],
	"DLR": [preload("res://assets/sprites/station/pipe_tee_lrd.png"), Vector2(1.4, -19.9)],
	"LRU": [preload("res://assets/sprites/station/pipe_tee_lru.png"), Vector2(0.1, 18.2)],
	"DLU": [preload("res://assets/sprites/station/pipe_tee_udl.png"), Vector2(18.4, -0.1)],
}
const FITTING_SCALE := PIPE_WIDTH / 32.0
## Obrys paluby po částech (ve směru hodinových ručiček). Rozšíření nahradí pravý kraj a hotové
## parkoviště se napojí na spodní hranu, takže jsou s palubou jeden kus. Reflektor pak musí
## dosvítit až na nové kraje.
const DECK_LEFT: Array[Vector2] = [Vector2(-328, 160), Vector2(-360, 128), Vector2(-360, -128), Vector2(-328, -160)]
const DECK_RIGHT: Array[Vector2] = [Vector2(328, -160), Vector2(360, -128), Vector2(360, 128), Vector2(328, 160)]
const DECK_RIGHT_ABOVE_PARKING: Array[Vector2] = [Vector2(328, -160), Vector2(360, -128), Vector2(360, 160)]
const DECK_RIGHT_EXTENDED: Array[Vector2] = [Vector2(520, -160), Vector2(552, -128), Vector2(552, 128), Vector2(520, 160)]
const DECK_PARKING: Array[Vector2] = [
	Vector2(448, 160), Vector2(448, 284), Vector2(432, 300), Vector2(-52, 300), Vector2(-68, 284), Vector2(-68, 160),
]
const LARGE_DECK_FLOODLIGHT_SCALE := 10.0
## Délka ramen spojek od středu spojky po konec objímky (px textury). Trubka se do objímky
## zasune o FITTING_SOCKET, takže zakryje otvor a kolem ní zůstane vidět jen mosazný kroužek.
const FITTING_ARMS := {
	"DL": {"D": 55.0, "L": 55.0},
	"RU": {"R": 61.0, "U": 54.0},
	"LU": {"L": 62.0, "U": 59.0},
	"DR": {"D": 57.0, "R": 54.0},
	"DLR": {"D": 59.0, "L": 56.0, "R": 54.0},
	"LRU": {"L": 50.0, "R": 49.0, "U": 55.0},
	"DLU": {"D": 52.0, "L": 55.0, "U": 52.0},
}
const FITTING_SOCKET := 13.0
## Příruba, spojka, průhledítko a tlakoměr jsou z dřívějšího archu, kde je trubka tlustá
## 27,7 px. Kde je v nich osa: střed příruby (pahýl doleva) a osa trubky pod tlakoměrem.
const PART_SCALE := PIPE_WIDTH / 27.66
const FLANGE_CENTER := Vector2(12.5, 0.0)
const GAUGE_AXIS := Vector2(0.0, 17.6)
## Vedení potrubí: poloměr zásobníku a hlavní větev v uličce mezi horními a dolními
## parcelami (y vůči středu zásobníku). Ze zásobníku vede trubka nahoru do hlavní větve
## a z ní odbočují T kusy k čerpadlům.
const TANK_PIPE_RADIUS := 46.0
const TRUNK_LANE := -68.0
## Jak daleko od odboček musí být průhledítko nebo tlakoměr na hlavní větvi.
const DECOR_CLEARANCE := 30.0
## Jak blízko (px) k androidovi nebo zásobníku musí hráč kliknout, aby je vybral.
const ANDROID_PICK_RADIUS := 32.0
const TANK_PICK_RADIUS := 50.0
const DRONE_PICK_RADIUS := 18.0

## Pravidla aktuální mise (nastavuje kampaň).
var max_slots := 1
var entertainment_available := false
var dual_hose_available := false
var warehouse_available := false
## Jestli jde rozšířit plošinu a postavit motel s parkovištěm.
var motel_available := false
## Které běžné rakety už létají (číslo mise, `Ship.HULLS`).
var ship_tier := 1
var shop_available := false
var tower_available := false
var control_center_available := false
## Na jaký level jdou koupit filtry. Mise 8 ho zvýší, až dostaneme schéma.
var max_filter_level := 1
var galaxin_economy := false
## Jestli je paluba rozšířená doprava a má další parcely.
var platform_extended := false
## Řídící centrum u zásobníku (i rozestavěné), nebo null.
var control_center: ControlCenter
## Skladiště u obchodu, nebo null.
var warehouse: Warehouse
## Artefakty ve skladišti (v pořadí nálezu).
var stored_artifacts: Array[Dictionary] = []
## Účinky artefaktů: násobek prodlevy mezi útoky pirátů a násobek ceny trosek.
var pirate_interval_factor := 1.0
var loot_bonus := 1.0

## Sloty napojené potrubím na zásobník (v pořadí napojení).
var _piped_slots: Array[FuelSlot] = []

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
## Sprity, které teď svítí jako vybraný objekt.
var _glowing: Array[Sprite2D] = []

@onready var tank: GalaxinTank = $Tank
@onready var supply: Supply = $Supply
@onready var drone: ConstructionDrone = $Drone
@onready var _plots: Node2D = $Plots
@onready var _pipes: Node2D = $Pipes
@onready var _queue_points: Node2D = $QueuePoints
@onready var _staff: Node2D = $Staff
@onready var _control_center_spot: Marker2D = $ControlCenterSpot
@onready var _platform: Polygon2D = $Platform
@onready var _floodlight: PointLight2D = $Floodlight


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
	_update_plots()
	if not is_instance_valid(selected):
		selected = null
	_defend_with_androids()


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var picked := _pick(get_local_mouse_position())
	if picked:
		Sfx.play("ui_select")
	select(picked)
	get_viewport().set_input_as_handled()


func select(object: Node) -> void:
	_move_selection_glow(object)
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


## Motel (i rozestavěný), nebo null.
func motel() -> Motel:
	for plot in get_plots():
		if plot.building is Motel:
			return plot.building
	return null


func has_motel() -> bool:
	return motel() != null and motel().is_operational()


## Parkoviště (i rozestavěné), nebo null.
func parking() -> Parking:
	for plot in get_plots():
		if plot.building is Parking:
			return plot.building
	return null


func has_parking() -> bool:
	return parking() != null and parking().is_operational()


## Posádka si občas po natankování vezme pokoj v motelu (zájezdy ne). Když je kde zaparkovat,
## loď přeletí na parkoviště a vrátí se true.
func try_motel_stay(ship: Ship) -> bool:
	if ship.kind == Ship.Kind.TOURIST or not has_motel() or not has_parking() \
			or not parking().has_free_bay() or randf() >= Motel.GUEST_CHANCE:
		return false
	ship.park_at(parking().take_bay(ship), randi_range(Motel.PAYMENTS_MIN, Motel.PAYMENTS_MAX))
	return true


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


## Jestli jde na prázdné parcele teď něco začít stavět (podle pravidel mise a limitů;
## nezávisle na tom, jestli na to hráč zrovna má). Jinak parcela není vidět ani klikatelná.
func can_build_on(plot: Plot) -> bool:
	if not plot.is_empty():
		return false
	for type in _building_types(plot):
		if _build_cost(type) >= 0:
			return true
	return false


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


## Cena první části skladiště, nebo -1, když ho teď postavit nejde
## (není povolené misí, chybí hotový obchod, nebo už stojí).
func warehouse_cost() -> int:
	if not warehouse_available or warehouse != null or shop_products() < 0:
		return -1
	return Warehouse.PHASES[0].cost


## Začne stavět skladiště vedle obchodu. Vrátí, jestli se to povedlo.
func build_warehouse() -> bool:
	var cost := warehouse_cost()
	if cost < 0 or Game.credits < cost:
		return false
	_place_warehouse().start_next_phase()
	select(warehouse)
	state_changed.emit()
	return true


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
func queue_job(target: Node2D, title: String, phase: Dictionary, on_done: Callable,
		urgent := false) -> ConstructionJob:
	var job := ConstructionJob.new(target, title, phase)
	job.on_done = func() -> void:
		target.set("job", null)
		if target is Building or target == tank:
			Sfx.play("build_done")
		if on_done.is_valid():
			on_done.call()
		state_changed.emit()
	target.set("job", job)
	drone.add_job(job, urgent)
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


## Napojí čerpací slot potrubím na zásobník (po poslední fázi stavby slotu).
func connect_pipe(slot: FuelSlot) -> void:
	if _piped_slots.has(slot):
		return
	_piped_slots.append(slot)
	_rebuild_pipes()


## Postaví celé potrubí znovu. Vede jen vodorovně a svisle: čerpadla nad zásobníkem jsou
## napojená na hlavní větev v uličce (T kusy, na konci větve koleno), ta vede do horní části
## zásobníku. Čerpadla níž mají vlastní trubku do boku zásobníku.
## Nejdřív se posbírají úseky, spojky a ostatní díly, pak se kreslí v pořadí spojky, trubky
## (zasunuté do objímek spojek) a nakonec příruby, podlahové spojky a ozdoby.
func _rebuild_pipes() -> void:
	for child in _pipes.get_children():
		child.queue_free()
	var plan := {"segments": [], "fittings": {}, "parts": []}
	var top: Array[FuelSlot] = []
	for slot in _piped_slots:
		if slot.pipe_position().y < tank.position.y - TANK_PIPE_RADIUS:
			top.append(slot)
		else:
			_plan_side_pipe(plan, slot)
	if not top.is_empty():
		_plan_trunk(plan, top)
	for at: Vector2 in plan.fittings:
		var key: String = plan.fittings[at]
		var fitting := _add_pipe_part(PIPE_FITTINGS[key][0], at, 0.0, -PIPE_FITTINGS[key][1])
		fitting.scale = Vector2.ONE * FITTING_SCALE
	for segment in plan.segments:
		_add_pipe_segment(_socket_end(plan, segment[0], segment[1]), _socket_end(plan, segment[1], segment[0]))
	for part in plan.parts:
		_add_pipe_part(part[0], part[1], part[2], part[3])


func _plan_side_pipe(plan: Dictionary, slot: FuelSlot) -> void:
	var foot := slot.pipe_position()
	var side := signf(foot.x - tank.position.x)
	var entry := tank.position + Vector2(side * TANK_PIPE_RADIUS, 0)
	var corner := Vector2(foot.x, entry.y)
	plan.segments.append([entry, corner])
	plan.segments.append([corner, foot])
	_plan_fitting(plan, corner, [entry - corner, foot - corner])
	plan.parts.append([PIPE_FLANGE, entry, (corner - entry).angle() - PI, -FLANGE_CENTER])
	plan.parts.append([PIPE_FLOOR, foot, 0.0, Vector2.ZERO])


func _plan_trunk(plan: Dictionary, slots: Array[FuelSlot]) -> void:
	var lane_y := tank.position.y + TRUNK_LANE
	var hub := Vector2(tank.position.x, lane_y)
	var surface := Vector2(tank.position.x, tank.position.y - TANK_PIPE_RADIUS)
	plan.segments.append([surface, hub])
	plan.parts.append([PIPE_FLANGE, surface, PI / 2.0, -FLANGE_CENTER])
	var hub_arms: Array[Vector2] = [Vector2.DOWN]
	for side in [-1.0, 1.0]:
		var branch: Array[FuelSlot] = []
		for slot in slots:
			if signf(slot.pipe_position().x - hub.x) == side:
				branch.append(slot)
		if branch.is_empty():
			continue
		branch.sort_custom(func(a: FuelSlot, b: FuelSlot) -> bool:
			return absf(a.pipe_position().x - hub.x) < absf(b.pipe_position().x - hub.x))
		hub_arms.append(Vector2(side, 0))
		# Hlavní větev po úsecích mezi spojkami, aby se každý úsek zasunul do objímek.
		var previous := hub
		for i in branch.size():
			var foot := branch[i].pipe_position()
			var junction := Vector2(foot.x, lane_y)
			plan.segments.append([previous, junction])
			plan.segments.append([junction, foot])
			previous = junction
			var arms: Array[Vector2] = [Vector2.UP, Vector2(-side, 0)]
			if i < branch.size() - 1:
				arms.append(Vector2(side, 0))
			_plan_fitting(plan, junction, arms)
			plan.parts.append([PIPE_FLOOR, foot, 0.0, Vector2.ZERO])
		# Průhledítko (vlevo) nebo tlakoměr (vpravo) doprostřed nejdelšího volného úseku větve.
		var stops := [hub.x]
		for slot in branch:
			stops.append(slot.pipe_position().x)
		var best_gap := 0.0
		var best_x := 0.0
		for i in stops.size() - 1:
			var gap := absf(stops[i + 1] - stops[i]) - 2.0 * DECOR_CLEARANCE
			if gap > best_gap:
				best_gap = gap
				best_x = (stops[i] + stops[i + 1]) / 2.0
		if best_gap > 0.0:
			if side < 0.0:
				plan.parts.append([PIPE_SIGHT, Vector2(best_x, lane_y), 0.0, Vector2.ZERO])
			else:
				plan.parts.append([PIPE_GAUGE, Vector2(best_x, lane_y), 0.0, -GAUGE_AXIS])
	_plan_fitting(plan, hub, hub_arms)


## Koleno nebo T kus v místě, kde se trubky potkávají (podle směrů ramen).
## Rovný průchod spojku nepotřebuje.
func _plan_fitting(plan: Dictionary, at: Vector2, arms: Array[Vector2]) -> void:
	var letters := PackedStringArray()
	for arm in arms:
		letters.append(_arm_letter(arm))
	letters.sort()
	var key := "".join(letters)
	if PIPE_FITTINGS.has(key):
		plan.fittings[at] = key


func _arm_letter(direction: Vector2) -> String:
	return {Vector2.LEFT: "L", Vector2.RIGHT: "R", Vector2.UP: "U", Vector2.DOWN: "D"}[direction.normalized().round()]


## Konec úseku: když v něm je spojka, trubka končí uvnitř její objímky, jinak v bodě samém.
func _socket_end(plan: Dictionary, end: Vector2, other: Vector2) -> Vector2:
	if not plan.fittings.has(end):
		return end
	var arm_length: float = FITTING_ARMS[plan.fittings[end]][_arm_letter(other - end)]
	return end + (other - end).normalized() * (arm_length - FITTING_SOCKET) * FITTING_SCALE


## Rovný úsek trubky. Vodorovné se kreslí zleva doprava a svislé zdola nahoru, aby měla
## textura lesk vždy na straně ke světlu (nahoře, u svislých vlevo).
func _add_pipe_segment(from: Vector2, to: Vector2) -> void:
	var horizontal := absf(to.x - from.x) > absf(to.y - from.y)
	var swap := (horizontal and from.x > to.x) or (not horizontal and from.y < to.y)
	var pipe := Line2D.new()
	pipe.points = PackedVector2Array([to, from] if swap else [from, to])
	pipe.width = PIPE_WIDTH
	pipe.texture = PIPE_TEXTURE
	pipe.texture_mode = Line2D.LINE_TEXTURE_TILE
	pipe.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_pipes.add_child(pipe)


func _add_pipe_part(texture: Texture2D, at: Vector2, angle: float, offset: Vector2) -> Sprite2D:
	var part := Sprite2D.new()
	part.texture = texture
	part.offset = offset
	part.position = at
	part.rotation = angle
	part.scale = Vector2.ONE * PART_SCALE
	_pipes.add_child(part)
	return part


## Postaví všechno a vylepší to na maximum (start mise Z).
func setup_maxed() -> void:
	setup_start_buildings(START_SLOT_PLOTS.size(), 0, Shop.PRODUCTS.size(), 0, DefenseTower.LEVELS.size())
	(_place_building("entertainment", get_plots()[START_ENTERTAINMENT_PLOT]) as EntertainmentSystem).set_maxed()
	var tower_plot := first_empty_plot(Plot.Kind.TOWER)
	while tower_plot:
		(_place_building("tower", tower_plot) as DefenseTower).set_level(DefenseTower.LEVELS.size())
		tower_plot = first_empty_plot(Plot.Kind.TOWER)
	_place_control_center().set_maxed()
	_place_warehouse().finish_instantly()
	_open_extension()
	_place_building("motel", first_empty_plot()).finish_instantly()
	_place_building("parking", first_empty_plot(Plot.Kind.PARKING)).finish_instantly()
	_update_deck()
	tank.set_level(GalaxinTank.LEVELS.size())
	drone.set_maxed()
	for android in get_androids():
		android.set_maxed()


## Lodě u čerpadel to bez galaxínu vzdaly: odletí všechny, i ty ve frontě a na cestě k plošině.
## Nové nepřiletí, dokud v zásobníku nic není (hlídá to `ShipSpawner`).
func send_ships_away_no_fuel() -> void:
	# Nejdřív fronta, aby se na uvolněné sloty nikdo nezařadil.
	for ship in _queue.duplicate():
		ship.leave_without_fuel()
	for slot in get_slots():
		if slot.occupant:
			slot.occupant.leave_without_fuel()


## Druhá hadice pro androida se otevře, když ji mise povolí a stojí aspoň dva sloty.
func dual_hose_unlocked() -> bool:
	return dual_hose_available and get_slots().size() >= 2


## Jestli některá loď u čerpadla ještě zaplatí za natankovaný galaxín.
func ships_owe_payment() -> bool:
	return get_slots().any(func(slot: FuelSlot) -> bool: return slot.occupant and slot.occupant.owes_payment())


## Všechno, co jde prodat vetešníkovi. Na čem se právě pracuje, se prodat nedá.
func sale_items() -> Array[ShopItem]:
	var items: Array[ShopItem] = drone.sale_items()
	for android in get_androids():
		items.append_array(android.sale_items())
	if tank.job == null:
		items.append_array(tank.sale_items())
	if control_center and control_center.job == null:
		items.append_array(control_center.sale_items())
	for plot in get_plots():
		if plot.building and plot.building.job == null:
			items.append_array(plot.building.sale_items())
	return items


## Zapne ekonomiku galaxínu (omezený zásobník, dodavatelé, vlastní cena) a naplní zásobník.
func enable_galaxin_economy(initial_amount: float) -> void:
	galaxin_economy = true
	_apply_galaxin_economy()
	tank.amount = minf(initial_amount, tank.capacity())


func set_sell_price(value: int) -> void:
	sell_price = clampi(value, MIN_PRICE, MAX_PRICE)


## Kolikrát víc lodí přilétá než při běžné ceně. Levný galaxín láká, drahý odrazuje
## a při embargu se posádky bojí létat.
func demand_factor() -> float:
	var factor := pow(float(BASE_PRICE) / sell_price, 1.5)
	return factor * EMBARGO_DEMAND if supply.embargo else factor


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


## Zavře plošinu pro nouzové přistání: vezme volnou, a když žádná není, první, ze které loď uhne.
func close_slot_for_emergency() -> FuelSlot:
	var slot := _free_slot()
	if slot == null:
		slot = get_slots()[0]
	slot.closed = true
	if slot.occupant:
		slot.occupant.make_way()
	return slot


## Plošina je zase volná a nabídne se lodi, která čeká ve frontě.
func reopen_slot(slot: FuelSlot) -> void:
	slot.closed = false
	_on_slot_freed(slot)


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


## Postaví druhou věž hned (startovní stav mise).
func place_second_tower(level: int) -> void:
	(_place_building("tower", first_empty_plot(Plot.Kind.TOWER)) as DefenseTower).set_level(level)


## Postaví skladiště hned (startovní stav mise).
func place_warehouse_ready() -> void:
	_place_warehouse().finish_instantly()


func _place_warehouse() -> Warehouse:
	warehouse = WAREHOUSE_SCENE.instantiate()
	warehouse.station = self
	warehouse.position = shop().plot.position + shop().plot.annex_offset
	add_child(warehouse)
	# Pod androidem a dronem, nad parcelami.
	move_child(warehouse, tank.get_index() + 1)
	return warehouse


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
	Sfx.play("upgrade_done")
	if building is EntertainmentSystem or building is DefenseTower:
		building.power_on()
	elif building is FuelSlot:
		# Nový slot hned nabídne lodi, která čeká ve frontě.
		_on_slot_freed(building)
	elif building is PlatformExtension:
		if selected == building:
			select(null)
		building.plot.clear()
		_open_extension()
	elif building is Parking:
		_update_deck()


## Paluba se rozšíří a na novém kusu se otevřou parcely.
func _open_extension() -> void:
	platform_extended = true
	_update_deck()


## Poskládá obrys paluby podle toho, co už je postavené.
func _update_deck() -> void:
	var outline := PackedVector2Array(DECK_RIGHT)
	if platform_extended:
		outline = PackedVector2Array(DECK_RIGHT_EXTENDED)
	elif has_parking():
		outline = PackedVector2Array(DECK_RIGHT_ABOVE_PARKING)
	if has_parking():
		outline.append_array(PackedVector2Array(DECK_PARKING))
	outline.append_array(PackedVector2Array(DECK_LEFT))
	_platform.polygon = outline
	if platform_extended or has_parking():
		_floodlight.texture_scale = LARGE_DECK_FLOODLIGHT_SCALE


## Co jde na parcele daného druhu stavět.
func _building_types(plot: Plot) -> Array:
	if plot.needs_extension and not platform_extended:
		return []
	match plot.kind:
		Plot.Kind.TOWER:
			return ["tower"]
		Plot.Kind.EXTENSION:
			return ["extension"]
		Plot.Kind.PARKING:
			return ["parking"]
	return ["fuel_slot", "entertainment", "shop", "motel"]


func _build_phases(type: String) -> Array:
	match type:
		"fuel_slot":
			return FuelSlot.PHASES
		"entertainment":
			return EntertainmentSystem.PHASES
		"shop":
			return Shop.PHASES
		"motel":
			return Motel.PHASES
		"parking":
			return Parking.PHASES
		"extension":
			return PlatformExtension.PHASES
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
		"motel":
			allowed = motel_available and motel() == null
		"parking":
			allowed = motel_available and parking() == null
		"extension":
			allowed = motel_available and not platform_extended
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
	if warehouse and warehouse.rect().has_point(point):
		return warehouse
	for plot in get_plots():
		if plot.rect().has_point(point):
			if plot.building:
				return plot.building
			if can_build_on(plot):
				return plot
	return null


## Prázdné parcely ukazují obrys, jen když na nich jde stavět. Když přestane jít stavět na
## vybrané parcele (např. se zaplnil limit slotů), výběr se zruší.
func _update_plots() -> void:
	for plot in get_plots():
		if plot.is_empty():
			plot.set_outline_visible(can_build_on(plot))
	if selected is Plot and not can_build_on(selected):
		select(null)


## Přesune zvýraznění výběru: spritům vybraného objektu dá shader s obrysem. Sprity s vlastním
## materiálem (přičítané záře) se přeskočí. Prázdná parcela sprite nemá, svítí sama.
func _move_selection_glow(object: Node) -> void:
	for sprite in _glowing:
		if is_instance_valid(sprite):
			sprite.material = null
	_glowing.clear()
	if is_instance_valid(selected) and selected is Plot:
		selected.set_highlighted(false)
	if is_instance_valid(selected) and selected is DefenseTower:
		selected.set_range_visible(false)
	if object is DefenseTower:
		object.set_range_visible(true)
	if object is Plot:
		object.set_highlighted(true)
	elif object:
		for sprite: Sprite2D in object.find_children("*", "Sprite2D", true, false):
			if sprite.material == null:
				sprite.material = _selection_glow_for(sprite)
				_glowing.append(sprite)


## Pás animace potřebuje vlastní kopii materiálu, která zná počet snímků.
func _selection_glow_for(sprite: Sprite2D) -> ShaderMaterial:
	if sprite.hframes == 1:
		return SELECTION_GLOW
	var glow: ShaderMaterial = SELECTION_GLOW.duplicate()
	glow.set_shader_parameter("hframes", float(sprite.hframes))
	return glow


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


## Pirátovi, který útočí na stanici, se postaví android, i když stojí věže
## (jeden android na jednoho piráta).
func _defend_with_androids() -> void:
	for pirate in get_tree().get_nodes_in_group("pirates"):
		if not pirate.is_attacking() or pirate.fought_by != null:
			continue
		for android in get_androids():
			if android.can_fight():
				android.engage(pirate)
				pirate.fought_by = android
				break


## Pirát začal útočit: lodě ve frontě i u čerpadel utečou a dodávka galaxínu se zruší.
func on_pirate_attack() -> void:
	Sfx.play("alarm")
	# Nejdřív fronta, aby se na sloty uvolněné útěkem nikdo nezařadil.
	for ship in _queue.duplicate():
		ship.flee()
	for slot in get_slots():
		if slot.occupant:
			slot.occupant.flee()
	supply.abort_delivery()


## Ze sestřeleného piráta občas vypadne kořist a stavební dron ji sebere.
func spawn_loot(at: Vector2, gunship: bool) -> void:
	var tier := 1 if gunship else 0
	if randf() >= LOOT_CHANCE[tier]:
		return
	var loot: Loot = LOOT_SCENE.instantiate()
	loot.station = self
	var artifact := _random_artifact() if randf() < CHEST_CHANCE[tier] else {}
	if not artifact.is_empty():
		loot.kind = Loot.Kind.CHEST
		loot.artifact = artifact
	else:
		var credit_range: Vector2i = WRECKAGE_CREDITS[tier]
		loot.credits = roundi(randi_range(credit_range.x, credit_range.y) * loot_bonus)
	add_child(loot)
	# Kořist zůstane na obrazovce, aby k ní dron doletěl a hráč ji viděl.
	var screen := Game.visible_world_rect(self)
	loot.global_position = at.clamp(screen.position + Vector2(40, 40), screen.end - Vector2(40, 40))


## Upustí truhlu s artefaktem z příběhu, Bzučák pro ni doletí jako pro jinou kořist.
func drop_story_loot(at: Vector2, artifact: Dictionary) -> void:
	var loot: Loot = LOOT_SCENE.instantiate()
	loot.station = self
	loot.kind = Loot.Kind.CHEST
	loot.artifact = artifact
	add_child(loot)
	var screen := Game.visible_world_rect(self)
	loot.global_position = at.clamp(screen.position + Vector2(40, 40), screen.end - Vector2(40, 40))


## Dron přivezl artefakt. Hotové skladiště ho uloží a začne platit jeho účinek, bez něj (nebo
## když už ho hráč má) se hned prodá. Vrátí, jestli se uložil.
func add_artifact(artifact: Dictionary) -> bool:
	var keep: bool = artifact.has("story") \
			or (has_warehouse() and not stored_artifacts.has(artifact) and stored_artifacts.size() < Warehouse.SLOTS)
	if keep:
		store_artifact(artifact)
		artifact_stored.emit(artifact)
	else:
		Game.add_credits(artifact.credits)
	state_changed.emit()
	return keep


## Uloží artefakt do skladiště a zapne jeho účinek. Přímo se volá pro startovní stav mise.
func store_artifact(artifact: Dictionary) -> void:
	stored_artifacts.append(artifact)
	_apply_artifacts()


## Prodá artefakt ze skladiště. Jeho účinek skončí a znovu může vypadnout z pirátů.
func sell_artifact(artifact: Dictionary) -> void:
	stored_artifacts.erase(artifact)
	Game.add_credits(artifact.credits)
	Sfx.play("coin")
	_apply_artifacts()
	state_changed.emit()


func has_warehouse() -> bool:
	return warehouse != null and warehouse.is_operational()


## Účinky platí, jen dokud je artefakt ve skladišti.
func _apply_artifacts() -> void:
	var stored := stored_artifacts.map(func(artifact: Dictionary) -> String: return artifact.id)
	pirate_interval_factor = RADIO_INTERVAL_FACTOR if stored.has("radio") else 1.0
	loot_bonus = MAP_LOOT_BONUS if stored.has("map") else 1.0
	tank.bonus_capacity = CRYSTAL_CAPACITY if stored.has("crystal") else 0.0
	tank.amount = minf(tank.amount, tank.capacity())


## Co hráč ve skladišti už má, z pirátů znovu nevypadne. Prázdné = všechno už má.
func _random_artifact() -> Dictionary:
	var pool := ARTIFACTS.filter(func(artifact: Dictionary) -> bool: return not stored_artifacts.has(artifact))
	return {} if pool.is_empty() else pool.pick_random()


## Kolik lodí čeká ve frontě.
func queue_size() -> int:
	return _queue.size()


## Jestli zrovna útočí nějaký pirát (nové lodě se ke stanici neodváží).
func under_attack() -> bool:
	return get_tree().get_nodes_in_group("pirates").any(
			func(pirate: Node) -> bool: return pirate.is_attacking())


## Místa kolem stanice, kde visí útočící piráti (globální souřadnice).
func pirate_targets() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for marker in $PirateTargets.get_children():
		result.append((marker as Node2D).global_position)
	return result


## Zadá stavebnímu dronovi opravu poškozeného androida. Oprava má přednost před vším ostatním.
func request_repair(android: Android) -> void:
	queue_job(android, "Oprava: %s" % android.display_name,
			{"name": "Oprava", "duration": Android.REPAIR_TIME}, android.finish_repair, true)
