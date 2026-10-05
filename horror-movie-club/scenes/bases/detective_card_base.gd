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

## Updates the card's global position smoothly while being dragged, keeping it inside container bounds.
func _input(event: InputEvent) -> void:
	if is_dragging and event is InputEventMouseMotion:
		var target_pos = get_global_mouse_position() - drag_offset
		
		# Get the parent board / margin container reference
		var container = get_parent()
		if container and container is Control:
			var container_rect = container.get_global_rect()
			
			# Clamp target position to container edges minus card dimensions
			target_pos.x = clamp(target_pos.x, container_rect.position.x, container_rect.position.x + container_rect.size.x - size.x)
			target_pos.y = clamp(target_pos.y, container_rect.position.y, container_rect.position.y + container_rect.size.y - size.y)
		
		global_position = target_pos
		
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
	_check_drop_on_slot()

func _check_drop_on_slot() -> void:
	var mouse_pos = get_global_mouse_position()
	var slots = get_tree().get_nodes_in_group("ordered_slots")

	for slot in slots:
		if slot is Control and slot.is_visible_in_tree():
			# Check exact global rectangle of this specific spawned slot
			if slot.get_global_rect().has_point(mouse_pos):
				if slot.has_method("_can_drop_data") and slot._can_drop_data(Vector2.ZERO, self):
					slot._drop_data(Vector2.ZERO, self)
					return
