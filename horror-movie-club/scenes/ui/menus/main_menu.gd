extends Node2D

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/core/Game.tscn")
	Dialogic.start("prologue")

func _on_load_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menus/Load.tscn")

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menus/Options.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
