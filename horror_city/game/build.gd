class_name Build
extends RefCounted
# Level banane ke helper: deewar (darwaze ki jagah chhodke), farsh, props (GLB + collision), roshni.
const H := 3.4

static func box(parent: Node, center: Vector3, size: Vector3, mat: Material, collide := true, nm := "") -> Node3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	if not collide:
		mi.position = center
		if nm != "":
			mi.name = nm
		parent.add_child(mi)
		return mi
	var sb := StaticBody3D.new()
	sb.position = center
	sb.collision_layer = 1
	sb.collision_mask = 0
	sb.add_to_group("navsource")
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	sb.add_child(cs)
	sb.add_child(mi)
	if nm != "":
		sb.name = nm
	parent.add_child(sb)
	return sb

# X ke saath deewar (z fixed). openings: [{c:center_x, w:width, h:height}]
static func wall_x(parent: Node, z: float, x0: float, x1: float, mat: Material, openings: Array = [], h := H, th := 0.3) -> void:
	var ops := openings.duplicate()
	ops.sort_custom(func(a, b): return a.c < b.c)
	var cur := x0
	for o in ops:
		var a: float = o.c - o.w / 2.0
		var b: float = o.c + o.w / 2.0
		if a > cur + 0.001:
			box(parent, Vector3((cur + a) / 2.0, h / 2.0, z), Vector3(a - cur, h, th), mat)
		if o.h < h:
			box(parent, Vector3(o.c, (o.h + h) / 2.0, z), Vector3(o.w, h - o.h, th), mat)
		cur = b
	if x1 > cur + 0.001:
		box(parent, Vector3((cur + x1) / 2.0, h / 2.0, z), Vector3(x1 - cur, h, th), mat)

# Z ke saath deewar (x fixed)
static func wall_z(parent: Node, x: float, z0: float, z1: float, mat: Material, openings: Array = [], h := H, th := 0.3) -> void:
	var ops := openings.duplicate()
	ops.sort_custom(func(a, b): return a.c < b.c)
	var cur := z0
	for o in ops:
		var a: float = o.c - o.w / 2.0
		var b: float = o.c + o.w / 2.0
		if a > cur + 0.001:
			box(parent, Vector3(x, h / 2.0, (cur + a) / 2.0), Vector3(th, h, a - cur), mat)
		if o.h < h:
			box(parent, Vector3(x, (o.h + h) / 2.0, o.c), Vector3(th, h - o.h, o.w), mat)
		cur = b
	if z1 > cur + 0.001:
		box(parent, Vector3(x, h / 2.0, (cur + z1) / 2.0), Vector3(th, h, z1 - cur), mat)

static func floor_(parent: Node, x0: float, z0: float, x1: float, z1: float, mat: Material, y := 0.0) -> void:
	box(parent, Vector3((x0 + x1) / 2.0, y - 0.15, (z0 + z1) / 2.0), Vector3(x1 - x0, 0.3, z1 - z0), mat)

static func ceiling(parent: Node, x0: float, z0: float, x1: float, z1: float, mat: Material, h := H) -> void:
	box(parent, Vector3((x0 + x1) / 2.0, h + 0.15, (z0 + z1) / 2.0), Vector3(x1 - x0, 0.3, z1 - z0), mat)

static func _aabb(n: Node, xf: Transform3D) -> AABB:
	var res := AABB()
	var have := false
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		res = xf * (n as MeshInstance3D).mesh.get_aabb()
		have = true
	for c in n.get_children():
		if c is Node3D:
			var sub := _aabb(c, xf * (c as Node3D).transform)
			if sub.size != Vector3.ZERO:
				res = sub if not have else res.merge(sub)
				have = true
	return res

static func prop(parent: Node, file: String, pos: Vector3, rot_deg := 0.0, sc := 1.0, collide := true) -> Node3D:
	var path := "res://assets/props/%s.glb" % file
	if not ResourceLoader.exists(path):
		push_error("prop missing: " + file)
		return null
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation_degrees.y = rot_deg
	holder.scale = Vector3.ONE * sc
	holder.name = file
	var inst := (load(path) as PackedScene).instantiate() as Node3D
	holder.add_child(inst)
	parent.add_child(holder)
	if collide:
		var bb := _aabb(inst, inst.transform)
		if bb.size.x > 0.05 and bb.size.z > 0.05 and bb.size.y > 0.15:
			var sb := StaticBody3D.new()
			sb.collision_layer = 1
			sb.collision_mask = 0
			sb.add_to_group("navsource")
			var cs := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = bb.size * 0.92
			cs.shape = bs
			cs.position = bb.get_center()
			sb.add_child(cs)
			holder.add_child(sb)
	return holder

static func lamp(parent: Node, pos: Vector3, color: Color, energy: float, rng: float, flicker := 0.0, zone := "", bulb := true) -> Lamp:
	var l := Lamp.new()
	l.position = pos
	l.light_color = color
	l.base_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.4
	l.flicker = flicker
	l.zone = zone
	parent.add_child(l)
	if bulb:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.07
		sm.height = 0.14
		mi.mesh = sm
		mi.material_override = Mats.solid(color, 0.4, 3.0)
		l.add_child(mi)
		l.bulb = mi
	return l

static func tube(parent: Node, pos: Vector3, color: Color, energy: float, rng: float, flicker := 0.0, zone := "", along_x := true) -> Lamp:
	var l := Lamp.new()
	l.position = pos
	l.light_color = color
	l.base_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.3
	l.flicker = flicker
	l.zone = zone
	parent.add_child(l)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.2, 0.06, 0.12) if along_x else Vector3(0.12, 0.06, 1.2)
	mi.mesh = bm
	mi.material_override = Mats.solid(color, 0.4, 2.5)
	l.add_child(mi)
	l.bulb = mi
	return l
