class_name SoundButton
extends Button

## Ikonka reproduktoru, která ztlumí nebo zase zapne zvuky.

const ICON_ON := preload("res://assets/ui/icons/sound_on.svg")
const ICON_OFF := preload("res://assets/ui/icons/sound_off.svg")


func _ready() -> void:
	pressed.connect(func() -> void: Sfx.muted = not Sfx.muted)
	Sfx.muted_changed.connect(_update_icon)
	_update_icon()


func _update_icon() -> void:
	icon = ICON_OFF if Sfx.muted else ICON_ON
	tooltip_text = "Zapnout zvuky" if Sfx.muted else "Ztlumit zvuky"
