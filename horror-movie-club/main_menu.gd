extends Node2D



func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("game.tscn")


func _on_load_pressed() -> void:
	get_tree().change_scene_to_file("load.tscn")


func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://options.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
