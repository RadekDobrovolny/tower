extends SceneTree

## Simulace levelu s „robotickým hráčem“, který vylepší androida, jakmile na to má.
## Vypíše časovou osu a čas splnění levelu.
##
## Spuštění (volitelně s cestou k jinému levelu za `--`):
##   godot --headless --path . --fixed-fps 60 -s res://tools/balance_sim.gd -- res://levels/level_1.tscn
##
## Skript schválně nepoužívá typy ze hry (Level, Android…): v režimu -s se kompiluje
## dřív, než existují autoloady, a herní skripty odkazující na `Game` by nešly zkompilovat.

const MAX_SECONDS := 15 * 60
const REPORT_EVERY := 30.0

var _game: Node
var _level: Node
var _done := false
var _next_report := REPORT_EVERY


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var path: String = args[0] if args.size() > 0 else "res://levels/level_1.tscn"
	_game = root.get_node_or_null("Game")
	var scene: PackedScene = load(path)
	if _game == null or scene == null:
		push_error("Simulaci nejde spustit: chybí autoload Game nebo level %s" % path)
		quit(1)
		return
	_level = scene.instantiate()
	root.add_child(_level)
	_level.completed.connect(func() -> void: _done = true)
	print("Simulace: %s" % path)


func _process(_delta: float) -> bool:
	if _level == null:
		return true
	for android in _level.station.get_androids():
		if android.is_max_level():
			continue
		var cost: int = android.upgrade_cost()
		if android.try_upgrade():
			_log("android -> L%d (-%s kr)" % [android.level, _game.format_number(cost)])
	if _level.elapsed >= _next_report:
		_next_report += REPORT_EVERY
		_log("kredity %s, obslouženo %d, odletělo %d" % [
			_game.format_number(_game.credits), _game.ships_served, _game.ships_lost])
	if _done:
		_log("LEVEL SPLNĚN (obslouženo %d, odletělo %d)" % [_game.ships_served, _game.ships_lost])
		return true
	if _level.elapsed > MAX_SECONDS:
		_log("level nesplněn ani po %d minutách" % (MAX_SECONDS / 60))
		return true
	return false


func _log(message: String) -> void:
	var seconds := int(_level.elapsed)
	print("%2d:%02d  %s" % [seconds / 60, seconds % 60, message])
