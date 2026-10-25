extends Control
class_name MainHUD

var current_rm = RoomManager.current_room
var current_ch = GameManager.current_chapter

func _ready() -> void:
	VBoxContainer.visible = false

func _on_move_button_pressed() -> void:
	visible = false
	_populate_room_buttons(current_rm)
	
func _populate_room_buttons(current: String) -> void:
	
	
	
	VBoxContainer.visible = true
