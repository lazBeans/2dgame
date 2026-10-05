## PURPOSE: Manages an individual evidence card on the detective board, 
## handling free-form dragging via DragManager, dynamic evidence texture/label loading, 
## and pin click interactions used for drawing yarn connection threads.
extends DetectiveCardBase
class_name EvidenceCard

signal pin_clicked(card: EvidenceCard)

# ==========================================
# STATE VARIABLES & SETTERS
# ==========================================
var evidence_identifier: String = "":
	set(value):
		evidence_identifier = value
		_update_card_display()

@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label
@onready var pin_button: TextureButton = $PinButton

# ==========================================
# INITIALIZATION & SETUP
# ==========================================

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if pin_button:
		pin_button.pressed.connect(_on_pin_pressed)

## Updates the card's text label based on current evidence identifiers.
func _update_card_display() -> void:
	if evidence_identifier.is_empty():
		return
		
	var resource_path = "res://resources/evidences/" + evidence_identifier + ".tres"
	var evidence_data = load(resource_path) as EvidenceData
	
	if evidence_data and label:
		label.text = evidence_data.evidence_name

## Implements the abstract base method. Syncs card_identifier to evidence_identifier 
## to ensure thread connections receive the correct ID, then loads textures and text.
func setup_card_visual() -> void:
	# Synchronize base identifier with the subclass property to fix thread connection routing
	evidence_identifier = card_identifier
	
	var resource_path = "res://resources/evidences/" + evidence_identifier + ".tres"
	var evidence_data = load(resource_path) as EvidenceData
	
	if evidence_data:
		if texture_rect and evidence_data.texture:
			texture_rect.texture = evidence_data.texture
		if label:
			label.text = evidence_data.evidence_name
	else:
		push_error("EvidenceCard: Failed to load Card resource at path: " + resource_path)

# ==========================================
# INPUT & DRAGGING OVERRIDES
# ==========================================

## Extends base drag behavior to hide pin interactions while moving.
func start_dragging() -> void:
	super()
	if pin_button:
		pin_button.visible = false

## Restores pin visibility when dragging concludes.
func stop_dragging() -> void:
	super()
	if pin_button:
		pin_button.visible = true

# ==========================================
# SIGNAL CALLBACKS
# ==========================================

## Handles pin button clicks, passing the synchronized evidence identifier to the ThreadContainer.
func _on_pin_pressed() -> void:
	print("Pin clicked on evidence card: ", evidence_identifier)
	
	var thread_container = get_tree().get_first_node_in_group("thread_container")
	if thread_container:
		thread_container._on_pin_clicked(evidence_identifier, pin_button)
	else:
		push_error("EvidenceCard: Could not find ThreadContainer in group 'thread_container'!")
