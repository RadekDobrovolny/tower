class_name Mission
extends Resource

## Jedna mise (úkol) v kontinuální hře. Pravidla platí od začátku mise a zůstávají,
## dokud je nezmění další mise. Startovní stav se použije jen tehdy, když hra začne
## rovnou od téhle mise (výběr v menu, hodí se pro testování).

@export var title := ""

@export_group("Pravidla")
## Nejvyšší level, na který jde vylepšit androida (tankování i jízdu).
@export var max_android_level := 6
## Jestli jde koupit druhou hadici. Otevře se, až stojí dva čerpací sloty.
@export var dual_hose_available := false
## Jestli jde koupit a vylepšovat zábavní systém.
@export var entertainment_available := false
## Kolik čerpacích slotů může stanice mít celkem (včetně těch ve stavbě).
@export var max_slots := 1
## Jestli se hraje s ekonomikou galaxínu (zásobník, dodavatelé, vlastní cena).
@export var galaxin_economy := false
## Kolik galaxínu dostane hráč do zásobníku, když se ekonomika galaxínu zapne.
@export var start_galaxin := 300
## Rozmezí v sekundách mezi přílety lodí (při běžné ceně galaxínu).
@export var ship_interval_min := 3.0
@export var ship_interval_max := 7.0
## Jestli jde postavit obchod, řídící centrum u zásobníku a obranné věže.
@export var shop_available := false
@export var control_center_available := false
@export var tower_available := false
## Jestli jde k obchodu přistavět skladiště.
@export var warehouse_available := false
## Jestli jde vylepšovat stavební dron (rychlost letu a práce).
@export var drone_upgrades := false
## Jestli na stanici útočí piráti a rozmezí v sekundách mezi útoky.
@export var pirates := false
@export var pirate_interval_min := 40.0
@export var pirate_interval_max := 70.0

@export_group("Cíle")
## Kolik kreditů musí mít hráč zároveň na účtu. Cíle s hodnotou 0 se nepoužívají.
@export var goal_credits := 0
## Na jaký level musí hráč vylepšit androidovi tankování.
@export var goal_fuel_level := 0
@export var goal_entertainment_level := 0
@export var goal_tank_level := 0
## Kolik hotových čerpacích slotů musí stanice mít.
@export var goal_slots := 0
## Jestli musí stát hotový obchod.
@export var goal_shop := false
## Kolik druhů zboží navíc musí obchod prodávat.
@export var goal_shop_products := 0
## Jestli musí řídící centrum objednávat samo (automatický dispečink).
@export var goal_dispatch := false
## Jestli musí stát hotové skladiště.
@export var goal_warehouse := false
@export var goal_tower_level := 0
## Kolik pirátů musí stanice sestřelit (věží i androidem).
@export var goal_pirates_shot := 0

@export_group("Start při výběru z menu")
@export var start_credits := 0
@export var start_fuel_level := 1
@export var start_walk_level := 1
## Jestli má android druhou hadici.
@export var start_dual_hose := false
## 0 = zábavní systém ještě není koupený.
@export var start_entertainment_level := 0
@export var start_slots := 1
@export var start_tank_level := 1
## -1 = bez obchodu, jinak kolik druhů zboží navíc obchod prodává.
@export var start_shop_products := -1
## 0 = bez řídícího centra, 1 = postavené, 2 = i s automatickým dispečinkem.
@export var start_control_center := 0
## 0 = bez obranné věže.
@export var start_tower_level := 0
## Všechno postavené a vylepšené na maximum. Levely výše se pak nepoužijí.
@export var start_maxed := false
