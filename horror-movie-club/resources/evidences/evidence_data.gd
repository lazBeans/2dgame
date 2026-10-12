# res://scripts/resources/EvidenceData.gd
extends Resource
class_name EvidenceData

## Unique string identifier matching the ID passed from Dialogic signals (e.g., "hoop_shape").
@export var id: String = ""

## The human-readable name of the evidence displayed in the inventory slots and cards.
@export var name: String = ""

@export var type: String = ""

## Detailed notes, clues, or description text associated with this piece of evidence.
@export_multiline var description: String = ""

## The visual icon or sprite texture representing the evidence item.
@export var texture: Texture2D = null
