extends Panel
class_name TraySlot

signal slot_emptied
signal slot_filled(evidence_id: String)

var _evidence_id: String = ""

@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label

func _ready() -> void:
	custom_minimum_size = Vector2(120, 160)
	clear_slot()

func get_evidence_id() -> String:
	return _evidence_id

func is_empty() -> bool:
	return _evidence_id.is_empty()

func set_evidence(id: String) -> void:
	setup_tray_item(id)

func setup_tray_item(id: String) -> void:
	_evidence_id = id
	
	if _evidence_id.is_empty():
		clear_slot()
		return
	
	var resource_path = "res://resources/evidence/" + _evidence_id + ".tres"
	var evidence_data = load(resource_path) as EvidenceData
	
	if evidence_data:
		# Check if TextureRect node actually exists in the scene tree
		if texture_rect:
			texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_rect.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
			texture_rect.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
			if evidence_data.texture:
				texture_rect.texture = evidence_data.texture 
			else:
				push_warning("TraySlot: Resource '" + _evidence_id + "' has no texture assigned!")
		else:
			push_error("TraySlot ERROR: '$TextureRect' node not found! Check your BottomDock node tree and node names.")
				
		# Check if Label node actually exists in the scene tree
		if label:
			label.text = evidence_data.evidence_name
			label.visible = true
		else:
			push_error("TraySlot ERROR: '$Label' node not found! Check your BottomDock node tree and node names.")
			
		visible = true
		slot_filled.emit(_evidence_id)
		print("TraySlot: Successfully populated tray with -> ", evidence_data.evidence_name)
	else:
		push_error("TraySlot: Failed to load resource at path: " + resource_path)
		clear_slot()

func clear_slot() -> void:
	_evidence_id = ""
	# REMOVE or comment out: visible = false (so the slot container stays visible)
	
	if texture_rect:
		texture_rect.texture = null
	if label:
		label.text = ""
		label.visible = false
		
	slot_emptied.emit()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if is_empty():
		return null
	
	var preview = TextureRect.new()
	if texture_rect:
		preview.texture = texture_rect.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = Vector2(100, 140)
	set_drag_preview(preview)
	
	return self
