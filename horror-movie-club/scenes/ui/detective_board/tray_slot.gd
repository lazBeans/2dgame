## PURPOSE: Manages the inventory tray slot where new evidence items arrive.
## Handles holding current evidence data, integration with DragManager for payload delivery,
## and spawning the final deduction trigger button when a chapter is solved.
extends DetectiveSlotBase
class_name TraySlot

signal slot_filled(evidence_id: String)
signal deduction_button_pressed

# ==========================================
# STATE & EXPORT VARIABLES
# ==========================================

var active_button: Node = null

@export var deduction_button_scene: PackedScene

# ==========================================
# INITIALIZATION & CURSOR FIXES
# ==========================================

## Clears the tray slot on startup.
func _ready() -> void:
	clear_slot()

# ==========================================
# EVIDENCE SETUP & CLEARING
# ==========================================

## Alias wrapper to assign evidence to the tray slot.
func set_evidence(id: String) -> void:
	setup_tray_item(id)

## Loads evidence resource data and populates the tray graphics (texture and label).
func setup_tray_item(id: String) -> void:
	super(id)
	var resource_path = "res://resources/evidence/" + _card_id + ".tres"
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
		slot_filled.emit(_card_id)
	else:
		clear_slot()

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
