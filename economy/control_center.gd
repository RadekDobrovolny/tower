class_name ControlCenter
extends Building

## Řídící centrum (serverovna) přistavěné k zásobníku. Jde postavit, když má zásobník
## level 3. Vylepšuje dodávky galaxínu (spolehlivost, rychlost, větší cisterny, rychlejší
## přečerpávání) a nakonec umí cisterny objednávat samo (automatický dispečink).
## Nestojí na parcele, ale na pevném místě vedle zásobníku.

## Části stavby: název, cena (dohromady 4 000 kr) a doba stavby (s).
const PHASES := [
	{"name": "Základy", "cost": 1000, "duration": 4.0},
	{"name": "Serverovna", "cost": 2000, "duration": 6.0},
	{"name": "Napojení na zásobník", "cost": 1000, "duration": 4.0},
]
## Vylepšení: ceny a doby instalace pro každý level a účinek na každém levelu (index 0 = bez
## vylepšení). Účinky čte zásobování (Supply).
## - reliability: násobek šance na zpoždění a na poloprázdnou cisternu
## - speed: násobek doby dodání (i zpoždění)
## - capacity: násobek velikosti cisterny
## - unloading: násobek rychlosti přečerpávání
## - purification: kolik nekvalitního galaxínu z dodávky zůstane (zbytek se vyčistí)
## - dispatch: jestli centrum objednává cisterny samo
const UPGRADES := [
	{
		"id": "reliability", "name": "Spolehlivé dodávky",
		"costs": [2000, 4000], "times": [6.0, 8.0], "values": [1.0, 0.5, 0.0],
	},
	{
		"id": "speed", "name": "Rychlé doručení",
		"costs": [2000, 4000], "times": [6.0, 8.0], "values": [1.0, 0.7, 0.45],
	},
	{
		"id": "capacity", "name": "Větší cisterny",
		"costs": [2500, 5000], "times": [6.0, 8.0], "values": [1.0, 1.5, 2.0],
	},
	{
		"id": "unloading", "name": "Rychlé přečerpávání",
		"costs": [1500, 3000], "times": [5.0, 7.0], "values": [1.0, 1.6, 2.5],
	},
	{
		"id": "purification", "name": "Čištění galaxínu",
		"costs": [2000, 3500, 5000], "times": [6.0, 8.0, 10.0], "values": [1.0, 0.6, 0.3, 0.0],
	},
	{
		"id": "dispatch", "name": "Automatický dispečink",
		"costs": [6000], "times": [10.0], "values": [false, true],
	},
]
## Pod jakým podílem kapacity zásobníku dispečink objedná cisternu.
const DISPATCH_SHARE := 0.4
const SIZE := Vector2(84, 72)
const SHELL_MODULATE := Color(0.3, 0.3, 0.32)

## Level každého vylepšení (id -> level).
var levels := {}

var _time := 0.0

@onready var _base: Sprite2D = $Base
@onready var _body: Sprite2D = $Body
@onready var _servers: Sprite2D = $Servers
@onready var _dish: Sprite2D = $Dish


func _ready() -> void:
	for upgrade in UPGRADES:
		levels[upgrade.id] = 0
	super()


func _process(delta: float) -> void:
	super(delta)
	_time += delta
	# Servery blikají, při instalaci vylepšení rychleji.
	_servers.modulate.a = 0.55 + 0.45 * sin(_time * (9.0 if job else 2.5))


## Účinek vylepšení `id` na aktuálním levelu (dokud centrum nefunguje, jako bez vylepšení).
static func base_value(id: String) -> Variant:
	return _upgrade(id).values[0]


func value(id: String) -> Variant:
	if not is_operational():
		return base_value(id)
	return _upgrade(id).values[levels[id]]


## Postaví centrum hned (startovní stav mise), případně i s dispečinkem.
func set_ready(with_dispatch: bool) -> void:
	finish_instantly()
	levels["dispatch"] = 1 if with_dispatch else 0
	_update_construction_looks()


