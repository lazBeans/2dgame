## Script Purpose: Handles drop target validation and drop execution for UI elements on the detective board.
extends Control

## Validates whether dragged data can be dropped onto this container.
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if owner and owner.has_method("can_drop_evidence"):
		return owner.can_drop_evidence(data)
	return false

## Executes the drop action when valid data is dropped onto the container.
func _drop_data(at_position: Vector2, data: Variant) -> void:
	if owner and owner.has_method("drop_evidence"):
		owner.drop_evidence(at_position, data)
