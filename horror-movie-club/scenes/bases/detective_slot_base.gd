## PURPOSE: Abstract base class for all interactive UI slots (TraySlot, DeductionSlot, etc.).
## Handles shared state, item holding, drag-and-drop detection, and slot updates.
extends Control
class_name DetectiveSlotBase

signal slot_filled(item_id: String)
signal slot_emptied

# ==========================================
# STATE VARIABLES & NODE REFERENCES
# ==========================================
var current_item_id: String = ""

@onready var texture_rect: TextureRect = get_node_or_null("TextureRect")
@onready var label: Label = get_node_or_null("Label")

# ==========================================
# GETTERS & HELPER METHODS
# ==========================================

## Returns true if the slot does not currently contain an item.
func is_empty() -> bool:
	return current_item_id.is_empty()

## Returns the ID of the item currently resting in the slot.
func get_item_id() -> String:
	return current_item_id

## Backward-compatibility alias for scripts calling get_evidence_id().
func get_evidence_id() -> String:
	return current_item_id

# ==========================================
# SLOT SETTERS & CLEARING
# ==========================================

## Base method to populate the slot. Subclasses override this for custom visual loading.
func set_slot_item(id: String) -> void:
	current_item_id = id
	if not current_item_id.is_empty():
		slot_filled.emit(current_item_id)

## Backward-compatibility alias for scripts calling set_evidence().
func set_evidence(id: String) -> void:
	set_slot_item(id)

## Clears the slot's current item and resets its visual elements.
func clear_slot() -> void:
	current_item_id = ""
	if texture_rect:
		texture_rect.texture = null
	if label:
		label.text = ""
		label.visible = false
	slot_emptied.emit()

# ==========================================
# DRAG-AND-DROP LOGIC
# ==========================================

## Determines whether this slot can accept an incoming dragged payload.
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not is_empty():
		return false
	if data is DetectiveSlotBase or data is Panel:
		return true
	if typeof(data) == TYPE_OBJECT and ("evidence_identifier" in data or data.has_method("get_evidence_id") or data.has_method("get_item_id")):
		return true
	return false

## Handles receiving a dropped item, extracting its ID, and populating this slot.
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var item_id: String = ""
	
	if typeof(data) == TYPE_OBJECT:
		if "evidence_identifier" in data and not str(data.evidence_identifier).is_empty():
			item_id = str(data.evidence_identifier)
		elif data.has_method("get_item_id"):
			item_id = data.get_item_id()
		elif data.has_method("get_evidence_id"):
			item_id = data.get_evidence_id()
			
		# If transferred from another slot, clear origin slot
		if data is DetectiveSlotBase and data != self:
			data.clear_slot()

	if not item_id.is_empty():
		set_slot_item(item_id)

## Generates drag data preview when pulling an item out of this slot.
func _get_drag_data(at_position: Vector2) -> Variant:
	if is_empty():
		return null

	var preview := TextureRect.new()
	if texture_rect and texture_rect.texture:
		preview.texture = texture_rect.texture
	
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	# 1. Define scale factor (1.15 = 15% larger, 1.2 = 20% larger)
	var scale_factor := 1.15
	
	# 2. Calculate the scaled target size
	var base_size := size if size != Vector2.ZERO else Vector2(100, 100)
	var target_size := base_size * scale_factor
	
	preview.custom_minimum_size = target_size
	preview.size = target_size
	
	# 3. Adjust position offset so the cursor anchor scales proportionally
	preview.position = -at_position * scale_factor

	var drag_container := Control.new()
	drag_container.add_child(preview)
	set_drag_preview(drag_container)

	return self
