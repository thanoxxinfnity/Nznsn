extends SceneTree
# Rigged character + Mixamo library: tracks match, bone moves, hips sahi jagah. cm-skeleton (mera rig) -> mixamo_anims.glb, meter-skeleton (Blender rig) -> mixamo_anims_m.glb
func _lib(path: String) -> AnimationLibrary:
	var r: Node = (load(path) as PackedScene).instantiate()
	var ap: AnimationPlayer = r.find_children("*", "AnimationPlayer", true, false)[0]
	var lib := AnimationLibrary.new()
	for n in ap.get_animation_list():
		lib.add_animation(n, ap.get_animation(n))
	return lib

func _init():
	var libs := {"cm": _lib("res://assets/anims/mixamo_anims.glb")}
	var dir := DirAccess.open("res://assets/rigged"); var ok := 0; var bad := 0
	for f in dir.get_files():
		if not f.ends_with(".glb"): continue
		var root: Node = (load("res://assets/rigged/" + f) as PackedScene).instantiate()
		get_root().add_child(root)
		var sk: Skeleton3D = root.find_children("*", "Skeleton3D", true, false)[0]
		var hips := sk.find_bone("mixamorig_Hips")
		var own := root.find_children("*", "AnimationPlayer", true, false)
		var kind := "baked" if own.size() > 0 else "cm"
		var ap: AnimationPlayer
		if kind == "baked":
			ap = own[0]
		else:
			ap = AnimationPlayer.new(); root.add_child(ap)
			ap.root_node = ap.get_path_to(root)
			ap.add_animation_library("", libs["cm"])
		var anim: Animation = ap.get_animation("ZombieWalk")
		print("   clips=", ap.get_animation_list().size())
		var found := 0
		for t in anim.get_track_count():
			var p := str(anim.track_get_path(t))
			if root.has_node(NodePath(p.split(":")[0])) and sk.find_bone(p.get_slice(":", 1)) >= 0: found += 1
		var arm := sk.find_bone("mixamorig_LeftArm")
		var before := sk.get_bone_pose_rotation(arm)
		ap.play("ZombieWalk"); ap.seek(1.0, true); ap.advance(0.0)
		var moved := not before.is_equal_approx(sk.get_bone_pose_rotation(arm))
		var hp := sk.get_bone_global_pose(hips).origin
		var res := moved and found > 40 and hp.length() < (300.0 if kind == "cm" else 3.0)
		print("ANIM ", f, " lib=", kind, " tracks=", found, "/", anim.get_track_count(), " moved=", moved, " hips=", hp, " ", "OK" if res else "BAD")
		if res: ok += 1
		else: bad += 1
	print("ANIMCHECK ok=", ok, " bad=", bad)
	quit()
