extends Control

func _can_drop_data(at_position, data):
	if owner and owner.has_method("can_drop_evidence"):
		return owner.can_drop_evidence(data)
	return false

func _drop_data(at_position, data):
	if owner and owner.has_method("drop_evidence"):
		owner.drop_evidence(at_position, data)
