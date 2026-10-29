class_name SpeechBubble
extends PanelContainer

## Bublina s hláškou nad lodí nebo androidem. Další hlášky se řadí za sebe.

const NORMAL_COLOR := Color(0.1, 0.12, 0.18)
const ANGRY_COLOR := Color(0.8, 0.12, 0.1)
const DURATION := 2.2

## Jak vysoko nad svým vlastníkem visí spodní hrana bubliny.
@export var height := 44.0

var _queue: Array[Dictionary] = []
var _time_left := 0.0

@onready var _label: Label = $Label


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		_show_next()


func say(text: String, angry := false) -> void:
	_queue.append({"text": text, "angry": angry})
	if not visible:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		hide()
		set_process(false)
		return
	var line: Dictionary = _queue.pop_front()
	_label.text = line.text
	_label.add_theme_color_override("font_color", ANGRY_COLOR if line.angry else NORMAL_COLOR)
	_time_left = DURATION
	reset_size()
	position = Vector2(-size.x / 2.0, -height - size.y)
	show()
	set_process(true)
