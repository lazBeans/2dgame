## PURPOSE: Manages inventory tray slots for receiving evidence and spawning deduction triggers.
## Extends DetectiveSlotBase to inherit drag-and-drop state & method overrides.
extends DetectiveSlotBase
class_name TraySlot

signal deduction_button_pressed

@export var deduction_button_scene: PackedScene
var active_button: Node = null

func _ready() -> void:
	clear_slot()

func _process(_delta: float) -> void:
	if Input.get_current_cursor_shape() == CURSOR_FORBIDDEN:
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)

## Populates the tray slot and loads evidence graphics & labels from resources.
func set_slot_item(id: String) -> void:
	super(id)

	if current_item_id.is_empty():
		clear_slot()
		return

	var resource_path := "res://resources/evidences/" + current_item_id + ".tres"
	if ResourceLoader.exists(resource_path):
		var evidence_data = load(resource_path)
		if evidence_data:
			if texture_rect:
				texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				texture_rect.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
				texture_rect.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
				if "texture" in evidence_data and evidence_data.texture:
					texture_rect.texture = evidence_data.texture
			if label:
				if "evidence_name" in evidence_data:
					label.text = evidence_data.evidence_name
				label.visible = true
			visible = true
	else:
		push_warning("TraySlot: Could not find evidence resource at path: " + resource_path)

## Instantiates and attaches the deduction button inside the tray slot when conditions are met.
func spawn_deduction_button() -> void:
	if not deduction_button_scene:
		deduction_button_scene = preload("res://scenes/components/DeductionButton.tscn") as PackedScene

	if deduction_button_scene and (not active_button or not is_instance_valid(active_button)):
		clear_slot()
		active_button = deduction_button_scene.instantiate()
		add_child(active_button)

		if active_button is Control:
			active_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		var btn: Button = null
		if active_button is Button:
			btn = active_button
		elif active_button.has_node("Button"):
			btn = active_button.get_node("Button") as Button

		if btn and not btn.pressed.is_connected(_on_deduction_pressed):
			btn.pressed.connect(_on_deduction_pressed)

func _on_deduction_pressed() -> void:
	deduction_button_pressed.emit()
