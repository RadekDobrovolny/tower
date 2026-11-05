class_name DeckSide
extends Node2D

## Bok paluby: pás pod hranami paluby, které míří dolů. Budovy jsou kreslené zepředu, takže
## je vidět jen přední bok a paluba působí jako plovoucí plošina. Stanice mu po každé změně
## obrysu (rozšíření, parkoviště) pošle nový zvlněný obrys (`build`), bok proto kopíruje
## zuby hrany. Kreslí se pod palubou, takže z něj zbude jen pruh pod spodní hranou.
## Plochy čelem ke světlu (vlevo dole) jsou světlejší. Bok je složený z plechů širokých jako
## deska paluby (PLATE_LENGTH) a jejich spáry leží přesně pod spárami desek. Textura (`texture`)
## má vedle sebe varianty plechu, shader station/deck_side.gdshader dá každému plechu
## náhodnou variantu a rozsvítí okénka. Na krajních spodních rozích blikají poziční světla:
## vlevo červené, vpravo zelené (záře z přičítaných spritů, ne skutečná světla).

const SHADER := preload("res://station/deck_side.gdshader")
const GLOW := preload("res://fx/soft_light.tres")
const ADDITIVE := preload("res://fx/additive.tres")
## Tloušťka boku (px). Pod hotovým parkovištěm zbývá do spodního okraje obrazovky jen 20 px.
const THICKNESS := 16.0
## Nasvícení plochy odvrácené od světla a plochy čelem ke světlu (vlevo dole).
const SHADE_MIN := 0.6
const SHADE_MAX := 1.15
const NAV_LEFT := Color(1.0, 0.22, 0.16)
const NAV_RIGHT := Color(0.3, 1.0, 0.5)
## Poziční světla svítí slabě a jednou za BLINK_PERIOD krátce bliknou, levé a pravé střídavě.
const NAV_DIM := 0.6
const BLINK_PERIOD := 1.6
const BLINK_TIME := 0.14
const NAV_GLOW_SIZE := 30.0
const NAV_CORE_SIZE := 7.0
## Jak daleko od kraje boku poziční světlo je (px).
const NAV_INSET := 4.0
## Šířka desky paluby (px): textura paluby (256 px) má 4 desky vedle sebe.
const PLATE_LENGTH := 64.0
## Bok mají jen kousky hrany, které míří dolů aspoň takhle (y vnější normály). Svislé hrany
## jsou zvlněné a jejich kousky občas míří nepatrně dolů, ty bok nemají.
const FACING_DOWN := 0.3

## Textura boku: varianty plechu (jedna deska) vedle sebe.
@export var texture: Texture2D
## Kolik variant je v textuře (nejvýš 8).
@export var variants := 1
## Okénko každé varianty: x, y středu (0–1 v plechu) a z = 1, když tam okénko je.
@export var portholes := PackedVector3Array()
## Poloměr skla okénka vůči výšce boku.
@export var glass_radius := 0.165
## Šířka skla vůči výšce (plechy jsou při zmenšení na šířku desky trochu zúžené).
@export var glass_aspect := 1.0

var _quads: Array[Dictionary] = []
var _nav: Array[Node2D] = []
var _time := 0.0


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var side := ShaderMaterial.new()
	side.shader = SHADER
	side.set_shader_parameter("thickness", THICKNESS)
	side.set_shader_parameter("variants", variants)
	side.set_shader_parameter("plate_length", PLATE_LENGTH)
	side.set_shader_parameter("portholes", portholes)
	side.set_shader_parameter("glass_radius", glass_radius)
	side.set_shader_parameter("glass_aspect", glass_aspect)
	material = side
	for color: Color in [NAV_LEFT, NAV_RIGHT]:
		var light := Node2D.new()
		light.light_mask = 0
		# Záře přesahuje přes hranu paluby, proto je nad ní.
		light.z_index = 1
		light.add_child(_glow(NAV_GLOW_SIZE, Color(color, 0.8)))
		light.add_child(_glow(NAV_CORE_SIZE, color.lightened(0.5)))
		light.visible = false
		add_child(light)
		_nav.append(light)


func _process(delta: float) -> void:
	_time = fmod(_time + delta, BLINK_PERIOD)
	for i in _nav.size():
		var phase := fmod(_time + BLINK_PERIOD * 0.5 * i, BLINK_PERIOD)
		_nav[i].modulate.a = 1.0 if phase < BLINK_TIME else NAV_DIM


## Postaví bok pod zvlněným obrysem paluby (body ve směru hodinových ručiček). Poziční
## světla dá na krajní spodní rohy obrysu před zvlněním (`corners`). `texture_offset` je
## posun textury paluby (Polygon2D.texture_offset.x), aby spáry plechů seděly pod deskami.
func build(outline: PackedVector2Array, corners: PackedVector2Array, texture_offset: float) -> void:
	_quads.clear()
	var count := outline.size()
	var outward: Array[Vector2] = []
	for i in count:
		outward.append(outline[i].direction_to(outline[(i + 1) % count]).rotated(-PI / 2.0))
	var down := Vector2(0.0, THICKNESS)
	for i in count:
		var a := outline[i]
		var b := outline[(i + 1) % count]
		if outward[i].y > FACING_DOWN:
			# Nasvícení ve vrcholech z průměru sousedních ploch, aby zvlněná hrana nebyla kostičkovaná.
			var shade_a := _shade(outward[(i - 1 + count) % count] + outward[i])
			var shade_b := _shade(outward[i] + outward[(i + 1) % count])
			_quads.append({
				"points": PackedVector2Array([a, b, b + down, a + down]),
				"colors": PackedColorArray([shade_a, shade_b, shade_b, shade_a]),
				# Textura jde podle x jako textura paluby, ne podél hrany.
				"uvs": PackedVector2Array([Vector2(a.x + texture_offset, 0), Vector2(b.x + texture_offset, 0),
						Vector2(b.x + texture_offset, 1), Vector2(a.x + texture_offset, 1)]),
			})
	_place_nav_lights(corners)
	queue_redraw()


## Poziční světla na nejlevější a nejpravější roh hrany, která míří dolů.
func _place_nav_lights(corners: PackedVector2Array) -> void:
	var left := Vector2(INF, 0.0)
	var right := Vector2(-INF, 0.0)
	for i in corners.size():
		var a := corners[i]
		var b := corners[(i + 1) % corners.size()]
		if a.direction_to(b).rotated(-PI / 2.0).y <= FACING_DOWN:
			continue
		for point: Vector2 in [a, b]:
			if point.x < left.x:
				left = point
			if point.x > right.x:
				right = point
	_nav[0].position = left + Vector2(NAV_INSET, THICKNESS * 0.55)
	_nav[1].position = right + Vector2(-NAV_INSET, THICKNESS * 0.55)
	for light in _nav:
		light.visible = left.x < INF


func _draw() -> void:
	for quad in _quads:
		draw_polygon(quad.points, quad.colors, quad.uvs, texture)


## Jak je plocha nasvícená podle směru, kterým míří (světlo jde zleva zdola).
static func _shade(normal: Vector2) -> Color:
	var toward_light := -DropShadow.DIRECTION.normalized()
	var lit := lerpf(SHADE_MIN, SHADE_MAX, clampf(normal.normalized().dot(toward_light), 0.0, 1.0))
	return Color(lit, lit, lit)


static func _glow(size: float, color: Color) -> Sprite2D:
	var glow := Sprite2D.new()
	glow.texture = GLOW
	glow.material = ADDITIVE
	glow.modulate = color
	glow.scale = Vector2.ONE * size / GLOW.get_width()
	return glow
