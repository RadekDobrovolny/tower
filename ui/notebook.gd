extends Node2D

## Pumpíkův zápisník: encyklopedie hry s kapitolami a Centrem zvuků. Obsah je v `Notebook`.

const SOUND_CENTER_SCENE := "res://ui/sound_center.tscn"
const IMAGE_MAX_HEIGHT := 190.0
const ROW_HEIGHT := 34.0
const MONEY_ICON_SIZE := 15

var _chapter_buttons: Array[Button] = []
var _entry_buttons: Array[Button] = []
var _entries: Array[Dictionary] = []

@onready var _chapters: VBoxContainer = %Chapters
@onready var _entry_list: VBoxContainer = %EntryList
@onready var _image: TextureRect = %EntryImage
@onready var _title: Label = %EntryTitle
@onready var _text: RichTextLabel = %EntryText


func _ready() -> void:
	for i in Notebook.CHAPTERS.size():
		var button := _make_button(Notebook.CHAPTERS[i])
		button.pressed.connect(_show_chapter.bind(i))
		_chapters.add_child(button)
		_chapter_buttons.append(button)
	%SoundCenterButton.pressed.connect(get_tree().change_scene_to_file.bind(SOUND_CENTER_SCENE))
	%BackButton.pressed.connect(get_tree().change_scene_to_file.bind(Missions.MENU_SCENE))
	_show_chapter(0)


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = ROW_HEIGHT
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_NONE
	button.toggle_mode = true
	return button


func _show_chapter(index: int) -> void:
	for i in _chapter_buttons.size():
		_chapter_buttons[i].set_pressed_no_signal(i == index)
	for button in _entry_buttons:
		button.queue_free()
	_entry_buttons.clear()
	_entries = Notebook.entries(Notebook.CHAPTERS[index])
	for i in _entries.size():
		var button := _make_button(_entries[i].title)
		button.pressed.connect(_show_entry.bind(i))
		_entry_list.add_child(button)
		_entry_buttons.append(button)
	_show_entry(0)


func _show_entry(index: int) -> void:
	for i in _entry_buttons.size():
		_entry_buttons[i].set_pressed_no_signal(i == index)
	var entry: Dictionary = _entries[index]
	_image.texture = entry.get("image")
	_image.visible = entry.has("image")
	_title.text = entry.title
	_text.text = UiIcons.money_bbcode(entry.text, MONEY_ICON_SIZE)
