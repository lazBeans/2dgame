@abstract
extends Panel
class_name DetectiveCardBase

var card_identifier: String = ""
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

# ==========================================
# ABSTRACTION
# ==========================================

@abstract func setup_card_visual() -> void

func setup(id: String) -> void:
	card_identifier = id
	setup_card_visual()

# ==========================================
# INPUT & DRAGGING BEHAVIOR
# ==========================================

## Handles mouse button input events to toggle dragging state, notify DragManager, and bring the card to the foreground.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_dragging()
		else:
			stop_dragging()

## Updates the card's global position smoothly while it is being dragged by the mouse.
func _input(event: InputEvent) -> void:
	if is_dragging and event is InputEventMouseMotion:
		global_position = get_global_mouse_position() - drag_offset
		
## Initiates the dragging sequence for this card.
func start_dragging() -> void:
	is_dragging = true
	drag_offset = get_local_mouse_position()
	if DragManager:
		DragManager.start_drag(self)
		
	# Force current moving card to sit on top of its siblings while being dragged
	var parent_node = get_parent()
	if parent_node:
		parent_node.move_child(self, parent_node.get_child_count() - 1)

## Ends the dragging sequence for this card.
func stop_dragging() -> void:
	is_dragging = false
	if DragManager:
		DragManager.end_drag(true)
