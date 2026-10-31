class_name Shop
extends Building

## Obchod na stanici. Posádka každé lodi, která přistane, si občas něco koupí, a lodím ve
## frontě se díky obchodu pomaleji krátí trpělivost (koukají do výlohy, čtou holonoviny).
## Hráč do obchodu přidává další druhy zboží, každý má vedle obchodu vlastní stánek.

## Části stavby: název, cena (dohromady 3 000 kr) a doba stavby (s).
const PHASES := [
	{"name": "Základová deska", "cost": 500, "duration": 3.0},
	{"name": "Kiosek", "cost": 1200, "duration": 5.0},
	{"name": "Vybavení a pult", "cost": 800, "duration": 4.0},
	{"name": "Neonová reklama", "cost": 500, "duration": 3.0},
]
## Zboží, které obchod prodává hned po postavení: šance, že si ho posádka koupí,
## rozsah ceny (kr) a o kolik zpomalí úbytek trpělivosti lodí ve frontě.
const BASIC := {"name": "Nápoje", "chance": 0.4, "price_min": 10, "price_max": 25, "patience": 0.05}
## Další druhy zboží: cena a doba instalace (staví Bzučák), prodej a trpělivost jako u BASIC
## a stánek, který se objeví vedle obchodu.
const PRODUCTS := [
	{
		"name": "Párky v rohlíku", "cost": 2000, "time": 6.0,
		"chance": 0.45, "price_min": 20, "price_max": 45, "patience": 0.06,
		"prop": preload("res://assets/sprites/shop/food_cart.png"),
	},
	{
		"name": "Holonoviny", "cost": 2500, "time": 6.0,
		"chance": 0.5, "price_min": 10, "price_max": 25, "patience": 0.08,
		"prop": preload("res://assets/sprites/shop/holonews.png"),
	},
	{
		"name": "Suvenýry", "cost": 3000, "time": 8.0,
		"chance": 0.3, "price_min": 40, "price_max": 90, "patience": 0.04,
		"prop": preload("res://assets/sprites/shop/souvenirs.png"),
	},
	{
		"name": "Doplňky", "cost": 4000, "time": 8.0,
		"chance": 0.25, "price_min": 60, "price_max": 140, "patience": 0.04,
		"prop": preload("res://assets/sprites/shop/accessories.png"),
	},
]
## Kde vedle obchodu stojí stánky (v pořadí PRODUCTS).
const PROP_POSITIONS := [Vector2(-66, 34), Vector2(66, 32), Vector2(-68, -26), Vector2(68, -26)]
const PROP_SCALE := 0.42
const SALE_COLOR := Color(0.45, 0.95, 0.85)
## Prodej v obchodě cinkne výš a tišeji než platba za galaxín.
const SALE_COIN_PITCH := 1.5
const SALE_COIN_GAIN_DB := -8.0
## Jak tmavě je kiosek vidět ve 2. a 3. části stavby (rozestavěný, bez světel).
const SHELL_MODULATE := Color(0.3, 0.3, 0.32)
const NO_NEON_MODULATE := Color(0.65, 0.62, 0.6)

## Indexy zboží z PRODUCTS, které obchod už prodává.
var products: Array[int] = []
## Kolik obchod celkem vydělal.
var revenue := 0

var _props: Array[Sprite2D] = []

@onready var _base: Sprite2D = $Base
@onready var _kiosk: Sprite2D = $Kiosk
@onready var _neon: PointLight2D = $Neon
@onready var _label: Label = $Label


func _ready() -> void:
	for i in PRODUCTS.size():
		var prop := Sprite2D.new()
		prop.texture = PRODUCTS[i].prop
		prop.scale = Vector2.ONE * PROP_SCALE
		prop.position = PROP_POSITIONS[i]
		prop.hide()
		add_child(prop)
		# Stánky dole jsou před kioskem, horní za ním.
		move_child(prop, _kiosk.get_index() + (1 if PROP_POSITIONS[i].y > 0 else 0))
		_props.append(prop)
	super()


func build_phases() -> Array:
	return PHASES


func display_name() -> String:
	return "Obchod"


## Postaví obchod hned i s prvními `count` druhy zboží (startovní stav mise).
func set_products(count: int) -> void:
	finish_instantly()
	products.clear()
	for i in mini(count, PRODUCTS.size()):
		products.append(i)
	_update_construction_looks()


