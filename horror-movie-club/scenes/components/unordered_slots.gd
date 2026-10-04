extends DetectiveSlotBase
class_name UnorderedSlots

signal slot_filled(segment_id: String)

# ==========================================
# INITIALIZATION & CURSOR FIXES
# ==========================================

## Clears the tray slot on startup.
func _ready() -> void:
	clear_slot()
	
## Loads evidence resource data and populates the tray graphics (texture and label).
func setup_tray_item(id: String) -> void:
	super(id)
	var resource_path = "res://resources/segment/" + _card_id + ".tres"
	var evidence_data = load(resource_path) as SegmentData
	
	if evidence_data:
		if texture_rect:
			texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_rect.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
			texture_rect.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
			if evidence_data.texture:
				texture_rect.texture = evidence_data.texture 
		if label:
			label.text = evidence_data.evidence_name
			label.visible = true
		visible = true
		slot_filled.emit(_card_id)
	else:
		clear_slot()
