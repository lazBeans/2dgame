## PURPOSE: Interactive event segment card node extending Area2D DetectiveCardBase.
## Displays event visual graphics and title labels based on loaded segment data resources.
extends DetectiveCardBase
class_name EventSegment

# ==========================================
# PROPERTIES & NODE REFERENCES
# ==========================================

## Unique string identifier corresponding to the event resource file.
var segment_identifier: String = "":
	set(value):
		segment_identifier = value
		if is_node_ready():
			_update_segment_display()

@onready var background: NinePatchRect = $Background
@onready var label: Label = $Label

# ==========================================
# INITIALIZATION & DISPLAY
# ==========================================

func _ready() -> void:
	_update_segment_display()

## Configures the segment with a specific event ID.
func setup(id: String) -> void:
	segment_identifier = id
	if is_node_ready():
		_update_segment_display()

## Loads the corresponding event resource file and updates the visual elements.
func _update_segment_display() -> void:
	if segment_identifier.is_empty():
		return
	
	if FileManager.load_required_segments(GameManager.current_chapter):
		var options: Array = FileManager.load_required_segments(GameManager.current_chapter).get(segment_identifier)
		if options:
			for i in range(options.size()):
				# Ensure this path string matches your FileSystem directory exactly:
				var resource_path: String = "res://resources/segments/" + options[i] + ".tres"
				
				if ResourceLoader.exists(resource_path):
					var segment_data: Resource = load(resource_path)
					if segment_data:
						if background and "texture" in segment_data and segment_data.texture:
							background.texture = segment_data.texture
						if label and "description" in segment_data:
							label.text = segment_data.description
				else:
					push_error("EventSegment: Failed to load resource at: " + resource_path)
