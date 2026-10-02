## PURPOSE: Main orchestrator for the Detective Board UI layer.
## Manages board visibility toggles via key inputs, coordinates incoming evidence tray updates,
## handles card instantiation from drop events, and listens for puzzle completion milestones.
extends CanvasLayer
class_name DetectiveBoard

# ==========================================
# EXPORTED & ONREADY REFERENCES
# ==========================================
@export var evidence_card_scene: PackedScene = preload("res://scenes/components/EvidenceCard.tscn")
@onready var board_container = find_child("BoardContainer")
@onready var tray_slot = find_child("TraySlot")

var stored_final_timeline: String = ""

# ==========================================
# INITIALIZATION & SIGNAL BINDINGS
# ==========================================

## Hides the board by default on startup and hooks up global signal listeners.
func _ready() -> void:
	visible = false
	
	SignalBus.all_segments_unlocked.connect(_on_all_segments_unlocked)
	SignalBus.evidence_queued.connect(_on_manager_evidence_queued)
	SignalBus.board_reset.connect(_on_manager_board_reset)
	
	if tray_slot:
		tray_slot.slot_emptied.connect(_on_tray_emptied)
		tray_slot.deduction_button_pressed.connect(_on_start_deduction_pressed)
		
	call_deferred("update_tray")

# ==========================================
# INPUT & TOGGLE CONTROLS
# ==========================================

## Listens for shortcut keys (like Tab) to toggle the detective board's visibility.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			toggle_board()
			get_viewport().set_input_as_handled()

## Toggles the canvas visibility state, synchronizes thread line nodes, and updates the tray.
func toggle_board() -> void:
	visible = not visible
	SignalBus.board_toggled.emit(visible)
	
	var tc = get_tree().get_first_node_in_group("thread_container")
	if tc:
		tc.visible = visible
		if not visible and tc.has_method("reset_connection_state"):
			tc.reset_connection_state()
			
	if visible:
		update_tray()

# ==========================================
# TRAY & EVIDENCE MANAGEMENT
# ==========================================

## Checks the GameManager for pending evidence items and populates the tray slot if open.
func update_tray() -> void:
	if not visible:
		return
	if tray_slot and tray_slot.is_empty() and GameManager.has_pending_evidence():
		var next_id = GameManager.pop_next_evidence()
		tray_slot.set_evidence(next_id)

## Returns true if the incoming payload is valid for dropping onto the board.
func can_drop_evidence(data: Variant) -> bool:
	return data is TraySlot and not data.is_empty()

## Instantiates a physical EvidenceCard onto the board canvas at the specified mouse drop position.
func drop_evidence(at_position: Vector2, data: Variant) -> void:
	if data is TraySlot:
		var evidence_id = data.get_card_id()
		data.clear_slot()
		
		var new_card = evidence_card_scene.instantiate() as EvidenceCard
		if new_card:
			board_container.add_child(new_card)
			new_card.global_position = at_position - (new_card.size / 2)
			new_card.setup(evidence_id)

## Wipes all evidence cards from the board workspace and clears lines/tray state.
func clear_board_visuals() -> void:
	if tray_slot:
		tray_slot.clear_slot()
		
	for child in board_container.get_children():
		child.queue_free()
		
	var tc = get_tree().get_first_node_in_group("thread_container")
	if tc and tc.has_method("clear_lines"):
		tc.clear_lines()

# ==========================================
# SIGNAL CALLBACKS
# ==========================================

## Handles unlocking all segments by storing the final timeline and prompting the tray button.
func _on_all_segments_unlocked(connection_data: Variant) -> void:
	stored_final_timeline = connection_data
	if tray_slot and tray_slot.has_method("spawn_deduction_button"):
		tray_slot.spawn_deduction_button()

## Launches the chapter deduction Dialogic timeline when the deduction button is pressed.
func _on_start_deduction_pressed() -> void:
	var deduction_timeline = GameManager.current_chapter + "_deduction"
	Dialogic.start(deduction_timeline)

## Triggers tray updates when new evidence arrives in the global queue.
func _on_manager_evidence_queued(_evidence_id: String) -> void:
	update_tray()

## Resets board visuals when triggered by a global board reset signal.
func _on_manager_board_reset() -> void:
	clear_board_visuals()

## Automatically triggers tray refreshes when a slot is emptied.
func _on_tray_emptied() -> void:
	call_deferred("update_tray")
