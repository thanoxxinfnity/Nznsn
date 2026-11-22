extends SceneTree
# Godot mein rigged character + Mixamo library: animations chalti hain ya nahi. Use: --script res://tools/anim_test.gd
func _init():
	var lib_root: Node = (load("res://assets/anims/mixamo_anims.glb") as PackedScene).instantiate()
	var lap: AnimationPlayer = lib_root.find_children("*", "AnimationPlayer", true, false)[0]
	var lib := AnimationLibrary.new()
	for n in lap.get_animation_list():
		lib.add_animation(n, lap.get_animation(n))
	var dir := DirAccess.open("res://assets/rigged"); var ok := 0; var bad := 0
	for f in dir.get_files():
		if not f.ends_with(".glb"): continue
		var root: Node = (load("res://assets/rigged/" + f) as PackedScene).instantiate()
		get_root().add_child(root)
		var ap := AnimationPlayer.new(); root.add_child(ap)
		ap.root_node = ap.get_path_to(root)
		ap.add_animation_library("", lib)
		var sk: Skeleton3D = root.find_children("*", "Skeleton3D", true, false)[0]
		var hips := sk.find_bone("mixamorig_Hips")
		var anim: Animation = ap.get_animation("ZombieWalk")
		var found := 0
		for t in anim.get_track_count():
			var p := str(anim.track_get_path(t))
			var np := NodePath(p.split(":")[0])
			if root.has_node(np) and sk.find_bone(p.get_slice(":", 1)) >= 0: found += 1
		var before := sk.get_bone_pose_rotation(sk.find_bone("mixamorig_LeftArm"))
		ap.play("ZombieWalk"); ap.seek(1.0, true); ap.advance(0.0)
		var after := sk.get_bone_pose_rotation(sk.find_bone("mixamorig_LeftArm"))
		var moved := not before.is_equal_approx(after)
		print("ANIM ", f, " tracks_matched=", found, "/", anim.get_track_count(), " arm_moved=", moved, " hips=", hips >= 0)
		if moved and found > 100: ok += 1
		else: bad += 1
	print("ANIMCHECK ok=", ok, " bad=", bad)
	quit()
