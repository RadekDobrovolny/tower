class_name DefenseTower
extends Building

## Obranná věž s laserovým kanónem. Stojí na místě pro věž na kraji paluby, sama hledá
## nejbližšího piráta v dosahu, natočí kanón a střílí. Vylepšení zvyšují poškození,
## rychlost střelby a dosah, na levelu 3 dostane dvojitou hlaveň.

## Části stavby: název, cena (dohromady 6 000 kr) a doba stavby (s).
const PHASES := [
	{"name": "Základna", "cost": 1500, "duration": 4.0},
	{"name": "Věž", "cost": 1500, "duration": 4.0},
	{"name": "Laserový kanón", "cost": 2000, "duration": 5.0},
	{"name": "Napájení", "cost": 1000, "duration": 3.0},
]
## Pro každý level: cena a doba vylepšení, poškození jednoho výstřelu, prodleva mezi
## výstřely (s), dosah (px) a počet hlavní. Level 1 je samotná stavba.
const LEVELS := [
	{"cost": 0, "time": 0.0, "damage": 1, "interval": 0.9, "range": 520.0, "barrels": 1},
	{"cost": 4000, "time": 8.0, "damage": 2, "interval": 0.75, "range": 620.0, "barrels": 1},
	{"cost": 7000, "time": 10.0, "damage": 2, "interval": 0.45, "range": 720.0, "barrels": 2},
]
const TURN_SPEED := 7.0
## O kolik (rad) smí kanón mířit vedle, aby už vystřelil.
const AIM_TOLERANCE := 0.12
const BOLT_LENGTH := 76.0
const SINGLE_TEXTURE := preload("res://assets/sprites/defense/turret.png")
const TWIN_TEXTURE := preload("res://assets/sprites/defense/turret_twin.png")
## Kde je osa otáčení a ústí hlavní v textuře kanónu (px textury vůči jejímu středu).
const SINGLE_PIVOT := Vector2(-24, 0)
const SINGLE_MUZZLES: Array[Vector2] = [Vector2(60, 0)]
const TWIN_PIVOT := Vector2(-21, 4)
const TWIN_MUZZLES: Array[Vector2] = [Vector2(60, -17), Vector2(60, 19)]
const SHELL_MODULATE := Color(0.35, 0.35, 0.37)

## Level 0 znamená, že věž ještě nefunguje (není dostavěná).
var level := 0
var kills := 0

var _cooldown := 0.0
var _barrel := 0
var _show_range := false

@onready var _base: Sprite2D = $Base
@onready var _pedestal: Sprite2D = $Pedestal
@onready var _turret: Sprite2D = $Turret
@onready var _range_ring: RangeRing = $RangeRing
@onready var _label: Label = $Label


func _process(delta: float) -> void:
	super(delta)
	if level == 0:
		return
	_cooldown -= delta
	var target := _find_target()
	if target == null:
		return
	var aim := (target.global_position - _turret.global_position).angle()
	_turret.global_rotation = lerp_angle(_turret.global_rotation, aim, minf(TURN_SPEED * delta, 1.0))
	if _cooldown <= 0.0 and absf(angle_difference(_turret.global_rotation, aim)) < AIM_TOLERANCE:
		_fire(target)


func build_phases() -> Array:
	return PHASES


func display_name() -> String:
	return "Obranná věž"


## Zapne věž po dostavění (level 1).
func power_on() -> void:
	level = maxi(level, 1)
	_update_construction_looks()


## Postaví věž hned a nastaví level (startovní stav mise).
func set_level(value: int) -> void:
	finish_instantly()
	level = clampi(value, 1, LEVELS.size())
	_update_construction_looks()


func stats() -> Dictionary:
	return LEVELS[maxi(level, 1) - 1]


func next_upgrade_cost() -> int:
	if level == 0 or job != null or level >= LEVELS.size():
		return -1
	return LEVELS[level].cost


func start_upgrade() -> bool:
	var cost := next_upgrade_cost()
	if cost < 0 or not Game.spend_credits(cost):
		return false
	var target_level := level + 1
	station.queue_job(self, "Vylepšení na level %d" % target_level,
			[{"name": "Výměna kanónu", "duration": LEVELS[target_level - 1].time}], Callable(), _finish_upgrade)
	return true


func info_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	if level == 0:
		lines.append(construction_line())
		lines.append("Až bude hotová, sama sestřeluje piráty v dosahu. Dokud nějaká věž stojí, Pumpík nemusí bojovat.")
		return lines
	var current := stats()
	lines.append("Level %d" % level)
	lines.append("Poškození: %d za výstřel, %s" % [current.damage, "dvojitá hlaveň" if current.barrels > 1 else "jedna hlaveň"])
	lines.append("Střelba: každých %.2f s" % current.interval)
	lines.append("Dosah: %d px" % roundi(current.range))
	lines.append("Sestřelených pirátů: %d" % kills)
	if job:
		lines.append(job_line())
	return lines


func info_actions() -> Array[ShopItem]:
	if not is_operational():
		return super()
	var actions: Array[ShopItem] = [
		ShopItem.new(func() -> String: return "Vylepšit kanón na level %d" % (level + 1),
				next_upgrade_cost, start_upgrade, ShopItem.Kind.UPGRADE),
	]
	return actions


## Nejbližší pirát v dosahu, na kterého jde střílet, nebo null.
func _find_target() -> Node2D:
	var best: Node2D = null
	var best_distance: float = stats().range
	for pirate in get_tree().get_nodes_in_group("pirates"):
		if not pirate.is_targetable():
			continue
		var distance := global_position.distance_to(pirate.global_position)
		if distance < best_distance:
			best = pirate
			best_distance = distance
	return best


func _fire(target: Node2D) -> void:
	var current := stats()
	_cooldown = current.interval
	var muzzles := TWIN_MUZZLES if current.barrels > 1 else SINGLE_MUZZLES
	_barrel = (_barrel + 1) % muzzles.size()
	var muzzle := _turret.to_global(muzzles[_barrel] + _turret.offset)
	LaserBolt.fire(station, muzzle, target, LaserBolt.GOLD, _on_bolt_hit.bind(target, current.damage), BOLT_LENGTH)


## Ukáže okruh dostřelu, dokud je věž vybraná. Nedostavěná věž ho ukáže, až bude hotová.
func set_range_visible(value: bool) -> void:
	_show_range = value
	_update_range_ring()


func _update_range_ring() -> void:
	_range_ring.visible = _show_range and level > 0
	if level > 0:
		_range_ring.radius = stats().range


func _on_bolt_hit(target: Node2D, damage: int) -> void:
	if target.hit(damage):
		kills += 1


func sale_items() -> Array[ShopItem]:
	if level <= 1:
		return []
	return [ShopItem.sale("Obranná věž, level %d" % level, LEVELS[level - 1].cost, set_level.bind(level - 1))]


func _finish_upgrade() -> void:
	level += 1
	_update_construction_looks()


func _update_construction_looks() -> void:
	super()
	_update_range_ring()
	# Části stavby: staveniště -> podstavec -> tmavý kanón -> zapojená věž.
	_base.visible = built_phases == 1
	_pedestal.visible = built_phases >= 2
	_turret.visible = built_phases >= 3
	_turret.modulate = SHELL_MODULATE if built_phases == 3 else Color.WHITE
	var twin: bool = stats().barrels > 1
	_turret.texture = TWIN_TEXTURE if twin else SINGLE_TEXTURE
	_turret.offset = -(TWIN_PIVOT if twin else SINGLE_PIVOT)
	_label.visible = built_phases >= 1
	_label.text = "Věž · L%d" % level if level > 0 else "Věž"
