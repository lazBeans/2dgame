## PURPOSE: Interactive evidence card node extending Area2D DetectiveCardBase.
## Handles evidence presentation, pin interaction triggers, and dragging state overrides.
extends DetectiveCardBase
class_name EvidenceCard

# ==========================================
# PROPERTIES & NODE REFERENCES
# ==========================================

## Unique identifier string referencing the evidence resource file.
var evidence_identifier: String = ""

@onready var background: NinePatchRect = $Background
@onready var label: Label = $Label
@onready var pin_button: TextureButton = $PinButton

# ==========================================
# INITIALIZATION & SETUP
# ==========================================

## Connects pin button signals on startup.
func _ready() -> void:
	super()
	if pin_button:
		pin_button.pressed.connect(_on_pin_pressed)

## Configures the card with an evidence ID and populates texture and label displays.
func setup(id: String) -> void:
	evidence_identifier = id
	if evidence_identifier.is_empty():
		return
	
	var resource_path: String = "res://resources/evidences/" + evidence_identifier + ".tres"
	if ResourceLoader.exists(resource_path):
		var evidence_data: Resource = load(resource_path)
		if evidence_data:
			if background and "texture" in evidence_data and evidence_data.texture:
				background.texture = evidence_data.texture
			if label and "evidence_name" in evidence_data:
				label.text = evidence_data.name

# ==========================================
# OVERRIDDEN DRAG BEHAVIOR
# ==========================================

## Hides the pin button while dragging the card.
func start_dragging() -> void:
	super()
	if pin_button:
		pin_button.visible = false

## Re-enables the pin button upon dropping the card.
func stop_dragging() -> void:
	super()
	if pin_button:
		pin_button.visible = true

# ==========================================
# PIN INTERACTION HANDLERS
# ==========================================

## Emits pin click events to the global ThreadContainer for thread connections.
func _on_pin_pressed() -> void:
	var thread_container: Node = get_tree().get_first_node_in_group("thread_container")
	if thread_container and thread_container.has_method("_on_pin_clicked"):
		thread_container._on_pin_clicked(evidence_identifier, pin_button)
	else:
		push_error("Evidence Card: Could not find Thread container!")
