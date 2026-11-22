class_name HideSpot
extends Node3D
# Almari/locker jisme chhup sakte ho. face_yaw = andar se bahar ki taraf dekhne ka kon.
var face_yaw := 0.0
var label := "अलमारी में छुपो"
var occupied := false

static func make(parent: Node, file: String, pos: Vector3, rot_deg: float, size: Vector3) -> HideSpot:
	var h := HideSpot.new()
	h.position = pos
	h.rotation_degrees.y = rot_deg
	parent.add_child(h)
	Build.prop(h, file, Vector3.ZERO, 0.0, 1.0, true)
	# prop ka saamne wala hissa +Z maana: bahar dekhne ka kon
	h.face_yaw = deg_to_rad(rot_deg) + PI
	Interactable.make(h, Vector3(0, size.y / 2.0, size.z / 2.0 + 0.05), Vector3(size.x, size.y, 0.3), func(p): return "" if p.hidden else h.label, func(p): h._enter(p))
	h.add_to_group("hide_spots")
	return h

func _enter(p) -> void:
	occupied = true
	p.hide_in(self)

func exit_pos() -> Vector3:
	return global_position + global_basis * Vector3(0, 0, 1.0)
