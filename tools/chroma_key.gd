extends SceneTree

## Odstraní čisté zelené pozadí (#00FF00) z obrázku a vrátí průhlednost i tenkým detailům, jako
## jsou vousy. Pro obrázky z generátorů, které neumí průhledné pozadí, např. z Codexu.
##
## Spuštění:
##   godot --headless --path . -s res://tools/chroma_key.gd -- vstup.png výstup.png

## Pod tímhle rozdílem zelené proti červené a modré je pixel celý popředí (olivové kabáty apod.),
## nad druhým je to celé pozadí. Generátor nikdy nevyrobí úplně čistou zelenou.
const KEEP_BELOW := 0.08
const REMOVE_ABOVE := 0.75


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var image := Image.load_from_file(args[0])
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			image.set_pixel(x, y, _unmix(image.get_pixel(x, y)))
	image.save_png(args[1])
	quit()


## Pixel je směs popředí a čisté zelené. Podle přebytku zelené určí průhlednost a zelenou odečte.
func _unmix(color: Color) -> Color:
	var excess := color.g - maxf(color.r, color.b)
	if excess <= KEEP_BELOW:
		return color
	if excess >= REMOVE_ABOVE:
		return Color(0, 0, 0, 0)
	var alpha := 1.0 - (excess - KEEP_BELOW) / (REMOVE_ABOVE - KEEP_BELOW)
	return Color(minf(color.r / alpha, 1.0), clampf((color.g - (1.0 - alpha)) / alpha, 0.0, 1.0), minf(color.b / alpha, 1.0), alpha)
