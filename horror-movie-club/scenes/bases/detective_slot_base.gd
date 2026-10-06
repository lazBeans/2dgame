## PURPOSE: Abstract base class for interactive UI slots (TraySlot, DeductionSlot, etc.).
## Manages held item state, drag-and-drop validation, and preview rendering.
extends Control
class_name DetectiveSlotBase

# ==========================================
# SIGNALS
# ==========================================

## Emitted when an item is successfully placed into this slot.
signal slot_filled(item_id: String)

## Emitted when the slot's contents are cleared.
signal slot_emptied

# ==========================================
# STATE & NODE REFERENCES
# ==========================================

## Identifier of the item currently occupying this slot.
var current_item_id: String = ""

@onready var texture_rect: TextureRect = get_node_or_null("TextureRect")
@onready var label: Label = get_node_or_null("Label")

# ==========================================
# STATE ACCESSORS & HELPERS
# ==========================================

## Returns true if the slot does not currently contain an item.
func is_empty() -> bool:
	return current_item_id.is_empty()

## Returns the unique ID string of the item held in the slot.
func get_item_id() -> String:
	return current_item_id

## Backward-compatibility alias returning the stored item ID string.
func get_evidence_id() -> String:
	return current_item_id

# ==========================================
# SLOT POPULATION & CLEARING
# ==========================================

## Sets the slot's current item identifier and emits the slot_filled signal.
func set_slot_item(id: String) -> void:
	current_item_id = id
	if not current_item_id.is_empty():
		slot_filled.emit(current_item_id)

## Backward-compatibility alias for setting slot items.
func set_evidence(id: String) -> void:
	set_slot_item(id)

## Resets the slot state and hides associated visual elements.
func clear_slot() -> void:
	current_item_id = ""
	if texture_rect:
		texture_rect.texture = null
	if label:
		label.text = ""
		label.visible = false
	slot_emptied.emit()

# ==========================================
# GODOT DRAG-AND-DROP OVERRIDES
# ==========================================

## Determines whether an incoming drag payload can be dropped into this slot.
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not is_empty():
		return false
	if data is DetectiveSlotBase or data is Panel:
		return true
	if typeof(data) == TYPE_OBJECT and ("evidence_identifier" in data or data.has_method("get_evidence_id") or data.has_method("get_item_id")):
		return true
	return false

## Accepts drag payload, extracts its identifier, populates this slot, and clears the origin slot.
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var item_id: String = ""
	
	if typeof(data) == TYPE_OBJECT:
		if "evidence_identifier" in data and not str(data.evidence_identifier).is_empty():
			item_id = str(data.evidence_identifier)
		elif data.has_method("get_item_id"):
			item_id = data.get_item_id()
		elif data.has_method("get_evidence_id"):
			item_id = data.get_evidence_id()
			
		if data is DetectiveSlotBase and data != self:
			data.clear_slot()

	if not item_id.is_empty():
		set_slot_item(item_id)

## Generates a visual drag preview control when dragging an item out of this slot.
func _get_drag_data(at_position: Vector2) -> Variant:
	if is_empty():
		return null

	var preview := TextureRect.new()
	if texture_rect and texture_rect.texture:
		preview.texture = texture_rect.texture
	
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	var scale_factor: float = 1.15
	var base_size: Vector2 = size if size != Vector2.ZERO else Vector2(100, 100)
	var target_size: Vector2 = base_size * scale_factor
	
	preview.custom_minimum_size = target_size
	preview.size = target_size
	preview.position = -at_position * scale_factor

	var drag_container := Control.new()
	drag_container.add_child(preview)
	set_drag_preview(drag_container)

	return self
