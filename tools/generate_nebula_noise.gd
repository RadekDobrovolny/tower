extends SceneTree

## Vygeneruje opakovatelnou šumovou texturu pro mlhoviny ve vesmíru (space/nebula.gdshader).
## Kanály: R velká oblaka, G druhý šum na zvlnění tvarů a barvu, B jemná vlákna.
## Spuštění: godot --headless --path . -s res://tools/generate_nebula_noise.gd
## Po změně spusť --import.

const SIZE := 512
const OUTPUT := "res://assets/sprites/space/nebula_noise.png"


func _init() -> void:
	var clouds := _noise(11, 0.006, FastNoiseLite.FRACTAL_FBM, 5)
	var warp := _noise(23, 0.009, FastNoiseLite.FRACTAL_FBM, 4)
	var wisps := _noise(37, 0.018, FastNoiseLite.FRACTAL_RIDGED, 4)
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			image.set_pixel(x, y, Color(clouds.get_pixel(x, y).r, warp.get_pixel(x, y).r,
					wisps.get_pixel(x, y).r))
	var error := image.save_png(OUTPUT)
	print("%s: %s" % [OUTPUT, error_string(error)])
	quit()


func _noise(noise_seed: int, frequency: float, fractal: int, octaves: int) -> Image:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = noise_seed
	noise.frequency = frequency
	noise.fractal_type = fractal
	noise.fractal_octaves = octaves
	return noise.get_seamless_image(SIZE, SIZE, false, false, 0.15, true)
