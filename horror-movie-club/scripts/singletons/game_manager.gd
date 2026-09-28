# GameManager.gd
extends Node

signal evidence_queued(evidence_id: String)
signal board_reset

var pending_evidence_queue: Array[String] = []

func _ready() -> void:
	# Defer connection so it runs safely after all autoloads finish initializing
	call_deferred("_connect_dialogic")

func _connect_dialogic() -> void:
	# Verify Dialogic exists in the root tree
	var dialogic_node = get_node_or_null("/root/Dialogic")
	if dialogic_node:
		if not Dialogic.signal_event.is_connected(_on_dialogic_signal):
			Dialogic.signal_event.connect(_on_dialogic_signal)
			
		if not Dialogic.text_signal.is_connected(_on_dialogic_text_signal):
			Dialogic.text_signal.connect(_on_dialogic_text_signal)
			
		print("GameManager: Successfully connected to Dialogic signals!")
	else:
		print("GameManager: Warning - Dialogic autoload not found at /root/Dialogic.")

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
		print("GameManager: Matched change_scene! Target name -> ", scene_name)
		
		var scene_paths: Dictionary = {
			"game": "res://scenes/core/Game.tscn",
			"combat_arena": "res://scenes/stages/combat_arena.tscn",
		}
		
		if scene_paths.has(scene_name):
			var target_path = scene_paths[scene_name]
			print("GameManager: Changing scene to -> ", target_path)
			
			# Cleanly end the active timeline before switching scenes
			Dialogic.end_timeline()
					
			get_tree().change_scene_to_file(target_path)
		else:
			push_error("GameManager: Invalid scene key: '" + scene_name + "'")
			
	elif arg_str.begins_with("set_chapter:"):
		var chapter_num = arg_str.get_slice(":", 1).strip_edges()
		print("GameManager: Chapter changed -> ", chapter_num)
		pending_evidence_queue.clear()
		board_reset.emit()

func _on_dialogic_text_signal(argument: String) -> void:
	print("GameManager: Received Text Signal -> ", argument)

func has_pending_evidence() -> bool:
	return not pending_evidence_queue.is_empty()

func pop_next_evidence() -> String:
	if not pending_evidence_queue.is_empty():
		return pending_evidence_queue.pop_front()
	return ""
