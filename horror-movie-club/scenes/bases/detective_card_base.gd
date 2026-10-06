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
		global_position = get_global_mouse_position() - drag_offset
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
	
	# 1. Check UI Control slots first
	var slots: Array[Node] = get_tree().get_nodes_in_group("slots")
	for slot in slots:
		if slot is Control and slot.is_visible_in_tree():
			if slot.get_global_rect().has_point(get_global_mouse_position()):
				if slot.has_method("receive_card"):
					slot.receive_card(self)
					return

	# 2. Fall back to dropping onto the primary workspace board container
	var board: Node = get_tree().get_first_node_in_group("board_container")
	if board and board.has_method("drop_card_on_board"):
		board.drop_card_on_board(self, global_position)

# ==========================================
# DROP TARGET DETECTION
# ==========================================

## Checks overlapping areas or UI drop rectangles on release.
func _check_drop_targets() -> void:
	# 1. Check overlapping Area2D target regions
	var overlapping_areas: Array[Area2D] = get_overlapping_areas()
	for area in overlapping_areas:
		if area.has_method("receive_card"):
			area.receive_card(self)
			return

	# 2. Check UI Control slots
	var slots: Array[Node] = get_tree().get_nodes_in_group("slots")
	for slot in slots:
		if slot is Control and slot.is_visible_in_tree():
			if slot.get_global_rect().has_point(get_global_mouse_position()):
				if slot.has_method("receive_card"):
					slot.receive_card(self)
					return
