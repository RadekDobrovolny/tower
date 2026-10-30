extends SceneTree

## Rozstříhá vygenerovaný arch (průhledné pozadí, několik objektů) na samostatné PNG.
## Objekty najde jako souvislé oblasti viditelných pixelů, drobné oddělené kousky (jiskry,
## odlesky) připojí k nejbližšímu objektu. Výstupy pojmenuje podle pozice v mřížce
## (zleva doprava, shora dolů), ořízne je a zmenší, aby delší strana měla nejvýš `max_size` px.
##
## Spuštění:
##   godot --headless --path . -s res://tools/slice_sheet.gd -- arch.png počet max_size cíl1.png cíl2.png ...

const ALPHA_THRESHOLD := 0.1
## Jak daleko (px) smí být drobný kousek od objektu, aby se k němu připojil.
const MERGE_DISTANCE := 60
const PADDING := 6


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var sheet := Image.load_from_file(args[0])
	var count := int(args[1])
	var max_size := int(args[2])
	var targets := args.slice(3)
	var w := sheet.get_width()
	var h := sheet.get_height()

	# Označí souvislé oblasti viditelných pixelů (4-okolí).
	var labels := PackedInt32Array()
	labels.resize(w * h)
	labels.fill(-1)
	var regions: Array[Dictionary] = []
	for start in w * h:
		if labels[start] != -1 or sheet.get_pixel(start % w, start / w).a <= ALPHA_THRESHOLD:
			continue
		var region := {"id": regions.size(), "count": 0, "rect": Rect2i(start % w, start / w, 1, 1), "ids": [regions.size()]}
		var stack := PackedInt32Array([start])
		labels[start] = region.id
		while not stack.is_empty():
			var i := stack[stack.size() - 1]
			stack.resize(stack.size() - 1)
			var x := i % w
			var y := i / w
			region.count += 1
			region.rect = region.rect.expand(Vector2i(x, y))
			for n in [i - 1, i + 1, i - w, i + w]:
				if n < 0 or n >= w * h or labels[n] != -1:
					continue
				if (n == i - 1 and x == 0) or (n == i + 1 and x == w - 1):
					continue
				if sheet.get_pixel(n % w, n / w).a > ALPHA_THRESHOLD:
					labels[n] = region.id
					stack.append(n)
		regions.append(region)

	# Největší oblasti jsou objekty, drobné kousky se připojí k nejbližšímu z nich.
	regions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.count > b.count)
	var objects := regions.slice(0, count)
	for small in regions.slice(count):
		var best: Dictionary = {}
		var best_distance := MERGE_DISTANCE + 1.0
		for obj in objects:
			var distance := _rect_distance(obj.rect, small.rect)
			if distance < best_distance:
				best_distance = distance
				best = obj
		if not best.is_empty():
			best.rect = best.rect.merge(small.rect)
			best.ids.append(small.id)

	# Pořadí jako v mřížce: po řádcích shora dolů, v řádku zleva doprava.
	var row_height := h / 2.0
	objects.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var row_a := int(a.rect.get_center().y / row_height)
		var row_b := int(b.rect.get_center().y / row_height)
		return row_a < row_b if row_a != row_b else a.rect.get_center().x < b.rect.get_center().x)

	for i in objects.size():
		var obj: Dictionary = objects[i]
		var obj_rect: Rect2i = obj.rect
		var rect := obj_rect.grow(PADDING).intersection(Rect2i(Vector2i.ZERO, sheet.get_size()))
		var piece := Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
		for y in rect.size.y:
			for x in rect.size.x:
				var sx := rect.position.x + x
				var sy := rect.position.y + y
				# Pixely jiných objektů, které by se do obdélníku dostaly, se vynechají.
				var label := labels[sy * w + sx]
				if label == -1 or obj.ids.has(label):
					piece.set_pixel(x, y, sheet.get_pixel(sx, sy))
		var scale := minf(1.0, float(max_size) / maxi(piece.get_width(), piece.get_height()))
		if scale < 1.0:
			piece.resize(roundi(piece.get_width() * scale), roundi(piece.get_height() * scale), Image.INTERPOLATE_LANCZOS)
		piece.save_png(targets[i])
		print("%s: %s -> %dx%d" % [targets[i], rect, piece.get_width(), piece.get_height()])
	quit()


func _rect_distance(a: Rect2i, b: Rect2i) -> float:
	var dx := maxi(0, maxi(a.position.x - b.end.x, b.position.x - a.end.x))
	var dy := maxi(0, maxi(a.position.y - b.end.y, b.position.y - a.end.y))
	return Vector2(dx, dy).length()
