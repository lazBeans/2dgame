## PURPOSE: Acts as a centralized global drag-and-drop state machine.
## Tracks active drag payloads and coordinates valid drop interactions 
## between the tray and detective board.
extends Node

# ==========================================
# SIGNALS
# ==========================================

## Emitted when a global drag operation starts.
signal drag_started(item_data: Variant)

## Emitted when a global drag operation finishes with success status.
signal drag_ended(item_data: Variant, drop_successful: bool)

# ==========================================
# STATE VARIABLES
# ==========================================

## Cached data payload of the item currently being dragged.
var current_drag_data: Variant = null

## Flag indicating whether a drag operation is currently active.
var is_active_dragging: bool = false

# ==========================================
# DRAG CONTROL & STATE MANAGEMENT
# ==========================================

## Begins a drag operation, caching the payload and emitting drag_started.
func start_drag(item_data: Variant) -> void:
	current_drag_data = item_data
	is_active_dragging = true
	drag_started.emit(item_data)

## Ends the current drag operation, clears state, and emits drag_ended.
func end_drag(drop_successful: bool) -> void:
	var item: Variant = current_drag_data
	current_drag_data = null
	is_active_dragging = false
	drag_ended.emit(item, drop_successful)

## Returns true if an item is currently being dragged anywhere in the game.
func has_active_drag() -> bool:
	return is_active_dragging

## Returns the data payload of the item currently being dragged.
func get_drag_data() -> Variant:
	return current_drag_data
