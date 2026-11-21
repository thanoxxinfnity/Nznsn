extends Node3D
# Lakdi ka khazane ka sandook. Blender se bana glb (animation 'open') use karta hai.

signal opened_signal
var is_open := false
var anim: AnimationPlayer
var beam: MeshInstance3D

func setup(scene: PackedScene) -> void:
    var inst := scene.instantiate()
    inst.scale = Vector3.ONE * 2.0
    add_child(inst)
    anim = _find_player(inst)
    var body := StaticBody3D.new()
    var cs := CollisionShape3D.new()
    var bs := BoxShape3D.new()
    bs.size = Vector3(1.3, 0.8, 0.9)
    cs.shape = bs
    cs.position.y = 0.4
    body.add_child(cs)
    add_child(body)
    # door se dikhne wali roshni ki kiran
    beam = MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 0.5; cm.bottom_radius = 0.5; cm.height = 30.0
    beam.mesh = cm
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(1.0, 0.85, 0.3, 0.4)
    m.emission_enabled = true
    m.emission = Color(1.0, 0.8, 0.2)
    m.emission_energy_multiplier = 1.5
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    beam.material_override = m
    beam.position.y = 15.0
    add_child(beam)
    var l := OmniLight3D.new()
    l.light_color = Color(1.0, 0.8, 0.4)
    l.omni_range = 7.0
    l.position.y = 1.5
    add_child(l)

func _find_player(n: Node) -> AnimationPlayer:
    if n is AnimationPlayer:
        return n
    for c in n.get_children():
        var r := _find_player(c)
        if r:
            return r
    return null

func open() -> void:
    if is_open:
        return
    is_open = true
    if beam:
        beam.queue_free()
    if anim:
        var name := "open"
        if not anim.has_animation(name):
            for a in anim.get_animation_list():
                if a != "RESET":
                    name = a
                    break
        anim.play(name)
    opened_signal.emit()

func opened_fraction() -> float:
    if anim and anim.is_playing():
        return anim.current_animation_position
    return 0.0
