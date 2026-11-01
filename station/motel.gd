class_name Motel
extends Building

## Provizorní motel pro posádky, které kvůli embargu uvízly na stanici. Když stojí i parkoviště,
## část lodí po natankování přeletí na stání a po celou dobu pobytu pravidelně platí. Přináší
## peníze, i když se galaxín moc neprodává.

## Části stavby: název, cena (dohromady 6 000 kr) a doba stavby (s).
const PHASES := [
	{"name": "Základy", "cost": 800, "duration": 3.0},
	{"name": "Ocelová kostra", "cost": 1500, "duration": 5.0},
	{"name": "Obytné kapsle", "cost": 2200, "duration": 6.0},
	{"name": "Neon a recepce", "cost": 1500, "duration": 4.0},
]
## Jak často si posádka po natankování vezme pokoj, jak často (s) a kolik (kr) za něj platí
## (`motel_pay` v `Ship.HULLS` to mění) a kolik plateb za pobyt pošle.
const GUEST_CHANCE := 0.35
const PAY_INTERVAL := 5.0
const PAY_AMOUNT := 20
const PAYMENTS_MIN := 5
const PAYMENTS_MAX := 9
const SHELL_MODULATE := Color(0.45, 0.45, 0.47)

## Kolik motel celkem vydělal.
var revenue := 0

@onready var _base: Sprite2D = $Base
@onready var _frame: Sprite2D = $Frame
@onready var _body: Sprite2D = $Body
@onready var _sign: Sprite2D = $Sign
@onready var _sign_glow: Sprite2D = $SignGlow
@onready var _vending: Sprite2D = $Vending
@onready var _luggage: Sprite2D = $Luggage
@onready var _label: Label = $Label


func build_phases() -> Array:
	return PHASES


func display_name() -> String:
	return "Motel"


## Host zaplatil za další část pobytu.
func add_payment(amount: int) -> void:
	revenue += amount


func info_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	if not is_operational():
		lines.append(construction_line())
		lines.append("Až bude hotový a bude stát parkoviště, posádky tu budou bydlet a platit.")
		return lines
	lines.append("Posádky, které uvízly kvůli embargu, tu bydlí. Každých %d s platí %d kr." % [roundi(PAY_INTERVAL), PAY_AMOUNT])
	if station.has_parking():
		lines.append("Hosté: %d / %d" % [station.parking().guests(), Parking.BAYS.size()])
	else:
		lines.append("Bez parkoviště nemají hosté kde nechat loď.")
	lines.append("Tržby celkem: %s kr" % Game.format_number(revenue))
	return lines


func _update_construction_looks() -> void:
	super()
	# Části stavby: staveniště -> kostra -> tmavé kapsle -> rozsvícený motel s neonem.
	_base.visible = built_phases == 1
	_frame.visible = built_phases == 2
	_body.visible = built_phases >= 3
	_body.modulate = Color.WHITE if is_operational() else SHELL_MODULATE
	_sign.visible = is_operational()
	_sign_glow.visible = is_operational()
	_vending.visible = is_operational()
	_luggage.visible = is_operational()
	_label.visible = built_phases >= 1
