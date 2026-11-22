class_name Save
extends RefCounted
# Checkpoint (scene reload ke baad bhi bacha rehta hai).
static var data := {}

static func has() -> bool:
	return data.has("pos")

static func clear() -> void:
	data = {}
