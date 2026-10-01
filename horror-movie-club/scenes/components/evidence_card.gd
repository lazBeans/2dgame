## Script Purpose: Manages an individual evidence card on the detective board, 
## handling drag-and-drop movement, dynamic texture loading, and pin click 
## interactions used for drawing yarn connection threads.
extends Panel
class_name EvidenceCard

signal pin_clicked(card: EvidenceCard)

var evidence_identifier: String = "":
	set(value):
		evidence_identifier = value
		_update_card_display()

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label
@onready var pin_button: TextureButton = $PinButton

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if pin_button:
		pin_button.pressed.connect(_on_pin_pressed)

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
		if texture_rect and evidence_data.texture:
			texture_rect.texture = evidence_data.texture
		if label:
			label.text = evidence_data.evidence_name
	else:
		push_error("EvidenceCard: Failed to load EvidenceData resource at path: " + resource_path)

## Handles mouse button input events to toggle dragging state and bring the card to the foreground.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			pin_button.visible = false
			drag_offset = get_local_mouse_position()
			
			var parent_node = get_parent()
			if parent_node:
				parent_node.move_child(self, parent_node.get_child_count() - 1)
		else:
			is_dragging = false
			pin_button.visible = true

## Updates the card's global position smoothly while it is being dragged by the mouse.
func _input(event: InputEvent) -> void:
	if is_dragging and event is InputEventMouseMotion:
		global_position = get_global_mouse_position() - drag_offset

## Handles pin button clicks, relaying the event to the ThreadContainer to create yarn connections.
func _on_pin_pressed() -> void:
	print("Pin clicked on evidence card: ", evidence_identifier)
	
	var thread_container = get_tree().get_first_node_in_group("thread_container")
	if thread_container:
		thread_container._on_pin_clicked(evidence_identifier, pin_button)
	else:
		push_error("EvidenceCard: Could not find ThreadContainer in group 'thread_container'!")
