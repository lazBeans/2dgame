## Script Purpose: Manages the detective board overlay, evidence tray coordination, 
## board visibility toggles, and UI-to-manager event relays.
extends CanvasLayer
class_name DetectiveBoardScene

signal board_toggled(is_open: bool)

@export var evidence_card_scene: PackedScene = preload("res://scenes/components/EvidenceCard.tscn")
@onready var board_container = find_child("BoardContainer")
@onready var tray_slot = find_child("TraySlot")

var thread_container: Node = null
var stored_final_timeline: String = ""

## Called when the node enters the scene tree; initializes signals and updates tray.
func _ready() -> void:
	visible = false
	
	thread_container = get_tree().get_first_node_in_group("thread_container")
	if thread_container and thread_container.has_signal("all_segments_unlocked"):
		if not thread_container.all_segments_unlocked.is_connected(_on_all_segments_unlocked):
			thread_container.all_segments_unlocked.connect(_on_all_segments_unlocked)
	
	GameManager.evidence_queued.connect(_on_manager_evidence_queued)
	GameManager.board_reset.connect(_on_manager_board_reset)
	
	if GameManager.has_signal("board_toggle_requested"):
		GameManager.board_toggle_requested.connect(toggle_board)
	
	if tray_slot:
		tray_slot.slot_emptied.connect(_on_tray_emptied)
		tray_slot.deduction_button_pressed.connect(_on_start_deduction_pressed)
		
	call_deferred("update_tray")

## Triggered when all puzzle segments are unlocked; spawns the deduction button.
func _on_all_segments_unlocked(connection_data: Variant) -> void:
	print("Puzzle complete! Spawning deduction button in the tray.")
	stored_final_timeline = connection_data
	
	if tray_slot and tray_slot.has_method("spawn_deduction_button"):
		tray_slot.spawn_deduction_button()
	else:
		push_error("DetectiveBoardScene: TraySlot reference is missing spawn_deduction_button()!")

## Triggered when the deduction button is pressed; transitions to the deduction scene.
func _on_start_deduction_pressed() -> void:
	print("Start Deduction clicked. Tracking current room and transitioning...")
	if get_tree().current_scene:
		GameManager.previous_room_scene = get_tree().current_scene.scene_file_path
	GameManager.pending_deduction_timeline = stored_final_timeline
	get_tree().change_scene_to_file("res://scenes/deduction_scene.tscn")

## Listens for shortcut inputs (Tab) to toggle board visibility.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			toggle_board()
			get_viewport().set_input_as_handled()

## Toggles the visibility state of the detective board overlay and thread container.
func toggle_board() -> void:
	visible = not visible
	board_toggled.emit(visible)
	
	var tc = get_tree().get_first_node_in_group("thread_container")
	if tc:
		tc.visible = visible
		if not visible and tc.has_method("reset_connection_state"):
			tc.reset_connection_state()
			
	if visible:
		update_tray()

## Pulls pending evidence from the GameManager and populates the tray slot.
func update_tray() -> void:
	if not visible:
		return
		
	if tray_slot and tray_slot.is_empty() and GameManager.has_pending_evidence():
		var next_id = GameManager.pop_next_evidence()
		tray_slot.set_evidence(next_id)

## Returns true if dropped data is a valid non-empty tray slot.
func can_drop_evidence(data: Variant) -> bool:
	return data is TraySlot and not data.is_empty()

## Instantiates and places a new evidence card onto the board from a dropped tray item.
func drop_evidence(at_position: Vector2, data: Variant) -> void:
	if data is TraySlot:
		var evidence_id = data.get_evidence_id()
		data.clear_slot()
		
		var new_card = evidence_card_scene.instantiate() as EvidenceCard
		if new_card:
			board_container.add_child(new_card)
			new_card.global_position = at_position - (new_card.size / 2)
			new_card.setup(evidence_id)
		else:
			push_error("DetectiveBoardScene: Failed to instantiate EvidenceCard.")

## Clears all visual evidence cards and reset lines on the board.
func clear_board_visuals() -> void:
	if tray_slot:
		tray_slot.clear_slot()
		
	for child in board_container.get_children():
		child.queue_free()
		
	var tc = get_tree().get_first_node_in_group("thread_container")
	if tc and tc.has_method("clear_lines"):
		tc.clear_lines()

## Refreshes the tray when new evidence is queued in GameManager.
func _on_manager_evidence_queued(_evidence_id: String) -> void:
	update_tray()

## Clears the board visuals when requested by GameManager.
func _on_manager_board_reset() -> void:
	clear_board_visuals()

## Automatically checks and updates the tray when it is emptied.
func _on_tray_emptied() -> void:
	call_deferred("update_tray")
