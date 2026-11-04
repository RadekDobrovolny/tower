extends ColorRect

## Holografická koule nad holokinem (shader `fx/holo_sphere.gdshader`). Vyšší level = jasnější
## a rychlejší obraz, od levelu 5 kolem ní obíhají neonové prstence. Občas zazrní a problikne
## a světlo na palubě i paprsek z projektoru problikávají s ní.

## Za jak dlouho (s) přijde další výpadek a jak dlouho trvá.
const GLITCH_GAP_MIN := 2.5
const GLITCH_GAP_MAX := 7.0
const GLITCH_LENGTH_MIN := 0.12
const GLITCH_LENGTH_MAX := 0.4

var level := 1:
	set(value):
		level = value
		if is_node_ready():
			_show_rings()

var _time := 0.0
var _next_glitch := 3.0
var _glitch_left := 0.0

@onready var _light: PointLight2D = $Light
@onready var _beam: Polygon2D = $Beam
@onready var _holo: ShaderMaterial = material


func _ready() -> void:
	_show_rings()


func _process(delta: float) -> void:
	_time += delta * (0.8 + 0.2 * level)
	var glitch := _update_glitch(delta)
	_holo.set_shader_parameter("phase", _time)
	_holo.set_shader_parameter("brightness", 0.6 + 0.1 * level)
	_holo.set_shader_parameter("glitch", glitch)
	_light.energy = (0.8 + 0.15 * level) * (1.0 - 0.6 * glitch)
	_beam.modulate.a = 1.0 - 0.7 * glitch


## Prstence se nastaví hned se změnou levelu, aby byly vidět i při pozastavené hře.
func _show_rings() -> void:
	_holo.set_shader_parameter("rings", 2.0 if level >= 5 else 0.0)


## Síla výpadku v tomhle snímku (0 = žádný). Během výpadku náhodně kolísá, aby koule problikávala.
func _update_glitch(delta: float) -> float:
	if _glitch_left > 0.0:
		_glitch_left -= delta
		if _glitch_left <= 0.0:
			_next_glitch = randf_range(GLITCH_GAP_MIN, GLITCH_GAP_MAX)
			return 0.0
		return randf_range(0.5, 1.0)
	_next_glitch -= delta
	if _next_glitch <= 0.0:
		_glitch_left = randf_range(GLITCH_LENGTH_MIN, GLITCH_LENGTH_MAX)
		_holo.set_shader_parameter("seed", randf() * 100.0)
	return 0.0
