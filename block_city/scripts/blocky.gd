class_name Blocky
extends RefCounted
# Dabbe jaise insaan / chhote dabbe banane ke helpers.

static func mat(c: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = 1.0
    return m

static func box(parent: Node3D, size: Vector3, pos: Vector3, c: Color) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = size
    mi.mesh = bm
    mi.material_override = mat(c)
    mi.position = pos
    parent.add_child(mi)
    return mi

static func human(root: Node3D, shirt: Color, pants: Color, skin: Color, hair: Color) -> Dictionary:
    box(root, Vector3(0.5, 0.7, 0.26), Vector3(0, 1.05, 0), shirt)
    box(root, Vector3(0.42, 0.42, 0.42), Vector3(0, 1.62, 0), skin)
    box(root, Vector3(0.44, 0.14, 0.44), Vector3(0, 1.87, 0), hair)
    box(root, Vector3(0.09, 0.09, 0.03), Vector3(-0.1, 1.64, 0.215), Color(0.1, 0.1, 0.15))
    box(root, Vector3(0.09, 0.09, 0.03), Vector3(0.1, 1.64, 0.215), Color(0.1, 0.1, 0.15))
    var parts := {}
    for spec in [["la", -0.37, 1.38, skin], ["ra", 0.37, 1.38, skin], ["ll", -0.13, 0.7, pants], ["rl", 0.13, 0.7, pants]]:
        var piv := Node3D.new()
        piv.position = Vector3(spec[1], spec[2], 0)
        root.add_child(piv)
        var sz := Vector3(0.2, 0.7, 0.2) if spec[0].begins_with("l") and spec[0] != "la" or spec[0] == "rl" else Vector3(0.2, 0.7, 0.2)
        box(piv, sz, Vector3(0, -0.3 if spec[0].ends_with("a") else -0.35, 0), spec[3])
        parts[spec[0]] = piv
    return parts

static func animate(parts: Dictionary, speed: float, t: float) -> void:
    var s := sin(t) * clampf(speed / 4.0, 0.0, 1.0) * 0.9
    parts["la"].rotation.x = s
    parts["ra"].rotation.x = -s
    parts["ll"].rotation.x = -s
    parts["rl"].rotation.x = s
