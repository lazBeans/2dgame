## PURPOSE: Acts as a centralized global drag-and-drop state machine.
## Tracks active drag payloads and coordinates valid drop interactions 
## between the tray and detective board.
extends Node

# ==========================================
# SIGNALS
# ==========================================
signal drag_started(item_data: Variant)
signal drag_ended(item_data: Variant, drop_successful: bool)

# ==========================================
# STATE VARIABLES
# ==========================================
var current_drag_data: Variant = null
var is_active_dragging: bool = false

# ==========================================
# DRAG CONTROL & STATE MANAGEMENT
# ==========================================

## Begins a drag operation, caching the payload.
func start_drag(item_data: Variant) -> void:
	current_drag_data = item_data
	is_active_dragging = true
	emit_signal("drag_started", item_data)

## Ends the current drag operation and registers success state.
func end_drag(drop_successful: bool) -> void:
	var item = current_drag_data
	current_drag_data = null
	is_active_dragging = false
	emit_signal("drag_ended", item, drop_successful)

## Returns true if an item is currently being dragged anywhere in the game.
func has_active_drag() -> bool:
	return is_active_dragging

## Returns the data payload of the item currently being dragged.
func get_drag_data() -> Variant:
	return current_drag_data
