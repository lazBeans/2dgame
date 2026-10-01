extends Node

var valid_connections: Dictionary = {}
var location: String = ""

## Loads valid connection rules from a JSON file.
func load_connections_from_file(path: String) -> void:
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json_text = file.get_as_text()
		var parsed_result = JSON.parse_string(json_text)
		if parsed_result is Dictionary:
			valid_connections = parsed_result
			print("Successfully loaded ", valid_connections.size(), " connection rules.")

## Loads valid scene from a JSON file.
func load_scene(scene: String) -> String:
	var file_path = "res://resources/scenes.json"
	
	if not FileAccess.file_exists(file_path):
		push_error("FileManager: Scene data JSON file not foud for ", scene)
		return ""
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_text = file.get_as_text()
	var json_data = JSON.parse_string(json_text)
	
	if json_data == null or not json_data is Dictionary:
		print("Error: Failed to parse JSON or data is not a dictionary.")
		return ""
		
	if json_data.has(scene):
		return json_data[scene]
			
	print("Error: '", scene, "' not found.")
	return ""
			
## Loads required puzzle solution segments for the specified chapter key.
func load_required_segments(chapter_key: String) -> Array:
	var file_path = "res://resources/deduction_master_list.json"
	
	if not FileAccess.file_exists(file_path):
		print("Error: Case data JSON file not found at ", file_path)
		return []
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_text = file.get_as_text()
	var json_data = JSON.parse_string(json_text)
	
	if json_data == null or not json_data is Dictionary:
		print("Error: Failed to parse JSON or data is not a dictionary.")
		return []
		
	if json_data.has(chapter_key):
		var chapter_data = json_data[chapter_key]
		if chapter_data.has("required_segments"):
			return chapter_data["required_segments"]
			
	print("Error: Chapter key '", chapter_key, "' or 'required_segments' not found.")
	return []
