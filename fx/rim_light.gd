class_name RimLight
extends SpriteCopy

## Jemný odlesk světla na hraně spritu, která míří ke světlu (vlevo dole, opačně než padá
## stín DropShadow). Kreslí se přes sprite přičítáním. Přidává ho DropShadow (`rim_light`)
## budovám, Pumpíkovi, cisterně a Bzučákovi; rakety a piráti mají místo něj obrys trupu
## (fx/hull_rim.gdshader) ze stejné strany.

const SHADER := preload("res://fx/rim_light.gdshader")


func _ready() -> void:
	super()
	_material.set_shader_parameter("light_dir", -DropShadow.DIRECTION)


func _shader() -> Shader:
	return SHADER
