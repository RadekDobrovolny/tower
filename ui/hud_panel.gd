class_name HudPanel
extends PanelContainer

## Panel HUD se shaderem: scanlines, zrnění, svítící rohy a přejíždějící světlo (hud_panel.gdshader).
## Shader potřebuje znát velikost panelu v pixelech, proto má každý panel vlastní materiál.
## Když se panel ukáže, „naskenuje“ se shora dolů a jeho obsah se rozsvítí.

const SHADER := preload("res://ui/hud_panel.gdshader")
const REVEAL_TIME := 0.22

@export var accent := Color(0.97, 0.74, 0.38)
@export var reveal_on_show := true

var _material: ShaderMaterial
var _reveal_tween: Tween


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter("accent", accent)
	material = _material
	resized.connect(_on_resized)
	visibility_changed.connect(_on_visibility_changed)
	_on_resized()


func play_reveal() -> void:
	if _reveal_tween:
		_reveal_tween.kill()
	modulate.a = 0.0
	_reveal_tween = create_tween().set_parallel()
	_reveal_tween.tween_method(_set_reveal, 0.0, 1.1, REVEAL_TIME)
	_reveal_tween.tween_property(self, "modulate:a", 1.0, REVEAL_TIME * 0.8)


func _set_reveal(value: float) -> void:
	_material.set_shader_parameter("reveal", value)


func _on_resized() -> void:
	_material.set_shader_parameter("rect_size", size)


func _on_visibility_changed() -> void:
	if reveal_on_show and is_visible_in_tree():
		play_reveal()
