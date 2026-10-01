## Script Purpose: Global autoload manager handling core game state, 
## evidence queue management, chapter tracking, and Dialogic signal event routing.
extends Node

signal evidence_queued(evidence_id: String)
signal board_reset
signal chapter_changed(current_chapter: String)

var pending_evidence_queue: Array[String] = []
var current_chapter: String = "chapter_1"

## Called when the node enters the scene tree; defers Dialogic signal connection.
func _ready() -> void:
	call_deferred("_connect_dialogic")
	print(current_chapter)

## Verifies Dialogic exists in the root tree and connects global event and text signals.
func _connect_dialogic() -> void:
	var dialogic_node = get_node_or_null("/root/Dialogic")
	if dialogic_node:
		if not Dialogic.signal_event.is_connected(_on_dialogic_signal):
			Dialogic.signal_event.connect(_on_dialogic_signal)
			
		if not Dialogic.text_signal.is_connected(_on_dialogic_text_signal):
			Dialogic.text_signal.connect(_on_dialogic_text_signal)
			
		print("GameManager: Successfully connected to Dialogic signals!")
	else:
		print("GameManager: Warning - Dialogic autoload not found at /root/Dialogic.")

## Handles incoming Dialogic custom signals to unlock evidence, switch scenes, or change chapters.
func _on_dialogic_signal(argument: Variant) -> void:
	var arg_str = str(argument).strip_edges()
	print("GameManager: Received Dialogic signal -> ", arg_str)
	
	if arg_str.begins_with("unlock_evidence:"):
		var evidence_id = arg_str.get_slice(":", 1).strip_edges()
		pending_evidence_queue.append(evidence_id)
		evidence_queued.emit(evidence_id)
		print("GameManager: Evidence queued -> ", evidence_id)
		
	elif arg_str.begins_with("change_scene:"):
		var scene_name = arg_str.get_slice(":", 1).strip_edges()
		print(scene_name)
		print("GameManager: Matched change_scene! Target name -> ", scene_name)
		
		if FileManager.load_scene(scene_name):
			var target_path = FileManager.load_scene(scene_name)
			print("GameManager: Changing scene to -> ", target_path)
			
			Dialogic.end_timeline()
			get_tree().change_scene_to_file(target_path)
		else:
			push_error("GameManager: Invalid scene key: '" + scene_name + "'")
			
	elif arg_str.begins_with("set_chapter:"):
		var chapter_num = arg_str.get_slice(":", 1).strip_edges()
		current_chapter = chapter_num
		emit_signal("chapter_changed", current_chapter)
		board_reset.emit()

## Receives and logs incoming Dialogic text signals.
func _on_dialogic_text_signal(argument: String) -> void:
	print("GameManager: Received Text Signal -> ", argument)

## Returns true if there are items waiting in the pending evidence queue.
func has_pending_evidence() -> bool:
	return not pending_evidence_queue.is_empty()

## Pops and returns the next evidence ID from the pending queue.
func pop_next_evidence() -> String:
	if not pending_evidence_queue.is_empty():
		return pending_evidence_queue.pop_front()
	return ""
