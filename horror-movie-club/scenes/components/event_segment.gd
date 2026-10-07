## PURPOSE: Interactive event segment card node extending Area2D DetectiveCardBase.
## Displays event visual graphics and title labels based on loaded segment data resources.
extends Button
class_name EventSegment

# ==========================================
# PROPERTIES & NODE REFERENCES
# ==========================================

## Unique string identifier corresponding to the event resource file.
var segment_identifier: String = "":
	set(value):
		segment_identifier = value
		
@onready var background: TextureRect = $Background
@onready var label: Label = $Label

# ==========================================
# INITIALIZATION & DISPLAY
# ==========================================
## Configures the segment with a specific event ID.
func setup(id: String) -> void:
	segment_identifier = id
	if is_node_ready():
		_update_segment_display(segment_identifier)

## Loads the corresponding event resource file and updates the visual elements.
func _update_segment_display(path: String) -> void:
	if segment_identifier.is_empty():
		return
	
	print("Segment: ", segment_identifier)
	print("Spawning path: ", path)
	# Ensure this path string matches your FileSystem directory exactly:
	if ResourceLoader.exists(path):
		var segment_data: Resource = load(path)
		if segment_data:
			if background and "texture" in segment_data and segment_data.texture:
					background.texture = segment_data.texture
			if label and "description" in segment_data:
				label.text = segment_data.description
	else:
		push_error("Path Not Found")
