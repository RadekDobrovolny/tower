class_name ShopItem
extends RefCounted

## Jedna položka obchodu v HUD, např. vylepšení Pumpíka nebo koupě slotu.

## Druh akce, podle kterého HUD vybere ikonku tlačítka.
enum Kind { BUILD, UPGRADE }

## () -> String: text tlačítka bez ceny.
var label: Callable
## () -> int: cena, nebo -1, když už není co koupit.
var cost: Callable
## () -> bool: provede nákup, vrátí, jestli se povedl.
var buy: Callable
var kind: Kind


## Položka pro vetešníka: `price` je původní cena vylepšení, `undo` ho vrátí o level zpět.
static func sale(text: String, price: int, undo: Callable) -> ShopItem:
	return ShopItem.new(func() -> String: return text, func() -> int: return price, undo, Kind.UPGRADE)


func _init(label_fn: Callable, cost_fn: Callable, buy_fn: Callable, item_kind := Kind.BUILD) -> void:
	label = label_fn
	cost = cost_fn
	buy = buy_fn
	kind = item_kind
