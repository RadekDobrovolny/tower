extends Node2D

## Úvodní obrazovka. Hra je kontinuální, ale dá se začít od kterékoli mise (se startovním stavem
## té mise), což se hodí hlavně pro testování. Mise jsou karty v mřížce po 8 v řadě, vejde se jich
## 32. Poslední je mise Z: volná hra se vším na maximu.

const NOTEBOOK_SCENE := "res://ui/notebook.tscn"
const CARD_SIZE := Vector2(140, 124)
const ICON_SIZE := 80.0
const NUMBER_FONT_SIZE := 22
## Tmavý obrys, aby dvouciferné číslo zůstalo čitelné i přes okraj obrázku.
const NUMBER_OUTLINE_SIZE := 6
const NUMBER_OUTLINE_COLOR := Color(0.03, 0.02, 0.05)
const NAME_FONT_SIZE := 12
const NAME_HEIGHT := 28.0

@onready var _mission_buttons: GridContainer = %MissionButtons


func _ready() -> void:
	get_tree().paused = false
	for i in Missions.ALL.size():
		_add_card(str(i + 1), Missions.ALL[i], i)
	_add_card("Z", Missions.FREE_PLAY, Missions.FREE_PLAY_INDEX)
	%NotebookButton.pressed.connect(get_tree().change_scene_to_file.bind(NOTEBOOK_SCENE))


## Karta mise: číslo v rohu, čtvercový obrázek a pod ním název.
func _add_card(number: String, mission: Mission, mission_index: int) -> void:
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_NONE
	card.tooltip_text = mission.title
	card.pressed.connect(_start_from.bind(mission_index))
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 4)
	var icon := TextureRect.new()
	icon.texture = mission.icon
	icon.custom_minimum_size = Vector2.ONE * ICON_SIZE
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := Label.new()
	title.text = mission.title
	title.custom_minimum_size.y = NAME_HEIGHT
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.max_lines_visible = 2
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
	content.add_child(icon)
	content.add_child(title)
	card.add_child(content)
	var number_label := Label.new()
	number_label.text = number
	number_label.position = Vector2(8, 2)
	number_label.theme_type_variation = &"HudTitle"
	number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number_label.add_theme_font_size_override("font_size", NUMBER_FONT_SIZE)
	number_label.add_theme_constant_override("outline_size", NUMBER_OUTLINE_SIZE)
	number_label.add_theme_color_override("font_outline_color", NUMBER_OUTLINE_COLOR)
	card.add_child(number_label)
	_mission_buttons.add_child(card)


func _start_from(mission_index: int) -> void:
	Game.start_mission = mission_index
	get_tree().change_scene_to_file(Missions.WORLD_SCENE)
