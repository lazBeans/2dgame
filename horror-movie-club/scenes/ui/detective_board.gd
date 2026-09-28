extends CanvasLayer
class_name DetectiveBoardScene

@export var evidence_card_scene: PackedScene = preload("res://scenes/components/EvidenceCard.tscn")
@onready var board_container = $MainLayout/BoardContainer
@onready var tray_slot = $MainLayout/TraySlot

func _ready() -> void:
	visible = false
	
	# Synchronize with GameManager instead of duplicating queue logic
	GameManager.evidence_queued.connect(_on_manager_evidence_queued)
	GameManager.board_reset.connect(_on_manager_board_reset)
	
	if GameManager.has_signal("board_toggle_requested"):
		GameManager.board_toggle_requested.connect(toggle_board)
	
	if tray_slot:
		tray_slot.slot_emptied.connect(_on_tray_emptied)
		
	call_deferred("update_tray")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			toggle_board()
			get_viewport().set_input_as_handled()

func toggle_board() -> void:
	visible = not visible
	if visible:
		update_tray()

func update_tray() -> void:
	# FIX: Do not pull items from the queue if the board is currently hidden
	if not visible:
		return
		
	if tray_slot and tray_slot.is_empty() and GameManager.has_pending_evidence():
		var next_id = GameManager.pop_next_evidence()
		tray_slot.set_evidence(next_id)

func _on_manager_evidence_queued(_evidence_id: String) -> void:
	update_tray()

func _on_manager_board_reset() -> void:
	clear_board_visuals()

func _on_tray_emptied() -> void:
	# FIX: Use call_deferred to prevent race conditions during drag-and-drop cleanup
	call_deferred("update_tray")

# --- Drop Relay Handlers ---
func can_drop_evidence(data: Variant) -> bool:
	return data is TraySlot and not data.is_empty()

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

func clear_board_visuals() -> void:
	if tray_slot:
		tray_slot.clear_slot()
		
	for child in board_container.get_children():
		child.queue_free()
