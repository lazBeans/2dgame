## PURPOSE: Acts as a drop target zone for the detective board workspace.
## Validates incoming drag payloads (like tray items) and facilitates spawning 
## physical EvidenceCards onto the board canvas at the drop coordinates.
extends Control
class_name DropTarget

# ==========================================
# INITIALIZATION
# ==========================================

## Sets mouse filtering rules to ensure container drop events register properly.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS

# ==========================================
# DRAG-AND-DROP VALIDATION & DROPPING
# ==========================================

## Validates if the item being dragged over the board container is acceptable.
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is TraySlot:
		return not data.is_empty()
		
	if data is EvidenceCard:
		return true
		
	return false

## Executes when an accepted payload is dropped, spawning a card or updating its position.
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var board_scene = _find_board_scene()
	
	if board_scene:
		if data is TraySlot:
			if board_scene.has_method("drop_evidence"):
				# Use global mouse position directly to avoid any to_global() parse errors
				board_scene.drop_evidence(get_global_mouse_position(), data)
				
		elif data is EvidenceCard:
			var container_rect = get_global_rect()
			var card_size = data.size if data.size != Vector2.ZERO else data.custom_minimum_size
			
			var global_drop_pos = get_global_mouse_position()
			var target_pos = global_drop_pos - (card_size / 2.0)
			
			# Clamp within container bounds using pure global coordinates
			target_pos.x = clamp(target_pos.x, container_rect.position.x, container_rect.position.x + container_rect.size.x - card_size.x)
			target_pos.y = clamp(target_pos.y, container_rect.position.y, container_rect.position.y + container_rect.size.y - card_size.y)
			
			data.global_position = target_pos

# ==========================================
# HELPER FUNCTIONS
# ==========================================

## Recursively traverses up the scene tree to locate the parent DetectiveBoard controller.
func _find_board_scene() -> Node:
	var current_node = self
	while current_node != null:
		if current_node is DetectiveBoard or current_node.has_method("drop_evidence"):
			return current_node
		current_node = current_node.get_parent()
		
	push_warning("DropTarget: Could not find DetectiveBoardScene in parent tree.")
	return null
