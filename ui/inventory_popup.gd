class_name InventoryPopup
extends ColorRect

## Inventář skladiště: sloty s artefakty, které v něm jsou. Kliknutím se ukáže, co artefakt
## dělá, a jde ho prodat (artefakt z příběhu ne). Zastaví hru. Běží i při pauze (process_mode Always).

const SLOT_SIZE := Vector2(92, 92)

var _station: Station
var _slots_buttons: Array[Button] = []
var _selected := 0
var _sell_button: ActionButton

@onready var _slots: GridContainer = %InventorySlots
@onready var _picture: TextureRect = %InventoryPicture
@onready var _name: Label = %InventoryName
@onready var _about: Label = %InventoryAbout
@onready var _effect: Label = %InventoryEffect


func _ready() -> void:
	hide()
	%InventoryClose.pressed.connect(_close)
	for i in Warehouse.SLOTS:
		var button := Button.new()
		button.custom_minimum_size = SLOT_SIZE
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.expand_icon = true
		button.pressed.connect(_select_slot.bind(i))
		_slots.add_child(button)
		_slots_buttons.append(button)
	_sell_button = ActionButton.new()
	_sell_button.setup(null, "Prodat")
	_sell_button.pressed.connect(_sell)
	%Detail.add_child(_sell_button)


## Otevře inventář a zastaví hru.
func open(station: Station) -> void:
	_station = station
	_select_slot(0)
	get_tree().paused = true
	show()


func _select_slot(index: int) -> void:
	_selected = index
	var stored := _station.stored_artifacts
	for i in _slots_buttons.size():
		var button := _slots_buttons[i]
		button.icon = stored[i].icon if i < stored.size() else null
		button.disabled = i >= stored.size()
		button.set_pressed_no_signal(i == index and i < stored.size())
	var has_artifact := index < stored.size()
	_picture.visible = has_artifact
	_effect.visible = has_artifact
	_sell_button.visible = has_artifact and not stored[index].has("story")
	if has_artifact:
		var artifact: Dictionary = stored[index]
		_picture.texture = artifact.icon
		_name.text = artifact.name
		_about.text = artifact.about
		_effect.text = artifact.info
		_sell_button.set_cost(artifact.credits)
	else:
		_name.text = "Skladiště je prázdné"
		_about.text = "Artefakty občas najdeš v truhlách ze sestřelených pirátů."


func _sell() -> void:
	_station.sell_artifact(_station.stored_artifacts[_selected])
	_select_slot(mini(_selected, maxi(_station.stored_artifacts.size() - 1, 0)))


func _close() -> void:
	hide()
	get_tree().paused = false
	_station.select(null)