func rect() -> Rect2:
	return Rect2(position - SIZE / 2.0, SIZE)


func build_phases() -> Array:
	return PHASES


func display_name() -> String:
	return "Řídící centrum"


## Cena dalšího levelu vylepšení, nebo -1 (centrum není hotové, pracuje se na něm, maximum).
func upgrade_cost(id: String) -> int:
	var upgrade := _upgrade(id)
	if not is_operational() or job != null or levels[id] >= upgrade.costs.size():
		return -1
	return upgrade.costs[levels[id]]


func start_upgrade(id: String) -> bool:
	var cost := upgrade_cost(id)
	if cost < 0 or not Game.spend_credits(cost):
		return false
	var upgrade := _upgrade(id)
	station.queue_job(self, "%s, level %d" % [upgrade.name, levels[id] + 1],
			[{"name": "Instalace", "duration": upgrade.times[levels[id]]}], Callable(), _finish_upgrade.bind(id))
	return true


func info_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	if not is_operational():
		lines.append(construction_line())
		lines.append("Až bude hotové, půjde vylepšovat dodávky galaxínu a nakonec zapnout automatický dispečink.")
		return lines
	lines.append("Spolehlivost: zpoždění a menší dodávky %s" % _percent_less(value("reliability")))
	lines.append("Doručení: o %d %% rychlejší" % roundi((1.0 - value("speed")) * 100.0))
	lines.append("Cisterny: %d %% velikosti" % roundi(value("capacity") * 100.0))
	lines.append("Přečerpávání: %d %% rychlosti" % roundi(value("unloading") * 100.0))
	var purification: float = value("purification")
	if purification <= 0.0:
		lines.append("Čištění: nekvalitní galaxín se vyčistí celý, levný dodavatel bez pokut.")
	elif purification < 1.0:
		lines.append("Čištění: vyčistí %d %% nekvalitního galaxínu." % roundi((1.0 - purification) * 100.0))
	if value("dispatch"):
		lines.append("Dispečink: objedná cisternu sám, když v zásobníku zbývá méně než %d %%."
				% roundi(DISPATCH_SHARE * 100.0))
	else:
		lines.append("Dispečink: vypnutý, cisterny objednáváš ručně.")
	if job:
		lines.append(job_line())
	return lines


func info_actions() -> Array[ShopItem]:
	if not is_operational():
		return super()
	var actions: Array[ShopItem] = []
	for upgrade in UPGRADES:
		var id: String = upgrade.id
		actions.append(ShopItem.new(_upgrade_label.bind(id), upgrade_cost.bind(id),
				start_upgrade.bind(id), ShopItem.Kind.UPGRADE))
	return actions


static func _upgrade(id: String) -> Dictionary:
	for upgrade in UPGRADES:
		if upgrade.id == id:
			return upgrade
	return {}


func _upgrade_label(id: String) -> String:
	var upgrade := _upgrade(id)
	if upgrade.costs.size() == 1:
		return "Zapnout: %s" % upgrade.name
	return "%s (level %d)" % [upgrade.name, levels[id] + 1]


func _percent_less(factor: float) -> String:
	if factor >= 1.0:
		return "jako u dodavatele"
	if factor <= 0.0:
		return "nehrozí"
	return "o %d %% méně často" % roundi((1.0 - factor) * 100.0)


func _finish_upgrade(id: String) -> void:
	levels[id] += 1
	_update_construction_looks()


func _update_construction_looks() -> void:
	super()
	# Části stavby: staveniště -> tmavá kostra -> hotová serverovna (servery svítí).
	_base.visible = built_phases == 1
	_body.visible = built_phases >= 2
	_body.modulate = SHELL_MODULATE if built_phases == 2 else Color.WHITE
	_servers.visible = is_operational()
	_dish.visible = is_operational() and levels.get("dispatch", 0) > 0
