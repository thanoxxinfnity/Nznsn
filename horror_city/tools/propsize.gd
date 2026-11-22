extends SceneTree
# Props ka size (m) print karo: godot --headless --path horror_city --script res://tools/propsize.gd -- NAME1 NAME2
func _aabb(n: Node, xf: Transform3D) -> AABB:
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
func _init():
	for nm in OS.get_cmdline_user_args():
		var path := "res://assets/props/%s.glb" % nm
		if not ResourceLoader.exists(path):
			print("SIZE ", nm, " MISSING")
			continue
		var n: Node3D = (load(path) as PackedScene).instantiate()
		var bb := _aabb(n, Transform3D.IDENTITY)
		print("SIZE ", nm, " size=", bb.size, " min=", bb.position)
	quit()
