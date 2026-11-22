class_name Settings
extends RefCounted
# Awaaz / sensitivity / quality. user://settings.json mein save hota hai.
static var quality := 1        # 0 kam, 1 madhyam, 2 uchch
static var sens := 1.0
static var volume := 0.9
const PATH := "user://settings.json"

static func load_() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		quality = int(d.get("quality", quality))
		sens = float(d.get("sens", sens))
		volume = float(d.get("volume", volume))

static func save_() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"quality": quality, "sens": sens, "volume": volume}))

static func apply(vp: Viewport, level, player) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(volume, 0.0001, 1.0)))
	if vp:
		vp.scaling_3d_scale = [0.7, 0.85, 1.0][quality]
		vp.msaa_3d = Viewport.MSAA_2X if quality == 2 else Viewport.MSAA_DISABLED
	if player:
		player.torch.shadow_enabled = quality >= 1
	if level:
		if level._rain:
			level._rain.amount = [200, 450, 700][quality]
		if level._env:
			level._env.glow_enabled = quality >= 1
