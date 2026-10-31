extends Node2D

## Centrum zvuků: všechny zvuky hry na jedné obrazovce, aby šly po jednom poslechnout a vybrat,
## které sedí. Hrají stejně hlasitě jako ve hře. Seznam se bere z `Sfx.SOUNDS` a `Sfx.LOOPS`,
## takže se tu nový zvuk objeví sám.

## Které skupiny zvuků jsou ve kterém sloupci.
const COLUMNS := [["Boj"], ["Provoz"], ["Rozhraní", "Smyčky"]]
const COLUMN_WIDTH := 280.0
const ROW_HEIGHT := 33.0

var _sounds: Array[String] = []
var _buttons: Array[Button] = []
## Index naposledy spuštěného zvuku, -1 = zatím žádný.
var _current := -1
var _loop_playing := false

@onready var _columns: HBoxContainer = %Columns
@onready var _now_playing: Label = %NowPlaying


func _ready() -> void:
	for groups: Array in COLUMNS:
		var column := VBoxContainer.new()
		column.custom_minimum_size.x = COLUMN_WIDTH
		_columns.add_child(column)
		for group: String in groups:
			_add_group(column, group)
	%PreviousButton.pressed.connect(func() -> void: _play(maxi(_current, 0) - 1))
	%ReplayButton.pressed.connect(func() -> void: _play(maxi(_current, 0)))
	%NextButton.pressed.connect(func() -> void: _play(_current + 1))
	%BackButton.pressed.connect(get_tree().change_scene_to_file.bind(Missions.MENU_SCENE))
	_refresh()


func _exit_tree() -> void:
	Sfx.stop_preview()


func _add_group(column: VBoxContainer, group: String) -> void:
	var caption := Label.new()
	caption.theme_type_variation = &"HudKicker"
	caption.text = group
	caption.uppercase = true
	column.add_child(caption)
	for sound: String in _sounds_in_group(group):
		var index := _sounds.size()
		var button := Button.new()
		button.set_meta(Sfx.SILENT_BUTTON, true)
		button.text = _info(sound).label
		button.custom_minimum_size.y = ROW_HEIGHT
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.pressed.connect(_on_sound_pressed.bind(index))
		column.add_child(button)
		_sounds.append(sound)
		_buttons.append(button)


func _sounds_in_group(group: String) -> Array[String]:
	var result: Array[String] = []
	for sound: String in Sfx.SOUNDS.keys() + Sfx.LOOPS.keys():
		if _info(sound).group == group:
			result.append(sound)
	return result


func _info(sound: String) -> Dictionary:
	return Sfx.LOOPS[sound] if Sfx.LOOPS.has(sound) else Sfx.SOUNDS[sound]


## Druhé kliknutí na hrající smyčku ji zastaví.
func _on_sound_pressed(index: int) -> void:
	if index == _current and _loop_playing:
		Sfx.stop_preview()
		_loop_playing = false
		_refresh()
	else:
		_play(index)


func _play(index: int) -> void:
	_current = posmod(index, _sounds.size())
	var sound := _sounds[_current]
	Sfx.preview(sound)
	_loop_playing = Sfx.LOOPS.has(sound)
	_refresh()


func _refresh() -> void:
	for i in _buttons.size():
		_buttons[i].set_pressed_no_signal(i == _current)
	if _current < 0:
		_now_playing.text = "Vyber zvuk, nebo projdi všechny tlačítkem Další."
		return
	var sound := _sounds[_current]
	var state := ""
	if Sfx.LOOPS.has(sound):
		state = " · hraje dokola" if _loop_playing else " · zastaveno"
	_now_playing.text = "%d / %d · %s (%s)%s" % [_current + 1, _sounds.size(), _info(sound).label, sound, state]
