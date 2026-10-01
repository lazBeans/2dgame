## Script Purpose: Manages an individual event segment in the deduction scene, 
## handling drag-and-drop movement, and dynamic label loading.
extends Panel
class_name EventSegment

signal event_segments

var evidence_identifier: String = "":
	set(value):
		evidence_identifier = value
		_update_card_display()

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

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
func _update_card_display() -> void:
	if evidence_identifier.is_empty():
		return
	var resource_path = "res://resources/evidence/" + evidence_identifier + ".tres"
	var evidence_data = load(resource_path) as EvidenceData
	
	if evidence_data and label:
		label.text = evidence_data.evidence_name
		
## Sets up the card with a given evidence ID, loading both its image texture and title.
func setup(id: String) -> void:
	evidence_identifier = id
	var resource_path = "res://resources/evidence/" + evidence_identifier + ".tres"
	var evidence_data = load(resource_path) as EvidenceData
	
	if evidence_data:
		if label:
			label.text = evidence_data.evidence_name
	else:
		push_error("EvidenceCard: Failed to load EvidenceData resource at path: " + resource_path)

## Handles mouse button input events to toggle dragging state and bring the card to the foreground.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_offset = get_local_mouse_position()
			
			var parent_node = get_parent()
			if parent_node:
				parent_node.move_child(self, parent_node.get_child_count() - 1)
		else:
			is_dragging = false

## Updates the card's global position smoothly while it is being dragged by the mouse.
func _input(event: InputEvent) -> void:
	if is_dragging and event is InputEventMouseMotion:
		global_position = get_global_mouse_position() - drag_offset
