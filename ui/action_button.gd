class_name ActionButton
extends Button

## Tlačítko akce v HUD: ikonka druhu akce, popisek vlevo a cena s mincí vpravo.
## Na co hráč nemá, zůstane vidět, ale je ztlumené a cena svítí červeně.

const PRICE_COLOR := Color(1, 0.87, 0.55)
const TOO_EXPENSIVE_COLOR := Color(0.95, 0.4, 0.42)

var _row: HBoxContainer
var _icon_rect: TextureRect
var _label: Label
var _cost_label: Label
var _coin: TextureRect


func _init() -> void:
	focus_mode = FOCUS_NONE
	custom_minimum_size = Vector2(0, 32)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.mouse_filter = MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 10)
	add_child(margin)
	_row = HBoxContainer.new()
	_row.mouse_filter = MOUSE_FILTER_IGNORE
	_row.add_theme_constant_override("separation", 6)
	margin.add_child(_row)
	_icon_rect = _make_icon(16)
	_icon_rect.hide()
	_row.add_child(_icon_rect)
	_label = Label.new()
	_label.size_flags_horizontal = SIZE_EXPAND_FILL
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_row.add_child(_label)
	_cost_label = Label.new()
	_cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cost_label.add_theme_font_override("font", preload("res://assets/fonts/ChakraPetch-SemiBold.ttf"))
	_row.add_child(_cost_label)
	_coin = _make_icon(15)
	_coin.texture = UiIcons.COIN
	_row.add_child(_coin)


func setup(icon_texture: Texture2D, label_text: String) -> void:
	_icon_rect.texture = icon_texture
	_icon_rect.visible = icon_texture != null
	set_label(label_text)


func set_label(label_text: String) -> void:
	_label.text = label_text
	tooltip_text = label_text


## Cena -1 znamená tlačítko bez ceny (např. „Cisterna je objednaná“).
func set_cost(cost: int, affordable := true) -> void:
	_cost_label.visible = cost >= 0
	_coin.visible = cost >= 0
	if cost >= 0:
		_cost_label.text = Game.format_number(cost)
		_cost_label.add_theme_color_override("font_color", PRICE_COLOR if affordable else TOO_EXPENSIVE_COLOR)


func set_enabled(enabled: bool) -> void:
	disabled = not enabled
	_row.modulate.a = 1.0 if enabled else 0.5


func _make_icon(icon_size: int) -> TextureRect:
	var rect := TextureRect.new()
	rect.custom_minimum_size = Vector2(icon_size, icon_size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.size_flags_vertical = SIZE_SHRINK_CENTER
	rect.mouse_filter = MOUSE_FILTER_IGNORE
	return rect
