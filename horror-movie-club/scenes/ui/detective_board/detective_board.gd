## PURPOSE: Main CanvasLayer controller for the Detective Board UI layer.
## Handles board visibility toggles, evidence card instantiation, and deduction trigger coordination.
extends CanvasLayer
class_name DetectiveBoard

# ==========================================
# EXPORTED & ONREADY REFERENCES
# ==========================================

@export var evidence_card_scene: PackedScene = preload("res://scenes/components/EvidenceCard.tscn")

@onready var board_container: Node = find_child("BoardContainer")
@onready var tray_slot: DetectiveSlotBase = find_child("TraySlot") as DetectiveSlotBase

var stored_final_timeline: String = ""

# ==========================================
# INITIALIZATION & SIGNAL LISTENERS
# ==========================================

## Hides the board on startup and connects global bus signals.
func _ready() -> void:
	visible = false
	
	SignalBus.all_segments_unlocked.connect(_on_all_segments_unlocked)
	SignalBus.evidence_queued.connect(_on_manager_evidence_queued)
	SignalBus.board_reset.connect(_on_manager_board_reset)
	
	if tray_slot:
		tray_slot.slot_emptied.connect(_on_tray_emptied)
		if "deduction_button_pressed" in tray_slot:
			tray_slot.deduction_button_pressed.connect(_on_start_deduction_pressed)
		
	call_deferred("update_tray")

# ==========================================
# BOARD VISIBILITY CONTROLS
# ==========================================

## Listens for input shortcuts (e.g. Tab key) to toggle board visibility.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			toggle_board()
			get_viewport().set_input_as_handled()

## Toggles canvas visibility and notifies thread layers and sub-systems.
# detective_board.gd
func toggle_board() -> void:
	visible = not visible
	SignalBus.board_toggled.emit(visible)
	
	var thread_container: Node = get_tree().get_first_node_in_group("thread_container")
	if thread_container:
		# Use the new custom function to toggle the line canvas
		if thread_container.has_method("set_lines_visible"):
			thread_container.set_lines_visible(visible)
		else:
			thread_container.visible = visible
			
		if not visible and thread_container.has_method("reset_connection_state"):
			thread_container.reset_connection_state()
			
	if visible:
		update_tray()

# ==========================================
# TRAY & WORKSPACE BOARD MANAGEMENT
# ==========================================

## Pulls pending evidence from GameManager and updates tray slot contents.
func update_tray() -> void:
	if not visible:
		return
	if tray_slot and tray_slot.is_empty() and GameManager.has_pending_evidence():
		var next_id: String = GameManager.pop_next_evidence()
		tray_slot.set_evidence(next_id)

## Returns true if the incoming payload is valid for dropping onto the board.
func can_drop_evidence(data: Variant) -> bool:
	return data is TraySlot and not data.is_empty()

## Instantiates an EvidenceCard onto the board canvas at the specified mouse position.
func drop_evidence(at_position: Vector2, data: Variant) -> void:
	if data is TraySlot:
		var evidence_id: String = data.get_card_id()
		data.clear_slot()
		
		var new_card: EvidenceCard = evidence_card_scene.instantiate() as EvidenceCard
		if new_card:
			board_container.add_child(new_card)
			
			var card_size: Vector2 = new_card.get_card_size() if new_card.has_method("get_card_size") else Vector2(500.0, 608.0)
			var card_half_size: Vector2 = card_size / 2.0
			var container_rect: Rect2 = board_container.get_global_rect() if board_container is Control else get_viewport().get_visible_rect()
			
			var target_pos: Vector2 = at_position
			target_pos.x = clamp(
				target_pos.x, 
				container_rect.position.x + card_half_size.x, 
				container_rect.position.x + container_rect.size.x - card_half_size.x
			)
			target_pos.y = clamp(
				target_pos.y, 
				container_rect.position.y + card_half_size.y, 
				container_rect.position.y + container_rect.size.y - card_half_size.y
			)
			
			new_card.global_position = target_pos
			new_card.setup(evidence_id)

## Clears all evidence card instances and thread connections from the board.
func clear_board_visuals() -> void:
	if tray_slot:
		tray_slot.clear_slot()
		
	for child in board_container.get_children():
		child.queue_free()
		
	var thread_container: Node = get_tree().get_first_node_in_group("thread_container")
	if thread_container and thread_container.has_method("clear_lines"):
		thread_container.clear_lines()

# ==========================================
# SIGNAL CALLBACKS
# ==========================================

## Stores the timeline data and triggers deduction button creation on puzzle completion.
func _on_all_segments_unlocked(connection_data: Variant) -> void:
	stored_final_timeline = str(connection_data)
	if tray_slot and tray_slot.has_method("spawn_deduction_button"):
		tray_slot.spawn_deduction_button()

## Launches the chapter deduction dialogue timeline via Dialogic.
func _on_start_deduction_pressed() -> void:
	var deduction_timeline: String = GameManager.current_chapter + "_deduction"
	Dialogic.start(deduction_timeline)

## Refreshes tray contents when new evidence is queued in GameManager.
func _on_manager_evidence_queued(_evidence_id: String) -> void:
	update_tray()

## Resets board visuals when global board reset signal is received.
func _on_manager_board_reset() -> void:
	clear_board_visuals()

## Deferred tray refresh triggered when a slot becomes empty.
func _on_tray_emptied() -> void:
	call_deferred("update_tray")
