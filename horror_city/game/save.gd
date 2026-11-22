class_name Save
extends RefCounted
# Checkpoint: memory + disk (user://save.json). Scene reload / app band hone ke baad bhi bacha rehta hai.
static var data := {}
static var skip_menu := false   # death/retry ke baad seedha khel
const PATH := "user://save.json"

static func has() -> bool:
	return data.has("pos")

static func clear() -> void:
	data = {}
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))

static func write() -> void:
	var d := data.duplicate(true)
	if d.has("pos"):
		d["pos"] = [d.pos.x, d.pos.y, d.pos.z]
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))

static func read() -> bool:
	if not FileAccess.file_exists(PATH):
		return false
	var f := FileAccess.open(PATH, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if not (d is Dictionary) or not d.has("pos"):
		return false
	d["pos"] = Vector3(d.pos[0], d.pos[1], d.pos[2])
	d["yaw"] = float(d.get("yaw", 0.0))
	d["battery"] = float(d.get("battery", 100.0))
	var items := {}
	for k in d.get("items", {}):
		items[k] = int(d.items[k])
	d["items"] = items
	d["collected"] = d.get("collected", [])
	data = d
	return true

static func exists_on_disk() -> bool:
	return FileAccess.file_exists(PATH)
