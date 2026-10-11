## PURPOSE: Abstract base class for Area2D interactive detective board cards/segments.
## Manages mouse dragging mechanics, spatial depth re-ordering, and target drop-zone detection.
extends Area2D
class_name DetectiveCardBase

# ==========================================
# STATE & NODE REFERENCES
# ==========================================

## Indicates whether the card is currently being dragged by the mouse.
var is_dragging: bool = false

## Positional offset between the cursor position and the card's origin upon drag start.
var drag_offset: Vector2 = Vector2.ZERO

@export var card_size: Vector2 = Vector2(500.0, 608.0)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# ==========================================
# INITIALIZATION & INPUT PROCESSING
# ==========================================

## Enables input pickable state on ready.
func _ready() -> void:
	input_pickable = true

## Detects left-click mouse inputs on the Area2D collision shape to initiate dragging.
func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_dragging()

## Updates global position during mouse motion and handles release triggers while dragging.
func _input(event: InputEvent) -> void:
	if not is_dragging:
		return

	if event is InputEventMouseMotion:
		var target_pos = get_global_mouse_position() - drag_offset
		
		var container = get_parent()
		var container_rect: Rect2
		
		if container and container is Control and container.get_global_rect().size > Vector2.ZERO:
			container_rect = container.get_global_rect()
		else:
			container_rect = get_viewport().get_visible_rect()
		
		var half_size = card_size / 2.0
		
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
		
		global_position = target_pos
		
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		stop_dragging()

# ==========================================
# DRAGGING & DROP LOGIC
# ==========================================

## Initiates dragging state and moves the node to the front of its parent rendering order.
func start_dragging() -> void:
	is_dragging = true
	drag_offset = get_global_mouse_position() - global_position
	
	var parent_node: Node = get_parent()
	if parent_node:
		parent_node.move_child(self, parent_node.get_child_count() - 1)

## Ends dragging state and queries for slot or board container drop targets.
func stop_dragging() -> void:
	is_dragging = false
	
	var board: Node = get_tree().get_first_node_in_group("detective_board")
	if board and board.has_method("drop_card_on_board"):
		board.drop_card_on_board(self, global_position)

# ==========================================
# DROP TARGET DETECTION
# ==========================================

## Checks overlapping areas or UI drop rectangles on release.
func _check_drop_targets() -> void:
	
	var board: Node = get_tree().get_first_node_in_group("detective_board")
	if board and board.has_method("drop_card_on_board"):
		board.drop_card_on_board(self, global_position)
