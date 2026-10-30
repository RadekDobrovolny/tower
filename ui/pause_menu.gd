class_name PauseMenu
extends ColorRect

## Pauza během hry: zastaví hru a nabídne pokračovat, začít znovu (od mise, od které hra začala)
## nebo odejít do hlavního menu.
## Otevírá se tlačítkem „Menu“ v HUD nebo klávesou Esc. Běží i při pauze (process_mode Always).


func _ready() -> void:
	hide()
	%ResumeButton.pressed.connect(close)
	%PauseRestartButton.pressed.connect(_on_restart_pressed)
	%MainMenuButton.pressed.connect(_on_main_menu_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if visible:
		close()
	else:
		open()
	get_viewport().set_input_as_handled()


## Pozastaví hru a ukáže menu. Když už je hra zastavená něčím jiným (např. vítězstvím), nic neudělá.
func open() -> void:
	if get_tree().paused:
		return
	get_tree().paused = true
	show()


func close() -> void:
	hide()
	get_tree().paused = false


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(Missions.MENU_SCENE)
