# res://scripts/resources/Segment.gd
extends Resource
class_name SegmentData

## Unique string identifier matching the ID passed from Dialogic signals (e.g., "hoop_shape").
@export var id: String = ""

## Detailed notes, clues, or description text associated with this piece of evidence.
@export_multiline var description: String = ""

## The visual icon or sprite texture representing the evidence item.
@export var texture: Texture2D = null
