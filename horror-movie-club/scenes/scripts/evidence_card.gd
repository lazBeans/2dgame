extends Control

signal start_drawing_string(card: Control, pin_global_position: Vector2)
@onready var pin_button: TextureButton = $PinButton

func _ready() -> void:
	pin_button.button_down.connect(_on_pin_button_down)

func _on_pin_button_down() -> void:
	var pin_pos = pin_button.global_position + (pin_button.size / 2.0)
	emit_signal("start_drawing_string", self, pin_pos)
