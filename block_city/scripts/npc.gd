class_name Npc
extends CharacterBody3D
# Raahgir: sadak par tehalta hai.

const GRAV := 24.0
var parts: Dictionary
var rig: Node3D
var heading := 0.0
var turn_t := 2.0
var walk_t := 0.0

func _ready() -> void:
    var cs := CollisionShape3D.new()
    var cap := CapsuleShape3D.new()
    cap.radius = 0.34
    cap.height = 1.76
    cs.shape = cap
    cs.position.y = 0.88
    add_child(cs)
    rig = Node3D.new()
    add_child(rig)
    var r := RandomNumberGenerator.new()
    r.randomize()
    parts = Blocky.human(rig, Color.from_hsv(r.randf(), 0.55, 0.85), Color.from_hsv(r.randf(), 0.4, 0.5), Color(0.9, 0.7, 0.55), Color(0.15, 0.1, 0.05))
    heading = r.randf() * TAU
    turn_t = r.randf_range(2.0, 6.0)

func _physics_process(delta: float) -> void:
    turn_t -= delta
    if turn_t <= 0.0:
        heading += randf_range(-1.6, 1.6)
        turn_t = randf_range(2.0, 6.0)
    var dir := Vector3(sin(heading), 0, cos(heading))
    velocity.x = dir.x * 1.8
    velocity.z = dir.z * 1.8
    if not is_on_floor():
        velocity.y -= GRAV * delta
    else:
        velocity.y = -1.0
    move_and_slide()
    if is_on_wall():
        heading += PI * 0.6
        if is_on_floor():
            velocity.y = 7.2
    rig.rotation.y = lerp_angle(rig.rotation.y, heading, minf(1.0, 8.0 * delta))
    walk_t += delta * 3.0
    Blocky.animate(parts, 3.5, walk_t)
    position.x = clampf(position.x, 2.0, VoxelWorld.W - 2.0)
    position.z = clampf(position.z, 2.0, VoxelWorld.D - 2.0)
