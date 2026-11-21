extends SceneTree
# Har GLB ke materials mein texture hai ya nahi (embed ke baad jaanch).
func _initialize() -> void:
    var d := DirAccess.open("res://assets/props")
    var total := 0
    var with_tex := 0
    var missing: Array = []
    for f in d.get_files():
        if not f.ends_with(".glb"):
            continue
        total += 1
        var ps: PackedScene = load("res://assets/props/" + f)
        var inst := ps.instantiate()
        var found := false
        for m in inst.find_children("*", "MeshInstance3D", true, false):
            var mesh: Mesh = (m as MeshInstance3D).mesh
            for i in mesh.get_surface_count():
                var mat := mesh.surface_get_material(i)
                if mat is BaseMaterial3D and (mat as BaseMaterial3D).albedo_texture != null:
                    found = true
        if found:
            with_tex += 1
        else:
            missing.append(f)
        inst.free()
    print("TEXCHECK total=", total, " with_texture=", with_tex, " missing=", missing.slice(0, 8))
    quit()
