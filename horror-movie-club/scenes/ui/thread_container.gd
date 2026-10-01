## Script Purpose: Manages yarn thread lines between evidence card pins, validates 
## connection rules against configuration data, and coordinates puzzle completion states.
extends Control
class_name ThreadContainer

signal all_segments_unlocked(connection_data)

var selected_pins: Array = []
var active_connections: Array = []
var required_segments: Array = []
var valid_connections: Dictionary = {}
var line_parent: Node2D
var temp_line: Line2D
var permanent_lines: Array = []

## Called when node enters the tree; initializes thread containers and loads connection rules.
func _ready() -> void:
	add_to_group("thread_container")
	visible = false
	
	line_parent = Node2D.new()
	add_child(line_parent)
	
	FileManager.load_connections_from_file("res://resources/case_connections.json")
	valid_connections = FileManager.valid_connections
	
	required_segments = FileManager.load_required_segments(GameManager.current_chapter)
	
	temp_line = Line2D.new()
	temp_line.width = 4.0
	temp_line.default_color = Color("#e63946")
	temp_line.antialiased = true
	temp_line.z_index = 100
	temp_line.visible = false
	line_parent.add_child(temp_line)

## Process loop updating temporary dragging lines and dynamic permanent line positions.
func _process(_delta: float) -> void:
	if visible and selected_pins.size() == 1 and temp_line:
		var anchor_pin = selected_pins[0]["pin"] as Control
		if is_instance_valid(anchor_pin):
			var start_pos = anchor_pin.get_global_rect().get_center()
			var mouse_pos = get_viewport().get_mouse_position()
			temp_line.set_point_position(0, start_pos)
			temp_line.set_point_position(1, mouse_pos)
			
	if visible:
		for i in range(permanent_lines.size() - 1, -1, -1):
			var item = permanent_lines[i]
			if is_instance_valid(item["pin_a"]) and is_instance_valid(item["pin_b"]):
				var card_a = item["pin_a"].get_parent() as EvidenceCard
				var card_b = item["pin_b"].get_parent() as EvidenceCard
				
				var is_card_moving = (card_a and card_a.is_dragging) or (card_b and card_b.is_dragging)
				
				if is_card_moving:
					item["line"].visible = false
				else:
					item["line"].visible = true
					item["line"].set_point_position(0, item["pin_a"].get_global_rect().get_center())
					item["line"].set_point_position(1, item["pin_b"].get_global_rect().get_center())
			else:
				item["line"].queue_free()
				permanent_lines.remove_at(i)

## Handles pin click events to anchor or complete a thread connection between two pins.
func _on_pin_clicked(card_id: String, pin_node: Control) -> void:
	if not visible:
		return
		
	if selected_pins.size() == 0:
		selected_pins.append({"id": card_id, "pin": pin_node})
		if temp_line:
			temp_line.visible = true
			var start_pos = pin_node.get_global_rect().get_center()
			temp_line.clear_points()
			temp_line.add_point(start_pos)
			temp_line.add_point(start_pos)
		print("Anchor set: ", card_id)
		
	elif selected_pins.size() == 1:
		var first_selection = selected_pins[0]
		
		if first_selection["pin"] == pin_node:
			reset_connection_state()
			return
			
		var second_selection = {"id": card_id, "pin": pin_node}
		validate_and_resolve_connection(first_selection, second_selection)
		reset_connection_state()

## Validates whether the selected pin pair forms a correct connection.
func validate_and_resolve_connection(pin_a: Dictionary, pin_b: Dictionary) -> void:
	var pair = [pin_a["id"], pin_b["id"]]
	pair.sort()
	var connection_key = "%s:%s" % [pair[0], pair[1]]
	
	if not active_connections.has(connection_key):
		if valid_connections.has(connection_key):
			print("SUCCESS! Unlocked: ", valid_connections[connection_key])
			spawn_permanent_line(pin_a["pin"], pin_b["pin"])
			active_connections.push_back(connection_key)
					
			Dialogic.start(valid_connections[connection_key])
					
			if active_connections.size() == required_segments.size():
				all_segments_unlocked.emit(valid_connections[connection_key])

## Spawns a permanent yarn Line2D between two connected pins.
func spawn_permanent_line(pin_a: Control, pin_b: Control) -> void:
	if not pin_a or not pin_b:
		print("ERROR: Cannot spawn line, missing pins!")
		return
		
	var perm_line = Line2D.new()
	perm_line.width = 6.0
	perm_line.default_color = Color("#e63946")
	perm_line.antialiased = true
	perm_line.z_index = 1  # <--- Changed from -1 to 1 so it renders above the background!
	
	var start_pos = pin_a.get_global_rect().get_center()
	var end_pos = pin_b.get_global_rect().get_center()
	
	perm_line.add_point(start_pos)
	perm_line.add_point(end_pos)
	
	line_parent.add_child(perm_line)
	
	permanent_lines.append({
		"line": perm_line,
		"pin_a": pin_a,
		"pin_b": pin_b
	})
	
	print("SUCCESS: Permanent Line2D spawned from ", start_pos, " to ", end_pos)

## Resets active temporary connection states.
func reset_connection_state() -> void:
	selected_pins.clear()
	if temp_line:
		temp_line.visible = false
		temp_line.clear_points()

## Clears all active lines and resets connection states.
func clear_lines() -> void:
	reset_connection_state()
	for item in permanent_lines:
		if is_instance_valid(item["line"]):
			item["line"].queue_free()
	permanent_lines.clear()
