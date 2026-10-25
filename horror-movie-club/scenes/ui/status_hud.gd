extends Control
class_name MainHUD

@export var action_button_scene: PackedScene
var active_button: Node = null

var current_rm = RoomManager.current_room
var current_ch = GameManager.current_chapter

func _ready() -> void:
	VBoxContainer.visible = false

func _on_move_button_pressed() -> void:
	visible = false
	_populate_room_buttons(current_rm)
	
func _populate_room_buttons(current: String) -> void:
	
	var destinations = FileManager.rooms
	
	for room in destinations:
		pass
	
	VBoxContainer.visible = true
	
## Instantiates and attaches the deduction trigger button inside the slot.
func spawn_action_button(current_button: ButtonType) -> void:
	
	if not action_button_scene:
		action_button_scene = preload("res://scenes/components/ActionButton.tscn") as PackedScene
		
	if action_button_scene and (not active_button or not is_instance_valid(active_button)):
		clear_slot()
		active_button = action_button_scene.instantiate()
		add_child(active_button)

		if active_button is Control:
			active_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		var btn: BaseButton = null
		if active_button is BaseButton:
			btn = active_button
		elif active_button.has_node("ActionButton"):
			btn = active_button.get_node("ActionButton") as BaseButton
