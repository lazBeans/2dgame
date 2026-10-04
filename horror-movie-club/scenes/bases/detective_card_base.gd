## PURPOSE: Abstract base class for all interactive board items (EvidenceCards, EventSegments).
## Manages shared polymorphic initialization, z-indexing, and global mouse-dragging mechanics.
@abstract
extends Panel
class_name DetectiveCardBase

var card_identifier: String = ""
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

# ==========================================
# POLYMORPHIC INITIALIZATION
# ==========================================

## Core setup method called externally. Caches the item ID and 
## delegates specific visual configuration to the extended subclass.
func setup(id: String) -> void:
	card_identifier = id
	setup_card_visual()

## Abstract method enforced in Godot 4.5+. Subclasses must implement 
## their own resource path loading and label/texture assignments here.
@abstract func setup_card_visual() -> void

# ==========================================
# INPUT & DRAGGING BEHAVIOR
# ==========================================

## Handles mouse button input events to toggle dragging state, notify DragManager, 
## and bring the active card to the foreground layer.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_dragging()
		else:
			stop_dragging()

## Updates the card's global canvas position smoothly while being dragged by the mouse cursor.
func _input(event: InputEvent) -> void:
	if is_dragging and event is InputEventMouseMotion:
		global_position = get_global_mouse_position() - drag_offset
		
## Initiates the dragging sequence, caching offsets and moving the node to the top of its parent.
func start_dragging() -> void:
	is_dragging = true
	drag_offset = get_local_mouse_position()
	if DragManager:
		DragManager.start_drag(self)
		
	var parent_node = get_parent()
	if parent_node:
		parent_node.move_child(self, parent_node.get_child_count() - 1)

## Concludes the dragging sequence and notifies the global DragManager.
func stop_dragging() -> void:
	is_dragging = false
	if DragManager:
		DragManager.end_drag(true)
