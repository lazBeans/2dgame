## PURPOSE: Drop target control for the detective board workspace.
## Validates drag payloads and handles spawning card nodes onto the board canvas within boundary limits.
extends Control
class_name DropTarget

# ==========================================
# INITIALIZATION
# ==========================================

## Sets mouse filter rules and registers in the board_container group.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_to_group("board_container")

# ==========================================
# GUI DRAG-AND-DROP VALIDATION
# ==========================================

## Validates whether the item being dragged over the board container is acceptable.
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is TraySlot:
		return not data.is_empty()
	if data is DetectiveCardBase or data is EvidenceCard:
		return true
	return false

## Handles dropping accepted payloads onto the workspace board canvas.
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var board_scene: Node = _find_board_scene()
	if board_scene:
		if data is TraySlot:
			if board_scene.has_method("drop_evidence"):
				board_scene.drop_evidence(get_global_mouse_position(), data)
		elif data is DetectiveCardBase or data is EvidenceCard:
			drop_card_on_board(data, get_global_mouse_position())

# ==========================================
# CARD PLACEMENT & BOUNDARY CLAMPING
# ==========================================

## Called when an Area2D card is released over the board.
func receive_card(card: DetectiveCardBase) -> void:
	drop_card_on_board(card, get_global_mouse_position())

## Reparents and clamps an Area2D card within board boundaries.
func drop_card_on_board(card: DetectiveCardBase, drop_global_pos: Vector2) -> void:
	if card.get_parent() != self:
		if card.get_parent():
			card.get_parent().remove_child(card)
		add_child(card)

	var half_size: Vector2 = _get_card_half_size(card)
	var container_rect: Rect2 = get_global_rect()

	var target_pos: Vector2 = drop_global_pos
	target_pos.x = clamp(
		target_pos.x, 
		container_rect.position.x + half_size.x, 
		container_rect.position.x + container_rect.size.x - half_size.x
	)
	target_pos.y = clamp(
		target_pos.y, 
		container_rect.position.y + half_size.y, 
		container_rect.position.y + container_rect.size.y - half_size.y
	)

	card.global_position = target_pos

# ==========================================
# HELPER FUNCTIONS
# ==========================================

## Returns half dimensions for card boundary calculation based on card type.
func _get_card_half_size(card: DetectiveCardBase) -> Vector2:
	if card is EvidenceCard:
		return Vector2(250.0, 304.0)
	
	var col: CollisionShape2D = card.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col and col.shape and col.shape is RectangleShape2D:
		return col.shape.size / 2.0
		
	return Vector2(100.0, 100.0)

## Traverses up the scene tree to locate the parent DetectiveBoard controller.
func _find_board_scene() -> Node:
	var current_node: Node = self
	while current_node != null:
		if current_node is DetectiveBoard or current_node.has_method("drop_evidence"):
			return current_node
		current_node = current_node.get_parent()
		
	push_warning("DropTarget: Could not find DetectiveBoard Scene in parent tree.")
	return null
