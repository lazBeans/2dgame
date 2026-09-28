# EvidenceCard.gd
extends Panel
class_name EvidenceCard

signal pin_clicked(card: EvidenceCard)

## Encapsulated property: setting this automatically triggers the UI update
var evidence_id: String = "":
	set(value):
		evidence_id = value
		_update_card_display()

## Tracks whether the player is currently clicking and dragging this card around.
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label
@onready var pin_button: TextureButton = $PinButton

func _ready() -> void:
	if pin_button:
		pin_button.pressed.connect(_on_pin_pressed)

func _update_card_display() -> void:
	if evidence_id.is_empty():
		return
	var resource_path = "res://resources/evidence/" + evidence_id + ".tres"
	var evidence_data = load(resource_path) as EvidenceData
	
	if evidence_data and label:
		label.text = evidence_data.evidence_name

func setup(id: String) -> void:
	evidence_id = id
	var resource_path = "res://resources/evidence/" + evidence_id + ".tres"
	var evidence_data = load(resource_path) as EvidenceData
	
	if evidence_data:
		if texture_rect and evidence_data.texture:
			texture_rect.texture = evidence_data.texture
		if label:
			label.text = evidence_data.evidence_name
	else:
		push_error("EvidenceCard: Failed to load EvidenceData resource at path: " + resource_path)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			pin_button.visible = false
			drag_offset = get_local_mouse_position()
			
			var parent = get_parent()
			if parent:
				parent.move_child(self, parent.get_child_count() - 1)
		else:
			# FIX: Stop dragging when the mouse button is released!
			is_dragging = false
			pin_button.visible = true

func _input(event: InputEvent) -> void:
	if is_dragging and event is InputEventMouseMotion:
		global_position = get_global_mouse_position() - drag_offset

func _on_pin_pressed() -> void:
	print("Pin clicked on evidence card: ", evidence_id)
