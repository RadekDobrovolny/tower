class_name SpeechBubble
extends PanelContainer

## Bublina s hláškou nad lodí, cisternou, pirátem nebo androidem. Další hlášky se řadí za sebe.
## Vypadá jako panely HUD: tmavá, se zkoseným levým horním a pravým dolním rohem, tenkým
## mosazným lemem a ocáskem dolů k mluvčímu. Rozzlobená hláška má rudý lem i text.
## Každá nová hláška krátce „vyskočí“.

const TEXT_COLOR := Color(0.92, 0.89, 0.84)
const ANGRY_TEXT_COLOR := Color(1.0, 0.5, 0.42)
const BACKGROUND := Color(0.045, 0.035, 0.07, 0.94)
const BORDER := Color(0.62, 0.48, 0.24, 0.9)
const ANGRY_BORDER := Color(0.86, 0.22, 0.2, 0.95)
const DURATION := 2.2
## Ocásek bubliny: šířka u bubliny a výška (px).
const TAIL_WIDTH := 10.0
const TAIL_HEIGHT := 6.0
const POP_TIME := 0.16

## Jak vysoko nad svým vlastníkem visí spodní hrana bubliny.
@export var height := 44.0

var _queue: Array[Dictionary] = []
var _time_left := 0.0
var _normal_style := _make_style(BORDER)
var _angry_style := _make_style(ANGRY_BORDER)
var _style := _normal_style
var _pop: Tween

@onready var _label: Label = $Label


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		_show_next()


func say(text: String, angry := false) -> void:
	_queue.append({"text": text, "angry": angry})
	if not visible:
		_show_next()


## Přeruší, co bublina právě říká, a hned ukáže novou hlášku.
func say_now(text: String, angry := false) -> void:
	_queue.clear()
	_queue.append({"text": text, "angry": angry})
	_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		hide()
		set_process(false)
		return
	var line: Dictionary = _queue.pop_front()
	_label.text = line.text
	_label.add_theme_color_override("font_color", ANGRY_TEXT_COLOR if line.angry else TEXT_COLOR)
	_style = _angry_style if line.angry else _normal_style
	add_theme_stylebox_override("panel", _style)
	_time_left = DURATION
	reset_size()
	position = Vector2(-size.x / 2.0, -height - size.y)
	pivot_offset = Vector2(size.x / 2.0, size.y + TAIL_HEIGHT)
	show()
	set_process(true)
	queue_redraw()
	_play_pop()


func _play_pop() -> void:
	if _pop:
		_pop.kill()
	scale = Vector2.ONE * 0.82
	modulate.a = 0.0
	_pop = create_tween().set_parallel()
	_pop.tween_property(self, "scale", Vector2.ONE, POP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pop.tween_property(self, "modulate:a", 1.0, POP_TIME * 0.6)


## Ocásek pod bublinou. Překryje kousek spodního lemu, aby na bublinu navazoval.
func _draw() -> void:
	var bottom := size.y
	var middle := size.x / 2.0
	var tip := Vector2(middle, bottom + TAIL_HEIGHT)
	var left := Vector2(middle - TAIL_WIDTH / 2.0, bottom)
	var right := Vector2(middle + TAIL_WIDTH / 2.0, bottom)
	draw_colored_polygon(PackedVector2Array([left + Vector2(0, -1.5), right + Vector2(0, -1.5), tip]), _style.bg_color)
	draw_line(left, tip, _style.border_color, 1.0, true)
	draw_line(right, tip, _style.border_color, 1.0, true)


static func _make_style(border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BACKGROUND
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 1
	style.corner_detail = 1
	style.content_margin_left = 9.0
	style.content_margin_right = 9.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 4.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 4
	return style
