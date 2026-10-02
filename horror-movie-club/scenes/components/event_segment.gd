## Script Purpose: Manages an individual event segment in the deduction scene, 
## handling drag-and-drop movement, and dynamic label loading.
extends DetectiveCardBase
class_name EventSegment

signal event_segments

var segment_identifier: String = "":
	set(value):
		segment_identifier = value
		_update_segment_display()

@onready var label: Label = $Label

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func in_valid_order(segments: Array) -> bool:
	var master_array = FileManager.load_required_segments(GameManager.current_chapter)
	
	if master_array == segments:
		Dialogic.start("qilin_hunt")
		return true
	
	return false
	
## Updates the card's text label based on the current evidence identifier resource.
func _update_segment_display() -> void:
	if segment_identifier.is_empty():
		return
	var resource_path = "res://resources/segment/" + segment_identifier + ".tres"
	var segment_data = load(resource_path) as SegmentData
	
	if segment_data and label:
		label.text = segment_data.evidence_name
		
## Sets up the card with a given evidence ID, loading both its image texture and title.
func setup_card_visual() -> void:
	var resource_path = "res://resources/evidence/" + card_identifier + ".tres"
	var segment_data = load(resource_path) as SegmentData
	
	if segment_data:
		if label:
			label.text = segment_data.evidence_name
	else:
		push_error("EvidenceCard: Failed to load EvidenceData resource at path: " + resource_path)

## Updates the card's global position smoothly while it is being dragged by the mouse.
func _input(event: InputEvent) -> void:
	if is_dragging and event is InputEventMouseMotion:
		global_position = get_global_mouse_position() - drag_offset
