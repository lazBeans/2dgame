## PURPOSE: Manages an individual evidence card on the detective board, 
## handling free-form dragging on the board via DragManager, dynamic texture loading, 
## and pin click interactions used for drawing yarn connection threads.
extends DetectiveCardBase
class_name EvidenceCard

signal pin_clicked(card: EvidenceCard)

# ==========================================
# EXPORTED & STATE VARIABLES
# ==========================================
var evidence_identifier: String = "":
	set(value):
		evidence_identifier = value
		_update_card_display()

@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label
@onready var pin_button: TextureButton = $PinButton

# ==========================================
# INITIALIZATION
# ==========================================

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if pin_button:
		pin_button.pressed.connect(_on_pin_pressed)

# ==========================================
# DISPLAY & SETUP
# ==========================================

## Updates the card's text label based on the current evidence identifier resource.
func _update_card_display() -> void:
	if evidence_identifier.is_empty():
		return
		
	var resource_path = "res://resources/evidence/" + evidence_identifier + ".tres"
	var evidence_data = load(resource_path) as EvidenceData
	
	if evidence_data and label:
		label.text = evidence_data.evidence_name

## Sets up the card with a given evidence ID, loading both its image texture and title.
func setup_card_visual() -> void:
	var resource_path = "res://resources/evidence/" + card_identifier + ".tres"
	var evidence_data = load(resource_path) as EvidenceData
	
	if evidence_data:
		if texture_rect and evidence_data.texture:
			texture_rect.texture = evidence_data.texture
		if label:
			label.text = evidence_data.evidence_name
	else:
		push_error("EvidenceCard: Failed to load Card resource at path: " + resource_path)

# ==========================================
# INPUT & DRAGGING BEHAVIOR
# ==========================================

func start_dragging() -> void:
	super()
	if pin_button:
		pin_button.visible = false

func stop_dragging() -> void:
	super()
	if pin_button:
		pin_button.visible = true

# ==========================================
# SIGNAL CALLBACKS
# ==========================================

## Handles pin button clicks, relaying the event to the ThreadContainer to create yarn connections.
func _on_pin_pressed() -> void:
	print("Pin clicked on evidence card: ", evidence_identifier)
	
	var thread_container = get_tree().get_first_node_in_group("thread_container")
	if thread_container:
		thread_container._on_pin_clicked(evidence_identifier, pin_button)
	else:
		push_error("EvidenceCard: Could not find ThreadContainer in group 'thread_container'!")
