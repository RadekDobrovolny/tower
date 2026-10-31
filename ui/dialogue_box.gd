class_name DialogueBox
extends ColorRect

## Rozhovor ve spodní části obrazovky: vlevo obličej postavy, vedle její jméno a text, který se
## postupně vypisuje. Dokud je vidět, hra stojí a hráč musí repliky odkliknout. Běží i při
## pauze (process_mode Always).

signal closed

## Kolik znaků za sekundu se vypisuje.
const REVEAL_SPEED := 60.0
const MONEY_ICON_SIZE := 17

var _lines: Array = []
var _index := 0
var _reveal: Tween

@onready var _portrait: TextureRect = %DialoguePortrait
@onready var _name: Label = %DialogueName
@onready var _text: RichTextLabel = %DialogueText
@onready var _ok: Button = %DialogueOk


func _ready() -> void:
	hide()
	_ok.pressed.connect(_advance)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_accept"):
		_advance()
		get_viewport().set_input_as_handled()


## Přehraje rozhovor a zastaví hru, dokud ho hráč neodklikne.
func play(lines: Array) -> void:
	_lines = lines
	_index = -1
	get_tree().paused = true
	show()
	_show_next_line()


func is_open() -> bool:
	return visible


func close() -> void:
	hide()
	get_tree().paused = false
	closed.emit()


## OK dopíše rozepsaný text, teprve pak přejde na další repliku.
func _advance() -> void:
	if _reveal and _reveal.is_running():
		_reveal.kill()
		_text.visible_ratio = 1.0
	else:
		_show_next_line()


func _show_next_line() -> void:
	_index += 1
	if _index >= _lines.size():
		close()
		return
	var line: Dictionary = _lines[_index]
	var speaker: Dictionary = Story.SPEAKERS[line.speaker]
	_name.text = speaker.name
	_portrait.texture = speaker.portraits[line.mood]
	_text.text = UiIcons.money_bbcode(line.text, MONEY_ICON_SIZE)
	_text.visible_ratio = 0.0
	_reveal = create_tween()
	_reveal.tween_property(_text, "visible_ratio", 1.0, line.text.length() / REVEAL_SPEED)
