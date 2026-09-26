extends Control

var active_line: Line2D = null
var source_card: Control = null

# (When spawning your cards onto the board, make sure to connect their signal like this:)
# card.connect("start_drawing_string", _on_evidence_card_start_drawing)

func _on_evidence_card_start_drawing(card: Control, pin_pos: Vector2) -> void:
	source_card = card

	active_line = Line2D.new()
	active_line.default_color = Color.RED
	active_line.width = 4.0

	active_line.add_point(pin_pos) # Start point
	active_line.add_point(pin_pos) # End point (follows mouse)

	add_child(active_line)

func _input(event: InputEvent) -> void:
	if active_line != null and event is InputEventMouseMotion:
		active_line.set_point_position(1, get_global_mouse_position())
