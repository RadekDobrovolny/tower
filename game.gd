extends Node

## Globální stav rozehrané hry (autoload `Game`).

signal credits_changed(credits: int)
signal stats_changed

## Ve webu hra kreslí nanejvýš tolik snímků za sekundu. Prohlížeč by jinak kreslil podle
## displeje (na Macu 120 Hz) a zbytečně by vytížil procesor. Mimo web se nic neomezuje,
## aby běhy z příkazové řádky s --fixed-fps (simulace tempa) běžely rychleji než reálný čas.
const WEB_MAX_FPS := 60

## Od které mise (index v Missions.ALL) hra začne. Nastavuje ho menu.
var start_mission := 0
var credits := 0
var ships_served := 0
var ships_lost := 0
var pirates_shot := 0
## Jestli hráč v Misi 7 prozradil Zoru císařské hlídce.
var zora_reported := false


func _ready() -> void:
	if OS.has_feature("web"):
		Engine.max_fps = WEB_MAX_FPS


## Vynuluje stav na začátku hry. Hráč může začínat s nějakými kredity.
func reset(start_credits := 0) -> void:
	credits = start_credits
	ships_served = 0
	ships_lost = 0
	pirates_shot = 0
	zora_reported = false
	credits_changed.emit(credits)
	stats_changed.emit()


func add_credits(amount: int) -> void:
	credits += amount
	credits_changed.emit(credits)


## Odečte kredity, pokud na to hráč má. Vrátí, jestli se platba povedla.
func spend_credits(amount: int) -> bool:
	if amount > credits:
		return false
	credits -= amount
	credits_changed.emit(credits)
	return true


func record_ship_served() -> void:
	ships_served += 1
	stats_changed.emit()


func record_ship_lost() -> void:
	ships_lost += 1
	stats_changed.emit()


func record_pirate_shot() -> void:
	pirates_shot += 1
	stats_changed.emit()


## Část světa, která je právě vidět na obrazovce (ve světových souřadnicích). Obraz se
## roztahuje podle poměru stran displeje (aspect „expand“) a kamera drží střed hry
## uprostřed, takže viditelná oblast může být širší nebo vyšší než základních 1280×720.
static func visible_world_rect(item: CanvasItem) -> Rect2:
	return item.get_canvas_transform().affine_inverse() * item.get_viewport_rect()


## Naformátuje číslo s mezerami mezi tisíci, např. 10000 → „10 000“.
static func format_number(value: int) -> String:
	var digits := str(absi(value))
	var result := ""
	while digits.length() > 3:
		result = " " + digits.right(3) + result
		digits = digits.left(digits.length() - 3)
	return ("-" if value < 0 else "") + digits + result
