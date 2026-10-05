## Script Purpose: Manages main menu button interactions for starting a new game, opening submenus, or quitting the application.
extends Node2D

## Triggered when the start button is pressed; starts the core game scene and prologue.
func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/core/Game.tscn")
	Dialogic.start("prologue")

## Triggered when the load button is pressed; opens the load game menu.
func _on_load_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu/Load.tscn")

## Triggered when the options button is pressed; opens the game options menu.
func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu/Options.tscn")

## Triggered when the quit button is pressed; exits the application.
func _on_quit_pressed() -> void:
	get_tree().quit()
