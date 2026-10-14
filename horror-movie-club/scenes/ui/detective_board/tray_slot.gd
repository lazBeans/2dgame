## PURPOSE: Inventory tray slot for holding evidence items and spawning deduction trigger buttons.
## Extends DetectiveSlotBase to inherit drag-and-drop state & method overrides.
extends DetectiveSlotBase
class_name TraySlot

# ==========================================
# SIGNALS & EXPORTS
# ==========================================

## Emitted when the spawned deduction button is clicked.
signal deduction_button_pressed
signal boss_button_pressed

@export var action_button_scene: PackedScene
var active_button: Node = null

enum button_type {DEDUCTION, BOSS}

# ==========================================
# INITIALIZATION & PROCESS
# ==========================================

## Clears slot state on startup.
func _ready() -> void:
	clear_slot()

## Ensures mouse cursor shape resets if stuck in forbidden shape.
func _process(_delta: float) -> void:
	if Input.get_current_cursor_shape() == CURSOR_FORBIDDEN:
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)

# ==========================================
# TRAY POPULATION & ACCESSIBILITY
# ==========================================

## Populates the tray slot and loads evidence textures and labels from resource files.
func set_slot_item(id: String) -> void:
	super(id)

	if current_item_id.is_empty():
		clear_slot()
		return

	var resource_path: String = "res://resources/evidences/" + current_item_id + ".tres"
	if ResourceLoader.exists(resource_path):
		var evidence_data: Resource = load(resource_path)
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

## Returns the current evidence identifier string held in the tray.
func get_card_id() -> String:
	return get_evidence_id()

# ==========================================
# DEDUCTION BUTTON TRIGGER
# ==========================================

## Instantiates and attaches the deduction trigger button inside the slot.
func spawn_action_button(current_button: String) -> void:
	
	if not action_button_scene:
		action_button_scene = preload("res://scenes/components/ActionButton.tscn") as PackedScene
		
	if action_button_scene and (not active_button or not is_instance_valid(active_button)):
		clear_slot()
		active_button = action_button_scene.instantiate()
		add_child(active_button)

		if active_button is Control:
			active_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		var btn: BaseButton = null
		if active_button is BaseButton:
			btn = active_button
		elif active_button.has_node("ActionButton"):
			btn = active_button.get_node("ActionButton") as BaseButton
		
		match current_button:
			button_type.DEDUCTION:
				if btn and not btn.pressed.is_connected(_on_deduction_pressed):
					btn.pressed.connect(_on_deduction_pressed)
			button_type.BOSS:
				if btn and not btn.pressed.is_connected(_on_boss_pressed):
					btn.pressed.connect(_on_boss_pressed)

## Emits deduction_button_pressed signal when the deduction button is pressed.
func _on_deduction_pressed() -> void:
	deduction_button_pressed.emit()
	var child_to_remove = get_node_or_null("ActionButton")
	if child_to_remove:
		child_to_remove.queue_free()
		
## Emits deduction_button_pressed signal when the deduction button is pressed.
func _on_boss_pressed() -> void:
	boss_button_pressed.emit()
	var child_to_remove = get_node_or_null("ActionButton")
	if child_to_remove:
		child_to_remove.queue_free()
	
	
