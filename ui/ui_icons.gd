class_name UiIcons
extends RefCounted

## Ikonky HUD a převod textů s cenami na BBCode, kde místo „kr“ stojí ikonka mince.

const COIN := preload("res://assets/ui/icons/coin.svg")
const BUILD := preload("res://assets/ui/icons/build.svg")
const UPGRADE := preload("res://assets/ui/icons/upgrade.svg")
const GOAL := preload("res://assets/ui/icons/goal.svg")
const CHECK := preload("res://assets/ui/icons/check.svg")

## Číslo (i s mezerami mezi tisíci a znaménkem) následované „kr“, které nepokračuje dalším písmenem.
const MONEY_PATTERN := "([+-]?\\d+(?: \\d{3})*) ?kr(?![a-zA-Z\\x{00C0}-\\x{017F}])"

static var _money_regex: RegEx


## Nahradí „1 200 kr“ za „1 200“ s ikonkou mince (a „6 kr/j“ za „6 [mince]/j“).
## Výsledek je pro RichTextLabel se zapnutým BBCode.
static func money_bbcode(text: String, icon_size := 14) -> String:
	if _money_regex == null:
		_money_regex = RegEx.create_from_string(MONEY_PATTERN)
	return _money_regex.sub(text, "$1 " + coin_bbcode(icon_size), true)


static func coin_bbcode(icon_size := 14) -> String:
	return "[img=%dx%d]%s[/img]" % [icon_size, icon_size, COIN.resource_path]


static func action_icon(kind: ShopItem.Kind) -> Texture2D:
	return UPGRADE if kind == ShopItem.Kind.UPGRADE else BUILD
