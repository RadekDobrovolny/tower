class_name Hud
extends CanvasLayer

## Herní HUD: kredity, cíle levelu, vylepšení androida a obrazovka vítězství.

const DONE_COLOR := Color(0.45, 0.95, 0.5)

var _level: Level
var _android: Android

@onready var _credits_label: Label = $CreditsLabel
@onready var _stats_label: Label = $StatsLabel
@onready var _credits_goal: Label = %CreditsGoal
@onready var _android_goal: Label = %AndroidGoal
@onready var _upgrade_button: Button = $UpgradeButton
@onready var _victory_overlay: Control = $VictoryOverlay
@onready var _summary: Label = %Summary
@onready var _restart_button: Button = %RestartButton


func setup(level: Level) -> void:
	_level = level
	_android = level.station.get_androids()[0]
	Game.credits_changed.connect(_refresh.unbind(1))
	Game.stats_changed.connect(_refresh)
	_android.upgraded.connect(_refresh.unbind(1))
	_upgrade_button.pressed.connect(_android.try_upgrade)
	_restart_button.pressed.connect(_on_restart_pressed)
	level.completed.connect(_show_victory)
	_refresh()


func _refresh() -> void:
	_credits_label.text = "Kredity: %s kr" % Game.format_number(Game.credits)
	_stats_label.text = "Obslouženo: %d · Odletělo bez placení: %d" % [Game.ships_served, Game.ships_lost]

	_credits_goal.text = "Naspořit %s kr: %s / %s" % [
		Game.format_number(_level.goal_credits),
		Game.format_number(mini(Game.credits, _level.goal_credits)),
		Game.format_number(_level.goal_credits),
	]
	_credits_goal.modulate = DONE_COLOR if _level.is_credits_goal_met() else Color.WHITE

	_android_goal.text = "%s na levelu %d: %d / %d" % [
		_android.display_name, _level.goal_android_level, _level.best_android_level(),
		_level.goal_android_level,
	]
	_android_goal.modulate = DONE_COLOR if _level.is_android_goal_met() else Color.WHITE

	if _android.is_max_level():
		_upgrade_button.text = "%s je na maximálním levelu" % _android.display_name
		_upgrade_button.disabled = true
	else:
		_upgrade_button.text = "%s: vylepšit na level %d (%s kr)" % [
			_android.display_name, _android.level + 1, Game.format_number(_android.upgrade_cost()),
		]
		_upgrade_button.disabled = Game.credits < _android.upgrade_cost()


func _show_victory() -> void:
	var seconds := int(_level.elapsed)
	_summary.text = "Čas: %d:%02d\nObslouženo lodí: %d\nOdletělo bez placení: %d" % [
		seconds / 60, seconds % 60, Game.ships_served, Game.ships_lost,
	]
	_victory_overlay.show()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
