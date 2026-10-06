## PURPOSE: Controls main menu button interactions for starting games, loading scenes, and quitting.
extends Node2D

# ==========================================
# MENU BUTTON HANDLERS
# ==========================================

## Starts the core game scene and initiates the prologue dialogue timeline.
func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/core/Game.tscn")
	Dialogic.start("prologue")

## Opens the game load menu scene.
func _on_load_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu/Load.tscn")

## Opens the options menu scene.
func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu/Options.tscn")

## Quits and exits the application.
func _on_quit_pressed() -> void:
	get_tree().quit()
