## PURPOSE: Manages an individual event segment in the deduction scene, 
## handling dynamic segment resource loading and chapter sequence validation.
extends DetectiveCardBase
class_name EventSegment

# ==========================================
# STATE VARIABLES & SETTERS
# ==========================================
var segment_identifier: String = "":
	set(value):
		segment_identifier = value
		_update_segment_display()

# ==========================================
# DISPLAY & SETUP
# ==========================================

## Updates the card's text label based on the current segment identifier resource.
func _update_segment_display() -> void:
	if segment_identifier.is_empty():
		return
		
	var resource_path = "res://resources/segments/" + segment_identifier + ".tres"
	var segment_data = load(resource_path) as SegmentData
	
	if segment_data and has_node("EventDescription"):
		$EventDescription.text = segment_data.description

## Implements the abstract base method. Syncs card_identifier to segment_identifier 
## and loads the correct segment resource data from the segment directory.
func setup_card_visual() -> void:
	segment_identifier = card_identifier
	
	var resource_path = "res://resources/segments/" + card_identifier + ".tres"
	var segment_data = load(resource_path) as SegmentData
	
	if segment_data:
		if has_node("EventDescription"):
			$EventDescription.text = segment_data.description
		if has_node("TextureRect") and segment_data.texture:
			$TextureRect.texture = segment_data.texture
	else:
		push_error("EventSegment: Failed to load SegmentData resource at path: " + resource_path)

# ==========================================
# PUZZLE & VALIDATION LOGIC
# ==========================================

## Validates if the given sequence matches the required chapter segments.
func in_valid_order(segments: Array) -> bool:
	var master_array = FileManager.load_required_segments(GameManager.current_chapter)
	
	if master_array == segments:
		Dialogic.start("qilin_hunt")
		return true
	
	return false
