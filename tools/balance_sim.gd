extends SceneTree

## Simulace hry s „robotickým hráčem“, který koupí cokoli z obchodu, jakmile na to má
## (v pořadí, v jakém jsou tlačítka v HUD). Když hraje s ekonomikou galaxínu, nechá výchozí
## cenu i dodavatele a objedná cisternu, když zásobník klesne pod polovinu.
## Vypíše časovou osu a časy splnění misí.
##
## Spuštění: godot --headless --path . --fixed-fps 60 -s res://tools/balance_sim.gd -- [mise] [all]
##   mise  číslo mise, od které začít (výchozí 1, použije se její startovní stav)
##   all   po splnění mise pokračuje dalšími až do konce (jinak skončí po první splněné)
##
## Skript schválně nepoužívá typy ze hry (Campaign, Android…): v režimu -s se kompiluje
## dřív, než existují autoloady, a herní skripty odkazující na `Game` by nešly zkompilovat.

const WORLD_SCENE := "res://game/world.tscn"
const MAX_SECONDS := 30 * 60
const REPORT_EVERY := 30.0

var _game: Node
var _world: Node
var _all := false
var _done := false
var _total := 0.0
var _next_report := REPORT_EVERY


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var start := int(args[0]) if args.size() > 0 else 1
	_all = args.has("all")
	_game = root.get_node_or_null("Game")
	var scene: PackedScene = load(WORLD_SCENE)
	if _game == null or scene == null:
		push_error("Simulaci nejde spustit: chybí autoload Game nebo scéna %s" % WORLD_SCENE)
		quit(1)
		return
	_game.start_mission = start - 1
	_world = scene.instantiate()
	root.add_child(_world)
	_world.mission_started.connect(_on_mission_started)
	_world.mission_completed.connect(_on_mission_completed)
	print("Simulace od mise %d%s" % [start, " přes všechny mise" if _all else ""])


func _process(delta: float) -> bool:
	if _world == null or _done:
		return true
	if paused:
		# Okno mise (úvod nebo shrnutí): robot pokračuje.
		_world.continue_game()
		if _world.mission == null:
			_log("všechny mise splněny")
			return true
		return false
	_total += delta
	# Nejdřív galaxín (bez něj nejsou tržby), pak teprve nákupy.
	var station = _world.station
	if station.galaxin_economy and station.tank.amount < station.tank.capacity() / 2.0:
		var cost: int = station.supply.order_cost()
		if station.supply.order():
			_log("objednána cisterna (-%s kr)" % _game.format_number(cost))
	for item in _world.get_shop_items():
		var cost: int = item.cost.call()
		if cost < 0 or _game.credits < cost:
			continue
		var label: String = item.label.call()
		if item.buy.call():
			_log("%s (-%s kr)" % [label, _game.format_number(cost)])
	if _total >= _next_report:
		_next_report += REPORT_EVERY
		_log("kredity %s, obslouženo %d, odletělo %d" % [
			_game.format_number(_game.credits), _game.ships_served, _game.ships_lost])
	if _total > MAX_SECONDS:
		_log("simulace ukončena po %d minutách" % (MAX_SECONDS / 60))
		return true
	return false


func _on_mission_started(number: int) -> void:
	_log("--- mise %d: %s" % [number, _world.mission.title])


func _on_mission_completed(number: int) -> void:
	var seconds := int(_world.mission_elapsed)
	_log("MISE %d SPLNĚNA za %d:%02d (kredity %s, obslouženo %d, odletělo %d)" % [
		number, seconds / 60, seconds % 60, _game.format_number(_game.credits),
		_game.ships_served, _game.ships_lost])
	if not _all:
		_done = true


func _log(message: String) -> void:
	var seconds := int(_total)
	print("%2d:%02d  %s" % [seconds / 60, seconds % 60, message])
