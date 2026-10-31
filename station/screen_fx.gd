extends ColorRect

## Film na plátně autokina (shader `fx/film_screen.gdshader`). Vyšší level = jasnější a rychlejší
## obraz. Plátno svítí do okolí a projektor na něj hází kužel v barvě, která v obraze převládá.

var level := 1

var _time := 0.0

@onready var _light: PointLight2D = $Light
@onready var _beam: Polygon2D = $Beam
@onready var _film: ShaderMaterial = material


func _process(delta: float) -> void:
	_time += delta * (0.8 + 0.2 * level)
	var color := Color.from_hsv(fmod(_time * 0.07 + 0.3, 1.0), 0.6, 1.0)
	_light.color = color
	_light.energy = 0.9 + 0.2 * level
	_beam.color = color
	_film.set_shader_parameter("phase", _time)
	_film.set_shader_parameter("brightness", 0.55 + 0.1 * level)
