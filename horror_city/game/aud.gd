class_name Aud
extends RefCounted
# Chhote awaaz-helper: ek baar bajne wali 2D/3D awaaz, apne aap hat jaati hai.

static func play2d(parent: Node, snd: String, vol_db := 0.0, pitch := 1.0) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = Sfx.get_sound(snd)
	p.volume_db = vol_db
	p.pitch_scale = pitch
	parent.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
	return p

static func play3d(parent: Node, pos: Vector3, snd: String, vol_db := 0.0, pitch := 1.0, max_dist := 30.0) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = Sfx.get_sound(snd)
	p.volume_db = vol_db
	p.pitch_scale = pitch
	p.max_distance = max_dist
	p.unit_size = 4.0
	parent.add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	p.play()
	return p

static func loop3d(parent: Node, pos: Vector3, snd: String, vol_db := 0.0, max_dist := 25.0) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = Sfx.get_sound(snd)
	p.volume_db = vol_db
	p.max_distance = max_dist
	p.unit_size = 5.0
	parent.add_child(p)
	p.global_position = pos
	p.play()
	return p
