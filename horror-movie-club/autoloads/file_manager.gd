## PURPOSE: Acts as the central database singleton for the game.
## Loads, parses, and caches all JSON configuration files into memory on startup
## to provide instant, globally accessible data without repeated disk I/O.
extends Node
# ==========================================
# DATA CACHES
# ==========================================

var current_rm = RoomManager.current_room

## Caches pair connection mappings loaded from JSON.
var valid_connections: Dictionary = {}

## Caches scene file paths mapped by string key.
var scenes_data: Dictionary = {}

## Caches chapter deduction requirements and metadata.
var deduction_master_data: Dictionary = {}

var rooms: Dictionary = {}

var culprit_to_evidence: Dictionary = {}

# ==========================================
# INITIALIZATION
# ==========================================

## Called automatically on startup. Initializes all data caches from JSON files.
func _ready() -> void:
	load_connections_from_file("res://resources/json/case_connections.json")
	load_scenes_from_file("res://resources/json/scenes.json")
	load_deduction_master_from_file("res://resources/json/deduction_master_list.json")
	load_culprit_to_evidence("res://resources/json/culprit_to_evidence.json")
	load_rooms_from_file("res://resources/rooms/rooms.json")
	
# ==========================================
# DATA LOADING HELPERS
# ==========================================

## Opens a file at the given path, reads it as text, and parses it into a JSON Variant.
func load_json_file(path: String) -> Variant:
	if FileAccess.file_exists(path):
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file:
			var json_text: String = file.get_as_text()
			return JSON.parse_string(json_text)
	return null

## Parses the case connections JSON and caches it into the valid_connections dictionary.
func load_connections_from_file(path: String) -> void:
	var parsed_result: Variant = load_json_file(path)
	if parsed_result is Dictionary:
		valid_connections = parsed_result

## Parses the scenes JSON and caches it into the scenes_data dictionary.
func load_scenes_from_file(path: String) -> void:
	var parsed_result: Variant = load_json_file(path)
	if parsed_result is Dictionary:
		scenes_data = parsed_result

## Parses the deduction master JSON and caches it into the deduction_master_data dictionary.
func load_deduction_master_from_file(path: String) -> void:
	var parsed_result: Variant = load_json_file(path)
	if parsed_result is Dictionary:
		deduction_master_data = parsed_result
		
func load_culprit_to_evidence(path: String) -> void:
	var parsed_result: Variant = load_json_file(path)
	if parsed_result is Dictionary:
		culprit_to_evidence = parsed_result
			
## Parses the current room into an array.
func load_rooms_from_file(path: String) -> void:
	var parsed_result: Variant = load_json_file(path)
	if parsed_result is Dictionary:
		rooms = parsed_result

# ==========================================
# DATA GETTERS
# ==========================================

## Retrieves the file path for a specific scene key. Returns an empty string if not found.
func load_scene(scene: String) -> String:
	if scenes_data.has(scene):
		return scenes_data[scene]
	return ""

## Retrieves the required deduction segments for a specific chapter key.
func load_required_segments(chapter_key: String) -> Dictionary:
	if deduction_master_data.has(chapter_key):
		return deduction_master_data[chapter_key]
	return {}
	
func load_specific_culprit(culprit_id: String) -> Array:
	if culprit_to_evidence.has(culprit_id):
		return culprit_to_evidence[culprit_id]
	return []

func get_display_name() -> String:
	if rooms.has(current_rm):
		var room_data = rooms.get(current_rm)
		if room_data.has("display_name"):
			return room_data.get("display_name")
	return ""

func get_background() -> String:
	if rooms.has(current_rm):
		var room_data = rooms.get(current_rm)
		if room_data.has("path"):
			return room_data.get("path")
	return ""
			
