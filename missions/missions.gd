class_name Missions
extends RefCounted

## Mise v pořadí, ve kterém jdou za sebou. Novou misi přidej sem a její úvod do
## `Story.MISSION_INTROS`: objeví se v menu a hra na ni po splnění předchozí plynule naváže. Mise Z (volná hra se vším na maximu)
## stojí mimo pořadí, jde na ni jen z menu.

const WORLD_SCENE := "res://game/world.tscn"
const MENU_SCENE := "res://ui/main_menu.tscn"
## Hodnota `Game.start_mission` pro misi Z.
const FREE_PLAY_INDEX := -1
const FREE_PLAY := preload("res://missions/mission_z.tres")

const ALL := [
	preload("res://missions/mission_1.tres"),
	preload("res://missions/mission_2.tres"),
	preload("res://missions/mission_3.tres"),
	preload("res://missions/mission_4.tres"),
	preload("res://missions/mission_5.tres"),
	preload("res://missions/mission_6.tres"),
	preload("res://missions/mission_7.tres"),
	preload("res://missions/mission_8.tres"),
	preload("res://missions/mission_9.tres"),
]
