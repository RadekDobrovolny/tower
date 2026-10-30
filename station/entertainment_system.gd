class_name EntertainmentSystem
extends Building

## Zábavní systém: billboard s televizí. Lodě ve frontě se dívají, takže jim pomaleji
## ubývá trpělivost, a pobavení zákazníci o něco častěji nechávají dýško.
## Začne fungovat, až je postavený celý (po zapojení elektřiny).

## Části stavby: název, cena (dohromady 2 000 kr) a doba stavby (s).
const PHASES := [
	{"name": "Základní deska", "cost": 300, "duration": 3.0},
	{"name": "Rampa na obrazovku", "cost": 400, "duration": 4.0},
	{"name": "Instalace obrazovky", "cost": 900, "duration": 5.0},
	{"name": "Napojení elektřiny", "cost": 400, "duration": 3.0},
]
## Pro každý level: cena vylepšení na tenhle level, jak rychle lodím ve frontě ubývá
## trpělivost (1 = bez televize), o kolik se zvýší šance na dýško a jak dlouho (s)
## vylepšení trvá. Level 1 je samotná stavba (cena a doba jsou v PHASES).
const LEVELS := [
	{"cost": 0, "patience_drain": 0.75, "tip_bonus": 0.02, "upgrade_time": 0.0},
	{"cost": 3000, "patience_drain": 0.6, "tip_bonus": 0.04, "upgrade_time": 8.0},
	{"cost": 5000, "patience_drain": 0.45, "tip_bonus": 0.06, "upgrade_time": 12.0},
]
const SCROLL_SPEED := 40.0
const AD_GAP := 60.0

## Jak tmavě je televize vidět, když je hotová jen rampa (rozestavěný rám).
const FRAME_ONLY_MODULATE := Color(0.3, 0.3, 0.32)

## Level 0 znamená, že systém ještě nefunguje (není dostavěný).
var level := 0

@onready var _base: Sprite2D = $Base
@onready var _tv: Sprite2D = $Tv
@onready var _screen_fx: Node2D = $ScreenFx
@onready var _screen: Control = $Screen
@onready var _ad_label: Label = $Screen/AdLabel
@onready var _level_label: Label = $LevelLabel


func _ready() -> void:
	super()
	_next_ad()


func _process(delta: float) -> void:
	super(delta)
	if level == 0:
		return
	_ad_label.position.x -= SCROLL_SPEED * delta
	if _ad_label.position.x < -_ad_label.size.x - AD_GAP:
		_next_ad()


func build_phases() -> Array:
	return PHASES


func display_name() -> String:
	return "Zábavní systém"


## Zapne systém po dostavění (level 1).
func power_on() -> void:
	level = maxi(level, 1)
	_update_construction_looks()


## Postaví systém hned a nastaví level (startovní stav mise). 0 = nic.
func set_level(value: int) -> void:
	finish_instantly()
	level = clampi(value, 0, LEVELS.size())
	_update_construction_looks()


## Jak rychle ubývá trpělivost lodím ve frontě (1 = normálně).
func patience_drain() -> float:
	return 1.0 if level == 0 else LEVELS[level - 1].patience_drain


## O kolik se zvyšuje šance na dýško.
func tip_bonus() -> float:
	return 0.0 if level == 0 else LEVELS[level - 1].tip_bonus


## Cena vylepšení, nebo -1, když teď vylepšit nejde (staví se, je na maximu).
func next_upgrade_cost() -> int:
	if level == 0 or job != null or level >= LEVELS.size():
		return -1
	return LEVELS[level].cost


## Zaplatí vylepšení a zadá ho stavebnímu dronovi. Vrátí, jestli se to povedlo.
func start_upgrade() -> bool:
	var cost := next_upgrade_cost()
	if cost < 0 or not Game.spend_credits(cost):
		return false
	var target_level := level + 1
	station.queue_job(self, "Vylepšení na level %d" % target_level,
			[{"name": "Vylepšování", "duration": LEVELS[target_level - 1].upgrade_time}],
			Callable(), _finish_upgrade)
	return true


func info_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	if level == 0:
		lines.append(construction_line())
		lines.append("Až bude hotový, lodím ve frontě pomaleji ubude trpělivost a častěji nechají dýško.")
		return lines
	lines.append("Level %d" % level)
	lines.append("Trpělivost lodí ve frontě ubývá o %d %% pomaleji." % roundi((1.0 - patience_drain()) * 100.0))
	lines.append("Šance na dýško: +%d %%" % roundi(tip_bonus() * 100.0))
	if job:
		lines.append(job_line())
	return lines


func info_actions() -> Array[ShopItem]:
	if not is_operational():
		return super()
	var actions: Array[ShopItem] = [
		ShopItem.new(_upgrade_label, next_upgrade_cost, start_upgrade, ShopItem.Kind.UPGRADE),
	]
	return actions


func _upgrade_label() -> String:
	return "Vylepšit na level %d" % (level + 1)


func _finish_upgrade() -> void:
	level += 1
	_update_construction_looks()


func _next_ad() -> void:
	_ad_label.text = Lines.pick(Lines.BILLBOARD)
	_ad_label.reset_size()
	_ad_label.position.x = _screen.size.x


func _update_construction_looks() -> void:
	super()
	# Části stavby: staveniště -> tmavý rám na rampě -> televize -> po zapojení elektřiny obraz.
	_base.visible = built_phases == 1
	_tv.visible = built_phases >= 2
	_tv.modulate = FRAME_ONLY_MODULATE if built_phases == 2 else Color.WHITE
	_screen_fx.visible = level > 0
	_screen_fx.set("level", level)
	_screen.visible = level > 0
	_level_label.visible = built_phases >= 1
	_level_label.text = "Zábavní systém · L%d" % level if level > 0 else "Zábavní systém"
