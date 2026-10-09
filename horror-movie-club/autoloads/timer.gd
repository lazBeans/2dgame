extends Node

var timer: Timer

func _ready():
	
	timer = Timer.new()
	timer.wait_time = 2.0
	timer.timeout.connect(_on_button_pressed)
	
	add_child(timer)
	timer.start()
	
func _on_button_pressed() -> void:
	timer.stop()
