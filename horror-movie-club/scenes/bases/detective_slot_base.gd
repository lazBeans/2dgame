@abstract
extends Panel
class_name DetectiveSlotBase

signal slot_emptied

@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label

var _card_id: String = ""

## Returns the ID of the evidence currently resting in the tray.
func get_card_id() -> String:
	return _card_id

## Clears stuck forbidden cursor artifacts if frame conditions change.
func _process(_delta: float) -> void:
	if Input.get_current_cursor_shape() == CURSOR_FORBIDDEN:
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)
		
# ==========================================
# DRAG-AND-DROP PAYLOAD HANDLING
# ==========================================

## Returns true if the tray slot is currently empty.
func is_empty() -> bool:
	return _card_id.is_empty()
	
## Generates a see-through visual preview matching the tray slot's exact size and registers the drag state.
func _get_drag_data(_at_position: Vector2) -> Variant:
	if is_empty():
		return null
		
	var preview = TextureRect.new()
	if texture_rect:
		preview.texture = texture_rect.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	# Match the exact dimensions of the original slot without distortion
	preview.size = size
	preview.position = -_at_position
	
	# Make the drag preview see-through
	preview.modulate.a = 0.6
	
	var drag_container = Control.new()
	drag_container.add_child(preview)
	set_drag_preview(drag_container)
	
	if DragManager:
		DragManager.start_drag(self)
		
	return self
	
## Resets the tray slot back to an empty, hidden state.
func clear_slot() -> void:
	_card_id = ""
	if texture_rect:
		texture_rect.texture = null
	if label:
		label.text = ""
		label.visible = false
	slot_emptied.emit()
	
func setup_tray_item(id: String) -> void:
	_card_id = id
	
	if _card_id.is_empty():
		clear_slot()
		return
