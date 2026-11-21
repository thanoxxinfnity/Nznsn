extends SceneTree
# Har prop GLB ko Godot mein kholo: AABB (size, neeche ka hissa) print karo.
func _initialize() -> void:
    var d := DirAccess.open("res://assets/props")
    var files: Array = []
    for f in d.get_files():
        if f.ends_with(".glb"):
            files.append(f)
    files.sort()
    var bad := 0
    for f in files:
        var ps: PackedScene = load("res://assets/props/" + f)
        if ps == null:
            print("FAIL load ", f); bad += 1; continue
        var inst := ps.instantiate()
        root.add_child(inst)
        var aabb := AABB()
        var first := true
        var meshes := inst.find_children("*", "MeshInstance3D", true, false)
        for m in meshes:
            var mi := m as MeshInstance3D
            var a := mi.global_transform * mi.get_aabb()
            aabb = a if first else aabb.merge(a)
            first = false
        var ok := not first and absf(aabb.position.y) < 0.02 and absf(aabb.get_center().x) < 0.02 and absf(aabb.get_center().z) < 0.02
        if not ok: bad += 1
        print(("OK   " if ok else "BAD  "), f.get_basename(), "  size=(%.2f, %.2f, %.2f) bottom_y=%.3f meshes=%d" % [aabb.size.x, aabb.size.y, aabb.size.z, aabb.position.y, meshes.size()])
        inst.queue_free()
    print("CHECK ", "PASS" if bad == 0 else "FAIL %d" % bad, " files=", files.size())
    quit(0 if bad == 0 else 1)
