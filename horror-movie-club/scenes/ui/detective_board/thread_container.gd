## PURPOSE: Manages dynamic Line2D yarn connections on the detective board.
## Handles pin selection logic, temporary drag lines, connection validation, and line updates.
extends Control
class_name ThreadContainer

# ==========================================
# STATE & VISUAL VARIABLES
# ==========================================

var selected_pins: Array = []
var active_connections: Array = []
var valid_culprit_evidences: Array = []
var required_segments: Dictionary = {}
var valid_connections: Dictionary = {}

var line_parent: Node2D
var temp_line: Line2D
var permanent_lines: Array = []

# ==========================================
# INITIALIZATION
# ==========================================

## Sets up line rendering layers, fetches connection database resources, and creates drag lines.
func _ready() -> void:
	add_to_group("thread_container")
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE
	
	line_parent = Node2D.new()
	add_child(line_parent)
	
	if Engine.has_singleton("FileManager") or get_node_or_null("/root/FileManager"):
		valid_connections = FileManager.valid_connections
		required_segments = FileManager.load_required_segments(GameManager.current_chapter)
		
	temp_line = Line2D.new()
	temp_line.width = 4.0
	temp_line.default_color = Color("#e63946")
	temp_line.antialiased = true
	temp_line.z_index = 100
	temp_line.visible = false
	line_parent.add_child(temp_line)

# ==========================================
# PROCESS & FRAME UPDATES
# ==========================================

## Updates temporary and permanent line anchor positions each frame.
func _process(_delta: float) -> void:
	# 1. Update temporary line following the cursor during active pin selection
	if visible and selected_pins.size() == 1 and temp_line:
		var anchor_pin = selected_pins[0]["pin"] as Control
		if is_instance_valid(anchor_pin):
			var start_pos: Vector2 = line_parent.to_local(anchor_pin.get_global_rect().get_center())
			var mouse_pos: Vector2 = line_parent.to_local(get_viewport().get_mouse_position())
			temp_line.set_point_position(0, start_pos)
			temp_line.set_point_position(1, mouse_pos)
			
	# 2. Update permanent connection lines between pinned cards
	if visible:
		for i in range(permanent_lines.size() - 1, -1, -1):
			var item: Dictionary = permanent_lines[i]
			if is_instance_valid(item["pin_a"]) and is_instance_valid(item["pin_b"]):
				var card_a: EvidenceCard = item["pin_a"].get_parent() as EvidenceCard
				var card_b: EvidenceCard = item["pin_b"].get_parent() as EvidenceCard
				
				var is_card_moving: bool = (card_a and card_a.is_dragging) or (card_b and card_b.is_dragging)
				
				if is_card_moving:
					item["line"].visible = false
				else:
					item["line"].visible = true
					item["line"].set_point_position(0, line_parent.to_local(item["pin_a"].get_global_rect().get_center()))
					item["line"].set_point_position(1, line_parent.to_local(item["pin_b"].get_global_rect().get_center()))
			else:
				item["line"].queue_free()
				permanent_lines.remove_at(i)

# ==========================================
# INTERACTION & VALIDATION
# ==========================================

## Called by EvidenceCards when their pin button is clicked. Manages selection state.
func _on_pin_clicked(card_id: String, card_type:String, pin_node: Control) -> void:
	if not visible:
		return
		
	# First pin selected
	if selected_pins.size() == 0:
		selected_pins.append({"id": card_id, "type": card_type, "pin": pin_node})
		if temp_line:
			temp_line.visible = true
			var start_pos: Vector2 = line_parent.to_local(pin_node.get_global_rect().get_center())
			temp_line.clear_points()
			temp_line.add_point(start_pos)
			temp_line.add_point(start_pos)
		print("Anchor successfully set for: ", card_id)
		
	# Second pin selected
	elif selected_pins.size() == 1:
		var first_selection: Dictionary = selected_pins[0]
		
		if first_selection["pin"] == pin_node:
			reset_connection_state()
			return
			
		var second_selection := {"id": card_id, "type": card_type, "pin": pin_node}
		
		if first_selection["type"] == "evidence" and second_selection["type"] == "evidence":
			validate_and_resolve_connection(first_selection, second_selection)
			reset_connection_state()
		elif first_selection["type"] == "culprit":
			validate_culprit_connection(first_selection, second_selection)
			reset_connection_state()
		elif second_selection["type"] == "culprit":
			validate_culprit_connection(second_selection, first_selection)
			reset_connection_state()

## Validates if two selected pins form a valid evidence pair and triggers associated timelines/signals.
func validate_and_resolve_connection(pin_a: Dictionary, pin_b: Dictionary) -> void:
	var pair: Array = [pin_a["id"], pin_b["id"]]
	pair.sort()
	var connection_key: String = "%s:%s" % [pair[0], pair[1]]
	
	if not active_connections.has(connection_key):
		if valid_connections.has(connection_key):
			spawn_permanent_line(pin_a["pin"], pin_b["pin"])
			active_connections.push_back(connection_key)
			if Engine.has_singleton("Dialogic") or get_node_or_null("/root/Dialogic"):
				Dialogic.start(valid_connections[connection_key])
					
			if active_connections.size() == required_segments.size():
				if Engine.has_singleton("SignalBus") or get_node_or_null("/root/SignalBus"):
					SignalBus.all_segments_unlocked.emit(valid_connections[connection_key])

func validate_culprit_connection(culprit: Dictionary, evidence: Dictionary) -> void:
	valid_culprit_evidences = FileManager.load_specific_culprit(culprit["id"])
	
	if valid_culprit_evidences.size() > 0:
		if valid_culprit_evidences.has(evidence["id"]):
			valid_culprit_evidences.erase(evidence["id"])
			spawn_permanent_line(culprit["pin"], evidence["pin"])
	if valid_culprit_evidences.size() == 0:
		SignalBus.all_evidence_connected.emit()

# ==========================================
# VISUAL LINE RENDERING & CLEANUP
# ==========================================

## Creates a permanent Line2D node connected between two pin control positions.
func spawn_permanent_line(pin_a: Control, pin_b: Control) -> void:
	if not pin_a or not pin_b:
		return
		
	var perm_line := Line2D.new()
	perm_line.width = 6.0
	perm_line.default_color = Color("#e63946")
	perm_line.antialiased = true
	perm_line.z_index = 1 
	
	var start_pos: Vector2 = line_parent.to_local(pin_a.get_global_rect().get_center())
	var end_pos: Vector2 = line_parent.to_local(pin_b.get_global_rect().get_center())
	
	perm_line.add_point(start_pos)
	perm_line.add_point(end_pos)
	line_parent.add_child(perm_line)
	
	permanent_lines.append({
		"line": perm_line,
		"pin_a": pin_a,
		"pin_b": pin_b
	})

## Resets pin selections and hides the active dragging line.
func reset_connection_state() -> void:
	selected_pins.clear()
	if temp_line:
		temp_line.visible = false
		temp_line.clear_points()

## Removes all permanent lines and resets connection data.
func clear_lines() -> void:
	reset_connection_state()
	for item in permanent_lines:
		if is_instance_valid(item["line"]):
			item["line"].queue_free()
	permanent_lines.clear()
