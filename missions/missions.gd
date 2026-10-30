class_name Missions
extends RefCounted

## Mise v pořadí, ve kterém jdou za sebou. Novou misi přidej sem: objeví se v menu
## a hra na ni po splnění předchozí plynule naváže.

const WORLD_SCENE := "res://game/world.tscn"
const MENU_SCENE := "res://ui/main_menu.tscn"

const ALL := [
	preload("res://missions/mission_1.tres"),
	preload("res://missions/mission_2.tres"),
	preload("res://missions/mission_3.tres"),
]
