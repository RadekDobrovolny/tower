class_name Mission
extends Resource

## Jedna mise (úkol) v kontinuální hře. Pravidla platí od začátku mise a zůstávají,
## dokud je nezmění další mise. Startovní stav se použije jen tehdy, když hra začne
## rovnou od téhle mise (výběr v menu, hodí se pro testování).

@export var title := ""
## Úvodní text mise, ukáže se v okně na začátku mise.
@export_multiline var description := ""

@export_group("Pravidla")
## Nejvyšší level, na který jde vylepšit androida (tankování i chůzi).
@export var max_android_level := 6
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

@export_group("Cíle")
## Kolik kreditů musí mít hráč zároveň na účtu. Cíle s hodnotou 0 se nepoužívají.
@export var goal_credits := 0
## Na jaký level musí hráč vylepšit androidovi tankování.
@export var goal_fuel_level := 0
@export var goal_entertainment_level := 0
@export var goal_tank_level := 0

@export_group("Start při výběru z menu")
@export var start_credits := 0
@export var start_fuel_level := 1
@export var start_walk_level := 1
## 0 = zábavní systém ještě není koupený.
@export var start_entertainment_level := 0
@export var start_slots := 1
@export var start_tank_level := 1
