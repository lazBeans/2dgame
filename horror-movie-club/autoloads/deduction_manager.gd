## PURPOSE: Manages sequence-based puzzle completion routines and coordinates 
## chained dialogue events between clue resolutions and chapter deductions.
extends Control

# ==========================================
# EXPORT & STATE VARIABLES
# ==========================================

## Scene resource assigned in the Inspector for ordered slot placements.
@export var slot_scene: PackedScene

## Identifier string of the current chapter loaded from GameManager.
var current_ch: String = GameManager.current_chapter

## Array of required event segment IDs for the current chapter sequence.
var master_evidences: Dictionary = FileManager.load_required_segments(current_ch)
var master_clues: Array = []

## Preloaded EventSegment scene used for instantiation.
var segment: PackedScene = preload("res://scenes/components/EventSegment.tscn")

## Unordered segment identifiers available to be spawned on the board.
var options: Array = []

## Array of Marker2D or Node spawn point locations found in the scene tree.
var spawns: Array = []

var current_clue: String = ""

# ==========================================
# INITIALIZATION
# ==========================================

## Fetches board markers, sets up slots, and spawns available event segments.
func _ready() -> void:
	visible = false
	initialize_deduction()

## Initializes the deduction stage manually or on startup.
func initialize_deduction() -> void:
	# 1. Fetch spawn point markers
	var spawn_container: Node = _find_target_node("SpawnPoints")
	if spawn_container:
		spawns = spawn_container.get_children()
	else:
		spawns = get_tree().get_nodes_in_group("spawn_points")
	
	# 3. Create a master ordered clues list
	if not master_evidences.is_empty():
		master_clues = master_evidences.keys()
			
		current_clue = master_clues.pop_front()
	
	# 4. Spawn cards onto the board canvas
	if not master_clues.is_empty():
		_spawn_all_segments()

# ==========================================
# SEARCH HELPER
# ==========================================

## Finds a node by name anywhere in the active scene tree or relative to self.
func _find_target_node(node_name: String) -> Node:
	var n: Node = get_node_or_null(node_name)
	if n:
		return n
	
	if has_node("%" + node_name):
		return get_node("%" + node_name)
		
	if get_tree() and get_tree().current_scene:
		if get_tree().current_scene.name == node_name:
			return get_tree().current_scene
		var found: Node = get_tree().current_scene.find_child(node_name, true, false)
		if found:
			return found
			
	return null

# ==========================================
# SPAWN HELPERS
# ==========================================

## Instantiates and places EventSegment instances at available spawn points.
func _spawn_all_segments() -> void:
	print("--- SPAWN DEBUG START ---")
	print("Unordered Segments to spawn: ", options.size())
	print("Spawn Markers found: ", spawns.size())

	if segment == null:
		push_error("DeductionManager ERROR: 'segment' PackedScene is not assigned in the Inspector!")
		return

	var spawn_parent = _find_target_node("SpawnPoints")
	var parent_to_use = spawn_parent if spawn_parent else get_tree().current_scene
	
	_deduction_phase(current_clue)
	
	for i in range(spawns.size()):
		print("Spawning segment ", i, " with ID: ", options[i])
		
		# 1. Instantiate without strict type-casting that can resolve to null
		var event_segment = segment.instantiate()
		
		if not event_segment:
			push_error("Failed to instantiate segment scene for index: " + str(i))
			continue
			
		# 2. Add to scene tree first
		parent_to_use.add_child(event_segment)
		event_segment.z_index = 10
		
		# 3. Assign global position safely
		if spawns[i]:
			event_segment.global_position = spawns[i].global_position
			event_segment.rotation = spawns[i].global_rotation
			print("Set position to marker at: ", spawns[i].global_position)
		
		# 4. Initialize card data
		if event_segment.has_method("setup"):
			event_segment.setup(options[i])
			
	print("--- SPAWN DEBUG END ---")
	
func _deduction_phase(evidence_id: String) -> void:
	if not options.is_empty():
		options.clear()
	if options.is_empty():
		options.append(master_evidences.get(evidence_id).get("correct"))
		options.append(master_evidences.get(evidence_id).get("wrong"))
	options.shuffle()
	for option in options:
		print("Option: ", option)
		
# ==========================================
# PUZZLE COMPLETION FLOW
# ==========================================

## Triggers the final clue timeline and connects listener for chapter deduction dialogue.
func handle_puzzle_completion(final_clue_timeline: String) -> void:
	Dialogic.start(final_clue_timeline)
	
	if not Dialogic.timeline_ended.is_connected(_on_clue_dialogue_finished):
		Dialogic.timeline_ended.connect(_on_clue_dialogue_finished)

## Called when clue dialogue finishes to initiate the chapter's master deduction sequence.
func _on_clue_dialogue_finished() -> void:
	if Dialogic.timeline_ended.is_connected(_on_clue_dialogue_finished):
		Dialogic.timeline_ended.disconnect(_on_clue_dialogue_finished)
		
	var chapter_deduction: String = GameManager.current_chapter + "_deduction"
	Dialogic.start(chapter_deduction)
