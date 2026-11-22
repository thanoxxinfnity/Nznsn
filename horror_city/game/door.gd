class_name Door
extends Node3D
# Hinge par khulne wala darwaza: closed/open tween, locked + chaabi, monster khud khol sakta hai.
signal opened
var width := 1.1
var height := 2.3
var locked := false
var key_id := ""
var lock_msg := Tr.t("The door is locked. You need a key.")
var metal := true
var is_open := false
var pivot: Node3D
var _tw: Tween
var _inter: Interactable
var _blocker: StaticBody3D
var _snd: AudioStreamPlayer3D
var open_angle := 98.0

# along_x: deewar X ke saath hai (darwaza Z-normal)
static func make(parent: Node, pos: Vector3, along_x: bool, width_ := 1.1, height_ := 2.3, metal_ := true) -> Door:
	var d := Door.new()
	d.width = width_
	d.height = height_
	d.metal = metal_
	d.position = pos
	d.rotation_degrees.y = 0.0 if along_x else 90.0
	parent.add_child(d)
	return d

func _ready() -> void:
	add_to_group("doors")
	pivot = Node3D.new()
	pivot.position = Vector3(-width / 2.0, 0.0, 0.0)
	add_child(pivot)
	var mat := Mats.door_metal() if metal else Mats.door_wood()
	var slab := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width - 0.04, height - 0.03, 0.07)
	slab.mesh = bm
	slab.material_override = mat
	slab.position = Vector3(width / 2.0, height / 2.0, 0.0)
	pivot.add_child(slab)
	# haath ka handle (dono taraf)
	for s in [-1.0, 1.0]:
		var hm := MeshInstance3D.new()
		var hb := BoxMesh.new()
		hb.size = Vector3(0.16, 0.035, 0.05)
		hm.mesh = hb
		hm.material_override = Mats.solid(Color(0.55, 0.48, 0.3), 0.35)
		hm.material_override.metallic = 0.8
		hm.position = Vector3(width - 0.2, 1.05, 0.07 * s)
		pivot.add_child(hm)
	# patti (panel) ubhar
	var pm := MeshInstance3D.new()
	var pb := BoxMesh.new()
	pb.size = Vector3(width - 0.3, height * 0.55, 0.09)
	pm.mesh = pb
	pm.material_override = mat
	pm.position = Vector3(width / 2.0, height * 0.55, 0.0)
	pivot.add_child(pm)
	# rokne wala (player ko) — layer 16
	_blocker = StaticBody3D.new()
	_blocker.collision_layer = 16
	_blocker.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(width - 0.04, height - 0.03, 0.12)
	cs.shape = bs
	_blocker.add_child(cs)
	_blocker.position = slab.position
	pivot.add_child(_blocker)
	_inter = Interactable.make(pivot, slab.position, Vector3(width, height, 0.25), _prompt, _use)
	_snd = AudioStreamPlayer3D.new()
	_snd.max_distance = 28.0
	_snd.unit_size = 5.0
	_snd.position = Vector3(0, 1.2, 0)
	add_child(_snd)

func _prompt(p) -> String:
	if locked:
		return Tr.t("Locked door")
	return Tr.t("Close door") if is_open else Tr.t("Open door")

func _use(p) -> void:
	if locked:
		if key_id != "" and p.has_item(key_id):
			locked = false
			Aud.play2d(p, "click", -3.0)
			if p.hud:
				p.hud.toast(Tr.t("Door unlocked"))
		else:
			_snd.stream = Sfx.get_sound("door_locked")
			_snd.play()
			if p.hud:
				p.hud.toast(lock_msg)
			_rattle()
			return
	toggle(p.global_position)

func _rattle() -> void:
	var tw := create_tween()
	tw.tween_property(pivot, "rotation:y", deg_to_rad(1.8), 0.05)
	tw.tween_property(pivot, "rotation:y", deg_to_rad(-1.2), 0.05)
	tw.tween_property(pivot, "rotation:y", 0.0, 0.06)

func toggle(from_pos: Vector3) -> void:
	if is_open:
		close()
	else:
		open_away_from(from_pos)

func open_away_from(from_pos: Vector3) -> void:
	if is_open:
		return
	var lp := to_local(from_pos)
	var sgn := 1.0 if lp.z > 0.0 else -1.0
	_swing(sgn * deg_to_rad(open_angle), 0.9)
	is_open = true
	_snd.stream = Sfx.get_sound("door_creak")
	_snd.pitch_scale = randf_range(0.9, 1.1)
	_snd.play()
	_blocker.collision_layer = 0
	opened.emit()

func close(slam := false) -> void:
	if not is_open and not slam:
		return
	_swing(0.0, 0.18 if slam else 0.8)
	is_open = false
	_blocker.collision_layer = 16
	if slam:
		get_tree().create_timer(0.17).timeout.connect(func():
			_snd.stream = Sfx.get_sound("door_slam")
			_snd.pitch_scale = 1.0
			_snd.play())
	else:
		_snd.stream = Sfx.get_sound("door_creak")
		_snd.pitch_scale = 0.8
		_snd.play()

func _swing(angle: float, t: float) -> void:
	if _tw:
		_tw.kill()
	_tw = create_tween()
	_tw.tween_property(pivot, "rotation:y", angle, t).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func monster_open(from_pos: Vector3) -> void:
	if not is_open:
		locked = false
		open_away_from(from_pos)
