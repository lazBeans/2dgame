## PURPOSE: Manages sequence-based puzzle completion routines and coordinates 
## chained dialogue events between clue resolutions and chapter deductions.
extends Node

# ==========================================
# INITIALIZATION
# ==========================================
@export var slot_scene: PackedScene # Assign your OrderedSlot.tscn here in Inspector

var current_ch = GameManager.current_chapter
var ordered_segments = FileManager.load_required_segments(current_ch)
var segment = preload("res://scenes/components/EventSegment.tscn")
var unordered_segments: Array = []
var spawns: Array = []

## Initialization: Fetches board markers, sets up slots, and spawns available evidence.
func _ready() -> void:
	initialize_deduction()

## Can be called manually when switching into the Deduction stage scene
func initialize_deduction() -> void:
	# 1. Fetch spawn point markers
	var spawn_container = _find_target_node("SpawnPoints")
	if spawn_container:
		spawns = spawn_container.get_children()
	else:
		spawns = get_tree().get_nodes_in_group("spawn_points")
		
	# 2. Shuffle spawn points
	spawns.shuffle()
	
	# 4. Grab unlocked segments
	if "unlocked_segments" in GameManager:
		for seg_id in GameManager.unlocked_segments:
			if not unordered_segments.has(seg_id):
				unordered_segments.append(seg_id)
	
	# 5. Spawn cards on board
	if not unordered_segments.is_empty():
		_spawn_all_segments()

# ==========================================
# SEARCH HELPER
# ==========================================

## Finds a node by name anywhere in the active scene or under self
func _find_target_node(node_name: String) -> Node:
	var n = get_node_or_null(node_name)
	if n:
		return n
	
	if has_node("%" + node_name):
		return get_node("%" + node_name)
		
	if get_tree() and get_tree().current_scene:
		if get_tree().current_scene.name == node_name:
			return get_tree().current_scene
		var found = get_tree().current_scene.find_child(node_name, true, false)
		if found:
			return found
			
	return null

# ==========================================
# ORDERED SLOT SETUP & VERIFICATION
# ==========================================

# ==========================================
# SPAWN HELPERS
# ==========================================

func _spawn_all_segments() -> void:
	print("--- SPAWN DEBUG START ---")
	print("Unordered Segments to spawn: ", unordered_segments.size())
	print("Spawn Markers found: ", spawns.size())
	
	var spawn_parent = _find_target_node("SpawnPoints")
	var parent_to_use = spawn_parent if spawn_parent else get_tree().current_scene

	for i in range(min(unordered_segments.size(), spawns.size())):
		print("Spawning segment ", i, " with ID: ", unordered_segments[i])
		var event_segment = segment.instantiate() as Control
		parent_to_use.add_child(event_segment)
		
		event_segment.global_position = spawns[i].global_position
		print("Set position to marker at: ", spawns[i].global_position)
		
		event_segment.setup(unordered_segments[i])
		print("Segment actual pixel size is: ", event_segment.size)
		
	print("--- SPAWN DEBUG END ---")

# ==========================================
# PUZZLE COMPLETION FLOW
# ==========================================

func handle_puzzle_completion(final_clue_timeline: String) -> void:
	Dialogic.start(final_clue_timeline)
	
	if not Dialogic.timeline_ended.is_connected(_on_clue_dialogue_finished):
		Dialogic.timeline_ended.connect(_on_clue_dialogue_finished)

func _on_clue_dialogue_finished() -> void:
	if Dialogic.timeline_ended.is_connected(_on_clue_dialogue_finished):
		Dialogic.timeline_ended.disconnect(_on_clue_dialogue_finished)
		
	var chapter_deduction: String = GameManager.current_chapter + "_deduction"
	Dialogic.start(chapter_deduction)
