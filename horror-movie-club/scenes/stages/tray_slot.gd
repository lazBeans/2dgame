## Script Purpose: Manages an inventory slot in the detective tray for holding, 
## displaying, and dragging unplaced evidence items or triggering deductions.
extends Panel
class_name TraySlot

signal slot_emptied
signal slot_filled(evidence_id: String)
signal deduction_button_pressed

var _evidence_id: String = ""
var active_button: Node = null

@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label
@export var deduction_button_scene: PackedScene

## Called when the node enters the scene tree; clears slot and overrides cursor bugs.
func _ready() -> void:
	clear_slot()

## Process loop ensuring cursor compatibility with forbidden system shapes.
func _process(_delta: float) -> void:
	if Input.get_current_cursor_shape() == CURSOR_FORBIDDEN:
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)

## Returns the stored evidence identifier string.
func get_evidence_id() -> String:
	return _evidence_id

## Returns true if the tray slot is currently empty.
func is_empty() -> bool:
	return _evidence_id.is_empty()

## Sets the evidence ID for the slot.
func set_evidence(id: String) -> void:
	setup_tray_item(id)

## Populates the tray slot with data loaded from an evidence resource.
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
			else:
				push_warning("TraySlot: Resource '" + _evidence_id + "' has no texture assigned!")
		else:
			push_error("TraySlot ERROR: '$TextureRect' node not found!")
				
		if label:
			label.text = evidence_data.evidence_name
			label.visible = true
		else:
			push_error("TraySlot ERROR: '$Label' node not found!")
			
		visible = true
		slot_filled.emit(_evidence_id)
		print("TraySlot: Successfully populated tray with -> ", evidence_data.evidence_name)
	else:
		push_error("TraySlot: Failed to load resource at path: " + resource_path)
		clear_slot()

## Clears the current slot content and emits the slot emptied signal.
func clear_slot() -> void:
	_evidence_id = ""
	
	if texture_rect:
		texture_rect.texture = null
	if label:
		label.text = ""
		label.visible = false
		
	slot_emptied.emit()

## Generates drag data and custom preview when dragging items out of the tray.
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

## Spawns the deduction button inside the tray slot when the puzzle is solved.
func spawn_deduction_button() -> void:
	var button_scene = preload("res://scenes/components/DeductionButton.tscn")
	var button_instance = button_scene.instantiate()
	
	add_child(button_instance)
	
	if button_instance is Button:
		button_instance.pressed.connect(_on_deduction_pressed)
	else:
		var actual_button = button_instance.get_node("Button")
		actual_button.pressed.connect(_on_deduction_pressed)

## Handles clicking on the deduction button, triggering scene transitions.
func _on_deduction_pressed() -> void:
	print("Deduction button clicked! Transitioning scene...")
	get_tree().change_scene_to_file("res://scenes/stages/Deduction.tscn")
