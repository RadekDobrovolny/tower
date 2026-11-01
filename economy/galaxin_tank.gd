class_name GalaxinTank
extends Node2D

## Zásobník galaxínu uprostřed stanice. Pumpík z něj čerpá do lodí a cisterny ho doplňují.
## Bez ekonomiky galaxínu je neomezený a slouží jen jako dekorace.
## Rozšíření kapacity staví stavební dron.

## Kapacita (jednotky), cena rozšíření na daný level a jak dlouho (s) rozšíření trvá.
const LEVELS := [
	{"capacity": 500.0, "cost": 0, "upgrade_time": 0.0},
	{"capacity": 800.0, "cost": 1500, "upgrade_time": 10.0},
	{"capacity": 1200.0, "cost": 3000, "upgrade_time": 14.0},
	{"capacity": 1800.0, "cost": 5000, "upgrade_time": 18.0},
]
## Pod jakým podílem kapacity se zásobník hlásí jako téměř prázdný.
const LOW_SHARE := 0.2
const LOW_COLOR := Color(1.0, 0.35, 0.3)
const OK_COLOR := Color(0.95, 0.75, 0.25)
## Síla růžové záře z průzorů u prázdného a plného zásobníku.
const GLOW_EMPTY := 0.3
const GLOW_FULL := 2.0

## Neomezený zásobník se nikdy nevyprázdní a neukazuje hladinu.
var unlimited := true:
	set(value):
		unlimited = value
		if is_node_ready():
			_update_looks()
var level := 1
var amount := 0.0
## Kapacita navíc od artefaktu ve skladišti.
var bonus_capacity := 0.0
## Stanice, ke které zásobník patří. Nastaví ji stanice.
var station: Station
## Zakázka stavebního drona na rozšíření, nebo null.
var job: ConstructionJob

## Kolik jednotek v zásobníku je nekvalitního galaxínu (od levného dodavatele).
var _low_quality := 0.0
var _blink := 0.0
var _glow_time := 0.0

@onready var _glow: PointLight2D = $Glow
@onready var _gauge: ProgressBar = $Gauge
@onready var _amount_label: Label = $AmountLabel
@onready var _level_label: Label = $LevelLabel


func _ready() -> void:
	_update_looks()


func _process(delta: float) -> void:
	_glow_time += delta
	var fill := 1.0 if unlimited else amount / capacity()
	_glow.energy = lerpf(GLOW_EMPTY, GLOW_FULL, fill) * (0.85 + 0.15 * sin(_glow_time * 1.6))
	if unlimited:
		return
	var low := amount < capacity() * LOW_SHARE
	_blink = fmod(_blink + delta, 1.0)
	_amount_label.text = "%d j" % roundi(amount)
	_amount_label.modulate = LOW_COLOR if low and _blink < 0.5 else Color.WHITE
	_gauge.max_value = capacity()
	_gauge.value = amount
	_gauge.modulate = LOW_COLOR if low else OK_COLOR
	if job:
		_level_label.text = "Zásobník · rozšiřuje se %d %%" % roundi(job.phase_fraction() * 100.0)
	else:
		_level_label.text = "Zásobník · L%d" % level


func sale_items() -> Array[ShopItem]:
	if level <= 1:
		return []
	return [ShopItem.sale("Zásobník, level %d" % level, LEVELS[level - 1].cost, set_level.bind(level - 1))]


## Nastaví level bez placení (startovní stav).
func set_level(value: int) -> void:
	level = clampi(value, 1, LEVELS.size())
	_update_looks()


func capacity() -> float:
	return LEVELS[level - 1].capacity + bonus_capacity


func free_space() -> float:
	return INF if unlimited else capacity() - amount


func is_empty() -> bool:
	return not unlimited and amount <= 0.0


## Podíl nekvalitního galaxínu v zásobníku (0–1).
func low_quality_share() -> float:
	return 0.0 if unlimited or amount <= 0.0 else _low_quality / amount


## Odčerpá až `requested` jednotek. Vrátí, kolik se opravdu odčerpalo.
func draw(requested: float) -> float:
	if unlimited:
		return requested
	var drawn := minf(requested, amount)
	if amount > 0.0:
		_low_quality -= drawn * _low_quality / amount
	amount -= drawn
	return drawn


## Doplní galaxín. Vrátí, kolik jednotek se do zásobníku vešlo.
## `low_quality_share` je podíl nekvalitního galaxínu v dodávce (0–1).
func fill(units: float, low_quality_share: float) -> float:
	var accepted := minf(units, free_space())
	amount += accepted
	_low_quality += accepted * low_quality_share
	return accepted


## Cena rozšíření na další level, nebo -1, když teď rozšířit nejde.
func next_upgrade_cost() -> int:
	if unlimited or job != null or level >= LEVELS.size():
		return -1
	return LEVELS[level].cost


## Zaplatí rozšíření a zadá ho stavebnímu dronovi. Vrátí, jestli se to povedlo.
func start_upgrade() -> bool:
	var cost := next_upgrade_cost()
	if cost < 0 or not Game.spend_credits(cost):
		return false
	var target_level := level + 1
	station.queue_job(self, "Rozšíření na level %d" % target_level,
			{"name": "Rozšiřování", "duration": LEVELS[target_level - 1].upgrade_time},
			_finish_upgrade)
	return true


func info_title() -> String:
	return "Zásobník galaxínu"


func info_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	if unlimited:
		lines.append("Galaxín zatím dodává smluvní dodavatel, takže zásobník nikdy nedojde.")
		return lines
	lines.append("Level %d, kapacita %d j" % [level, roundi(capacity())])
	lines.append("Obsah: %d j" % roundi(amount))
	if low_quality_share() > 0.0:
		lines.append("Nekvalitní galaxín: %d %% obsahu" % roundi(low_quality_share() * 100.0))
	if job:
		lines.append(job.status_text(station.drone))
	lines.append("Cenu galaxínu, dodavatele a objednávky nastavíš v panelu vlevo.")
	if station.control_center_cost() >= 0:
		lines.append("K zásobníku jde přistavět řídící centrum: 3 části, celkem %s kr. Vylepší dodávky a umí objednávat samo."
				% Game.format_number(_control_center_total()))
	return lines


func info_actions() -> Array[ShopItem]:
	var actions: Array[ShopItem] = []
	if not unlimited:
		actions.append(ShopItem.new(_upgrade_label, next_upgrade_cost, start_upgrade, ShopItem.Kind.UPGRADE))
		actions.append(ShopItem.new(func() -> String: return "Přistavět řídící centrum",
				station.control_center_cost, station.build_control_center))
	return actions


func _control_center_total() -> int:
	var total := 0
	for phase in ControlCenter.PHASES:
		total += phase.cost
	return total


func _upgrade_label() -> String:
	return "Rozšířit na %d j" % roundi(LEVELS[level].capacity)


func _finish_upgrade() -> void:
	level += 1
	_update_looks()


func _update_looks() -> void:
	_gauge.visible = not unlimited
	_amount_label.visible = not unlimited
	_level_label.visible = not unlimited
	_level_label.text = "Zásobník · L%d" % level
