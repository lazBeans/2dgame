extends Node

signal board_toggled(is_open: bool)

var current_room: String = ""

## Container node inside Game.tscn where room and deduction sub-scenes are loaded
var sub_scene_container: Node = null

## Currently instantiated sub-scene node
var current_sub_scene: Node = null

## Remembers the previous room path before entering deduction
var previous_room_path: String = ""

@export var default_scene_key: String = "roombase"

func _ready() -> void:
	# Delay scene initialization until Game.tscn is fully ready
	call_deferred("_initialize_default_scene")

func _initialize_default_scene() -> void:
	_ensure_container_reference()
	if sub_scene_container and current_sub_scene == null:
		change_sub_scene_by_key(default_scene_key)

## Dynamic lookup to locate WorldContainer in Game.tscn
func _ensure_container_reference() -> void:
	if sub_scene_container != null and is_instance_valid(sub_scene_container):
		return
		
	if get_tree() and get_tree().current_scene:
		if sub_scene_container == null and get_tree().current_scene.has_node("%WorldContainer"):
			sub_scene_container = get_tree().current_scene.get_node("%WorldContainer")

## Main entry point - accepts either a scenes.json key or direct "res://" path
func change_sub_scene(path_or_key: String) -> void:
	if path_or_key.begins_with("res://"):
		change_sub_scene_by_path(path_or_key)
	else:
		change_sub_scene_by_key(path_or_key)

## Load sub-scene by key mapped in scenes.json
func change_sub_scene_by_key(scene_key: String) -> void:
	var path: String = FileManager.load_scene(scene_key)
	if not path.is_empty():
		change_sub_scene_by_path(path)
	else:
		push_error("RoomManager: Key '" + scene_key + "' not found in scenes.json")

## Swap sub-scene inside WorldContainer
func change_sub_scene_by_path(scene_path: String) -> void:
	_ensure_container_reference()
	
	if sub_scene_container == null:
		push_error("RoomManager ERROR: 'sub_scene_container' could not be found!")
		return

	# 1. Save current room path if not deduction
	if current_sub_scene and is_instance_valid(current_sub_scene):
		var current_path = current_sub_scene.scene_file_path
		if not current_path.ends_with("Deduction.tscn"):
			previous_room_path = current_path
		
		current_sub_scene.queue_free()
		current_sub_scene = null

	# 2. Instantiate and attach new scene
	var packed_scene = load(scene_path) as PackedScene
	if not packed_scene:
		push_error("RoomManager: Failed to load scene at path: " + scene_path)
		return

	var new_scene = packed_scene.instantiate()
	sub_scene_container.add_child(new_scene)
	current_sub_scene = new_scene

	# 3. Setup layout/visibility for new scene
	if new_scene is Control:
		new_scene.visible = true
		new_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
	if new_scene.has_method("activate_deduction"):
		new_scene.activate_deduction()

	# 4. Wait 1 frame until the new scene renders on screen, THEN hide the board
	await get_tree().process_frame
	_hide_detective_board()
	
## Helper function to locate and hide the Detective Board
func _hide_detective_board() -> void:
	var board: Node = get_tree().get_first_node_in_group("detective_board")
	
	if board == null and get_tree().current_scene:
		if get_tree().current_scene.has_node("%DetectiveBoard"):
			board = get_tree().current_scene.get_node("%DetectiveBoard")
		else:
			board = get_tree().current_scene.find_child("DetectiveBoard", true, false)
		
	if board:
		board.visible = false
		if board.has_signal("board_toggled"):
			board.board_toggled.emit(false)
