class_name JunkDealer
extends Node

## Vesmírný vetešník: pojistka, aby se hráč nikdy nezasekl. Když je zásobník prázdný, žádná
## cisterna není na cestě a na užitečnou dávku nejsou kredity, přiletí a nabídne odkup tří vylepšení
## za polovinu ceny. Prodané vylepšení hráč ztratí. Kdo nemá co prodat, dostane almužnu.

signal arrived(offers: Array[ShopItem])

const SALE_SHARE := 0.5
const OFFER_COUNT := 3
## Jak dlouho (s) musí stav trvat, než vetešník přiletí. Kredity ještě můžou přinést kořist,
## obchod nebo automaty. Na lodě, které ještě zaplatí za natankovaný galaxín, počká celou dobu.
const WAIT_TIME := 4.0
## Za jak dlouho (s) se vrátí, když ho hráč odmítl.
const RETRY_TIME := 30.0
const HANDOUT := 150
const SALE_COLOR := Color(0.45, 0.95, 0.85)

@export var station: Station

var _waited := 0.0


func _process(delta: float) -> void:
	if not _is_stranded():
		_waited = 0.0
		return
	_waited += delta
	if _waited >= WAIT_TIME:
		_waited = WAIT_TIME - RETRY_TIME
		arrived.emit(_offers())


## Kolik hráč za položku dostane.
func refund(item: ShopItem) -> int:
	return roundi(item.cost.call() * SALE_SHARE)


## Prodá položku: vylepšení zmizí a hráč dostane peníze. Vybere zásobník, ať je objednávka
## cisterny hned po ruce.
func sell(item: ShopItem) -> void:
	var amount := refund(item)
	item.buy.call()
	Game.add_credits(amount)
	Sfx.play("coin")
	FloatingText.spawn(station, station.tank.position + Vector2(0, -60), "+%d kr od vetešníka" % amount, SALE_COLOR)
	station.select(station.tank)


func _is_stranded() -> bool:
	return station.galaxin_economy and station.tank.is_empty() \
			and station.supply.state == Supply.State.IDLE \
			and not station.supply.can_afford_useful_tanker() and not station.under_attack() \
			and not station.ships_owe_payment()


func _offers() -> Array[ShopItem]:
	var items := station.sale_items()
	if items.is_empty():
		return [ShopItem.sale("Almužna od vetešníka", roundi(HANDOUT / SALE_SHARE), func() -> void: pass)]
	items.shuffle()
	return items.slice(0, OFFER_COUNT)
