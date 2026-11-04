class_name DropShadow
extends SpriteCopy

## Vržený stín spritu. Světlo přichází zleva zdola, takže stín padá doprava nahoru za objekt
## a budovy stojí pevně na palubě (stín pod nimi by vypadal, jako by levitovaly).
## Stín má tvar spritu (viz SpriteCopy), je ztmavený, má rozmazaný okraj a je posunutý
## o `height` pixelů. Směr posunu je ve světě stejný, i když se sprite otáčí nebo je zmenšený.
## Objektu zároveň přidá jemný odlesk světla na hraně ke světlu (RimLight), když `rim_light`.
##
## Běžně je stín dítětem spritu: kreslí se těsně pod ním (show_behind_parent), takže leží na
## tom, co je nakreslené před ním (paluba, plošina), a objekt sám nezakryje. Viditelnost
## a průhlednost má po rodiči. Lodě mají stín jako první dítě svého těla (`Body`) se `source`
## nastaveným na sprite, aby se kreslil i pod plamenem motoru.

## Kam stín padá: světlo je vlevo dole. Stejný směr (obráceně) mají odlesky RimLight
## a obrys trupů lodí (fx/hull_rim.gdshader).
const DIRECTION := Vector2(0.78, -0.62)
const SHADER := preload("res://fx/drop_shadow.gdshader")

## Jak vysoko nad palubou objekt je (px světa): o tolik se stín posune směrem DIRECTION.
@export var height := 8.5
## Kde je pod objektem zem (px světa), když je výška kreslená posunem nahoru (Bzučák visí
## nad budovou): stín se nejdřív posune sem a teprve pak o `height`.
@export var ground_offset := Vector2.ZERO
## Velikost stínu vůči spritu. Loď ve vzduchu je kreslená větší, stín zůstane velký jako na zemi.
@export var ground_scale := 1.0
## Síla stínu 0–1.
@export_range(0.0, 1.0) var opacity := 0.54:
	set(value):
		opacity = value
		if _material:
			_material.set_shader_parameter("opacity", opacity)
## Rozmazání okraje (px obrazovky).
@export var softness := 6.0:
	set(value):
		softness = value
		if _material:
			_material.set_shader_parameter("softness", softness)
		queue_redraw()
## Jestli sprite dostane i odlesk světla (RimLight). Lodě a piráti ho nemají, jejich trup má
## vlastní obrys ze stejné strany.
@export var rim_light := true

var _rim: RimLight


## Přidá stín spritu, který vzniká ve skriptu (ve scéně stačí přidat uzel se skriptem).
static func attach(sprite: Sprite2D, shadow_height: float) -> DropShadow:
	var shadow := DropShadow.new()
	shadow.height = shadow_height
	sprite.add_child(shadow)
	return shadow


func _ready() -> void:
	super()
	show_behind_parent = true
	_material.set_shader_parameter("opacity", opacity)
	_material.set_shader_parameter("softness", softness)
	if rim_light:
		_rim = RimLight.new()
		_rim.source = source
		# Rodič ve chvíli, kdy je stín připravený, ještě přidává děti.
		source.add_child.call_deferred(_rim)


func _notification(what: int) -> void:
	# Odlesk, který se do stromu nestihl přidat (objekt zmizel hned po vzniku), by jinak zůstal viset.
	if what == NOTIFICATION_PREDELETE and is_instance_valid(_rim) and not _rim.is_inside_tree():
		_rim.free()


func _shader() -> Shader:
	return SHADER


func _margin() -> float:
	return softness * 1.5


## Stín má tvar a natočení spritu, jen je ve světě posunutý a případně zmenšený.
func _follow_source() -> void:
	global_transform = source.global_transform.scaled_local(Vector2.ONE * ground_scale) \
			.translated(ground_offset + DIRECTION * height)
