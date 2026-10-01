## PURPOSE: Manages the inventory tray slot where new evidence items arrive.
## Handles holding current evidence data, preview rendering during drag-and-drop operations,
## and spawning the final deduction trigger button when a chapter is solved.
extends Panel
class_name TraySlot

signal slot_emptied
signal slot_filled(evidence_id: String)
signal deduction_button_pressed

# ==========================================
# STATE & EXPORT VARIABLES
# ==========================================
var _evidence_id: String = ""
var active_button: Node = null

@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label
@export var deduction_button_scene: PackedScene

# ==========================================
# INITIALIZATION & CURSOR FIXES
# ==========================================

## Clears the tray slot on startup.
func _ready() -> void:
	clear_slot()

## Clears stuck forbidden cursor artifacts if frame conditions change.
func _process(_delta: float) -> void:
	if Input.get_current_cursor_shape() == CURSOR_FORBIDDEN:
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)

# ==========================================
# STATE GETTERS
# ==========================================

## Returns the ID of the evidence currently resting in the tray.
func get_evidence_id() -> String:
	return _evidence_id

## Returns true if the tray slot is currently empty.
func is_empty() -> bool:
	return _evidence_id.is_empty()

# ==========================================
# EVIDENCE SETUP & CLEARING
# ==========================================

## Alias wrapper to assign evidence to the tray slot.
func set_evidence(id: String) -> void:
	setup_tray_item(id)

## Loads evidence resource data and populates the tray graphics (texture and label).
func setup_tray_item(id: String) -> void:
	_evidence_id = id
	
	if _evidence_id.is_empty():
		clear_slot()
		return
	
	var resource_path = "res://resources/evidence/" + _evidence_id + ".tres"
	var evidence_data = load(resource_path) as EvidenceData
	
	if evidence_data:
		if texture_rect:
			texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_rect.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
			texture_rect.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
			if evidence_data.texture:
				texture_rect.texture = evidence_data.texture 
		if label:
			label.text = evidence_data.evidence_name
			label.visible = true
		visible = true
		slot_filled.emit(_evidence_id)
	else:
		clear_slot()

## Resets the tray slot back to an empty, hidden state.
func clear_slot() -> void:
	_evidence_id = ""
	if texture_rect:
		texture_rect.texture = null
	if label:
		label.text = ""
		label.visible = false
	slot_emptied.emit()

# ==========================================
# DRAG-AND-DROP PAYLOAD HANDLING
# ==========================================

## Generates a visual preview container when dragging evidence out of the tray slot.
func _get_drag_data(_at_position: Vector2) -> Variant:
	if is_empty():
		return null
	
	var preview = TextureRect.new()
	if texture_rect:
		preview.texture = texture_rect.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = Vector2(500, 608)
	preview.size = Vector2(500, 608)
	preview.position = -_at_position
	
	var drag_container = Control.new()
	drag_container.add_child(preview)
	set_drag_preview(drag_container)
	return self

# ==========================================
# DEDUCTION BUTTON SPAWNING
# ==========================================

## Instantiates and attaches the final deduction button to the tray area when puzzle requirements are met.
func spawn_deduction_button() -> void:
	var button_scene = preload("res://scenes/components/DeductionButton.tscn")
	var button_instance = button_scene.instantiate()
	add_child(button_instance)
	
	if button_instance is Button:
		button_instance.pressed.connect(_on_deduction_pressed)
	else:
		var actual_button = button_instance.get_node("Button")
		actual_button.pressed.connect(_on_deduction_pressed)

## Emits a signal when the deduction button is clicked.
func _on_deduction_pressed() -> void:
	print("DEBUG: Deduction button was physically clicked!")
	deduction_button_pressed.emit()
