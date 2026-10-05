## PURPOSE: The global game state and event controller.
## Acts as the bridge between Dialogic and the game world, handling scene transitions,
## tracking chapter progression, and managing the queue of newly discovered evidence.
extends Node

# ==========================================
# GLOBAL STATE VARIABLES
# ==========================================
var pending_evidence_queue: Array[String] = []
var unlocked_segments: Array[String] = []
var current_chapter: String = "chapter_1"

# ==========================================
# INITIALIZATION & SETUP
# ==========================================

## Delays connecting to Dialogic until the end of the frame to ensure all nodes exist.
func _ready() -> void:
	call_deferred("_connect_dialogic")

## Locates the Dialogic singleton and connects its signal event router to the manager.
func _connect_dialogic() -> void:
	var dialogic_node = get_node_or_null("/root/Dialogic")
	if dialogic_node:
		if not Dialogic.signal_event.is_connected(_on_dialogic_signal):
			Dialogic.signal_event.connect(_on_dialogic_signal)

# ==========================================
# EVENT ROUTING (DIALOGIC)
# ==========================================

## Parses raw string arguments emitted by Dialogic and triggers the corresponding game logic.
func _on_dialogic_signal(argument: Variant) -> void:
	var arg_str = str(argument).strip_edges()
	
	# Handles adding new evidence to the player's queue
	if arg_str.begins_with("unlock_evidence:"):
		var evidence_id = arg_str.get_slice(":", 1).strip_edges()
		pending_evidence_queue.append(evidence_id)
		if SignalBus.has_user_signal("evidence_queued"):
			SignalBus.evidence_queued.emit(evidence_id)
			
	elif arg_str.begins_with("unlock_segment:"):
		var segment_id = arg_str.get_slice(":", 1).strip_edges()
		if not unlocked_segments.has(segment_id):
			unlocked_segments.append(segment_id)
			
	# Handles transitioning to a new scene using keys defined in scenes.json
	elif arg_str.begins_with("change-scene:") or arg_str.begins_with("change_scene:"):
		var scene_key = arg_str.get_slice(":", 1).strip_edges()
		var target_path = FileManager.load_scene(scene_key)
		
		if target_path != "":
			Dialogic.end_timeline()
			get_tree().change_scene_to_file(target_path)
		else:
			push_error("GameManager: Key '" + scene_key + "' not found in scenes.json")
			
	# Handles advancing the game chapter and resetting the detective board
	elif arg_str.begins_with("set_chapter:"):
		var chapter_num = arg_str.get_slice(":", 1).strip_edges()
		current_chapter = chapter_num
		if SignalBus.has_user_signal("chapter_changed"):
			SignalBus.chapter_changed.emit(current_chapter)
			SignalBus.board_reset.emit()

# ==========================================
# EVIDENCE QUEUE MANAGEMENT
# ==========================================

## Returns true if there is unplaced evidence waiting in the queue.
func has_pending_evidence() -> bool:
	return not pending_evidence_queue.is_empty()

## Removes and returns the next evidence ID from the front of the queue.
func pop_next_evidence() -> String:
	if not pending_evidence_queue.is_empty():
		return pending_evidence_queue.pop_front()
	return ""
