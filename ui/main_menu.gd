extends Node2D

## Úvodní obrazovka. Hra je kontinuální, ale dá se začít od kterékoli mise
## (se startovním stavem té mise), což se hodí hlavně pro testování. Poslední je mise Z:
## volná hra se vším na maximu.

@onready var _mission_buttons: VBoxContainer = %MissionButtons


func _ready() -> void:
	get_tree().paused = false
	for i in Missions.ALL.size():
		var mission: Mission = Missions.ALL[i]
		_add_button("Mise %d\n%s" % [i + 1, mission.title], i)
	_add_button("Mise Z\n%s" % Missions.FREE_PLAY.title, Missions.FREE_PLAY_INDEX)


func _add_button(text: String, mission_index: int) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(340, 56)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 15)
	button.pressed.connect(_start_from.bind(mission_index))
	_mission_buttons.add_child(button)


func _start_from(mission_index: int) -> void:
	Game.start_mission = mission_index
	get_tree().change_scene_to_file(Missions.WORLD_SCENE)