## Jak rychle ubývá trpělivost lodím ve frontě kvůli obchodu (1 = normálně).
func patience_drain() -> float:
	if not is_operational():
		return 1.0
	var bonus: float = BASIC.patience
	for i in products:
		bonus += PRODUCTS[i].patience
	return 1.0 - bonus


## Posádka přistálé lodi si nakoupí: každé zboží si koupí s jeho šancí. Turisté nakupují
## ochotněji (dvojnásobná šance) a utratí 20× víc.
func serve_customer(ship: Ship) -> void:
	var tourists := ship.kind == Ship.Kind.TOURIST
	var total := 0
	for item in _assortment():
		if randf() < item.chance * (2.0 if tourists else 1.0):
			total += randi_range(item.price_min, item.price_max)
	if total <= 0:
		return
	if tourists:
		total = roundi(total * Ship.TOURIST_SHOPPING)
	revenue += total
	Game.add_credits(total)
	Sfx.play("coin", SALE_COIN_PITCH, SALE_COIN_GAIN_DB)
	FloatingText.spawn(station, station.to_local(global_position) + Vector2(0, -56),
			"+%d kr %s" % [total, "turisté" if tourists else "obchod"], SALE_COLOR)


## Cena přidání zboží, nebo -1, když teď přidat nejde (obchod není hotový, Bzučák na něm
## pracuje, nebo už se prodává).
func product_cost(index: int) -> int:
	if not is_operational() or job != null or products.has(index):
		return -1
	return PRODUCTS[index].cost


## Zaplatí nové zboží a zadá jeho instalaci stavebnímu dronovi.
func add_product(index: int) -> bool:
	var cost := product_cost(index)
	if cost < 0 or not Game.spend_credits(cost):
		return false
	var product: Dictionary = PRODUCTS[index]
	station.queue_job(self, "Nové zboží: %s" % product.name,
			[{"name": "Stavba stánku", "duration": product.time}], Callable(), _finish_product.bind(index))
	return true


func sale_items() -> Array[ShopItem]:
	var items: Array[ShopItem] = []
	for index in products:
		items.append(ShopItem.sale("Obchod: %s" % PRODUCTS[index].name, PRODUCTS[index].cost, _lose_product.bind(index)))
	return items


func info_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	if not is_operational():
		lines.append(construction_line())
		lines.append("Až bude hotový, posádky lodí tu budou nakupovat a lodím ve frontě pomaleji ubude trpělivost.")
		return lines
	var names := PackedStringArray()
	for item in _assortment():
		names.append(item.name)
	lines.append("Prodává: %s" % ", ".join(names))
	lines.append("Trpělivost lodí ve frontě ubývá o %d %% pomaleji." % roundi((1.0 - patience_drain()) * 100.0))
	lines.append("Tržby celkem: %s kr" % Game.format_number(revenue))
	if job:
		lines.append(job_line())
	return lines


func info_actions() -> Array[ShopItem]:
	if not is_operational():
		return super()
	var actions: Array[ShopItem] = []
	for i in PRODUCTS.size():
		actions.append(ShopItem.new(func() -> String: return "Přidat zboží: %s" % PRODUCTS[i].name,
				product_cost.bind(i), add_product.bind(i), ShopItem.Kind.UPGRADE))
	actions.append(ShopItem.new(func() -> String: return "Přistavět skladiště",
			station.warehouse_cost, station.build_warehouse))
	return actions


func _assortment() -> Array:
	var items := [BASIC]
	for i in products:
		items.append(PRODUCTS[i])
	return items


static func kinds_text(count: int) -> String:
	if count == 1:
		return "1 druh zboží"
	return "%d %s zboží" % [count, "druhy" if count <= 4 else "druhů"]


func _lose_product(index: int) -> void:
	products.erase(index)
	_update_construction_looks()


func _finish_product(index: int) -> void:
	products.append(index)
	_update_construction_looks()


func _update_construction_looks() -> void:
	super()
	# Části stavby: staveniště -> tmavá kostra kiosku -> kiosek bez světel -> rozsvícený obchod.
	_base.visible = built_phases == 1
	_kiosk.visible = built_phases >= 2
	match built_phases:
		2:
			_kiosk.modulate = SHELL_MODULATE
		3:
			_kiosk.modulate = NO_NEON_MODULATE
		_:
			_kiosk.modulate = Color.WHITE
	_neon.visible = is_operational()
	for i in _props.size():
		_props[i].visible = products.has(i)
	_label.visible = built_phases >= 1
	_label.text = "Obchod · %s" % kinds_text(_assortment().size()) if is_operational() else "Obchod"
